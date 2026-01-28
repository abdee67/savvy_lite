import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/purchase/other_expenses/repo/other_expense_repository.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/models/other_expenses.dart';
import 'package:savvy_stock/features/stock/item_cost/blocs/item_cost_bloc.dart';
import 'package:savvy_stock/features/stock/item_cost/blocs/item_cost_event.dart';
import 'package:savvy_stock/features/stock/item_entry/blocs/item_entry_bloc.dart';
import 'package:savvy_stock/features/stock/item_in_branch/blocs/item_in_branch_bloc.dart';
import 'package:savvy_stock/features/system_constant/bloc/system_constant_bloc.dart';

part 'other_expenses_event.dart';
part 'other_expenses_state.dart';

class OtherExpensesBloc extends Bloc<OtherExpensesEvent, OtherExpensesState> {
  final OtherExpenseRepository repository;
  final AuthBloc authBloc;
  final ItemCostBloc? itemCostBloc;
  final StockItemInBranchBloc? itemInBranchBloc;
  final SystemConstantBloc? systemConstantBloc;
  final StockItemsEntryBloc? itemEntryBloc;

  OtherExpensesBloc({
    required this.repository,
    required this.authBloc,
    this.itemCostBloc,
    this.itemInBranchBloc,
    this.systemConstantBloc,
    this.itemEntryBloc,
  }) : super(const OtherExpensesState()) {
    on<LoadOtherExpenses>(_onLoadOtherExpenses);
    on<LoadPaginatedExpenses>(_onLoadPaginatedExpenses);
    on<PrepareCreateExpense>(_onPrepareCreate);
    on<PrepareEditExpense>(_onPrepareEdit);
    on<PrepareCreateInCreate>(_onPrepareCreateInCreate);
    on<PrepareCreateInEdit>(_onPrepareCreateInEdit);
    on<SaveOtherExpense>(_onSaveOtherExpense);
    on<SaveCreateItems>(_onSaveCreateItems);
    on<SaveEditItems>(_onSaveEditItems);
    on<DeleteOtherExpense>(_onDeleteOtherExpense);
    on<DeleteMultipleExpenses>(_onDeleteMultipleExpenses);
    on<RemoveInCreate>(_onRemoveInCreate);
    on<RemoveInEdit>(_onRemoveInEdit);
    on<RefreshList>(_onRefreshList);
    on<SelectExpense>(_onSelectExpense);
    on<SelectMultipleExpenses>(_onSelectMultipleExpenses);
    on<ClearSelection>(_onClearSelection);
    on<UpdateDateFilters>(_onUpdateDateFilters);
    on<CancelCreate>(_onCancelCreate);
    on<CancelUpdate>(_onCancelUpdate);
    on<UpdateItemCostsByOverheadCosts>(_onUpdateItemCostsByOverheadCosts);
  }

  int? get _companyId => authBloc.state.companyId;
  int? get _userId => authBloc.state.userId?.id;

  /// Helper to generate next temp ID for list
  int _getNextTempId(List<OtherExpense> list) {
    if (list.isEmpty) return 1;
    return list.map((e) => e.tempId ?? 0).reduce(max) + 1;
  }

  /// Filter items by company permission (like Java implementation)
  List<OtherExpense> _filterByCompany(List<OtherExpense> items) {
    final companyId = _companyId;
    if (companyId == null) return items;

    return items.where((item) => item.company == companyId).toList();
  }

