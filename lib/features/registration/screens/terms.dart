import 'package:flutter/material.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
        elevation: 0,
        backgroundColor: const Color(0xFF145888),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Terms of Service - Savvy Stock',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF145888),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Last Updated: July 1, 2025',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            const Text(
              'This is a legally binding agreement. Please read it carefully.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _SectionHeading('1. Introduction'),
            _SectionContent(
              'By using Savvy Stock, you agree to these Terms on behalf of the business you represent. If you do not agree or lack authority, do not use the Service.',
            ),
            _SectionHeading('2. Definitions'),
            _BulletItem('Service: The Savvy Stock platform and APIs.'),
            _BulletItem('Client Data: Data submitted by you or your users.'),
            _BulletItem(
              'Authorized User: Individuals using the Service under your account.',
            ),
            _BulletItem(
              'Confidential Information: Non-public, sensitive data disclosed between parties.',
            ),
            _BulletItem(
              'Subscription Term: Duration of your active subscription.',
            ),
            _SectionHeading('3. User Accounts'),
            _BulletItem(
              'Provide accurate registration info and maintain security of credentials.',
            ),
            _BulletItem('You are liable for actions of all Authorized Users.'),
            _SectionHeading('4. License and Acceptable Use'),
            _SectionContent(
              'You are granted a limited license for internal business use. You must not:',
            ),
            _BulletItem('Use the Service unlawfully or maliciously.'),
            _BulletItem(
              'Reverse-engineer, resell, or probe the system without consent.',
            ),
            _SectionContent(
              'The Service may be updated but its core features will not be removed during your subscription.',
            ),
            _SectionHeading('5. Payment and Billing'),
            _BulletItem('Fees are billed in advance, in ETB, excluding taxes.'),
            _BulletItem(
              'Subscriptions renew automatically unless canceled before term ends.',
            ),
            _BulletItem('Non-payment may result in service suspension.'),
            _BulletItem('Fees are non-refundable unless required by law.'),
            _SectionHeading('6. Intellectual Property & Data'),
            _BulletItem('We retain rights to the platform and trademarks.'),
            _BulletItem(
              'You retain ownership of your data; we may process it to provide the Service.',
            ),
            _BulletItem('Data is protected per our Privacy Policy.'),
            _BulletItem('We may use your feedback without obligation.'),
            _SectionHeading('7. Confidentiality'),
            _SectionContent(
              'Both parties agree to protect each other’s confidential data with reasonable care, unless it becomes public, was previously known, or legally disclosed.',
            ),
            _SectionHeading('8. Indemnification'),
            _SectionContent(
              'You agree to hold us harmless against claims or damages resulting from your use of the Service or violation of these Terms.',
            ),
            _SectionHeading('9. Term & Termination'),
            _BulletItem('Terms are active while your subscription is active.'),
            _BulletItem('Either party may terminate for material breach.'),
            _BulletItem(
              'After termination, your data is retained for 30 days for export before deletion.',
            ),
            _SectionHeading('10. Changes to Terms'),
            _SectionContent(
              'We may update these Terms with 30 days\' notice via email or in-app notification. Continued use signifies acceptance.',
            ),
            _SectionHeading('11. General Provisions'),
            _BulletItem('Governing Law: Ethiopia'),
            _BulletItem('Disputes: Resolved via arbitration in Addis Ababa'),
            _BulletItem('Force Majeure: Not liable for events beyond control'),
            _BulletItem('Entire Agreement: Includes Terms and Privacy Policy'),
            _BulletItem('Severability: Invalid parts do not affect the rest'),
            _BulletItem(
              'Assignment: You cannot assign without our consent; we may assign during M&A',
            ),
            _SectionHeading('12. Contact'),
            const Text(
              'Tech Equations Technology PLC\n'
              'Sarbet Lidiya Building office No. 505\n'
              'Phone: +251 91 250 3117 or +251 93 572 4920\n'
              'Email: info@techequations.com',
              style: TextStyle(height: 1.5),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _SectionHeading(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF145888),
        ),
      ),
    );
  }

  Widget _SectionContent(String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(content, style: const TextStyle(fontSize: 16, height: 1.5)),
    );
  }

  Widget _BulletItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
