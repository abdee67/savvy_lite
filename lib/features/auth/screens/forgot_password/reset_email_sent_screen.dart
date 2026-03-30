import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:savvy_stock/core/constants/app_routes.dart';
import 'package:savvy_stock/features/auth/blocs/password_reset/password_reset_bloc.dart';

/// Screen for entering the 6-digit OTP code
class ResetEmailSentScreen extends StatefulWidget {
  final String? email;

  const ResetEmailSentScreen({super.key, this.email});

  @override
  State<ResetEmailSentScreen> createState() => _ResetEmailSentScreenState();
}

class _ResetEmailSentScreenState extends State<ResetEmailSentScreen> {
  final TextEditingController _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final int otpLength = 8; // Example: Set your required length
  final String _otp = '';

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _startCounter();
  }

  void _verify(String email) {
    if (_formKey.currentState!.validate()) {
      context.read<PasswordResetBloc>().add(
        VerifyOTP(email: email, code: _otpController.text),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PasswordResetBloc, PasswordResetState>(
      listener: (context, state) {
        if (state.status == PasswordResetStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message ?? 'An error occurred'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else if (state.status == PasswordResetStatus.tokenVerified) {
          // Navigate to new password screen upon successful verification
          // Use push to keep the BLoC (created in ForgotPasswordScreen) alive
          context.push(
            AppRoutes.newPassword,
            extra: {
              'bloc': context.read<PasswordResetBloc>(),
              'email': state.email, // Optional, but good to have
            },
          );
        }
      },
      builder: (context, state) {
        final isLoading = state.status == PasswordResetStatus.loading;
        final email = widget.email ?? state.email ?? 'your email';

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                context.read<PasswordResetBloc>().add(
                  const ResetPasswordResetState(),
                );
                context.go(AppRoutes.forgotPassword);
              },
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(
              color: Color.fromARGB(255, 12, 71, 114),
            ),
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Icon
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(
                            255,
                            12,
                            71,
                            114,
                          ).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.lock_clock_outlined,
                          size: 40,
                          color: Color.fromARGB(255, 12, 71, 114),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Title
                      const Text(
                        'Enter Verification Code',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 21, 88, 136),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Description
                      Text(
                        'We sent a 8-digit code to\n$email',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 32),
                      // OTP Input
                      TextFormField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: otpLength,
                        //auto validate
                        style: const TextStyle(
                          fontSize: 24,
                          letterSpacing: 8,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 12, 71, 114),
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          hintText: '00000000',
                          hintStyle: TextStyle(
                            fontSize: 24,
                            letterSpacing: 8,
                            color: Colors.grey.shade300,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color.fromARGB(255, 12, 71, 114),
                              width: 2,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.red),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Colors.red,
                              width: 2,
                            ),
                          ),
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter the code';
                          }
                          if (value.length != otpLength) {
                            return 'Code must be $otpLength digits';
                          }
                          return null;
                        },
                        onChanged: (value) {
                          if (value.length == otpLength) {
                            if (_formKey.currentState!.validate()) {
                              _verify(widget.email ?? state.email!);
                            }
                          }
                        },
                      ),
                      const SizedBox(height: 24),
                      // Verify Button
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: isLoading
                              ? null
                              : () => _verify(widget.email ?? state.email!),
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
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  'Verify Code',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Resend Option
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Didn't receive the code? ",
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          TextButton(
                            onPressed: !state.canResend || isLoading
                                ? null
                                : () {
                                    context.read<PasswordResetBloc>().add(
                                      ResendPasswordResetCode(email: email),
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Code resent successfully',
                                        ),
                                        backgroundColor: Colors.green,
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  },
                            child: Text(
                              state.canResend ? 'Resend' : 'Wait $_counter',
                              style: TextStyle(
                                color: state.canResend
                                    ? const Color.fromARGB(255, 12, 71, 114)
                                    : Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  //otp resend 60 sec counter
  int _counter = 60;
  Timer? _timer;

  void _startCounter() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_counter > 0) {
        setState(() {
          _counter--;
        });
      } else {
        _timer?.cancel();
      }
    });
  }
}
