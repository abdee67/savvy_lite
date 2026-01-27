import 'dart:async';
import 'dart:developer' as developer;
import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:savvy_stock/features/licensing/bloc/license_state.dart';
import 'package:savvy_stock/features/licensing/services/license_service.dart';
import 'package:savvy_stock/features/licensing/bloc/license_event.dart';

class LicenseBloc extends Bloc<LicenseEvent, LicenseState> {
  final LicenseService licenseService;

  LicenseBloc({required this.licenseService}) : super(const LicenseState()) {
    on<LoadLicense>(_onLoadLicense);
    on<GenerateMachineId>(_onGenerateMachineId);
    on<ValidateLicense>(_onValidateLicense);
    on<SaveLicense>(_onSaveLicense);
    on<ClearLicense>(_onClearLicense);
    on<CheckLicenseExpiration>(_onCheckLicenseExpiration);

    // Initialize license service
    licenseService
        .initialize()
        .then((_) {
          add(LoadLicense());
        })
        .catchError((error) {
          if (kDebugMode) {
            developer.log('Failed to initialize license service: $error');
          }
        });
  }

  Future<void> _onLoadLicense(
    LoadLicense event,
    Emitter<LicenseState> emit,
  ) async {
    emit(state.copyWith(status: LicenseStatus.loading));

    try {
      // Load and validate existing license
      final result = await licenseService.loadAndValidateLicense();

      if (result.isValid) {
        final payload = result.payload;
        final daysRemaining = result.daysRemaining;
        final isAboutToExpire = daysRemaining >= 0 && daysRemaining <= 15;

        emit(
          state.copyWith(
            status: LicenseStatus.valid,
            validationResult: result,
            licensePayload: payload,
            daysRemaining: daysRemaining,
            isLicenseAboutToExpire: isAboutToExpire,
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: LicenseStatus.invalid,
            validationResult: result,
            errorMessage: result.errorMessage,
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: LicenseStatus.error,
          errorMessage: 'Failed to load license: $e',
        ),
      );
    }
  }

  Future<void> _onGenerateMachineId(
    GenerateMachineId event,
    Emitter<LicenseState> emit,
  ) async {
    emit(state.copyWith(status: LicenseStatus.loading));

    try {
      final machineId = await licenseService.generateMachineId();

      emit(state.copyWith(status: LicenseStatus.loaded, machineId: machineId));
    } catch (e) {
      emit(
        state.copyWith(
          status: LicenseStatus.error,
          errorMessage: 'Failed to generate machine ID: $e',
        ),
      );
    }
  }

  Future<void> _onValidateLicense(
    ValidateLicense event,
    Emitter<LicenseState> emit,
  ) async {
    emit(state.copyWith(status: LicenseStatus.validating));

    try {
      final result = await licenseService.validateLicense(event.licenseKey);

      if (result.isValid) {
        emit(
          state.copyWith(
            status: LicenseStatus.valid,
            validationResult: result,
            licensePayload: result.payload,
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: LicenseStatus.invalid,
            validationResult: result,
            errorMessage: result.errorMessage,
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: LicenseStatus.error,
          errorMessage: 'Validation failed: $e',
        ),
      );
    }
  }

  Future<void> _onSaveLicense(
    SaveLicense event,
    Emitter<LicenseState> emit,
  ) async {
    if (state.validationResult == null || !state.validationResult!.isValid) {
      emit(
        state.copyWith(
          status: LicenseStatus.error,
          errorMessage: 'Cannot save invalid license',
        ),
      );
      return;
    }

    emit(state.copyWith(status: LicenseStatus.saving));

    try {
      await licenseService.saveLicense(
        event.licenseKey,
        state.validationResult!.payload!,
      );

      final daysRemaining = await licenseService.getDaysRemaining();
      final isAboutToExpire = await licenseService.isLicenseAboutToExpire();

      emit(
        state.copyWith(
          status: LicenseStatus.saved,
          daysRemaining: daysRemaining,
          isLicenseAboutToExpire: isAboutToExpire,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: LicenseStatus.error,
          errorMessage: 'Failed to save license: $e',
        ),
      );
    }
  }

  Future<void> _onClearLicense(
    ClearLicense event,
    Emitter<LicenseState> emit,
  ) async {
    emit(state.copyWith(status: LicenseStatus.loading));

    try {
      await licenseService.clearLicense();

      emit(
        state.copyWith(
          status: LicenseStatus.cleared,
          validationResult: null,
          licensePayload: null,
          daysRemaining: 0,
          isLicenseAboutToExpire: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: LicenseStatus.error,
          errorMessage: 'Failed to clear license: $e',
        ),
      );
    }
  }

  Future<void> _onCheckLicenseExpiration(
    CheckLicenseExpiration event,
    Emitter<LicenseState> emit,
  ) async {
    try {
      final daysRemaining = await licenseService.getDaysRemaining();
      final isAboutToExpire = await licenseService.isLicenseAboutToExpire();

      emit(
        state.copyWith(
          daysRemaining: daysRemaining,
          isLicenseAboutToExpire: isAboutToExpire,
        ),
      );
    } catch (e) {
      // Don't change state if check fails
      if (kDebugMode) {
        developer.log('Failed to check license expiration: $e');
      }
    }
  }
}
