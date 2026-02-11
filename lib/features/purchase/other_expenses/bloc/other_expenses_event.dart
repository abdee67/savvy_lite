part of 'other_expenses_bloc.dart';

sealed class OtherExpensesEvent extends Equatable {
  const OtherExpensesEvent();

  @override
  List<Object?> get props => [];
}

/// Load all expenses for the current company
class LoadOtherExpenses extends OtherExpensesEvent {
  const LoadOtherExpenses();
}

/// Load paginated expenses with optional date filtering
class LoadPaginatedExpenses extends OtherExpensesEvent {
  final int page;
  final int pageSize;
  final DateTime? dateFrom;
  final DateTime? dateTo;

  const LoadPaginatedExpenses({
    required this.page,
    required this.pageSize,
    this.dateFrom,
    this.dateTo,
  });

  @override
  List<Object?> get props => [page, pageSize, dateFrom, dateTo];
}

/// Prepare state for creating a new expense
class PrepareCreateExpense extends OtherExpensesEvent {
  const PrepareCreateExpense();
}

/// Prepare state for editing an existing expense
class PrepareEditExpense extends OtherExpensesEvent {
  final OtherExpense expense;

  const PrepareEditExpense(this.expense);

  @override
  List<Object?> get props => [expense];
}

/// Add new expense to create list
class PrepareCreateInCreate extends OtherExpensesEvent {
  const PrepareCreateInCreate();
}

/// Add new expense to edit list
class PrepareCreateInEdit extends OtherExpensesEvent {
  const PrepareCreateInEdit();
}

/// Save a single expense (create or update)
class SaveOtherExpense extends OtherExpensesEvent {
  final OtherExpense expense;

  const SaveOtherExpense(this.expense);

  @override
  List<Object?> get props => [expense];
}

/// Save all expenses in the create list
class SaveCreateItems extends OtherExpensesEvent {
  const SaveCreateItems();
}

/// Save all expenses in the edit list
class SaveEditItems extends OtherExpensesEvent {
  const SaveEditItems();
}

/// Delete a single expense
class DeleteOtherExpense extends OtherExpensesEvent {
  final int id;

  const DeleteOtherExpense(this.id);

  @override
  List<Object?> get props => [id];
}

/// Delete multiple expenses
class DeleteMultipleExpenses extends OtherExpensesEvent {
  final List<int> ids;

  const DeleteMultipleExpenses(this.ids);

  @override
  List<Object?> get props => [ids];
}

/// Remove expense from create list (before persisting)
class RemoveInCreate extends OtherExpensesEvent {
  final OtherExpense expense;

  const RemoveInCreate(this.expense);

  @override
  List<Object?> get props => [expense];
}

/// Remove expense from edit list
class RemoveInEdit extends OtherExpensesEvent {
  final OtherExpense expense;

  const RemoveInEdit(this.expense);

  @override
  List<Object?> get props => [expense];
}

/// Refresh the expense list
class RefreshList extends OtherExpensesEvent {
  const RefreshList();
}

/// Select an expense
class SelectExpense extends OtherExpensesEvent {
  final OtherExpense? expense;

  const SelectExpense(this.expense);

  @override
  List<Object?> get props => [expense];
}

/// Select multiple expenses
class SelectMultipleExpenses extends OtherExpensesEvent {
  final List<OtherExpense> expenses;

  const SelectMultipleExpenses(this.expenses);

  @override
  List<Object?> get props => [expenses];
}

/// Clear selection
class ClearSelection extends OtherExpensesEvent {
  const ClearSelection();
}

/// Update date filters
class UpdateDateFilters extends OtherExpensesEvent {
  final DateTime? dateFrom;
  final DateTime? dateTo;

  const UpdateDateFilters({this.dateFrom, this.dateTo});

  @override
  List<Object?> get props => [dateFrom, dateTo];
}

/// Cancel update operation
class CancelUpdate extends OtherExpensesEvent {
  const CancelUpdate();
}

/// Cancel create operation
class CancelCreate extends OtherExpensesEvent {
  const CancelCreate();
}

/// Update item costs by distributing overhead costs
/// This is the main business logic from Java updateItemCostsByOverheadCosts
class UpdateItemCostsByOverheadCosts extends OtherExpensesEvent {
  const UpdateItemCostsByOverheadCosts();
}
