part of 'registration_bloc.dart';

/// Registration status enum
enum RegistrationStatus {
  initial,
  loading,
  validating,
  registering,
  success,
  failure,
}

/// Registration state
class RegistrationState extends Equatable {
  final RegistrationStatus status;
  final int currentStep;
  final Company company;
  final Branch branch;
  final Employee employee;
  final UserModel adminUser;
  final String? confirmPassword;
  final SubscriptionManagement? subscriptionSettings;

  // Validation states
  final bool? usernameAvailable;
  final bool? emailAvailable;
  final bool? companyNameAvailable;
  final bool isValidating;

  // OTP Verification
  final bool isOtpSent;
  final String? verifiedEmail;
  final int resendCountdown;

  // Error handling
  final String? message;
  final Map<String, String> validationErrors;

  // Result
  final int? registeredUserId;
  final String? confirmationCode;

  const RegistrationState({
    this.status = RegistrationStatus.initial,
    this.currentStep = 0,
    required this.company,
    required this.branch,
    required this.employee,
    required this.adminUser,
    this.confirmPassword,
    this.subscriptionSettings,
    this.usernameAvailable,
    this.emailAvailable,
    this.companyNameAvailable,
    this.isValidating = false,
    this.message,
    this.validationErrors = const {},
    this.registeredUserId,
    this.confirmationCode,
    this.isOtpSent = false,
    this.verifiedEmail,
    this.resendCountdown = 0,
  });

  /// Initial state factory
  factory RegistrationState.initial() {
    return RegistrationState(
      company: Company.empty(),
      branch: Branch.empty(),
      employee: Employee.empty(),
      adminUser: const UserModel(id: 0, password: ''),
    );
  }

  /// Check if form is valid for current step
  bool get isCurrentStepValid {
    switch (currentStep) {
      case 0: // Profile (Company)
        return company.companyName.isNotEmpty && (companyNameAvailable ?? true);
      case 1: // Address
        return true; // Address is optional
      case 2: // Branch
        return branch.description?.isNotEmpty ?? false;
      case 3: // Admin
        return adminUser.userName?.isNotEmpty == true &&
            adminUser.userEmail?.isNotEmpty == true &&
            verifiedEmail == adminUser.userEmail &&
            adminUser.password?.isNotEmpty == true &&
            confirmPassword == adminUser.password &&
            (usernameAvailable ?? true) &&
            (emailAvailable ?? true);
      default:
        return true;
    }
  }

  /// Check if all required data is complete for registration
  bool get isReadyToSubmit {
    return company.companyName.isNotEmpty &&
        branch.description?.isNotEmpty == true &&
        employee.nameFirst.isNotEmpty &&
        adminUser.userName?.isNotEmpty == true &&
        adminUser.userEmail?.isNotEmpty == true &&
        verifiedEmail == adminUser.userEmail &&
        adminUser.password?.isNotEmpty == true &&
        confirmPassword == adminUser.password &&
        (companyNameAvailable ?? true) &&
        (usernameAvailable ?? true) &&
        (emailAvailable ?? true) &&
        subscriptionSettings != null;
  }

  /// Get total steps count
  int get totalSteps => 5;

  /// Step labels
  static const List<String> stepLabels = [
    'Profile',
    'Address',
    'Branch',
    'Admin',
    'Confirm',
  ];

  RegistrationState copyWith({
    RegistrationStatus? status,
    int? currentStep,
    Company? company,
    Branch? branch,
    Employee? employee,
    UserModel? adminUser,
    String? confirmPassword,
    SubscriptionManagement? subscriptionSettings,
    bool? usernameAvailable,
    bool? emailAvailable,
    bool? companyNameAvailable,
    bool? isValidating,
    String? message,
    Map<String, String>? validationErrors,
    int? registeredUserId,
    String? confirmationCode,
    bool? isOtpSent,
    String? verifiedEmail,
    int? resendCountdown,
  }) {
    return RegistrationState(
      status: status ?? this.status,
      currentStep: currentStep ?? this.currentStep,
      company: company ?? this.company,
      branch: branch ?? this.branch,
      employee: employee ?? this.employee,
      adminUser: adminUser ?? this.adminUser,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      subscriptionSettings: subscriptionSettings ?? this.subscriptionSettings,
      usernameAvailable: usernameAvailable ?? this.usernameAvailable,
      emailAvailable: emailAvailable ?? this.emailAvailable,
      companyNameAvailable: companyNameAvailable ?? this.companyNameAvailable,
      isValidating: isValidating ?? this.isValidating,
      message: message,
      validationErrors: validationErrors ?? this.validationErrors,
      registeredUserId: registeredUserId ?? this.registeredUserId,
      confirmationCode: confirmationCode ?? this.confirmationCode,
      isOtpSent: isOtpSent ?? this.isOtpSent,
      verifiedEmail: verifiedEmail ?? this.verifiedEmail,
      resendCountdown: resendCountdown ?? this.resendCountdown,
    );
  }

  @override
  List<Object?> get props => [
    status,
    currentStep,
    company,
    branch,
    employee,
    adminUser,
    confirmPassword,
    subscriptionSettings,
    usernameAvailable,
    emailAvailable,
    companyNameAvailable,
    isValidating,
    message,
    validationErrors,
    registeredUserId,
    confirmationCode,
    isOtpSent,
    verifiedEmail,
    resendCountdown,
  ];
}
