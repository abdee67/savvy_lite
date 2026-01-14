// features/stock/rules_table/blocs/rules_table_bloc.dart

import 'dart:async';
import 'dart:developer' as developer;
import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:savvy_stock/features/FSNMR/blocs/FSNMR_event.dart';
import 'package:savvy_stock/features/FSNMR/blocs/FSNMR_state.dart';
import 'package:savvy_stock/features/FSNMR/models/fast_slow_nonmoving_rule.dart';
import 'package:savvy_stock/features/FSNMR/repo/FSNMR_repository.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';

class FSNMRBloc extends Bloc<FSNMREvent, FSNMRState> {
  final FSNMRRepository repository;
  final AuthBloc authBloc;

  StreamSubscription? _authSubscription;

  FSNMRBloc({required this.repository, required this.authBloc})
    : super(FSNMRState()) {
    // Listen to auth state changes
    _authSubscription = authBloc.stream.listen((authState) {
      if (authState.isAuthenticated && authState.companyId != null) {
        add(LoadRules(authState.companyId!));
      }
    });

    // Event handlers - Core CRUD operations
    on<LoadRules>(_onLoadRules);
    on<CreateRule>(_onCreateRule);
    on<UpdateRule>(_onUpdateRule);
    on<DeleteRule>(_onDeleteRule);
    on<DeleteSelectedRules>(_onDeleteSelectedRules);
    on<PrepareCreate>(_onPrepareCreate);
    on<PrepareCreateInCreate>(_onPrepareCreateInCreate);
    on<SaveRow>(_onSaveRow);
    on<SaveRowMain>(_onSaveRowMain);
    on<SaveInEdit>(_onSaveInEdit);
    on<CancelUpdate>(_onCancelUpdate);
    on<CancelCreate>(_onCancelCreate);
    on<DiscardChanges>(_onDiscardChanges);
    on<RefreshList>(_onRefreshList);

    // Event handlers - Filter and search operations
    on<FilterRuleList>(_onFilterRuleList);
    on<SearchRules>(_onSearchRules);

    // Event handlers - Selection and UI operations
    on<SelectRule>(_onSelectRule);
    on<SelectAllRules>(_onSelectAllRules);
    on<ClearSelection>(_onClearSelection);
    on<SetRuleForm>(_onSetRuleForm);
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }

  // ========== CORE CRUD OPERATIONS ==========

  Future<void> _onLoadRules(LoadRules event, Emitter<FSNMRState> emit) async {
    emit(state.copyWith(status: FSNMRStatus.loading));

    try {
      final rules = await repository.findAll(event.companyId);

      emit(
        state.copyWith(
          status: FSNMRStatus.loaded,
          rules: rules,
          filteredRules: rules,
          companyId: event.companyId,
          selectedRules: [],
          searchQuery: '',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: FSNMRStatus.failure,
          message: 'Failed to load rules: $e',
        ),
      );
    }
  }

  Future<void> _onCreateRule(CreateRule event, Emitter<FSNMRState> emit) async {
    emit(
      state.copyWith(status: FSNMRStatus.creating, message: 'Creating rule...'),
    );

    try {
      final companyId = authBloc.state.companyId;
      if (companyId == null) {
        throw Exception('Company ID not found');
      }

      // Check for duplication
      final isDuplicate = await _duplicateChecker(event.rule, companyId);
      if (isDuplicate) {
        emit(
          state.copyWith(
            status: FSNMRStatus.duplication,
            message: 'Duplicate Rule ID or Barcode Not Allowed!',
          ),
        );
        return;
      }

      await repository.create(event.rule.copyWith(company: companyId));

      add(LoadRules(companyId));

      emit(
        state.copyWith(
          status: FSNMRStatus.success,
          message: 'Rule created successfully',
        ),
      );
      add(LoadRules(companyId));
    } catch (e) {
      emit(
        state.copyWith(
          status: FSNMRStatus.failure,
          message: 'Failed to create rule: $e',
        ),
      );
    }
  }

