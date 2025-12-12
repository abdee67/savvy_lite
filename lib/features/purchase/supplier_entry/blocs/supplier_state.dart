// lib/features/purchase/supplier/bloc/supplier_state.dart
import 'package:equatable/equatable.dart';
import 'package:savvy_stock/features/purchase/supplier_entry/models/supplier_model.dart';

enum SupplierStatus {
  initial,
  loading,
  loaded,
  creating,
  updating,
  deleting,
  saving,
  success,
  failure,
  validating,
}

class SupplierState extends Equatable {
  final SupplierStatus status;
  final List<SupplierModel> suppliers;
  final List<SupplierModel> filteredSuppliers;
  final List<SupplierModel> createItems;
  final List<SupplierModel> editItems;
  final List<SupplierModel> multiSelectionItems;
  final List<SupplierModel> selectedSuppliers;
  final SupplierModel? selected;
  final SupplierModel? selected1;
  final SupplierModel? selected2;
  final String message;
  final String errorMessage;
  final String? validationError;
  final int? companyId;
  final String searchQuery;
  final String? tinNumber;
  final String? phoneNumber;
  final String? country;
  final bool showDetailPanel;
  final SupplierModel? supplierDetail;
  final SupplierModel? supplierForm;
  final int firstItemIndex;
  final String dataName;
  final bool hasReachedMax;

  const SupplierState({
    this.status = SupplierStatus.initial,
    this.suppliers = const [],
    this.filteredSuppliers = const [],
    this.createItems = const [],
    this.editItems = const [],
    this.multiSelectionItems = const [],
    this.selectedSuppliers = const [],
    this.selected,
    this.selected1,
    this.selected2,
    this.message = '',
    this.errorMessage = '',
    this.validationError,
    this.companyId,
    this.searchQuery = '',
    this.tinNumber,
    this.phoneNumber,
    this.country,
    this.showDetailPanel = false,
    this.supplierDetail,
    this.supplierForm,
    this.firstItemIndex = 0,
    this.dataName = 'SupplierTable',
    this.hasReachedMax = false,
  });

  factory SupplierState.initial() {
    return const SupplierState(
      status: SupplierStatus.initial,
      suppliers: [],
      filteredSuppliers: [],
      createItems: [],
      editItems: [],
      multiSelectionItems: [],
      selectedSuppliers: [],
      selected: null,
      selected1: null,
      selected2: SupplierModel(),
      message: '',
      errorMessage: '',
      validationError: null,
      companyId: null,
      searchQuery: '',
      tinNumber: null,
      phoneNumber: null,
      country: null,
      showDetailPanel: false,
      supplierDetail: null,
      supplierForm: null,
      firstItemIndex: 0,
      dataName: 'SupplierTable',
      hasReachedMax: false,
    );
  }

  SupplierState copyWith({
    SupplierStatus? status,
    List<SupplierModel>? suppliers,
    List<SupplierModel>? filteredSuppliers,
    List<SupplierModel>? createItems,
    List<SupplierModel>? editItems,
    List<SupplierModel>? multiSelectionItems,
    List<SupplierModel>? selectedSuppliers,
    SupplierModel? selected,
    SupplierModel? selected1,
    SupplierModel? selected2,
    String? message,
    String? errorMessage,
    String? validationError,
    int? companyId,
    String? searchQuery,
    String? tinNumber,
    String? phoneNumber,
    String? country,
    bool? showDetailPanel,
    SupplierModel? supplierDetail,
    SupplierModel? supplierForm,
    int? firstItemIndex,
    String? dataName,
    bool? hasReachedMax,
  }) {
    return SupplierState(
      status: status ?? this.status,
      suppliers: suppliers ?? this.suppliers,
      filteredSuppliers: filteredSuppliers ?? this.filteredSuppliers,
      createItems: createItems ?? this.createItems,
      editItems: editItems ?? this.editItems,
      multiSelectionItems: multiSelectionItems ?? this.multiSelectionItems,
      selectedSuppliers: selectedSuppliers ?? this.selectedSuppliers,
      selected: selected ?? this.selected,
      selected1: selected1 ?? this.selected1,
      selected2: selected2 ?? this.selected2,
      message: message ?? this.message,
      errorMessage: errorMessage ?? this.errorMessage,
      validationError: validationError ?? this.validationError,
      companyId: companyId ?? this.companyId,
      searchQuery: searchQuery ?? this.searchQuery,
      tinNumber: tinNumber ?? this.tinNumber,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      country: country ?? this.country,
      showDetailPanel: showDetailPanel ?? this.showDetailPanel,
      supplierDetail: supplierDetail ?? this.supplierDetail,
      supplierForm: supplierForm ?? this.supplierForm,
      firstItemIndex: firstItemIndex ?? this.firstItemIndex,
      dataName: dataName ?? this.dataName,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
    );
  }

  // Helper methods for state transitions
  SupplierState loading() => copyWith(status: SupplierStatus.loading);
  SupplierState saving() => copyWith(status: SupplierStatus.saving);
  SupplierState creating() => copyWith(status: SupplierStatus.creating);
  SupplierState updating() => copyWith(status: SupplierStatus.updating);
  SupplierState deleting() => copyWith(status: SupplierStatus.deleting);

  SupplierState successState(String message) => copyWith(
    status: SupplierStatus.success,
    message: message,
    errorMessage: '',
    validationError: null,
  );

  SupplierState failureState(String error) => copyWith(
    status: SupplierStatus.failure,
    errorMessage: error,
    message: '',
  );

  SupplierState validationErrorState(String error) =>
      copyWith(status: SupplierStatus.failure, validationError: error);

  SupplierState clearMessages() =>
      copyWith(message: '', errorMessage: '', validationError: null);

  // Getters for Java controller equivalents
  List<SupplierModel> get getItems => suppliers;
  List<SupplierModel> get getCreateItems => createItems;
  List<SupplierModel> get getEditItems => editItems;
  List<SupplierModel> get getFilteredValues => filteredSuppliers;
  List<SupplierModel> get getMultiselectionItems => multiSelectionItems;

  bool get isSelectionMode => selectedSuppliers.isNotEmpty;
  bool get canEdit => selectedSuppliers.length == 1;
  bool get canDelete => selectedSuppliers.isNotEmpty;
  bool get hasSelection => selected != null || selected1 != null;
  bool get hasCreateItems => createItems.isNotEmpty;
  bool get hasEditItems => editItems.isNotEmpty;

  @override
  List<Object?> get props => [
    status,
    suppliers,
    filteredSuppliers,
    createItems,
    editItems,
    multiSelectionItems,
    selectedSuppliers,
    selected,
    selected1,
    selected2,
    message,
    errorMessage,
    validationError,
    companyId,
    searchQuery,
    tinNumber,
    phoneNumber,
    country,
    showDetailPanel,
    supplierDetail,
    supplierForm,
    firstItemIndex,
    dataName,
    hasReachedMax,
  ];
}
