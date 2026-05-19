import 'dart:async';
import 'dart:developer' as developer;

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:savvy_stock/features/admin/employees/models/employee_model.dart';
import 'package:savvy_stock/features/admin/users/models/user_model.dart';
import 'package:savvy_stock/features/auth/model/subscription_management_model.dart';
import 'package:savvy_stock/features/branch_list/models/branch_list_model.dart';
import 'package:savvy_stock/features/company/models/company_model.dart';
import 'package:savvy_stock/features/registration/model/signup_data_model.dart';
import 'package:savvy_stock/features/registration/services/registration_service.dart';

// Import secure storage
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

part 'registration_event.dart';
part 'registration_state.dart';

/// BLoC for handling user registration
class RegistrationBloc extends Bloc<RegistrationEvent, RegistrationState> {
  final RegistrationService registrationService;
  final FlutterSecureStorage secureStorage;

  RegistrationBloc({
    required this.registrationService,
    required this.secureStorage,
  }) : super(RegistrationState.initial()) {
    on<InitializeRegistration>(_onInitializeRegistration);
    on<UpdateCompanyData>(_onUpdateCompanyData);
    on<UpdateBranchData>(_onUpdateBranchData);
    on<UpdateEmployeeData>(_onUpdateEmployeeData);
    on<UpdateAdminUserData>(_onUpdateAdminUserData);
    on<CheckUsernameAvailability>(_onCheckUsernameAvailability);
    on<CheckEmailAvailability>(_onCheckEmailAvailability);
    on<CheckCompanyNameAvailability>(_onCheckCompanyNameAvailability);
    on<SubmitRegistration>(_onSubmitRegistration);
    on<ResetRegistration>(_onResetRegistration);
    on<NextStep>(_onNextStep);
    on<PreviousStep>(_onPreviousStep);
    on<GoToStep>(_onGoToStep);
    on<SendEmailVerificationCode>(_onSendEmailVerificationCode);
    on<VerifyEmailVerificationCode>(_onVerifyEmailVerificationCode);
    on<StartResendTimer>(_onStartResendTimer);
    on<TickResendTimer>(_onTickResendTimer);
  }

  Timer? _resendTimer;

