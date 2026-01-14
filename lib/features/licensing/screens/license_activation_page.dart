import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:savvy_stock/core/constants/app_routes.dart';
import 'package:savvy_stock/features/licensing/bloc/license_bloc.dart';
import 'package:savvy_stock/features/licensing/bloc/license_event.dart';
import 'package:savvy_stock/features/licensing/bloc/license_state.dart';

class LicenseActivationPage extends StatefulWidget {
  final bool isFromRegistration;

  const LicenseActivationPage({super.key, this.isFromRegistration = false});

  @override
  State<LicenseActivationPage> createState() => _LicenseActivationPageState();
}

class _LicenseActivationPageState extends State<LicenseActivationPage> {
  final TextEditingController _licenseKeyController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _machineId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LicenseBloc>().add(GenerateMachineId());
    });
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Machine ID copied to clipboard'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _activateLicense() {
    if (_licenseKeyController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your license key';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    // Validate and save license
    final licenseBloc = context.read<LicenseBloc>();
    licenseBloc.add(ValidateLicense(_licenseKeyController.text));
  }

  void _backToSignIn() {
    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: BlocListener<LicenseBloc, LicenseState>(
          listener: (context, state) {
            if (state.status == LicenseStatus.saved) {
              // Show success message and navigate to login
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'License activated successfully! Redirecting to details...',
                  ),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 3),
                ),
              );

              // Navigate to license details screen
              Future.delayed(const Duration(seconds: 1), () {
                if (mounted) {
                  context.go(AppRoutes.licenseDetails);
                }
              });
            } else if (state.status == LicenseStatus.error ||
                state.status == LicenseStatus.invalid) {
              setState(() {
                _isSubmitting = false;
                _errorMessage = state.errorMessage;
              });
            } else if (state.status == LicenseStatus.valid) {
              // Save the validated license
              context.read<LicenseBloc>().add(
                SaveLicense(_licenseKeyController.text),
              );
            } else if (state.machineId != null && _machineId == null) {
              setState(() {
                _machineId = state.machineId;
              });
            }
          },
          child: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo and Header
                    _buildHeader(),

                    const SizedBox(height: 20),

                    // Main Card
                    _buildLicenseCard(),

                    const SizedBox(height: 20),

                    // Support Section
                    _buildSupportSection(),

                    const SizedBox(height: 20),

                    // Footer
                    _buildFooter(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Savvy Lite',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF145888),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'License Activation Required',
          style: TextStyle(fontSize: 16, color: Colors.grey[700]),
        ),
      ],
    );
  }

  Widget _buildLicenseCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),

            // Instruction
            Text(
              'To activate your software, please provide your Machine ID to your '
              'account manager to receive a license key.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),

            const SizedBox(height: 24),

            // Machine ID Block
            _buildMachineIdBlock(),

            const SizedBox(height: 24),

            // License Key Block
            _buildLicenseKeyBlock(),

            const SizedBox(height: 24),

            // Error Message
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                ),
              ),

            // Activate Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _activateLicense,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF145888),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Activate Software',
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 16),

            // Back to Sign In
            if (widget.isFromRegistration)
              Center(
                child: GestureDetector(
                  onTap: _backToSignIn,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Text(
                      'Back to Sign In',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 14,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMachineIdBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Machine ID',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey[100],
          ),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: BlocBuilder<LicenseBloc, LicenseState>(
                    builder: (context, state) {
                      if (state.status == LicenseStatus.loading) {
                        return const Row(
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 8),
                            Text('Generating Machine ID...'),
                          ],
                        );
                      }

                      final machineId = state.machineId ?? _machineId;
                      return Text(
                        machineId ?? 'Failed to generate Machine ID',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      );
                    },
                  ),
                ),
              ),
              IconButton(
                onPressed: _machineId != null
                    ? () => _copyToClipboard(_machineId!)
                    : null,
                icon: const Icon(Icons.copy),
                tooltip: 'Copy Machine ID',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLicenseKeyBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Enter Your License Key',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: _licenseKeyController,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'Paste your license key here...',
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(12),
            ),
            style: const TextStyle(fontFamily: 'monospace'),
          ),
        ),
      ],
    );
  }

  Widget _buildSupportSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Having Trouble?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              _buildSupportItem(
                Icons.email,
                'Email us at: ',
                'info@techequations.com',
                'mailto:info@techequations.com',
              ),
              const SizedBox(height: 12),
              _buildSupportItem(
                Icons.phone,
                'Call us at: ',
                '+251 993 53 6047',
                'tel:+251993536047',
              ),
              const SizedBox(height: 12),
              _buildSupportItem(
                Icons.book,
                'Visit our support docs: ',
                'FAQ',
                'https://techequations.com/web/FAQ',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSupportItem(
    IconData icon,
    String label,
    String value,
    String url,
  ) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.blue[700]),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(color: Colors.grey[800], fontSize: 14),
              children: [
                TextSpan(text: label),
                WidgetSpan(
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () {
                        // Handle URL opening
                        // You might want to use url_launcher package
                      },
                      child: Text(
                        value,
                        style: TextStyle(
                          color: Colors.blue[700],
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    final year = DateTime.now().year;
    return Center(
      child: Text(
        '© $year Tech Equations Technology PLC. All Rights Reserved.',
        style: TextStyle(color: Colors.grey[600], fontSize: 12),
        textAlign: TextAlign.center,
      ),
    );
  }
}