  Future<void> _onUpdateRule(UpdateRule event, Emitter<FSNMRState> emit) async {
    emit(
      state.copyWith(status: FSNMRStatus.updating, message: 'Updating rule...'),
    );

    try {
      final companyId = authBloc.state.companyId;
      if (companyId == null) {
        throw Exception('Company ID not found');
      }

      // Check for duplication
      final isDuplicate = await _duplicateChecker(event.rule, companyId);
      if (isDuplicate) {
        emit(
          state.copyWith(
            status: FSNMRStatus.duplication,
            message: 'Duplicate Rule ID or Barcode Not Allowed!',
          ),
        );
        return;
      }

      await repository.update(event.rule);

      // Reload rules
      add(LoadRules(companyId));

      emit(
        state.copyWith(
          status: FSNMRStatus.success,
          message: 'Rule updated successfully',
        ),
      );
      add(LoadRules(companyId));
    } catch (e) {
      emit(
        state.copyWith(
          status: FSNMRStatus.failure,
          message: 'Failed to update rule: $e',
        ),
      );
    }
  }

  // ========== COMPLEX BUSINESS LOGIC FROM JAVA CONTROLLER ==========

  Future<void> _onSaveRow(SaveRow event, Emitter<FSNMRState> emit) async {
    emit(
      state.copyWith(status: FSNMRStatus.updating, message: 'Saving row...'),
    );

    try {
      final companyId = authBloc.state.companyId;
      if (companyId == null) {
        throw Exception('Company ID not found');
      }

      final isValid = await _duplicateChecker(event.rule, companyId);

      if (!isValid) {
        emit(
          state.copyWith(
            status: FSNMRStatus.failure,
            message: 'Duplicate Rule ID Not Allowed!',
          ),
        );
        return;
      }

      if (event.rule.id == 0) {
        // Create new
        await repository.create(event.rule.copyWith(company: companyId));
      } else {
        // Update existing
        await repository.update(event.rule);
      }

      emit(
        state.copyWith(
          status: FSNMRStatus.success,
          message: 'Saved successfully',
        ),
      );
      add(LoadRules(companyId));
    } catch (e) {
      emit(
        state.copyWith(
          status: FSNMRStatus.failure,
          //message: 'Failed to save row: $e',
        ),
      );
      if (kDebugMode) {
        developer.log('Failed to save row: $e');
      }
    }
  }

  Future<void> _onSaveRowMain(
    SaveRowMain event,
    Emitter<FSNMRState> emit,
  ) async {
    emit(
      state.copyWith(status: FSNMRStatus.updating, message: 'Saving row...'),
    );

    try {
      final companyId = authBloc.state.companyId;
      if (companyId == null) {
        throw Exception('Company ID not found');
      }

      var ruleToSave = event.rule;

      // Duplicate checker
      final isValid = await _duplicateChecker(ruleToSave, companyId);

      if (!isValid) {
        emit(
          state.copyWith(
            status: FSNMRStatus.failure,
            message: 'Duplicate Rule ID Not Allowed!',
          ),
        );
        return;
      }

      if (ruleToSave.id == 0) {
        // Create new
        ruleToSave = ruleToSave.copyWith(company: companyId);
        await repository.create(ruleToSave);
      } else {
        // Update existing
        await repository.update(ruleToSave);
      }

      // Refresh and prepare next create like in Java controller
      add(RefreshList());
      add(PrepareCreateInCreate());

      emit(
        state.copyWith(
          status: FSNMRStatus.success,
          message: 'Saved successfully',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: FSNMRStatus.failure,
          //message: 'Failed to save row: $e',
        ),
      );
      if (kDebugMode) {
        developer.log('Failed to save row: $e');
      }
    }
  }

  /// Handler for SaveInEdit event - uses repository's saveInEdit method
  /// (equivalent to Java's saveInEdit controller method)
  Future<void> _onSaveInEdit(SaveInEdit event, Emitter<FSNMRState> emit) async {
    emit(state.copyWith(status: FSNMRStatus.updating, message: 'Saving...'));

    try {
      final companyId = authBloc.state.companyId;
      final userId = authBloc.state.userId?.id;

      if (companyId == null) {
        throw Exception('Company ID not found');
      }

      if (userId == null) {
        throw Exception('User ID not found');
      }

      // Use the repository's saveInEdit method (equivalent to Java's saveInEdit)
      final result = await repository.saveInEdit(event.rule, companyId, userId);

      if (result.success) {
        // Reload rules after successful save
        add(LoadRules(companyId));

        emit(
          state.copyWith(status: FSNMRStatus.success, message: result.message),
        );
      } else if (result.isDuplicate) {
        emit(
          state.copyWith(
            status: FSNMRStatus.duplication,
            message: result.message,
          ),
        );
      } else if (!result.hasChanges) {
        emit(
          state.copyWith(status: FSNMRStatus.failure, message: result.message),
        );
      } else {
        emit(
          state.copyWith(status: FSNMRStatus.failure, message: result.message),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: FSNMRStatus.failure,
          message: 'Error occurred: $e',
        ),
      );
      if (kDebugMode) {
        developer.log('Failed to save in edit: $e');
      }
    }
  }