  /// Initialize registration with default subscription
  Future<void> _onInitializeRegistration(
    InitializeRegistration event,
    Emitter<RegistrationState> emit,
  ) async {
    emit(state.copyWith(status: RegistrationStatus.loading));

    try {
      final subscription = await registrationService.getDefaultSubscription();

      emit(
        state.copyWith(
          status: RegistrationStatus.initial,
          subscriptionSettings: subscription,
        ),
      );
      developer.log(
        'Registration initialized with subscription: ${subscription?.name}',
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: RegistrationStatus.failure,
          message: 'Failed to initialize registration: $e',
        ),
      );
    }
  }

  /// Update company data
  void _onUpdateCompanyData(
    UpdateCompanyData event,
    Emitter<RegistrationState> emit,
  ) {
    emit(state.copyWith(company: event.company));

    // Trigger company name availability check if name changed
    if (event.company.companyName.isNotEmpty) {
      add(CheckCompanyNameAvailability(event.company.companyName));
    }
  }

  /// Update branch data
  void _onUpdateBranchData(
    UpdateBranchData event,
    Emitter<RegistrationState> emit,
  ) {
    emit(state.copyWith(branch: event.branch));
  }

  /// Update employee data
  void _onUpdateEmployeeData(
    UpdateEmployeeData event,
    Emitter<RegistrationState> emit,
  ) {
    emit(state.copyWith(employee: event.employee));
  }

  /// Update admin user data
  void _onUpdateAdminUserData(
    UpdateAdminUserData event,
    Emitter<RegistrationState> emit,
  ) {
    emit(
      state.copyWith(
        adminUser: event.adminUser,
        confirmPassword: event.confirmPassword,
      ),
    );

    // Trigger validation checks
    if (event.adminUser.userName?.isNotEmpty == true) {
      add(CheckUsernameAvailability(event.adminUser.userName!));
    }
    if (event.adminUser.userEmail?.isNotEmpty == true) {
      add(CheckEmailAvailability(event.adminUser.userEmail!));
    }
  }

  /// Check username availability
  Future<void> _onCheckUsernameAvailability(
    CheckUsernameAvailability event,
    Emitter<RegistrationState> emit,
  ) async {
    if (event.username.isEmpty) {
      emit(state.copyWith(usernameAvailable: null));
      return;
    }

    emit(state.copyWith(isValidating: true));

    try {
      final isAvailable = await registrationService.isUsernameAvailable(
        event.username,
      );

      final errors = Map<String, String>.from(state.validationErrors);
      if (isAvailable) {
        errors.remove('username');
      } else {
        errors['username'] = 'Username already taken';
      }

      emit(
        state.copyWith(
          usernameAvailable: isAvailable,
          isValidating: false,
          validationErrors: errors,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isValidating: false));
    }
  }

  /// Check email availability
  Future<void> _onCheckEmailAvailability(
    CheckEmailAvailability event,
    Emitter<RegistrationState> emit,
  ) async {
    if (event.email.isEmpty) {
      emit(state.copyWith(emailAvailable: null));
      return;
    }

    emit(state.copyWith(isValidating: true));

    try {
      final isAvailable = await registrationService.isEmailAvailable(
        event.email,
      );

      final errors = Map<String, String>.from(state.validationErrors);
      if (isAvailable) {
        errors.remove('email');
      } else {
        errors['email'] = 'Email already registered';
      }

      emit(
        state.copyWith(
          emailAvailable: isAvailable,
          isValidating: false,
          validationErrors: errors,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isValidating: false));
    }
  }

  /// Check company name availability
  Future<void> _onCheckCompanyNameAvailability(
    CheckCompanyNameAvailability event,
    Emitter<RegistrationState> emit,
  ) async {
    if (event.companyName.isEmpty) {
      emit(state.copyWith(companyNameAvailable: null));
      return;
    }

    emit(state.copyWith(isValidating: true));

    try {
      final isAvailable = await registrationService.isCompanyNameAvailable(
        event.companyName,
      );

      final errors = Map<String, String>.from(state.validationErrors);
      if (isAvailable) {
        errors.remove('companyName');
      } else {
        errors['companyName'] = 'Company name already registered';
      }

      emit(
        state.copyWith(
          companyNameAvailable: isAvailable,
          isValidating: false,
          validationErrors: errors,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isValidating: false));
    }
  }

  /// Submit registration
  Future<void> _onSubmitRegistration(
    SubmitRegistration event,
    Emitter<RegistrationState> emit,
  ) async {
    // Validate all fields first
    // Validate all fields first
    if (!state.isReadyToSubmit) {
      final List<String> missingFields = [];
      if (state.company.companyName.isEmpty) missingFields.add('Company Name');
      if (state.branch.description?.isEmpty ?? true) {
        missingFields.add('Branch Name');
      }
      if (state.employee.nameFirst.isEmpty) missingFields.add('First Name');
      if (state.adminUser.userName?.isEmpty ?? true) {
        missingFields.add('Username');
      }
      if (state.adminUser.userEmail?.isEmpty ?? true) {
        missingFields.add('Email');
      }
      if (state.verifiedEmail != state.adminUser.userEmail) {
        missingFields.add('Verified Email Mismatch');
      }
      if (state.adminUser.password?.isEmpty ?? true) {
        missingFields.add('Password');
      }
      if (state.confirmPassword != state.adminUser.password) {
        missingFields.add('Passwords do not match');
      }
      if (state.subscriptionSettings == null) {
        missingFields.add('Subscription Settings (Internal Error)');
      }

      emit(
        state.copyWith(
          status: RegistrationStatus.failure,
          message: 'Please check: ${missingFields.join(', ')}',
        ),
      );
      return;
    }

    emit(state.copyWith(status: RegistrationStatus.registering));

    try {
      // Create signup data
      final signupData = SignupData(
        company: state.company,
        primaryBranch: state.branch,
        employee: state.employee,
        adminUser: state.adminUser,
        initialSettings: state.subscriptionSettings,
      );

      // Call registration service
      final result = await registrationService.register(signupData);

      if (result.success) {
        emit(
          state.copyWith(
            status: RegistrationStatus.success,
            message: result.message,
            registeredUserId: result.userId,
            confirmationCode: result.confirmationCode,
          ),
        );
        developer.log('Registration successful: User ID ${result.userId}');

        // Start Free Trial
        await secureStorage.write(key: 'trial_active', value: 'true');
        await secureStorage.write(
          key: 'trial_start_date',
          value: DateTime.now().toIso8601String(),
        );
        // We use the configured settings for the trial limits
        await secureStorage.write(
          key: 'trial_users',
          value: (state.subscriptionSettings?.initialSubscriptionUsers ?? 3)
              .toString(),
        );
        await secureStorage.write(
          key: 'trial_branches',
          value: (state.subscriptionSettings?.initialSubscriptionBranches ?? 2)
              .toString(),
        );
        await secureStorage.write(
          key: 'trial_days',
          value: (state.subscriptionSettings?.initialSubscriptionDays ?? 5)
              .toString(),
        );
        if (kDebugMode) {
          developer.log('Registration successful: User ID ${result.userId}');
        }
      } else {
        final isUsernameTaken = result.message.toLowerCase().contains(
          'username',
        );
        final errors = Map<String, String>.from(state.validationErrors);
        if (isUsernameTaken) {
          errors['username'] = 'Username already taken';
        }

        emit(
          state.copyWith(
            status: RegistrationStatus.failure,
            message: result.message,
            currentStep: isUsernameTaken ? 3 : state.currentStep,
            usernameAvailable: isUsernameTaken
                ? false
                : state.usernameAvailable,
            validationErrors: errors,
          ),
        );
        if (kDebugMode) {
          developer.log('Registration failed: ${result.message}');
        }
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: RegistrationStatus.failure,
          message: 'Registration failed: ${e.toString()}',
        ),
      );
      if (kDebugMode) {
        developer.log('Registration error: $e');
      }
    }
  }

  /// Reset registration form
  void _onResetRegistration(
    ResetRegistration event,
    Emitter<RegistrationState> emit,
  ) {
    emit(
      RegistrationState.initial().copyWith(
        subscriptionSettings: state.subscriptionSettings,
      ),
    );
  }

  /// Navigate to next step
  void _onNextStep(NextStep event, Emitter<RegistrationState> emit) {
    if (state.currentStep < state.totalSteps - 1) {
      emit(state.copyWith(currentStep: state.currentStep + 1));
    }
  }

  /// Navigate to previous step
  void _onPreviousStep(PreviousStep event, Emitter<RegistrationState> emit) {
    if (state.currentStep > 0) {
      emit(state.copyWith(currentStep: state.currentStep - 1));
    }
  }

  /// Go to specific step
  void _onGoToStep(GoToStep event, Emitter<RegistrationState> emit) {
    if (event.step >= 0 && event.step < state.totalSteps) {
      emit(state.copyWith(currentStep: event.step));
    }
  }

  /// Send email verification code
  Future<void> _onSendEmailVerificationCode(
    SendEmailVerificationCode event,
    Emitter<RegistrationState> emit,
  ) async {
    emit(state.copyWith(isValidating: true));

    try {
      final success = await registrationService.sendEmailVerificationCode(
        event.email,
      );

      if (success) {
        emit(
          state.copyWith(
            isValidating: false,
            isOtpSent: true,
            message: 'Verification code sent',
          ),
        );
        add(const StartResendTimer());
      } else {
        emit(
          state.copyWith(
            isValidating: false,
            message: 'Failed to send verification code',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          isValidating: false,
          message: 'Error sending verification code: $e',
        ),
      );
    }
  }

  /// Verify email verification code
  Future<void> _onVerifyEmailVerificationCode(
    VerifyEmailVerificationCode event,
    Emitter<RegistrationState> emit,
  ) async {
    emit(state.copyWith(isValidating: true));

    try {
      final success = await registrationService.verifyEmailVerificationCode(
        event.email,
        event.code,
      );

      if (success) {
        emit(
          state.copyWith(
            isValidating: false,
            verifiedEmail: event.email,
            message: 'Email verified successfully',
          ),
        );
      } else {
        emit(
          state.copyWith(
            isValidating: false,
            message: 'Invalid verification code',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          isValidating: false,
          message: 'Error verifying code: $e',
        ),
      );
    }
  }

  void _onStartResendTimer(
    StartResendTimer event,
    Emitter<RegistrationState> emit,
  ) {
    emit(state.copyWith(resendCountdown: 60));
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.resendCountdown > 0) {
        add(TickResendTimer(state.resendCountdown - 1));
      } else {
        timer.cancel();
      }
    });
  }

  void _onTickResendTimer(
    TickResendTimer event,
    Emitter<RegistrationState> emit,
  ) {
    emit(state.copyWith(resendCountdown: event.tick));
  }

  @override
  Future<void> close() {
    _resendTimer?.cancel();
    return super.close();
  }
}
