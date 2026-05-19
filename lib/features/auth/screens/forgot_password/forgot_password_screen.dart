import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:savvy_stock/core/constants/app_routes.dart';
import 'package:savvy_stock/core/services/conectitvity_service.dart';
import 'package:savvy_stock/core/widgets/custom_text_Form.dart';
import 'package:savvy_stock/features/auth/blocs/password_reset/password_reset_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

/// Screen for entering email to request password reset
class ForgotPasswordScreen extends StatefulWidget {
  final ConnectivityService connectivityService;
  const ForgotPasswordScreen({super.key, required this.connectivityService});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSendResetEmail() async {
    if (_formKey.currentState?.validate() ?? false) {
      FocusScope.of(context).unfocus();

      // Check for network connectivity
      final connectivityResult = await widget.connectivityService
          .checkConnectivity();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(connectivityResult.toString()),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      return;
    }

    if (mounted) {
      context.read<PasswordResetBloc>().add(
        SendPasswordResetCode(email: _emailController.text.trim()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PasswordResetBloc, PasswordResetState>(
      listener: (context, state) {
        if (state.status == PasswordResetStatus.emailSent) {
          // Navigate to email sent confirmation screen
          context.push(
            AppRoutes.resetEmailSent,
            extra: {
              'email': _emailController.text.trim(),
              'bloc': context.read<PasswordResetBloc>(),
            },
          );
        }
        if (state.status == PasswordResetStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message ?? 'An error occurred'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state.status == PasswordResetStatus.loading;

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                context.read<PasswordResetBloc>().add(
                  const ResetPasswordResetState(),
                );
                context.pop();
              },
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(
              color: Color.fromARGB(255, 12, 71, 114),
            ),
          ),
          body: SafeArea(
            child: Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 40),
                        // Header Icon
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(
                              255,
                              12,
                              71,
                              114,
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: const Icon(
                            Icons.lock_reset,
                            size: 50,
                            color: Color.fromARGB(255, 12, 71, 114),
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Title
                        const Text(
                          'Forgot Password?',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 21, 88, 136),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Subtitle
                        Text(
                          'Enter the email address associated with your account and we\'ll send you a link to reset your password.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 40),
                        // Email Input
                        CustomTextField(
                          controller: _emailController,
                          labelText: 'Email Address',
                          keyboardType: TextInputType.emailAddress,
                          suffixIcon: const Icon(
                            Icons.email_outlined,
                            color: Color.fromARGB(255, 12, 71, 114),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!RegExp(
                              r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                            ).hasMatch(value)) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 32),
                        // Send Reset Link Button
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _handleSendResetEmail,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(
                                255,
                                12,
                                71,
                                114,
                              ),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(27),
                              ),
                              elevation: 4,
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text(
                                    'Send Reset Link',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Back to Login
                        TextButton(
                          onPressed: () {
                            context.read<PasswordResetBloc>().add(
                              const ResetPasswordResetState(),
                            );
                            context.pop();
                          },
                          child: RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                              children: const [
                                TextSpan(text: 'Remember your password? '),
                                TextSpan(
                                  text: 'Login',
                                  style: TextStyle(
                                    color: Color.fromARGB(255, 12, 71, 114),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Loading Overlay
                if (isLoading) _buildLoadingOverlay(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: Center(
        child: Container(
          width: 200,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SpinKitDoubleBounce(
                size: 50,
                color: Color.fromARGB(255, 12, 71, 114),
              ),
              const SizedBox(height: 16),
              Text(
                'Sending email...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
