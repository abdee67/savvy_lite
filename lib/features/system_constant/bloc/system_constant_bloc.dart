import 'dart:async';
import 'dart:developer' as developer;
import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:savvy_stock/core/errors/exceptions.dart';
import 'package:savvy_stock/features/system_constant/models/system_constant.dart';
import 'package:savvy_stock/features/system_constant/repo/system_constant_repository.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'system_constant_event.dart';
import 'system_constant_state.dart';
import 'package:savvy_stock/features/system_constant/repo/system_constant_service.dart';

class SystemConstantBloc
    extends Bloc<SystemConstantEvent, SystemConstantState> {
  final SystemConstantRepository systemConstantRepository;
  //final AuthService authService;
  final SystemConstantsService systemConstantService;
  final AuthBloc authBloc;

  SystemConstantBloc({
    required this.systemConstantRepository,
    // required this.authService,
    required this.systemConstantService,
    required this.authBloc,
  }) : super(const SystemConstantState()) {
    on<LoadSystemConstants>(_onLoadSystemConstants);
    on<LoadSystemConstant>(_onLoadSystemConstant);
    on<LoadSystemConstantsForCompany>(_onLoadSystemConstantsForCompany);
    on<CreateSystemConstant>(_onCreateSystemConstant);
    on<UpdateSystemConstant>(_onUpdateSystemConstant);
    on<DeleteSystemConstant>(_onDeleteSystemConstant);
    on<PrepareCreate>(_onPrepareCreate);
    on<PrepareEdit>(_onPrepareEdit);
    on<CancelUpdate>(_onCancelUpdate);
    on<CancelCreate>(_onCancelCreate);
    on<SaveSystemConstants>(_onSaveSystemConstants);
    on<SaveInEdit>(_onSaveInEdit);
    on<RemoveInCreate>(_onRemoveInCreate);
    on<RemoveInEdit>(_onRemoveInEdit);
    on<SyncSystemConstants>(_onSyncSystemConstants);

    // Load data immediately when bloc is created
    // add(LoadSystemConstants(authBloc.state.companyId!));
    // Start periodic sync (every 5 minutes)
    // _startSyncTimer();
  }

  @override
  Future<void> close() {
    return super.close();
  }

  Future<void> _onLoadSystemConstants(
    LoadSystemConstants event,
    Emitter<SystemConstantState> emit,
  ) async {
    emit(state.copyWith(status: SystemConstantStatus.loading));
    try {
      // Try to load from local database first
      final systemConstants = await systemConstantRepository
          .getSystemConstants();
      final companyConstants = await systemConstantRepository
          .getCurrentCompanySystemConstants();

      final allConstants = List<SystemConstant>.from(systemConstants);
      if (!allConstants.any((c) => c.id == companyConstants.id)) {
        allConstants.add(companyConstants);
      }
      final unSyncedCount = allConstants.where((c) => !c.isSynced).length;
      emit(
        state.copyWith(
          status: SystemConstantStatus.success,
          systemConstants: [companyConstants],
          selected: companyConstants,
          errorMessage: null,
          unsyncedCount: unSyncedCount,
        ),
      );
      if (kDebugMode) {
        developer.log(
          '✅ SystemConstantBloc: State updated with lot_type: ${companyConstants.lotType}',
        );
      }
    } catch (e) {
      developer.log('Error loading system constants: $e');
      emit(
        state.copyWith(
          status: SystemConstantStatus.failure,
          // errorMessage: 'Failed to load system constants: ${e.toString()}',
        ),
      );
      developer.log('Error loading system constants: $e');
    }
  }

  Future<void> _onLoadSystemConstant(
    LoadSystemConstant event,
    Emitter<SystemConstantState> emit,
  ) async {
    emit(state.copyWith(status: SystemConstantStatus.loading));

    try {
      // Try to load from local database first
      final systemConstant = await systemConstantRepository.getSystemConstant(
        event.id,
      );

      emit(
        state.copyWith(
          status: SystemConstantStatus.success,
          systemConstants: [systemConstant],
          errorMessage: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: SystemConstantStatus.failure,
          // errorMessage: 'Failed to load system constant: ${e.toString()}',
        ),
      );
      developer.log('Error loading system constant: $e');
    }
  }

  Future<void> _onLoadSystemConstantsForCompany(
    LoadSystemConstantsForCompany event,
    Emitter<SystemConstantState> emit,
  ) async {
    emit(state.copyWith(status: SystemConstantStatus.loading));

    try {
      // Try to load from local database first
      final systemConstant = await systemConstantRepository
          .getCurrentCompanySystemConstants();

      emit(
        state.copyWith(
          status: SystemConstantStatus.success,
          systemConstants: [systemConstant],
          errorMessage: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: SystemConstantStatus.failure,
          // errorMessage:
          // 'Failed to load system constant for company: ${e.toString()}',
        ),
      );
      developer.log('Error loading system constant for company: $e');
    }
  }

  Future<void> _onSyncSystemConstants(
    SyncSystemConstants event,
    Emitter<SystemConstantState> emit,
  ) async {
    try {
      emit(state.copyWith(status: SystemConstantStatus.syncing));

      // For testing, we'll skip actual syncing
      developer.log('Sync requested but bypassed for testing');

      // Just reload data from local database
      final systemConstants = await systemConstantRepository
          .getSystemConstants();

      emit(
        state.copyWith(
          status: SystemConstantStatus.success,
          systemConstants: systemConstants,
          errorMessage: null,
        ),
      );
    } catch (e) {
      developer.log('Sync error (ignored in test mode): $e');
      emit(
        state.copyWith(
          status: SystemConstantStatus
              .success, // Don't show error for background sync
        ),
      );
    }
  }


  Future<void> _onCreateSystemConstant(
    CreateSystemConstant event,
    Emitter<SystemConstantState> emit,
  ) async {
    emit(state.copyWith(status: SystemConstantStatus.loading));
    try {
      await systemConstantRepository.createSystemConstant(event.systemConstant);
      emit(
        state.copyWith(
          status: SystemConstantStatus.success,
          errorMessage: null,
        ),
      );
      add(LoadSystemConstantsForCompany(authBloc.state.companyId!));
    } catch (e) {
      if (e is NetworkException) {
        emit(
          state.copyWith(
            status: SystemConstantStatus.success,
            errorMessage:
                'Created locally.Will sync when online:${e.toString()}',
          ),
        );
        add(
          LoadSystemConstantsForCompany(authBloc.state.companyId!),
        ); //Reload to include loacla changes
      } else {
        emit(
          state.copyWith(
            status: SystemConstantStatus.failure,
            errorMessage: 'Failed to create system constant:${e.toString()}',
          ),
        );
      }
    }
  }

  Future<void> _onUpdateSystemConstant(
    UpdateSystemConstant event,
    Emitter<SystemConstantState> emit,
  ) async {
    emit(state.copyWith(status: SystemConstantStatus.loading));
    try {
      await systemConstantRepository.updateSystemConstant(event.systemConstant);
      emit(
        state.copyWith(
          status: SystemConstantStatus.success,
          errorMessage: null,
        ),
      );
      // RELOAD DATA AFTER UPDATE to ensure UI shows latest
      Future.delayed(const Duration(milliseconds: 500), () {
        add(LoadSystemConstantsForCompany(authBloc.state.companyId!));
      });
    } catch (e) {
      if (e is NetworkException) {
        emit(
          state.copyWith(
            status: SystemConstantStatus.success,
            errorMessage:
                'Updated locally.Will sync when online:${e.toString()}',
          ),
        );
        add(
          LoadSystemConstantsForCompany(authBloc.state.companyId!),
        ); //Reload to include loacla changes
      } else {
        emit(
          state.copyWith(
            status: SystemConstantStatus.failure,
            errorMessage: 'Failed to update system constant:${e.toString()}',
          ),
        );
      }
    }
  }

  Future<void> _onDeleteSystemConstant(
    DeleteSystemConstant event,
    Emitter<SystemConstantState> emit,
  ) async {
    emit(state.copyWith(status: SystemConstantStatus.loading));
    try {
      await systemConstantRepository.deleteSystemConstant(
        event.systemConstant.id!,
      );
      add(LoadSystemConstantsForCompany(authBloc.state.companyId!));
    } catch (e) {
      if (e is NetworkException) {
        emit(
          state.copyWith(
            status: SystemConstantStatus.success,
            errorMessage:
                'Marked for deletion locally.Will sync when online:${e.toString()}',
          ),
        );
        add(
          LoadSystemConstantsForCompany(authBloc.state.companyId!),
        ); //Reload to include loacla changes
      } else {
        emit(
          state.copyWith(
            status: SystemConstantStatus.failure,
            errorMessage: 'Failed to delete system constant:${e.toString()}',
          ),
        );
      }
    }
  }

  Future<void> _onPrepareCreate(
    PrepareCreate event,
    Emitter<SystemConstantState> emit,
  ) async {
    try {
      final user = authBloc.state.userId;
      final companyId = authBloc.state.companyId;

      // Create a new system constant with default values
      final newSystemConstant = SystemConstant(
        tempId: 1,
        company: companyId,
        applyLotMgm: 'N',
        applyLocationMgm: 'Y',
        decimalPlaces: 2,
        autoSalesPrice: 'N',
        lotQtyAutoForSales: 'Y',
        locationCategoryLevel: 1,
      );

      emit(
        state.copyWith(
          createItems: [newSystemConstant],
          selected: newSystemConstant,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: SystemConstantStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onPrepareEdit(
    PrepareEdit event,
    Emitter<SystemConstantState> emit,
  ) async {
    try {
      // Load UDC data first

      final companyId = authBloc.state.companyId;

      // Get existing system constants for the current company
      final existingConstant = await systemConstantRepository
          .getSystemConstantByCompany(companyId!);

      SystemConstant selectedSystemConstant;

      if (existingConstant != null) {
        // Use existing system constant
        developer.log('Found existing system constant for editing');
        selectedSystemConstant = existingConstant;
      } else {
        // Create a new one if none exists
        developer.log('No existing system constant, creating new one');
        selectedSystemConstant = SystemConstant(
          company: companyId,
          applyLotMgm: 'N',
          applyOverheadCost: 'N',
          applyLocationMgm: 'Y',
          decimalPlaces: 2,
          autoSalesPrice: 'N',
          lotQtyAutoForSales: 'Y',
          locationCategoryLevel: 1,
          rateVatPercentage: 15.0,
          rateWithholdingPercentage: 2.0,
          withHoldInitials: 1000.0,
          generateBarcodeForItem: 'N',
          reorderPointUomType: 'I',
          discountDisplay: 'Y',
          taxInfoDisplay: 'Y',
          daysLeft: 180,
          currencyCode: 'ETB',
        );
      }

      emit(
        state.copyWith(
          editItems: [selectedSystemConstant],
          selected: selectedSystemConstant,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: SystemConstantStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onCancelUpdate(
    CancelUpdate event,
    Emitter<SystemConstantState> emit,
  ) async {
    emit(state.copyWith(selected1: null, editItems: const []));
  }

  Future<void> _onCancelCreate(
    CancelCreate event,
    Emitter<SystemConstantState> emit,
  ) async {
    emit(
      state.copyWith(
        selected: null,
        createItems: const [],
        systemConstants: const [],
      ),
    );
  }

  Future<void> _onSaveSystemConstants(
    SaveSystemConstants event,
    Emitter<SystemConstantState> emit,
  ) async {
    emit(state.copyWith(status: SystemConstantStatus.loading));
    try {
      final user = authBloc.state.userId;
      final companyId = authBloc.state.companyId;

      for (final systemConstant in event.systemConstants) {
        final systemConstantWithCompany = systemConstant.copyWith(
          company: companyId,
        );
        if (systemConstant.id == null) {
          await systemConstantRepository.createSystemConstant(
            systemConstantWithCompany,
          );
        } else {
          await systemConstantRepository.updateSystemConstant(
            systemConstantWithCompany,
          );
        }
      }

      emit(
        state.copyWith(
          status: SystemConstantStatus.success,
          systemConstants: const [],
        ),
      );

      add(LoadSystemConstantsForCompany(companyId!));
    } catch (e) {
      emit(
        state.copyWith(
          status: SystemConstantStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onSaveInEdit(
    SaveInEdit event,
    Emitter<SystemConstantState> emit,
  ) async {
    //only save if there is actual change
    if (event.systemConstants.isEmpty) {
      return;
    }
    emit(state.copyWith(status: SystemConstantStatus.loading));
    try {
      final companyId = authBloc.state.companyId;
      final userId = authBloc.state.userId;
      final now = DateTime.now();

      bool hasError = false;

      for (final systemConstant in event.systemConstants) {
        // Validate rates
        if ((systemConstant.rateWithholdingPercentage != null &&
                (systemConstant.rateWithholdingPercentage! < 0.0 ||
                    systemConstant.rateWithholdingPercentage! > 100.0)) ||
            (systemConstant.rateVatPercentage != null &&
                (systemConstant.rateVatPercentage! < 0.0 ||
                    systemConstant.rateVatPercentage! > 100.0))) {
          hasError = true;
          emit(
            state.copyWith(
              status: SystemConstantStatus.failure,
              errorMessage: 'Rate should be between 0 and 100%',
            ),
          );
          break;
        }

        final systemConstantToSave = systemConstant.copyWith(
          company: companyId,
          dateLastUpdated: now,
          timeLastUpdated: now,
          updatedBy: userId!.id,
        );

        // Check if we should update or create
        final existingConstant = await systemConstantRepository
            .getSystemConstantByCompany(companyId!);
        SystemConstant? savedConstant;
        if (existingConstant != null) {
          // Update existing record - ensure we preserve the ID
          developer.log(
            'Updating existing system constant for company $companyId',
          );
          await systemConstantRepository.updateSystemConstant(
            systemConstantToSave.copyWith(id: existingConstant.id),
          );
          savedConstant = systemConstantToSave.copyWith(
            id: existingConstant.id,
          );
        } else {
          // Create new record
          developer.log('Creating new system constant for company $companyId');
          await systemConstantRepository.createSystemConstant(
            systemConstantToSave,
          );
          systemConstantService.updateSystemConstant(systemConstantToSave);
        }

        if (!hasError) {
          // RELOAD DATA AFTER SAVING
          final updatedConstants = await systemConstantRepository
              .getSystemConstants();

          emit(
            state.copyWith(
              status: SystemConstantStatus.success,
              systemConstants: updatedConstants,
              errorMessage: null,
            ),
          );
          systemConstantService.updateSystemConstant(savedConstant!);
          // Reload to get the latest data
          add(LoadSystemConstantsForCompany(companyId));
        }
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: SystemConstantStatus.failure,
          // errorMessage: 'Failed to save system constants: ${e.toString()}',
        ),
      );
      if (kDebugMode) {
        developer.log('Failed to save system constants: ${e.toString()}');
      }
    }
  }

  Future<void> _onRemoveInCreate(
    RemoveInCreate event,
    Emitter<SystemConstantState> emit,
  ) async {
    try {
      final List<SystemConstant> updatedCreateItems = List.from(
        state.createItems,
      );

      if (event.systemConstant.id == null) {
        // Remove by tempId
        updatedCreateItems.removeWhere(
          (element) => element.tempId == event.systemConstant.tempId,
        );
      } else {
        // Remove by id and also delete from repository
        updatedCreateItems.removeWhere(
          (element) => element.id == event.systemConstant.id,
        );
        await systemConstantRepository.deleteSystemConstant(
          event.systemConstant.id!,
        );
      }

      emit(state.copyWith(createItems: updatedCreateItems));
    } catch (e) {
      if (e is NetworkException) {
        emit(
          state.copyWith(
            status: SystemConstantStatus.success,
            errorMessage:
                'Deleted locally. Will sync when online: ${e.message}',
          ),
        );
        add(
          LoadSystemConstantsForCompany(authBloc.state.companyId!),
        ); // Reload to include local changes
      } else {
        emit(
          state.copyWith(
            status: SystemConstantStatus.failure,
            errorMessage: e.toString(),
          ),
        );
      }
    }
  }

  Future<void> _onRemoveInEdit(
    RemoveInEdit event,
    Emitter<SystemConstantState> emit,
  ) async {
    try {
      final List<SystemConstant> updatedEditItems = List.from(state.editItems);

      if (event.systemConstant.id == null) {
        // Remove by tempId
        updatedEditItems.removeWhere(
          (element) => element.tempId == event.systemConstant.tempId,
        );
      } else {
        // Remove by id and also delete from repository
        updatedEditItems.removeWhere(
          (element) => element.id == event.systemConstant.id,
        );
        await systemConstantRepository.deleteSystemConstant(
          event.systemConstant.id!,
        );
      }

      emit(state.copyWith(editItems: updatedEditItems));
    } catch (e) {
      emit(
        state.copyWith(
          status: SystemConstantStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}
