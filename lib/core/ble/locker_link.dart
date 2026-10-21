import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../../app/app_config.dart';

/// Lifecycle phase of the focus planter, as reported over BLE.
///   idle    — connected, waiting for a duration (wire: SET_TIME)
///   growing — locked, counting down (wire: LOCKED)
///   bloomed — unlocked, session finished (wire: UNLOCKED)
///   offline — not connected
///   unknown — connected but no status seen yet
enum LockerPhase { idle, growing, bloomed, offline, unknown }

/// Talks to the ESP32-S3 focus planter over the Nordic UART Service.
///
/// The on-the-wire protocol (device name, service/characteristic UUIDs, the
/// `T:` / `LOCK` commands and the `STATUS:` lines) is fixed by the firmware and
/// must never change — only the Dart-side names around it differ.
class LockerLink extends ChangeNotifier {
  /// The device firmware accepts sessions from one to sixty minutes.
  static const int maxSessionMinutes = 60;
  static const String _deviceName = 'PhoneLocker';

  static final Guid _serviceUuid = Guid('6e400001-b5a3-f393-e0a9-e50e24dcca9e');
  static final Guid _txUuid = Guid('6e400003-b5a3-f393-e0a9-e50e24dcca9e');
  static final Guid _rxUuid = Guid('6e400002-b5a3-f393-e0a9-e50e24dcca9e');

  // --- Observable state ---
  LockerPhase _phase = LockerPhase.offline;
  int? _plannedMinutes;
  int? _remainingSeconds;
  bool _scanning = false;

  LockerPhase get phase => _phase;
  int? get plannedMinutes => _plannedMinutes;
  int? get remainingSeconds => _remainingSeconds;
  bool get scanning => _scanning;
  bool get connected =>
      _simulated ? _simConnected : (_device?.isConnected ?? false);

  // --- Simulation ---
  bool _simulated = false;
  bool get isSimulated => kSimulateLocker || _simulated;
  bool _simConnected = false;
  Timer? _simTimer;
  int _simRemaining = 0;

  // --- Real hardware handles ---
  BluetoothDevice? _device;
  BluetoothCharacteristic? _rxChar;
  BluetoothCharacteristic? _txChar;
  StreamSubscription? _scanSub;
  StreamSubscription? _isScanningSub;
  StreamSubscription? _connSub;
  StreamSubscription? _notifySub;
  String _buffer = '';
  bool _connecting = false;

  void _setPhase(LockerPhase phase, {int? minutes, int? seconds}) {
    _phase = phase;
    if (minutes != null) _plannedMinutes = minutes;
    _remainingSeconds = seconds;
    notifyListeners();
  }

  void _setScanning(bool value) {
    _scanning = value;
    notifyListeners();
  }

  /// Begin a simulated session with no hardware attached.
  Future<void> connectSimulated() async {
    _simulated = true;
    _simConnected = true;
    _setPhase(LockerPhase.idle);
  }

  /// Scan for the planter and connect. Throws if it can't be found.
  Future<void> scanAndConnect() async {
    if (connected) {
      // A newly connected planter is ready to receive T:<minutes>.  Waiting
      // for a status packet here makes the setup screen inaccessible on
      // firmware that only emits STATUS:SET_TIME after that first command.
      if (_phase == LockerPhase.unknown) _setPhase(LockerPhase.idle);
      return;
    }

    if (isSimulated) {
      _setScanning(true);
      await Future.delayed(const Duration(milliseconds: 500));
      _setScanning(false);
      _simConnected = true;
      _setPhase(LockerPhase.idle);
      return;
    }

    final adapter = await FlutterBluePlus.adapterState.first;
    if (adapter != BluetoothAdapterState.on) {
      throw Exception('Bluetooth is not enabled');
    }

    _setScanning(true);
    final completer = Completer<void>();
    var scanStarted = false;

    _scanSub?.cancel();
    _isScanningSub?.cancel();
    _scanSub = FlutterBluePlus.onScanResults.listen((results) {
      for (final r in results) {
        if (r.device.platformName == _deviceName) {
          unawaited(_connectScannedDevice(r.device, completer));
          return;
        }
      }
    }, onError: (Object error, StackTrace stackTrace) {
      _completeScanError(completer, error, stackTrace);
    });

    _isScanningSub = FlutterBluePlus.isScanning.listen((scanning) {
      if (scanStarted && !scanning && !_connecting && !completer.isCompleted) {
        _completeScanError(
          completer,
          Exception('Planter not found'),
          StackTrace.empty,
        );
      }
    });

    try {
      await FlutterBluePlus.startScan(
        withNames: [_deviceName],
        timeout: const Duration(seconds: 10),
      );
      scanStarted = true;
    } catch (error, stackTrace) {
      _completeScanError(completer, error, stackTrace);
    }

    return completer.future.whenComplete(_stopScanListeners);
  }

  Future<void> _connectScannedDevice(
      BluetoothDevice device, Completer<void> completer) async {
    if (_connecting || completer.isCompleted) return;

    _connecting = true;
    try {
      await FlutterBluePlus.stopScan();
      await _connect(device);
      if (!completer.isCompleted) completer.complete();
    } catch (error, stackTrace) {
      _completeScanError(completer, error, stackTrace);
    } finally {
      _connecting = false;
    }
  }

  void _completeScanError(
      Completer<void> completer, Object error, StackTrace stackTrace) {
    _setScanning(false);
    if (!completer.isCompleted) completer.completeError(error, stackTrace);
  }

