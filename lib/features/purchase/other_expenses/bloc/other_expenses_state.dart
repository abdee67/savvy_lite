part of 'other_expenses_bloc.dart';

enum OtherExpensesStatus {
  initial,
  loading,
  loaded,
  saving,
  saved,
  deleting,
  deleted,
  error,
}

class OtherExpensesState extends Equatable {
  final OtherExpensesStatus status;
  final List<OtherExpense> items;
  final OtherExpense? selected;
  final List<OtherExpense> selectedMultiple;
  final List<OtherExpense> createItems;
  final List<OtherExpense> editItems;
  final String? errorMessage;
  final int totalCount;
  final int currentPage;
  final DateTime? dateFrom;
  final DateTime? dateTo;

  const OtherExpensesState({
    this.status = OtherExpensesStatus.initial,
    this.items = const [],
    this.selected,
    this.selectedMultiple = const [],
    this.createItems = const [],
    this.editItems = const [],
    this.errorMessage,
    this.totalCount = 0,
    this.currentPage = 1,
    this.dateFrom,
    this.dateTo,
  });

  bool get isLoading => status == OtherExpensesStatus.loading;
  bool get isSaving => status == OtherExpensesStatus.saving;
  bool get hasError => status == OtherExpensesStatus.error;
  bool get hasMore => items.length < totalCount;
  int get totalPages =>
      (totalCount / 20).ceil().clamp(1, double.maxFinite.toInt());

  OtherExpensesState copyWith({
    OtherExpensesStatus? status,
    List<OtherExpense>? items,
    OtherExpense? selected,
    bool clearSelected = false,
    List<OtherExpense>? selectedMultiple,
    List<OtherExpense>? createItems,
    List<OtherExpense>? editItems,
    String? errorMessage,
    bool clearError = false,
    int? totalCount,
    int? currentPage,
    DateTime? dateFrom,
    bool clearDateFrom = false,
    DateTime? dateTo,
    bool clearDateTo = false,
  }) {
    return OtherExpensesState(
      status: status ?? this.status,
      items: items ?? this.items,
      selected: clearSelected ? null : (selected ?? this.selected),
      selectedMultiple: selectedMultiple ?? this.selectedMultiple,
      createItems: createItems ?? this.createItems,
      editItems: editItems ?? this.editItems,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      totalCount: totalCount ?? this.totalCount,
      currentPage: currentPage ?? this.currentPage,
      dateFrom: clearDateFrom ? null : (dateFrom ?? this.dateFrom),
      dateTo: clearDateTo ? null : (dateTo ?? this.dateTo),
    );
  }

  @override
  List<Object?> get props => [
    status,
    items,
    selected,
    selectedMultiple,
    createItems,
    editItems,
    errorMessage,
    totalCount,
    currentPage,
    dateFrom,
    dateTo,
  ];
}
