import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:meta/meta.dart';
import 'package:savvy_stock/core/models/system_constant.dart';
import 'package:savvy_stock/core/repositories/system_constant_repository.dart';
import 'package:savvy_stock/core/services/auth_services/auth_service.dart';
import 'system_constant_event.dart';
import 'system_constant_state.dart';

class SystemConstantBloc
    extends Bloc<SystemConstantEvent, SystemConstantState> {
  final SystemConstantRepository systemConstantRepository;
  final AuthService authService;
  Timer? _syncTimer;

  SystemConstantBloc({
    required this.systemConstantRepository,
    required this.authService,
  }) : super(const SystemConstantState()) {
    on<LoadSystemConstants>(_onLoadSystemConstants);
    on<LoadSystemConstant>(_onLoadSystemConstant);
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
    on<PullSystemConstants>(_onPullSystemConstants);

    // Start periodic sync (every 5 minutes)
    _startSyncTimer();
  }

  void _startSyncTimer() {
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      add(const SyncSystemConstants());
    });
  }

  @override
  Future<void> close() {
    _syncTimer?.cancel();
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
          .getLocalSystemConstants();

      // If no local data, try to pull from remote
      if (systemConstants.isEmpty) {
        await systemConstantRepository.pullLatestSystemConstants();
        final updatedSystemConstants = await systemConstantRepository
            .getLocalSystemConstants();
        emit(
          state.copyWith(
            status: SystemConstantStatus.success,
            systemConstants: updatedSystemConstants,
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: SystemConstantStatus.success,
            systemConstants: systemConstants,
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: SystemConstantStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onLoadSystemConstant(
    LoadSystemConstant event,
    Emitter<SystemConstantState> emit,
  ) async {
    emit(state.copyWith(status: SystemConstantStatus.loading));
    try {
      // Try to load from local database first
      final systemConstant = await systemConstantRepository
          .getLocalSystemConstant(event.id);

      if (systemConstant == null) {
        // If not found locally, try to pull from remote
        await systemConstantRepository.pullLatestSystemConstants();
        final updatedSystemConstant = await systemConstantRepository
            .getLocalSystemConstant(event.id);

        if (updatedSystemConstant != null) {
          emit(
            state.copyWith(
              status: SystemConstantStatus.success,
              selected: updatedSystemConstant,
            ),
          );
        } else {
          emit(
            state.copyWith(
              status: SystemConstantStatus.failure,
              errorMessage: 'System constant not found',
            ),
          );
        }
      } else {
        emit(
          state.copyWith(
            status: SystemConstantStatus.success,
            selected: systemConstant,
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: SystemConstantStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onSyncSystemConstants(
    SyncSystemConstants event,
    Emitter<SystemConstantState> emit,
  ) async {
    try {
      emit(state.copyWith(status: SystemConstantStatus.syncing));
      await systemConstantRepository.syncSystemConstants();

      // Reload data after sync
      final systemConstants = await systemConstantRepository
          .getLocalSystemConstants();
      emit(
        state.copyWith(
          status: SystemConstantStatus.success,
          systemConstants: systemConstants,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: SystemConstantStatus
              .success, // Don't show error for background sync
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onPullSystemConstants(
    PullSystemConstants event,
    Emitter<SystemConstantState> emit,
  ) async {
    try {
      emit(state.copyWith(status: SystemConstantStatus.syncing));
      await systemConstantRepository.pullLatestSystemConstants();

      // Reload data after pull
      final systemConstants = await systemConstantRepository
          .getLocalSystemConstants();
      emit(
        state.copyWith(
          status: SystemConstantStatus.success,
          systemConstants: systemConstants,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: SystemConstantStatus.failure,
          errorMessage: 'Failed to pull latest data: $e',
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
      await systemConstantRepository.insertLocalSystemConstant(
        event.systemConstant,
      );
      add(const LoadSystemConstants());

      // Try to sync in background
      add(const SyncSystemConstants());
    } catch (e) {
      emit(
        state.copyWith(
          status: SystemConstantStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onUpdateSystemConstant(
    UpdateSystemConstant event,
    Emitter<SystemConstantState> emit,
  ) async {
    emit(state.copyWith(status: SystemConstantStatus.loading));
    try {
      await systemConstantRepository.updateLocalSystemConstant(
        event.systemConstant,
      );
      add(const LoadSystemConstants());

      // Try to sync in background
      add(const SyncSystemConstants());
    } catch (e) {
      emit(
        state.copyWith(
          status: SystemConstantStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onDeleteSystemConstant(
    DeleteSystemConstant event,
    Emitter<SystemConstantState> emit,
  ) async {
    emit(state.copyWith(status: SystemConstantStatus.loading));
    try {
      await systemConstantRepository.deleteLocalSystemConstant(
        event.systemConstant.id!,
      );
      add(const LoadSystemConstants());

      // Try to sync in background
      add(const SyncSystemConstants());
    } catch (e) {
      emit(
        state.copyWith(
          status: SystemConstantStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onPrepareCreate(
    PrepareCreate event,
    Emitter<SystemConstantState> emit,
  ) async {
    try {
      final user = authService.currentUser;
      final companyId = user?.company;

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
      final user = authService.currentUser;
      final companyId = user?.company;
      final isSuperUser = user?.superUser == '1';

      // Get system constants for the current company
      final systemConstants = await systemConstantRepository
          .getLocalSystemConstants();
      final companySystemConstants = systemConstants.where((sc) {
        return (isSuperUser && sc.company == null) ||
            (sc.company != null && sc.company == companyId);
      }).toList();

      SystemConstant selectedSystemConstant;
      if (companySystemConstants.isNotEmpty) {
        selectedSystemConstant = companySystemConstants.first;
      } else {
        // Create a new one if none exists
        selectedSystemConstant = SystemConstant(
          company: companyId,
          applyLotMgm: 'N',
          applyLocationMgm: 'Y',
          decimalPlaces: 2,
          autoSalesPrice: 'N',
          lotQtyAutoForSales: 'Y',
          locationCategoryLevel: 1,
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
      final user = authService.currentUser;
      final companyId = user?.company;

      for (final systemConstant in event.systemConstants) {
        final systemConstantWithCompany = systemConstant.copyWith(
          company: companyId,
        );
        if (systemConstant.id == null) {
          await systemConstantRepository.createRemoteSystemConstant(
            systemConstantWithCompany,
          );
        } else {
          await systemConstantRepository.updateRemoteSystemConstant(
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

      add(const LoadSystemConstants());
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
    emit(state.copyWith(status: SystemConstantStatus.loading));
    try {
      final user = authService.currentUser;
      final companyId = user?.company;
      final now = DateTime.now();

      bool hasError = false;

      for (final systemConstant in event.systemConstants) {
        // Validate rates
        if ((systemConstant.rateWithPercentage != null &&
                (systemConstant.rateWithPercentage! < 0.0 ||
                    systemConstant.rateWithPercentage! > 100.0)) ||
            (systemConstant.rateVatPercentage != null &&
                (systemConstant.rateVatPercentage! < 0.0 ||
                    systemConstant.rateVatPercentage! > 100.0))) {
          hasError = true;
          emit(
            state.copyWith(
              status: SystemConstantStatus.failure,
              errorMessage: 'Rate is beyond 100%',
            ),
          );
          break;
        }

        final systemConstantToSave = systemConstant.copyWith(
          company: companyId,
          dateLastUpdated: now,
          timeLastUpdated: now,
        );

        if (systemConstantToSave.id == null) {
          await systemConstantRepository.createRemoteSystemConstant(
            systemConstantToSave,
          );
        } else {
          await systemConstantRepository.updateRemoteSystemConstant(
            systemConstantToSave,
          );
        }
      }

      if (!hasError) {
        emit(state.copyWith(status: SystemConstantStatus.success));
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: SystemConstantStatus.failure,
          errorMessage: e.toString(),
        ),
      );
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
        await systemConstantRepository.deleteLocalSystemConstant(
          event.systemConstant.id!,
        );
      }

      emit(state.copyWith(createItems: updatedCreateItems));
    } catch (e) {
      emit(
        state.copyWith(
          status: SystemConstantStatus.failure,
          errorMessage: e.toString(),
        ),
      );
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
        await systemConstantRepository.deleteLocalSystemConstant(
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
