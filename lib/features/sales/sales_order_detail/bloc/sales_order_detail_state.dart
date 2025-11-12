// features/sales/sales_order_details/blocs/sales_order_details_state.dart

import 'package:savvy_stock/features/sales/sales_order_detail/model/sales_order_detail.dart';
import 'package:savvy_stock/features/system_constant/models/system_constant.dart';

enum SalesOrderDetailStatus {
  initial,
  loading,
  processing,
  loaded,
  creating,
  updating,
  deleting,
  success,
  failure,
  saving,
  validatingStock,
}

class SalesOrderDetailState {
  final SalesOrderDetailStatus status;
  final List<SalesOrderDetail> items;
  final List<SalesOrderDetail> multiselectionItems;
  final List<SalesOrderDetail> createItems;
  final List<SalesOrderDetail> editItems;
  final List<SalesOrderDetail> filteredValues;
  final SalesOrderDetail? selected;
  final SalesOrderDetail? selected1;
  final SalesOrderDetail? selected2;
  final String dataName;
  final int first;
  final bool useBarcode;
  final String barCode;
  final Map<int, double> availableValidator; // Using item_in_branch id as key
  final Map<int, double> availableValidatorDouble;
  final String? errorMessage;
  final String? successMessage;
  final int? companyId;
  final bool enablePreview;
  final bool enableFinishingProcess;
  final String? availablitySelections;
  final Map<int, StockValidationResult> stockValidationResults;
  final SystemConstant? systemConstant;

  const SalesOrderDetailState({
    this.status = SalesOrderDetailStatus.initial,
    this.items = const [],
    this.multiselectionItems = const [],
    this.createItems = const [],
    this.editItems = const [],
    this.filteredValues = const [],
    this.selected,
    this.selected1,
    this.selected2,
    this.dataName = 'com.stock.entitySalesOrderDetail',
    this.first = 0,
    this.useBarcode = false,
    this.barCode = '',
    this.availableValidator = const {},
    this.availableValidatorDouble = const {},
    this.errorMessage,
    this.successMessage,
    this.companyId,
    this.enablePreview = false,
    this.enableFinishingProcess = false,
    this.availablitySelections,
    this.stockValidationResults = const {},
    this.systemConstant,
  });

  SalesOrderDetailState copyWith({
    SalesOrderDetailStatus? status,
    List<SalesOrderDetail>? items,
    List<SalesOrderDetail>? multiselectionItems,
    List<SalesOrderDetail>? createItems,
    List<SalesOrderDetail>? editItems,
    List<SalesOrderDetail>? filteredValues,
    SalesOrderDetail? selected,
    SalesOrderDetail? selected1,
    SalesOrderDetail? selected2,
    String? dataName,
    int? first,
    bool? useBarcode,
    String? barCode,
    Map<int, double>? availableValidator,
    Map<int, double>? availableValidatorDouble,
    String? errorMessage,
    String? successMessage,
    int? companyId,
    bool? enablePreview,
    bool? enableFinishingProcess,
    String? availablitySelections,
    Map<int, StockValidationResult>? stockValidationResults,
    SystemConstant? systemConstant,
  }) {
    return SalesOrderDetailState(
      status: status ?? this.status,
      items: items ?? this.items,
      multiselectionItems: multiselectionItems ?? this.multiselectionItems,
      createItems: createItems ?? this.createItems,
      editItems: editItems ?? this.editItems,
      filteredValues: filteredValues ?? this.filteredValues,
      selected: selected ?? this.selected,
      selected1: selected1 ?? this.selected1,
      selected2: selected2 ?? this.selected2,
      dataName: dataName ?? this.dataName,
      first: first ?? this.first,
      useBarcode: useBarcode ?? this.useBarcode,
      barCode: barCode ?? this.barCode,
      availableValidator: availableValidator ?? this.availableValidator,
      availableValidatorDouble:
          availableValidatorDouble ?? this.availableValidatorDouble,
      errorMessage: errorMessage ?? this.errorMessage,
      successMessage: successMessage ?? this.successMessage,
      companyId: companyId ?? this.companyId,
      enablePreview: enablePreview ?? this.enablePreview,
      enableFinishingProcess:
          enableFinishingProcess ?? this.enableFinishingProcess,
      availablitySelections:
          availablitySelections ?? this.availablitySelections,
      stockValidationResults:
          stockValidationResults ?? this.stockValidationResults,
      systemConstant: systemConstant ?? this.systemConstant,
    );
  }

  double get createItemsSubtotal {
    return createItems.fold(
      0.0,
      (sum, item) => sum + (item.extendedPrice ?? 0),
    );
  }

  bool get hasCreateItems => createItems.isNotEmpty;
  bool get hasEditItems => editItems.isNotEmpty;
  bool get hasMultiSelection => multiselectionItems.isNotEmpty;
  bool get canSave => createItems.every((item) => item.isValid);
  bool get canConfirm => enablePreview && createItems.isNotEmpty;
}
