import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:savvy_stock/core/constants/app_routes.dart';
import 'package:savvy_stock/features/registration/blocs/registration_bloc.dart';
import 'package:flutter/gestures.dart';
import 'package:savvy_stock/features/registration/screens/terms.dart';
import 'package:savvy_stock/features/registration/screens/privacy.dart';

class ConfirmationPage extends StatefulWidget {
  const ConfirmationPage({super.key});

  @override
  State<ConfirmationPage> createState() => _ConfirmationPageState();
}

class _ConfirmationPageState extends State<ConfirmationPage> {
  bool agreeTerms = false;
  bool _isSubmitting = false;

  void onSubscribe() {
    if (!agreeTerms) return;
    context.read<RegistrationBloc>().add(const SubmitRegistration());
  }

  void _redirectToLicenseActivation() {
    if (mounted) {
      // Navigate to login page
      context.go(AppRoutes.login);
    }
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF145888), Color(0xFF0D2C57)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.amber, size: 70),
              const SizedBox(height: 15),
              const Text(
                "Free Trial Activated!",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Your account has been created with a 5-day free trial (3 Users, 2 Branches). Please login to continue.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                onPressed: _redirectToLicenseActivation,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Text(
                    "Login",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final isTablet = screen.width > 600;

    return BlocListener<RegistrationBloc, RegistrationState>(
      listener: (context, state) {
        if (state.status == RegistrationStatus.registering) {
          setState(() => _isSubmitting = true);
        } else if (state.status == RegistrationStatus.success) {
          setState(() => _isSubmitting = false);
          _showSuccessDialog(context);
        } else if (state.status == RegistrationStatus.failure) {
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message ?? 'Registration failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0051FF),
                Color(0xFF5093F7),
                Color(0xFF58F8C3),
                Color(0xFF0051FF),
              ],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 30 : 18,
                vertical: isTablet ? 60 : 40,
              ),
              child: BlocBuilder<RegistrationBloc, RegistrationState>(
                builder: (context, state) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🔹 Back Button
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              if (!_isSubmitting) {
                                Navigator.pop(context);
                              }
                            },
                          ),
                          const SizedBox(width: 16),
                        ],
                      ),
                      // 🔹 Step Indicator
                      Center(child: _buildStepDots()),

                      const SizedBox(height: 30),

                      const Text(
                        "Confirm",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "Review Your Information",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 30),

                      // 🔹 Review Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionTitle("Company Details"),
                            _infoRow("Company Name", state.company.companyName),
                            _infoRow(
                              "Company Phone",
                              state.company.phoneNumber1 ?? '',
                            ),
                            _infoRow("City", state.company.city ?? ''),

                            const SizedBox(height: 10),
                            _sectionTitle("Administrator Account Details"),
                            _infoRow(
                              "Full Name",
                              "${state.employee.nameFirst} ${state.employee.nameMiddle} ${state.employee.nameLast}"
                                  .trim(),
                            ),
                            _infoRow(
                              "Admin Email",
                              state.adminUser.userEmail ?? '',
                            ),
                            _infoRow("Admin Phone", state.employee.phone),
                            _infoRow(
                              "Username",
                              state.adminUser.userName ?? '',
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      // 🔹 Terms Checkbox
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(color: Colors.white70),
                            ),
                            child: Checkbox(
                              value: agreeTerms,
                              onChanged: (v) {
                                setState(() => agreeTerms = v!);
                              },
                              activeColor: Colors.amber,
                              checkColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              side: const BorderSide(color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  const TextSpan(
                                    text: 'I Agree to the ',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'Terms of Service',
                                    style: TextStyle(
                                      color: Colors.amber.shade200,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => const TermsPage(),
                                          ),
                                        );
                                      },
                                  ),
                                  const TextSpan(
                                    text: ' and ',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'Privacy Policy',
                                    style: TextStyle(
                                      color: Colors.amber.shade200,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => const PrivacyPage(),
                                          ),
                                        );
                                      },
                                  ),
                                  const TextSpan(
                                    text: ' *',
                                    style: TextStyle(
                                      color: Colors.redAccent,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 40),

                      // 🔹 Subscribe Button (blurred until checkbox checked)
                      Opacity(
                        opacity: agreeTerms ? 1 : 0.4,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(25),
                          child: BackdropFilter(
                            filter: agreeTerms
                                ? ImageFilter.blur(sigmaX: 0, sigmaY: 0)
                                : ImageFilter.blur(sigmaX: 2.5, sigmaY: 2.5),
                            child: ElevatedButton(
                              onPressed: agreeTerms && !_isSubmitting
                                  ? onSubscribe
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 40,
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: agreeTerms ? 6 : 0,
                              ),
                              child: Center(
                                child: _isSubmitting
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.black,
                                        ),
                                      )
                                    : const Text(
                                        "Subscribe and Create Account",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 60),

                      // 🔹 Bottom Progress Dots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildProgressDot(false),
                          const SizedBox(width: 8),
                          _buildProgressDot(false),
                          const SizedBox(width: 8),
                          _buildProgressDot(false),
                          const SizedBox(width: 8),
                          _buildProgressDot(false),
                          const SizedBox(width: 8),
                          _buildProgressDot(true),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 🟣 Step Dots (Top)
  Widget _buildStepDots() {
    final steps = ["Company", "Address", "Branch", "Admin", "Confirm"];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: steps.map((step) {
        final isActive = step == "Confirm";
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 5),
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 7),
          decoration: BoxDecoration(
            color: isActive
                ? Colors.amber
                : Colors.white.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            step,
            style: TextStyle(
              color: isActive ? Colors.black : Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }).toList(),
    );
  }

  // 🧾 Info Row
  Widget _infoRow(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.amber,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildProgressDot(bool active) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: active ? Colors.amber : Colors.white54,
        shape: BoxShape.circle,
      ),
    );
  }
}