  // ========== PREPARATION OPERATIONS (FROM JAVA CONTROLLER) ==========

  void _onPrepareCreate(PrepareCreate event, Emitter<FSNMRState> emit) {
    emit(
      state.copyWith(
        createRules: state.createRules,
        selected: state.selected,
        status: FSNMRStatus.creating,
      ),
    );
  }

  void _onPrepareCreateInCreate(
    PrepareCreateInCreate event,
    Emitter<FSNMRState> emit,
  ) {
    emit(
      state.copyWith(
        rules: state.rules,
        selected: state.selected,
        status: FSNMRStatus.creating,
      ),
    );
  }

  // ========== FILTER AND SEARCH OPERATIONS ==========

  Future<void> _onFilterRuleList(
    FilterRuleList event,
    Emitter<FSNMRState> emit,
  ) async {
    emit(state.copyWith(status: FSNMRStatus.loading));

    try {
      final companyId = authBloc.state.companyId;
      if (companyId == null) {
        throw Exception('Company ID not found');
      }

      final rules = await repository.filter(
        companyId: companyId,
        reportFrequency: state.selected2!.reportFrequency,
        periodInDays: state.selected2!.periodInDays,
      );

      emit(
        state.copyWith(
          status: FSNMRStatus.loaded,
          rules: rules,
          filteredRules: rules,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: FSNMRStatus.failure,
          message: 'Failed to filter rules: $e',
        ),
      );
    }
  }

  Future<void> _onSearchRules(
    SearchRules event,
    Emitter<FSNMRState> emit,
  ) async {
    final query = event.query.trim();

    if (query.isEmpty) {
      emit(
        state.copyWith(
          filteredRules: state.rules,
          searchQuery: '',
          status: FSNMRStatus.success,
        ),
      );
      return;
    }

    emit(state.copyWith(status: FSNMRStatus.searching, searchQuery: query));

    try {
      final companyId = authBloc.state.companyId;
      if (companyId != null) {
        final searchResults = await repository.search(query, companyId);
        emit(
          state.copyWith(
            filteredRules: searchResults,
            status: FSNMRStatus.success,
          ),
        );
      }
    } catch (e) {
      // Fallback to local search
      final filtered = state.rules.where((rule) {
        return rule.reportFrequency?.toString().contains(query) == true ||
            rule.periodInDays.toString().contains(query) == true;
      }).toList();

      emit(
        state.copyWith(filteredRules: filtered, status: FSNMRStatus.success),
      );
    }
  }

  // ========== HELPER METHODS FROM JAVA CONTROLLER ==========

  // Duplicate checker like in Java controller
  Future<bool> _duplicateChecker(
    FastSlowNonMovingRule rule,
    int companyId,
  ) async {
    try {
      final hasValidReportFrequency =
          rule.reportFrequency != null &&
          rule.reportFrequency!.toString().isNotEmpty;
      final hasValidPeriodInDays = rule.periodInDays != null;

      if (hasValidPeriodInDays && hasValidReportFrequency) {
        // Check both rulesId and barcode
        final duplicate = await repository.checkDuplicate(
          companyId: companyId,
          reportFrequency: rule.reportFrequency,
          periodInDays: rule.periodInDays,
          excludeId: rule.id,
        );
        return !duplicate;
      } else if (hasValidPeriodInDays) {
        // Check only rulesId
        final duplicate = await repository.periodInDaysExists(
          rule.periodInDays!,
          companyId,
          excludeId: rule.id,
        );
        return !duplicate;
      }

      return true; // No rulesId to check
    } catch (e) {
      return false;
    }
  }

  // ========== SELECTION AND UI OPERATIONS ==========