  /// Load all expenses
  Future<void> _onLoadOtherExpenses(
    LoadOtherExpenses event,
    Emitter<OtherExpensesState> emit,
  ) async {
    try {
      emit(state.copyWith(status: OtherExpensesStatus.loading));

      final companyId = _companyId;
      if (companyId == null) {
        emit(
          state.copyWith(
            status: OtherExpensesStatus.error,
            errorMessage: 'No company selected',
          ),
        );
        return;
      }

      final items = await repository.findAll(companyId);
      final filteredItems = _filterByCompany(items);

      emit(
        state.copyWith(
          status: OtherExpensesStatus.loaded,
          items: filteredItems,
          totalCount: filteredItems.length,
          clearError: true,
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        developer.log('Error loading other expenses: $e');
      }
      emit(
        state.copyWith(
          status: OtherExpensesStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  /// Load paginated expenses with date filtering (Java getLazyItems equivalent)
  Future<void> _onLoadPaginatedExpenses(
    LoadPaginatedExpenses event,
    Emitter<OtherExpensesState> emit,
  ) async {
    try {
      emit(state.copyWith(status: OtherExpensesStatus.loading));

      final companyId = _companyId;
      if (companyId == null) {
        emit(
          state.copyWith(
            status: OtherExpensesStatus.error,
            errorMessage: 'No company selected',
          ),
        );
        return;
      }

      final result = await repository.getPaginatedExpenses(
        companyId: companyId,
        page: event.page,
        pageSize: event.pageSize,
        dateFrom: event.dateFrom ?? state.dateFrom,
        dateTo: event.dateTo ?? state.dateTo,
      );

      final filteredItems = _filterByCompany(result.items);

      emit(
        state.copyWith(
          status: OtherExpensesStatus.loaded,
          items: filteredItems,
          totalCount: result.totalCount,
          currentPage: event.page,
          dateFrom: event.dateFrom,
          dateTo: event.dateTo,
          clearError: true,
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        developer.log('Error loading paginated expenses: $e');
      }
      emit(
        state.copyWith(
          status: OtherExpensesStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  /// Prepare for creating a new expense (Java prepareCreate)
  Future<void> _onPrepareCreate(
    PrepareCreateExpense event,
    Emitter<OtherExpensesState> emit,
  ) async {
    final newExpense = OtherExpense(
      tempId: 1,
      company: _companyId,
      userId: _userId,
      datePayment: DateTime.now(),
    );

    emit(
      state.copyWith(
        createItems: [newExpense],
        selected: newExpense,
        clearError: true,
      ),
    );
  }

  /// Prepare for editing an existing expense (Java prepareEdit)
  Future<void> _onPrepareEdit(
    PrepareEditExpense event,
    Emitter<OtherExpensesState> emit,
  ) async {
    emit(
      state.copyWith(
        editItems: [event.expense],
        selected: event.expense,
        clearError: true,
      ),
    );
  }

  /// Add new expense to create list (Java prepareCreateInCreate)
  Future<void> _onPrepareCreateInCreate(
    PrepareCreateInCreate event,
    Emitter<OtherExpensesState> emit,
  ) async {
    final newTempId = _getNextTempId(state.createItems);
    final newExpense = OtherExpense(
      tempId: newTempId,
      company: _companyId,
      userId: _userId,
      datePayment: DateTime.now(),
    );

    final updatedList = [...state.createItems, newExpense];
    emit(state.copyWith(createItems: updatedList, selected: newExpense));
  }

  /// Add new expense to edit list (Java prepareCreateInEdit)
  Future<void> _onPrepareCreateInEdit(
    PrepareCreateInEdit event,
    Emitter<OtherExpensesState> emit,
  ) async {
    final newTempId = _getNextTempId(state.editItems);
    final newExpense = OtherExpense(
      tempId: newTempId,
      company: _companyId,
      userId: _userId,
      datePayment: DateTime.now(),
    );

    final updatedList = [...state.editItems, newExpense];
    emit(state.copyWith(editItems: updatedList, selected: newExpense));
  }

  /// Save a single expense (Java save)
  Future<void> _onSaveOtherExpense(
    SaveOtherExpense event,
    Emitter<OtherExpensesState> emit,
  ) async {
    try {
      emit(state.copyWith(status: OtherExpensesStatus.saving));

      final expense = event.expense.copyWith(
        company: event.expense.company ?? _companyId,
        userId: event.expense.userId ?? _userId,
        dateUpdated: DateTime.now(),
      );

      if (expense.id == null) {
        await repository.create(expense);
      } else {
        await repository.update(expense);
      }

      emit(state.copyWith(status: OtherExpensesStatus.saved, clearError: true));

      // Refresh list
      add(const LoadOtherExpenses());
    } catch (e) {
      if (kDebugMode) {
        developer.log('Error saving expense: $e');
      }
      emit(
        state.copyWith(
          status: OtherExpensesStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  /// Save all expenses in create list (Java saveRow for create)
  Future<void> _onSaveCreateItems(
    SaveCreateItems event,
    Emitter<OtherExpensesState> emit,
  ) async {
    try {
      emit(state.copyWith(status: OtherExpensesStatus.saving));

      final expensesToSave = state.createItems
          .map(
            (e) => e.copyWith(
              company: e.company ?? _companyId,
              userId: e.userId ?? _userId,
              dateUpdated: DateTime.now(),
            ),
          )
          .toList();

      await repository.saveMultiple(expensesToSave);

      emit(
        state.copyWith(
          status: OtherExpensesStatus.saved,
          createItems: [],
          clearSelected: true,
          clearError: true,
        ),
      );

      // Refresh list
      add(const LoadOtherExpenses());
    } catch (e) {
      if (kDebugMode) {
        developer.log('Error saving create items: $e');
      }
      emit(
        state.copyWith(
          status: OtherExpensesStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  /// Save all expenses in edit list (Java saveInEdit)
  Future<void> _onSaveEditItems(
    SaveEditItems event,
    Emitter<OtherExpensesState> emit,
  ) async {
    try {
      emit(state.copyWith(status: OtherExpensesStatus.saving));

      final expensesToSave = state.editItems
          .map((e) => e.copyWith(dateUpdated: DateTime.now()))
          .toList();

      await repository.saveMultiple(expensesToSave);

      emit(
        state.copyWith(
          status: OtherExpensesStatus.saved,
          editItems: [],
          clearSelected: true,
          clearError: true,
        ),
      );

      // Refresh list
      add(const LoadOtherExpenses());
    } catch (e) {
      if (kDebugMode) {
        developer.log('Error saving edit items: $e');
      }
      emit(
        state.copyWith(
          status: OtherExpensesStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  /// Delete a single expense
  Future<void> _onDeleteOtherExpense(
    DeleteOtherExpense event,
    Emitter<OtherExpensesState> emit,
  ) async {
    try {
      emit(state.copyWith(status: OtherExpensesStatus.deleting));

      await repository.delete(event.id);

      emit(
        state.copyWith(status: OtherExpensesStatus.deleted, clearError: true),
      );

      // Refresh list
      add(const LoadOtherExpenses());
    } catch (e) {
      if (kDebugMode) {
        developer.log('Error deleting expense: $e');
      }
      emit(
        state.copyWith(
          status: OtherExpensesStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  /// Delete multiple expenses (Java destroy with multiselection)
  Future<void> _onDeleteMultipleExpenses(
    DeleteMultipleExpenses event,
    Emitter<OtherExpensesState> emit,
  ) async {
    try {
      emit(state.copyWith(status: OtherExpensesStatus.deleting));

      await repository.deleteMultiple(event.ids);

      emit(
        state.copyWith(
          status: OtherExpensesStatus.deleted,
          selectedMultiple: [],
          clearError: true,
        ),
      );

      // Refresh list
      add(const LoadOtherExpenses());
    } catch (e) {
      if (kDebugMode) {
        developer.log('Error deleting multiple expenses: $e');
      }
      emit(
        state.copyWith(
          status: OtherExpensesStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  /// Remove expense from create list (Java removeInCreate)
  Future<void> _onRemoveInCreate(
    RemoveInCreate event,
    Emitter<OtherExpensesState> emit,
  ) async {
    final expense = event.expense;

    // If it has an ID, delete from database
    if (expense.id != null) {
      await repository.delete(expense.id!);
    }

    // Remove from create list
    final updatedList = state.createItems.where((e) {
      if (expense.id != null) {
        return e.id != expense.id;
      }
      return e.tempId != expense.tempId;
    }).toList();

    emit(state.copyWith(createItems: updatedList));
  }

  /// Remove expense from edit list (Java removeInEdit)
  Future<void> _onRemoveInEdit(
    RemoveInEdit event,
    Emitter<OtherExpensesState> emit,
  ) async {
    final expense = event.expense;

    // If it has an ID, delete from database
    if (expense.id != null) {
      await repository.delete(expense.id!);
    }

    // Remove from edit list
    final updatedList = state.editItems.where((e) {
      if (expense.id != null) {
        return e.id != expense.id;
      }
      return e.tempId != expense.tempId;
    }).toList();

    emit(state.copyWith(editItems: updatedList));
  }

  /// Refresh the expense list (Java refreshList)
  Future<void> _onRefreshList(
    RefreshList event,
    Emitter<OtherExpensesState> emit,
  ) async {
    emit(state.copyWith(items: [], clearSelected: true));
    add(const LoadOtherExpenses());
  }

  /// Select an expense
  Future<void> _onSelectExpense(
    SelectExpense event,
    Emitter<OtherExpensesState> emit,
  ) async {
    emit(
      state.copyWith(
        selected: event.expense,
        clearSelected: event.expense == null,
      ),
    );
  }

  /// Select multiple expenses
  Future<void> _onSelectMultipleExpenses(
    SelectMultipleExpenses event,
    Emitter<OtherExpensesState> emit,
  ) async {
    emit(state.copyWith(selectedMultiple: event.expenses));
  }

  /// Clear selection
  Future<void> _onClearSelection(
    ClearSelection event,
    Emitter<OtherExpensesState> emit,
  ) async {
    emit(state.copyWith(clearSelected: true, selectedMultiple: []));
  }

  /// Update date filters
  Future<void> _onUpdateDateFilters(
    UpdateDateFilters event,
    Emitter<OtherExpensesState> emit,
  ) async {
    emit(
      state.copyWith(
        dateFrom: event.dateFrom,
        dateTo: event.dateTo,
        clearDateFrom: event.dateFrom == null,
        clearDateTo: event.dateTo == null,
      ),
    );
  }

  /// Cancel create operation (Java cancelCreate)
  Future<void> _onCancelCreate(
    CancelCreate event,
    Emitter<OtherExpensesState> emit,
  ) async {
    emit(state.copyWith(createItems: [], clearSelected: true));
  }

  /// Cancel update operation (Java cancelUpdate)
  Future<void> _onCancelUpdate(
    CancelUpdate event,
    Emitter<OtherExpensesState> emit,
  ) async {
    emit(state.copyWith(editItems: []));
  }

  /// Update all item costs by distributing overhead costs
  /// (Java updateItemCostsByOverheadCosts + overHeadPerUnit)
  Future<void> _onUpdateItemCostsByOverheadCosts(
    UpdateItemCostsByOverheadCosts event,
    Emitter<OtherExpensesState> emit,
  ) async {
    try {
      emit(state.copyWith(status: OtherExpensesStatus.loading));

      // Check if overhead cost is enabled in system constants
      final systemConstant = systemConstantBloc?.state.selected;
      if (systemConstant == null || systemConstant.applyOverheadCost != 'Y') {
        if (kDebugMode) {
          developer.log('Overhead cost is not enabled in system constants');
        }
        emit(state.copyWith(status: OtherExpensesStatus.loaded));
        return;
      }

      final companyId = _companyId;
      if (companyId == null) {
        emit(
          state.copyWith(
            status: OtherExpensesStatus.error,
            errorMessage: 'No company selected',
          ),
        );
        return;
      }

      // Calculate overhead per unit
      final overheadPerUnit = await _calculateOverHeadPerUnit(companyId);

      if (overheadPerUnit <= 0) {
        if (kDebugMode) {
          developer.log('Overhead per unit is zero or negative');
        }
        emit(state.copyWith(status: OtherExpensesStatus.loaded));
        return;
      }

      if (kDebugMode) {
        developer.log('Calculated overhead per unit: $overheadPerUnit');
      }

      // Trigger item cost update via ItemCostBloc
      itemCostBloc?.add(UpdateItemCostsByOverhead(overheadPerUnit));

      emit(
        state.copyWith(status: OtherExpensesStatus.loaded, clearError: true),
      );
    } catch (e) {
      if (kDebugMode) {
        developer.log('Error updating item costs by overhead: $e');
      }
      emit(
        state.copyWith(
          status: OtherExpensesStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  /// Calculate overhead cost per unit (Java overHeadPerUnit)
  Future<double> _calculateOverHeadPerUnit(int companyId) async {
    try {
      // Get month boundaries for current date
      final now = DateTime.now();
      final boundaries = repository.getMonthBoundaries(now);
      final startDate = boundaries[0];
      final endDate = boundaries[1];

      // Get total monthly expenses
      final totalMonthlyExpenses = await repository.getMonthlyExpensesTotal(
        companyId: companyId,
        startDate: startDate,
        endDate: endDate,
      );

      if (kDebugMode) {
        developer.log('Total monthly expenses: $totalMonthlyExpenses');
      }

      if (totalMonthlyExpenses <= 0) return 0.0;

      // Get total units available across all items
      // This requires getting all items and summing their availability
      double totalUnits = 0.0;

      if (itemEntryBloc != null && itemInBranchBloc != null) {
        final items = itemEntryBloc!.state.items;
        for (final item in items) {
          final availability = await itemInBranchBloc!
              .totalAvailabilityOfAnItemInSpecificPrimary(item.id);
          totalUnits += availability;
        }
      }

      if (kDebugMode) {
        developer.log('Total units available: $totalUnits');
      }

      if (totalUnits <= 0) return 0.0;

      // Get decimal places from system constant
      final decimalPlaces =
          systemConstantBloc?.state.selected?.decimalPlaces ?? 2;

      // Calculate overhead per unit with proper rounding
      final overheadPerUnit = totalMonthlyExpenses / totalUnits;

      // Round to specified decimal places
      final multiplier = pow(10, decimalPlaces);
      return (overheadPerUnit * multiplier).roundToDouble() / multiplier;
    } catch (e) {
      if (kDebugMode) {
        developer.log('Error calculating overhead per unit: $e');
      }
      return 0.0;
    }
  }
}