  Future<void> _stopScanListeners() async {
    _setScanning(false);
    await _scanSub?.cancel();
    await _isScanningSub?.cancel();
    _scanSub = null;
    _isScanningSub = null;
  }

  /// Give up on an in-flight scan. Used by the garden screen so a demo isn't
  /// held hostage by a 10-second timeout in a radio-noisy room.
  Future<void> cancelScan() async {
    // The local scanner stays busy through connection setup. stopScan cannot
    // cancel that connection, so keep Plant disabled until it finishes.
    if (!_scanning || _connecting) return;
    await _scanSub?.cancel();
    _scanSub = null;
    if (!isSimulated) {
      try {
        await FlutterBluePlus.stopScan();
      } catch (_) {
        // Already stopped — nothing to undo.
      }
    }
    _setScanning(false);
  }

  Future<void> _connect(BluetoothDevice device) async {
    _device = device;
    await device.connect(autoConnect: false);

    _connSub?.cancel();
    _connSub = device.connectionState.listen((state) {
      if (state == BluetoothConnectionState.disconnected) {
        _cleanup();
        _setPhase(LockerPhase.offline);
      }
    });

    final services = await device.discoverServices();
    final service = services.cast<BluetoothService?>().firstWhere(
      (s) => s?.uuid == _serviceUuid,
      orElse: () => null,
    );
    if (service == null) {
      await device.disconnect();
      throw Exception('Nordic UART Service not found on device');
    }

    for (final c in service.characteristics) {
      if (c.uuid == _rxUuid) _rxChar = c;
      if (c.uuid == _txUuid) _txChar = c;
    }
    if (_rxChar == null || _txChar == null) {
      await device.disconnect();
      throw Exception('UART characteristics not found');
    }

    await _txChar!.setNotifyValue(true);
    _notifySub = _txChar!.onValueReceived.listen(_onData);
    // The first status line is only sent after a command on some firmware
    // versions, but this is still a usable, ready-to-configure connection.
    _setPhase(LockerPhase.idle);
  }

  void _onData(List<int> data) {
    _buffer += utf8.decode(data);
    while (_buffer.contains('\n')) {
      final i = _buffer.indexOf('\n');
      final line = _buffer.substring(0, i).trim();
      _buffer = _buffer.substring(i + 1);
      if (line.isNotEmpty) _parseLine(line);
    }
  }

  void _parseLine(String line) {
    // STATUS:SET_TIME:<min>, STATUS:LOCKED:<sec>, STATUS:UNLOCKED
    if (!line.startsWith('STATUS:')) return;
    final parts = line.split(':');
    if (parts.length < 2) return;
    switch (parts[1]) {
      case 'SET_TIME':
        _setPhase(
          LockerPhase.idle,
          minutes: parts.length >= 3 ? int.tryParse(parts[2]) : null,
        );
        break;
      case 'LOCKED':
        _setPhase(
          LockerPhase.growing,
          seconds: parts.length >= 3 ? int.tryParse(parts[2]) : null,
        );
        break;
      case 'UNLOCKED':
        _setPhase(LockerPhase.bloomed);
        break;
    }
  }

  /// Send a duration accepted by the firmware (1–60 minutes).
  Future<void> setTime(int minutes) async {
    if (minutes < 1 || minutes > maxSessionMinutes) {
      throw ArgumentError.value(
        minutes,
        'minutes',
        'must be between 1 and $maxSessionMinutes',
      );
    }
    if (isSimulated) {
      _simRemaining = minutes * 60;
      _plannedMinutes = minutes;
      notifyListeners();
      return;
    }
    await _send('T:$minutes');
  }

  /// Engage the lock and start the countdown.
  Future<void> lock() async {
    if (isSimulated) {
      _setPhase(LockerPhase.growing, seconds: _simRemaining);
      _simTimer?.cancel();
      // Virtual seconds tick down faster than wall-clock so a demo session
      // completes while someone is watching. The countdown the user reads is
      // still in session-seconds, so the plant and the clock stay in step.
      final period = Duration(
        milliseconds: (1000 / kDemoSpeedFactor).round().clamp(16, 1000),
      );
      _simTimer = Timer.periodic(period, (_) {
        _simRemaining--;
        if (_simRemaining <= 0) {
          _simTimer?.cancel();
          _setPhase(LockerPhase.bloomed);
          Future.delayed(const Duration(seconds: 3), () {
            if (_simConnected) _setPhase(LockerPhase.idle);
          });
        } else {
          _setPhase(LockerPhase.growing, seconds: _simRemaining);
        }
      });
      return;
    }
    await _send('LOCK');
  }

  Future<void> _send(String command) async {
    if (_rxChar == null) throw Exception('Not connected to planter');
    await _rxChar!.write(utf8.encode('$command\n'), withoutResponse: false);
  }

  Future<void> disconnect() async {
    if (isSimulated) {
      _simTimer?.cancel();
      _simConnected = false;
      _simulated = false;
      _setPhase(LockerPhase.offline);
      return;
    }
    await _device?.disconnect();
    _cleanup();
    _setPhase(LockerPhase.offline);
  }

  void _cleanup() {
    _notifySub?.cancel();
    _notifySub = null;
    _rxChar = null;
    _txChar = null;
    _device = null;
  }

  @override
  void dispose() {
    _simTimer?.cancel();
    _scanSub?.cancel();
    _isScanningSub?.cancel();
    _connSub?.cancel();
    _notifySub?.cancel();
    super.dispose();
  }
}
