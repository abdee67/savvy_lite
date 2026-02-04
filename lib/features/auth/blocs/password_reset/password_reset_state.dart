part of 'password_reset_bloc.dart';

/// Password reset status enum
enum PasswordResetStatus {
  initial,
  loading,
  emailSent,
  tokenVerified,
  success,
  failure,
}

/// State for password reset BLoC
class PasswordResetState extends Equatable {
  final PasswordResetStatus status;
  final String? message;
  final String? email;
  final PasswordResetErrorType? errorType;
  final DateTime? emailSentAt;
  final bool canResend;

  const PasswordResetState({
    this.status = PasswordResetStatus.initial,
    this.message,
    this.email,
    this.errorType,
    this.emailSentAt,
    this.canResend = true,
  });

  /// Initial state
  factory PasswordResetState.initial() {
    return const PasswordResetState();
  }

  /// Loading state
  factory PasswordResetState.loading({String? message}) {
    return PasswordResetState(
      status: PasswordResetStatus.loading,
      message: message,
    );
  }

  /// Email sent successfully
  factory PasswordResetState.emailSent({
    required String email,
    String? message,
  }) {
    return PasswordResetState(
      status: PasswordResetStatus.emailSent,
      email: email,
      message: message ?? 'Password reset email sent',
      emailSentAt: DateTime.now(),
      canResend: false,
    );
  }

  /// Token verified successfully
  factory PasswordResetState.tokenVerified({
    required String email,
    String? message,
  }) {
    return PasswordResetState(
      status: PasswordResetStatus.tokenVerified,
      email: email,
      message: message ?? 'Reset link verified',
    );
  }

  /// Password reset successful
  factory PasswordResetState.success({String? message}) {
    return PasswordResetState(
      status: PasswordResetStatus.success,
      message: message ?? 'Password reset successfully',
    );
  }

  /// Password reset failed
  factory PasswordResetState.failure({
    required String message,
    PasswordResetErrorType? errorType,
    String? email,
  }) {
    return PasswordResetState(
      status: PasswordResetStatus.failure,
      message: message,
      errorType: errorType,
      email: email,
    );
  }

  /// Copy with new values
  PasswordResetState copyWith({
    PasswordResetStatus? status,
    String? message,
    String? email,
    PasswordResetErrorType? errorType,
    DateTime? emailSentAt,
    bool? canResend,
  }) {
    return PasswordResetState(
      status: status ?? this.status,
      message: message ?? this.message,
      email: email ?? this.email,
      errorType: errorType ?? this.errorType,
      emailSentAt: emailSentAt ?? this.emailSentAt,
      canResend: canResend ?? this.canResend,
    );
  }

  @override
  List<Object?> get props => [
    status,
    message,
    email,
    errorType,
    emailSentAt,
    canResend,
  ];
}
