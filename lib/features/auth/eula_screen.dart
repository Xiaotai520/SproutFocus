import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// The product / company names referenced throughout the agreement.
const String kEulaAppName = 'Sprout Focus';
const String kEulaCompany = 'CodingMind';
const String kEulaContactEmail = 'support@codingmind.app';
const String kEulaLastUpdated = 'June 4, 2026';

/// Full End User License Agreement text. Includes the minimum terms Apple
/// requires of a custom EULA (Acknowledgement, Scope of License, Warranty,
/// Product Claims, Third-Party Beneficiary, etc.).
const String kEulaText =
    '''
END USER LICENSE AGREEMENT

Last updated: $kEulaLastUpdated

This End User License Agreement ("Agreement") is a legal agreement between you ("you" or "User") and $kEulaCompany ("we", "us", or the "Licensor") governing your use of the $kEulaAppName mobile application and any companion hardware device (together, the "Application"). By creating an account, or by installing or using the Application, you agree to be bound by this Agreement. If you do not agree, do not create an account or use the Application.

1. ACKNOWLEDGEMENT
This Agreement is concluded between you and $kEulaCompany only, and not with Apple Inc. ("Apple"). $kEulaCompany, not Apple, is solely responsible for the Application and its content. Apple has no obligation to furnish any maintenance or support services with respect to the Application.

2. SCOPE OF LICENSE
We grant you a limited, non-exclusive, non-transferable, revocable license to use the Application for your personal, non-commercial purposes on any Apple- or Android-branded device that you own or control, as permitted by the usage rules of the applicable app store. You may not redistribute, sell, lease, sublicense, reverse engineer, decompile, or otherwise attempt to derive the source code of the Application, except to the extent permitted by law.

3. ACCOUNTS
To use certain features you must create an account using a valid email address and password. You are responsible for maintaining the confidentiality of your credentials and for all activity under your account. You agree to provide accurate information and to keep it current. You may delete your account at any time from within the Application.

4. BLUETOOTH HARDWARE
The Application communicates with a companion focus-locker device over Bluetooth to start and time focus sessions. You are responsible for the safe and lawful use of the device and for any items you place in it. We are not responsible for any loss of, or inability to access, items placed in the device.

5. ACCEPTABLE USE
You agree not to use the Application for any unlawful purpose, to interfere with its operation, or to attempt to gain unauthorized access to any account, system, or network.

6. MAINTENANCE AND SUPPORT
$kEulaCompany is solely responsible for providing any maintenance and support services for the Application, as required under applicable law. You may contact us at $kEulaContactEmail.

7. WARRANTY DISCLAIMER
The Application is provided "AS IS" and "AS AVAILABLE" without warranties of any kind, whether express or implied, including but not limited to implied warranties of merchantability, fitness for a particular purpose, and non-infringement. In the event of any failure of the Application to conform to any applicable warranty, you may notify Apple, and Apple may refund the purchase price (if any) to you; to the maximum extent permitted by law, Apple will have no other warranty obligation whatsoever with respect to the Application.

8. LIMITATION OF LIABILITY
To the maximum extent permitted by law, $kEulaCompany shall not be liable for any indirect, incidental, special, consequential, or punitive damages, or any loss of data, profits, or goodwill, arising out of or related to your use of the Application.

9. PRODUCT CLAIMS
$kEulaCompany, not Apple, is responsible for addressing any claims by you or any third party relating to the Application or your possession and/or use of the Application, including but not limited to: (a) product liability claims; (b) any claim that the Application fails to conform to any applicable legal or regulatory requirement; and (c) claims arising under consumer protection, privacy, or similar legislation.

10. INTELLECTUAL PROPERTY
In the event that a third party claims the Application or your possession and use of the Application infringes that third party's intellectual property rights, $kEulaCompany, not Apple, will be solely responsible for the investigation, defense, settlement, and discharge of any such claim.

11. LEGAL COMPLIANCE
You represent and warrant that you are not located in a country subject to a U.S. Government embargo, or designated as a "terrorist supporting" country, and that you are not listed on any U.S. Government list of prohibited or restricted parties.

12. TERMINATION
This Agreement is effective until terminated by you or by us. Your rights under this Agreement will terminate automatically if you fail to comply with any of its terms. Upon termination, you must stop all use of the Application.

13. THIRD-PARTY BENEFICIARY
You acknowledge and agree that Apple and Apple's subsidiaries are third-party beneficiaries of this Agreement, and that, upon your acceptance of this Agreement, Apple will have the right (and will be deemed to have accepted the right) to enforce this Agreement against you as a third-party beneficiary thereof.

14. PRIVACY
Our handling of your personal information, including your email address, is described in our Privacy Policy. By using the Application you consent to that processing.

15. CHANGES
We may update this Agreement from time to time. Continued use of the Application after changes become effective constitutes acceptance of the revised Agreement.

16. CONTACT
If you have any questions about this Agreement, contact us at $kEulaContactEmail.
''';

/// Read-only screen that displays the full EULA.
class EulaScreen extends StatelessWidget {
  const EulaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('License Agreement')),
      body: const SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Text(
            kEulaText,
            style: TextStyle(fontSize: 14, height: 1.5, color: AppColors.ink),
          ),
        ),
      ),
    );
  }
}
