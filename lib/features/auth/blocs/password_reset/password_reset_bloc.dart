import 'dart:async';
import 'dart:developer' as developer;

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:savvy_stock/features/auth/services/password_reset_service.dart';

part 'password_reset_event.dart';
part 'password_reset_state.dart';

/// BLoC for handling password reset flow
class PasswordResetBloc extends Bloc<PasswordResetEvent, PasswordResetState> {
  final PasswordResetService passwordResetService;

  /// Timer for resend cooldown
  Timer? _resendTimer;

  /// Cooldown duration for resending email (60 seconds)
  static const Duration resendCooldown = Duration(seconds: 60);

  PasswordResetBloc({required this.passwordResetService})
    : super(PasswordResetState.initial()) {
    on<SendPasswordResetCode>(_onSendPasswordResetCode);
    on<ResendPasswordResetCode>(_onResendPasswordResetCode);
    on<VerifyOTP>(_onVerifyOTP);
    on<UpdatePassword>(_onUpdatePassword);
    on<ResetPasswordResetState>(_onResetState);
    on<SetResetEmail>(_onSetResetEmail);
  }

  /// Handle sending password reset code
  Future<void> _onSendPasswordResetCode(
    SendPasswordResetCode event,
    Emitter<PasswordResetState> emit,
  ) async {
    emit(
      state.copyWith(
        status: PasswordResetStatus.loading,
        message: 'Sending reset code...',
      ),
    );

    try {
      final result = await passwordResetService.sendPasswordResetCode(
        event.email.trim().toLowerCase(),
      );

      if (result.success) {
        emit(
          PasswordResetState.emailSent(
            email: event.email.trim().toLowerCase(),
            message: result.message,
          ),
        );

        // Start resend cooldown timer
        _startResendCooldown();
      } else {
        emit(
          PasswordResetState.failure(
            message: result.message,
            errorType: result.errorType,
          ),
        );
      }
    } catch (e) {
      developer.log('Error sending password reset code: $e');
      emit(
        PasswordResetState.failure(
          message: 'An unexpected error occurred. Please try again.',
          errorType: PasswordResetErrorType.unknown,
        ),
      );
    }
  }

  /// Handle resending password reset code
  Future<void> _onResendPasswordResetCode(
    ResendPasswordResetCode event,
    Emitter<PasswordResetState> emit,
  ) async {
    if (!state.canResend) {
      emit(
        state.copyWith(message: 'Please wait before requesting another code'),
      );
      return;
    }

    final email = state.email;
    if (email == null || email.isEmpty) {
      emit(
        PasswordResetState.failure(
          message: 'Email address not found. Please start over.',
          errorType: PasswordResetErrorType.unknown,
        ),
      );
      return;
    }

    add(SendPasswordResetCode(email: email));
  }

  /// Handle OTP code verification
  Future<void> _onVerifyOTP(
    VerifyOTP event,
    Emitter<PasswordResetState> emit,
  ) async {
    emit(
      state.copyWith(
        status: PasswordResetStatus.loading,
        message: 'Verifying code...',
      ),
    );

    try {
      final result = await passwordResetService.verifyOTP(
        email: event.email,
        code: event.code,
      );

      if (result.success && result.email != null) {
        emit(
          PasswordResetState.tokenVerified(
            email: result.email!,
            message: result.message,
          ),
        );
      } else {
        emit(
          PasswordResetState.failure(
            message: result.message,
            errorType: result.errorType,
            email: event.email, // Preserve email on failure
          ),
        );
      }
    } catch (e) {
      developer.log('Error verifying OTP: $e');
      emit(
        PasswordResetState.failure(
          message: 'Failed to verify code. Please check and try again.',
          errorType: PasswordResetErrorType.unknown,
          email: event.email, // Preserve email on failure
        ),
      );
    }
  }

  /// Handle password update
  Future<void> _onUpdatePassword(
    UpdatePassword event,
    Emitter<PasswordResetState> emit,
  ) async {
    // Validate passwords match
    if (event.newPassword != event.confirmPassword) {
      emit(
        PasswordResetState.failure(
          message: 'Passwords do not match',
          errorType: PasswordResetErrorType.unknown,
          email: state.email,
        ),
      );
      return;
    }

    // Validate password strength
    final passwordValidation = _validatePassword(event.newPassword);
    if (!passwordValidation.isValid) {
      emit(
        PasswordResetState.failure(
          message: passwordValidation.message,
          errorType: PasswordResetErrorType.unknown,
          email: state.email,
        ),
      );
      return;
    }

    final email = state.email;
    if (email == null || email.isEmpty) {
      emit(
        PasswordResetState.failure(
          message: 'Session expired. Please request a new reset link.',
          errorType: PasswordResetErrorType.invalidToken,
        ),
      );
      return;
    }

    emit(PasswordResetState.loading(message: 'Updating password...'));

    try {
      final result = await passwordResetService.updateLocalPassword(
        email: email,
        newPassword: event.newPassword,
      );

      if (result.success) {
        emit(PasswordResetState.success(message: result.message));
      } else {
        emit(
          PasswordResetState.failure(
            message: result.message,
            errorType: result.errorType,
            email: email,
          ),
        );
      }
    } catch (e) {
      developer.log('Error updating password: $e');
      emit(
        PasswordResetState.failure(
          message: 'Failed to update password. Please try again.',
          errorType: PasswordResetErrorType.unknown,
          email: email,
        ),
      );
    }
  }

  /// Handle state reset
  void _onResetState(
    ResetPasswordResetState event,
    Emitter<PasswordResetState> emit,
  ) {
    _cancelResendTimer();
    emit(PasswordResetState.initial());
  }

  /// Handle setting email from deep link verification
  void _onSetResetEmail(SetResetEmail event, Emitter<PasswordResetState> emit) {
    emit(
      PasswordResetState.tokenVerified(
        email: event.email,
        message: 'Enter your new password',
      ),
    );
  }

  /// Validate password strength
  _PasswordValidation _validatePassword(String password) {
    if (password.isEmpty) {
      return _PasswordValidation(
        isValid: false,
        message: 'Password cannot be empty',
      );
    }

    if (password.length < 6) {
      return _PasswordValidation(
        isValid: false,
        message: 'Password must be at least 6 characters',
      );
    }

    if (!password.contains(RegExp(r'[0-9]'))) {
      return _PasswordValidation(
        isValid: false,
        message: 'Password must contain at least one number',
      );
    }

    if (!password.contains(RegExp(r'[A-Za-z]'))) {
      return _PasswordValidation(
        isValid: false,
        message: 'Password must contain at least one letter',
      );
    }

    return _PasswordValidation(isValid: true, message: '');
  }

  /// Start resend cooldown timer
  void _startResendCooldown() {
    _cancelResendTimer();
    _resendTimer = Timer(resendCooldown, () {
      if (!isClosed) {
        // ignore: invalid_use_of_visible_for_testing_member
        emit(state.copyWith(canResend: true));
      }
    });
  }

  /// Cancel resend timer
  void _cancelResendTimer() {
    _resendTimer?.cancel();
    _resendTimer = null;
  }

  @override
  Future<void> close() {
    _cancelResendTimer();
    return super.close();
  }
}

/// Helper class for password validation
class _PasswordValidation {
  final bool isValid;
  final String message;

  _PasswordValidation({required this.isValid, required this.message});
}
