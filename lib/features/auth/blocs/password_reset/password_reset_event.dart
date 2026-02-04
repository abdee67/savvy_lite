part of 'password_reset_bloc.dart';

/// Events for password reset BLoC
abstract class PasswordResetEvent extends Equatable {
  const PasswordResetEvent();
}

/// Event to send password reset code
class SendPasswordResetCode extends PasswordResetEvent {
  final String email;

  const SendPasswordResetCode({required this.email});

  @override
  List<Object?> get props => [email];
}

/// Event to resend password reset code
class ResendPasswordResetCode extends PasswordResetEvent {
  const ResendPasswordResetCode();

  @override
  List<Object?> get props => [];
}

/// Event to verify OTP code
class VerifyOTP extends PasswordResetEvent {
  final String email;
  final String code;

  const VerifyOTP({required this.email, required this.code});

  @override
  List<Object?> get props => [email, code];
}

/// Event to update password after verification
class UpdatePassword extends PasswordResetEvent {
  final String newPassword;
  final String confirmPassword;

  const UpdatePassword({
    required this.newPassword,
    required this.confirmPassword,
  });

  @override
  List<Object?> get props => [newPassword, confirmPassword];
}

/// Event to reset the bloc state
class ResetPasswordResetState extends PasswordResetEvent {
  const ResetPasswordResetState();

  @override
  List<Object?> get props => [];
}

/// Event to set email for password reset (from deep link)
class SetResetEmail extends PasswordResetEvent {
  final String email;

  const SetResetEmail({required this.email});

  @override
  List<Object?> get props => [email];
}
