/// Set to true to bypass Bluetooth and grow a simulated session locally.
/// Handy for the iOS Simulator and for capturing App Store screenshots.
const bool kSimulateLocker = false;

/// Whether Settings offers the demo-mode toggle. Hidden in shipping builds so
/// judges and users can't put the app into a simulated state by accident; the
/// mode itself is untouched, so flipping this back exposes it again. The
/// "grow without device" prompt after a failed scan is unaffected.
const bool kShowDemoModeToggle = false;

/// How much faster a *simulated* session runs than real time. Only ever
/// applied on the simulated path — the hardware owns its own clock and is
/// never sped up. A factor of 3 means a "1 minute" demo blooms in ~20 s,
/// which is short enough to show a judge end-to-end at a booth.
const int kDemoSpeedFactor = 3;