  void _onSelectRule(SelectRule event, Emitter<FSNMRState> emit) {
    final selectedRules = List<FastSlowNonMovingRule>.from(state.selectedRules);

    if (event.isSelected) {
      selectedRules.add(event.rule);
    } else {
      selectedRules.removeWhere((rule) => rule.id == event.rule.id);
    }

    emit(state.copyWith(selectedRules: selectedRules));
  }

  void _onSelectAllRules(SelectAllRules event, Emitter<FSNMRState> emit) {
    if (state.selectedRules.length == event.rules.length) {
      emit(state.copyWith(selectedRules: []));
    } else {
      emit(state.copyWith(selectedRules: List.from(event.rules)));
    }
  }

  void _onClearSelection(ClearSelection event, Emitter<FSNMRState> emit) {
    emit(state.copyWith(selectedRules: []));
  }

  void _onSetRuleForm(SetRuleForm event, Emitter<FSNMRState> emit) {
    emit(state.copyWith(ruleForm: event.rule));
  }
  // ========== DELETE OPERATIONS ==========

  Future<void> _onDeleteRule(DeleteRule event, Emitter<FSNMRState> emit) async {
    emit(
      state.copyWith(status: FSNMRStatus.deleting, message: 'Deleting rule...'),
    );

    try {
      final companyId = authBloc.state.companyId;
      if (companyId == null) {
        throw Exception('Company ID not found');
      }

      await repository.delete(event.ruleId, companyId);

      // Update local state
      final updatedRules = state.rules
          .where((rule) => rule.id != event.ruleId)
          .toList();
      final updatedFilteredRules = state.filteredRules
          .where((rule) => rule.id != event.ruleId)
          .toList();

      emit(
        state.copyWith(
          rules: updatedRules,
          filteredRules: updatedFilteredRules,
          status: FSNMRStatus.success,
          message: 'Rule deleted successfully',
          recentlyDeleted: [...state.recentlyDeleted, event.deletedRule],
          recentlyDeletedIndexes: [
            ...state.recentlyDeletedIndexes,
            event.deletedIndex,
          ],
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: FSNMRStatus.failure,
          message: 'Failed to delete rule: $e',
        ),
      );
    }
  }

  Future<void> _onDeleteSelectedRules(
    DeleteSelectedRules event,
    Emitter<FSNMRState> emit,
  ) async {
    emit(
      state.copyWith(
        status: FSNMRStatus.deleting,
        message: 'Deleting selected rules...',
      ),
    );

    try {
      final companyId = authBloc.state.companyId;
      if (companyId == null) {
        throw Exception('Company ID not found');
      }

      await repository.deleteMultiple(event.selectedRules, companyId);

      // Update local state
      final updatedRules = state.rules
          .where((rule) => !event.selectedRules.contains(rule.id))
          .toList();
      final updatedFilteredRules = state.filteredRules
          .where((rule) => !event.selectedRules.contains(rule.id))
          .toList();

      emit(
        state.copyWith(
          rules: updatedRules,
          filteredRules: updatedFilteredRules,
          selectedRules: [],
          status: FSNMRStatus.success,
          message: '${event.selectedRules.length} rules deleted successfully',
          recentlyDeleted: [...state.recentlyDeleted, ...event.deletedRules],
          recentlyDeletedIndexes: [
            ...state.recentlyDeletedIndexes,
            ...event.deletedIndexes,
          ],
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: FSNMRStatus.failure,
          message: 'Failed to delete selected rules: $e',
        ),
      );
    }
  }
  // ========== CANCEL AND REFRESH OPERATIONS ==========

  void _onCancelUpdate(CancelUpdate event, Emitter<FSNMRState> emit) {
    emit(state.copyWith(selected1: null, editRules: []));
  }

  void _onCancelCreate(CancelCreate event, Emitter<FSNMRState> emit) {
    emit(state.copyWith(selected: null, editRules: []));
  }

  void _onDiscardChanges(DiscardChanges event, Emitter<FSNMRState> emit) {
    for (final rule in state.createRules) {
      repository.delete(rule.id!, authBloc.state.companyId!);
    }

    emit(
      state.copyWith(
        selected: null,
        createRules: [],
        rules: null,
        message: 'All records are removed',
      ),
    );
  }

  void _onRefreshList(RefreshList event, Emitter<FSNMRState> emit) {
    emit(state.copyWith(selected: null, editRules: []));

    add(LoadRules(authBloc.state.companyId!));
  }
}
