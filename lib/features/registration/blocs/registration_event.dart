part of 'registration_bloc.dart';

/// Base class for registration events
sealed class RegistrationEvent extends Equatable {
  const RegistrationEvent();

  @override
  List<Object?> get props => [];
}

/// Initialize registration with default subscription
class InitializeRegistration extends RegistrationEvent {
  const InitializeRegistration();
}

/// Update company data in registration form
class UpdateCompanyData extends RegistrationEvent {
  final Company company;

  const UpdateCompanyData(this.company);

  @override
  List<Object?> get props => [company];
}

/// Update branch data in registration form
class UpdateBranchData extends RegistrationEvent {
  final Branch branch;

  const UpdateBranchData(this.branch);

  @override
  List<Object?> get props => [branch];
}

/// Update employee data in registration form
class UpdateEmployeeData extends RegistrationEvent {
  final Employee employee;

  const UpdateEmployeeData(this.employee);

  @override
  List<Object?> get props => [employee];
}

/// Update admin user data in registration form
class UpdateAdminUserData extends RegistrationEvent {
  final UserModel adminUser;
  final String? confirmPassword;

  const UpdateAdminUserData(this.adminUser, {this.confirmPassword});

  @override
  List<Object?> get props => [adminUser, confirmPassword];
}

/// Check if username is available
class CheckUsernameAvailability extends RegistrationEvent {
  final String username;

  const CheckUsernameAvailability(this.username);

  @override
  List<Object?> get props => [username];
}

/// Check if email is available
class CheckEmailAvailability extends RegistrationEvent {
  final String email;

  const CheckEmailAvailability(this.email);

  @override
  List<Object?> get props => [email];
}

/// Check if company name is available
class CheckCompanyNameAvailability extends RegistrationEvent {
  final String companyName;

  const CheckCompanyNameAvailability(this.companyName);

  @override
  List<Object?> get props => [companyName];
}

/// Submit registration
class SubmitRegistration extends RegistrationEvent {
  const SubmitRegistration();
}

/// Reset registration form
class ResetRegistration extends RegistrationEvent {
  const ResetRegistration();
}

/// Navigate to next step
class NextStep extends RegistrationEvent {
  const NextStep();
}

/// Navigate to previous step
class PreviousStep extends RegistrationEvent {
  const PreviousStep();
}

/// Go to specific step
class GoToStep extends RegistrationEvent {
  final int step;

  const GoToStep(this.step);

  @override
  List<Object?> get props => [step];
}

/// Send email verification code
class SendEmailVerificationCode extends RegistrationEvent {
  final String email;

  const SendEmailVerificationCode(this.email);

  @override
  List<Object?> get props => [email];
}

/// Verify email verification code
class VerifyEmailVerificationCode extends RegistrationEvent {
  final String email;
  final String code;

  const VerifyEmailVerificationCode(this.email, this.code);

  @override
  List<Object?> get props => [email, code];
}

/// Start resend timer
class StartResendTimer extends RegistrationEvent {
  const StartResendTimer();
}

/// Tick resend timer
class TickResendTimer extends RegistrationEvent {
  final int tick;

  const TickResendTimer(this.tick);

  @override
  List<Object?> get props => [tick];
}
