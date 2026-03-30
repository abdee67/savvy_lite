import 'package:flutter/material.dart';

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
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
              'Privacy Policy - Savvy Stock',
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
            _SectionHeading('1. Introduction and Our Commitment to Privacy'),
            _SectionContent(
              'Welcome to Savvy Stock. This Privacy Policy outlines the practices of Tech Equations Technology PLC ("Company," "We," "Us," "Our") regarding the collection, use, and disclosure of information when you use our stock management platform and related services (collectively, the "Service").',
            ),
            _SectionContent(
              'We are committed to protecting your privacy and handling your data in an open and transparent manner. This policy is designed to help you understand:',
            ),
            _BulletItem('What information we collect.'),
            _BulletItem(
              'How we use that information and the legal basis for doing so.',
            ),
            _BulletItem('How we share and disclose information.'),
            _BulletItem('Your rights regarding your data.'),
            _SectionContent(
              'This Privacy Policy should be read in conjunction with our Terms of Service. By using the Service, you agree to the collection and use of information in accordance with this policy.',
            ),
            _SectionHeading('2. The Scope of This Policy'),
            _SectionContent(
              'This policy applies to the information we collect when you:',
            ),
            _BulletItem('Create an account and use the Savvy Stock Service.'),
            _BulletItem(
              'Visit our marketing website (www.techequations.com/web).',
            ),
            _BulletItem(
              'Communicate with us for customer support or other inquiries.',
            ),
            const SizedBox(height: 12),
            const Text(
              'A critical distinction:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            _SectionContent(
              'Personal Data: Information that directly or indirectly identifies an individual (e.g., name, email). For this, we are the Data Controller.',
            ),
            _SectionContent(
              'Client Data: Information uploaded by you (inventory, transactions, etc.). For this, you are the Data Controller, and we act as a Data Processor.',
            ),
            _SectionHeading('3. Information We Collect'),
            const Text(
              '3.1 Information You Provide to Us:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            _BulletItem(
              'Account and Registration: Name, company, email, phone, password.',
            ),
            _BulletItem(
              'Payment: Billing/payment details via secure processor.',
            ),
            _BulletItem('Client Data: Business-specific data you input.'),
            _BulletItem(
              'Communications: Info you send during support or feedback.',
            ),
            const SizedBox(height: 12),
            const Text(
              '3.2 Information We Collect Automatically:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            _BulletItem('Usage Data: Features used, session time, etc.'),
            _BulletItem('Log Data: IP address, browser, OS, timestamps.'),
            _BulletItem(
              'Cookies: We use cookies to improve experience and analytics.',
            ),
            _SectionHeading('4. How We Use Your Information'),
            _SectionContent(
              'The following table outlines our purposes for processing data and the legal basis:',
            ),
            const SizedBox(height: 8),
            _buildPrivacyTable(context),
            const SizedBox(height: 16),
            const Text(
              'We never sell your Personal or Client Data.',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            _SectionHeading('5. How We Share and Disclose Information'),
            _BulletItem(
              'Sub-processors: AWS, Chapa, Telebir, etc. under data protection agreements.',
            ),
            _BulletItem(
              'Legal Requirements: If compelled by law or necessary to protect rights/safety.',
            ),
            _BulletItem(
              'Business Transfers: In mergers or acquisitions, with prior notice.',
            ),
            _BulletItem('With Consent: Explicitly granted integrations.'),
            _BulletItem(
              'Aggregated Data: Shared for research/marketing, never personally identifiable.',
            ),
            _SectionHeading('6. Data Security'),
            _SectionContent(
              'We implement TLS/SSL encryption, strict access control, and routine audits. However, no method is 100% secure.',
            ),
            _SectionHeading('7. Data Retention'),
            _SectionContent(
              'We retain your data while your account is active and as legally required. Client Data is available for export for 30 days post-termination before deletion.',
            ),
            _SectionHeading('8. Your Rights and Choices'),
            _BulletItem('Right to Access'),
            _BulletItem('Right to Rectify'),
            _BulletItem('Right to Erasure'),
            _BulletItem('Right to Restrict Processing'),
            _BulletItem('Right to Portability'),
            _BulletItem('Right to Object (e.g., marketing)'),
            _SectionContent(
              'Contact your admin for Client Data requests. We support our clients in fulfilling user rights.',
            ),
            _SectionHeading('9. International Data Transfers'),
            _SectionContent(
              'Data may be transferred outside your country. We use mechanisms like SCCs to safeguard this.',
            ),
            _SectionHeading('10. Children\'s Privacy'),
            _SectionContent(
              'The Service is not intended for those under 16. We do not knowingly collect such data.',
            ),
            _SectionHeading('11. Changes to This Privacy Policy'),
            _SectionContent(
              'If we make material changes, we will notify you by email or a prominent notice. Please review periodically.',
            ),
            _SectionHeading('12. Contact Information'),
            const Text(
              'Data Protection Officer / Privacy Team\n'
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

  Widget _buildPrivacyTable(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(
          const Color(0xFF145888).withOpacity(0.1),
        ),
        columns: const [
          DataColumn(
            label: Text(
              'Purpose',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              'Type of Data',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              'Legal Basis',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
        rows: const [
          DataRow(
            cells: [
              DataCell(Text('Provide Service')),
              DataCell(Text('Account, Client, Usage')),
              DataCell(Text('Contract')),
            ],
          ),
          DataRow(
            cells: [
              DataCell(Text('Process Payments')),
              DataCell(Text('Payment Info')),
              DataCell(Text('Contract')),
            ],
          ),
          DataRow(
            cells: [
              DataCell(Text('Communicate')),
              DataCell(Text('Account, Comms')),
              DataCell(Text('Contract/Interest')),
            ],
          ),
          DataRow(
            cells: [
              DataCell(Text('Improve Service')),
              DataCell(Text('Usage, Logs, Feedback')),
              DataCell(Text('Interest')),
            ],
          ),
          DataRow(
            cells: [
              DataCell(Text('Security')),
              DataCell(Text('Account, Log, Usage')),
              DataCell(Text('Interest/Legal')),
            ],
          ),
          DataRow(
            cells: [
              DataCell(Text('Marketing')),
              DataCell(Text('Account, Preferences')),
              DataCell(Text('Consent')),
            ],
          ),
          DataRow(
            cells: [
              DataCell(Text('Legal Compliance')),
              DataCell(Text('Relevant data')),
              DataCell(Text('Legal Obligation')),
            ],
          ),
        ],
      ),
    );
  }
}
