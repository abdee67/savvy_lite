// bloc/sales_order_details/sales_order_details_state.dart
import 'package:flutter/foundation.dart';
import 'package:savvy_stock/features/stock/item_in_branch/models/item_in_branch_model.dart';
import 'package:savvy_stock/features/stock/sales_order_detail/model/sales_order_detail.dart';
@immutable
abstract class SalesOrderDetailState {
  const SalesOrderDetailState();
}

class SalesOrderDetailInitial extends SalesOrderDetailState {}

class SalesOrderDetailLoading extends SalesOrderDetailState {}

class SalesOrderDetailLoadSuccess extends SalesOrderDetailState {
  final List<SalesOrderDetail> items;
  final List<SalesOrderDetail> createItems;
  final List<SalesOrderDetail> editItems;
  final List<SalesOrderDetail> multiSelectionItems;
  final List<SalesOrderDetail> filteredValues;
  final SalesOrderDetail? selected;
  final SalesOrderDetail? selected1;
  final SalesOrderDetail selected2;
  final Map<ItemInBranchModel, double> availableValidator;
  final bool enablePreview;
  final bool enableFinishingProcess;
  final String? barcode;
  final bool useBarcode;

  const SalesOrderDetailLoadSuccess({
    required this.items,
    required this.createItems,
    required this.editItems,
    required this.multiSelectionItems,
    required this.filteredValues,
    this.selected,
    this.selected1,
    required this.selected2,
    required this.availableValidator,
    required this.enablePreview,
    required this.enableFinishingProcess,
    this.barcode,
    required this.useBarcode,
  });

  SalesOrderDetailLoadSuccess copyWith({
    List<SalesOrderDetail>? items,
    List<SalesOrderDetail>? createItems,
    List<SalesOrderDetail>? editItems,
    List<SalesOrderDetail>? multiSelectionItems,
    List<SalesOrderDetail>? filteredValues,
    SalesOrderDetail? selected,
    SalesOrderDetail? selected1,
    SalesOrderDetail? selected2,
    Map<ItemInBranchModel, double>? availableValidator,
    bool? enablePreview,
    bool? enableFinishingProcess,
    String? barcode,
    bool? useBarcode,
  }) {
    return SalesOrderDetailLoadSuccess(
      items: items ?? this.items,
      createItems: createItems ?? this.createItems,
      editItems: editItems ?? this.editItems,
      multiSelectionItems: multiSelectionItems ?? this.multiSelectionItems,
      filteredValues: filteredValues ?? this.filteredValues,
      selected: selected ?? this.selected,
      selected1: selected1 ?? this.selected1,
      selected2: selected2 ?? this.selected2,
      availableValidator: availableValidator ?? this.availableValidator,
      enablePreview: enablePreview ?? this.enablePreview,
      enableFinishingProcess: enableFinishingProcess ?? this.enableFinishingProcess,
      barcode: barcode ?? this.barcode,
      useBarcode: useBarcode ?? this.useBarcode,
    );
  }
}

class SalesOrderDetailOperationSuccess extends SalesOrderDetailState {
  final String message;
  final List<SalesOrderDetail> items;
  final List<SalesOrderDetail> createItems;

  const SalesOrderDetailOperationSuccess({
    required this.message,
    required this.items,
    required this.createItems,
  });
}

class SalesOrderDetailError extends SalesOrderDetailState {
  final String error;

  const SalesOrderDetailError(this.error);
}

class SalesOrderDetailValidationError extends SalesOrderDetailState {
  final String error;
  final List<SalesOrderDetail> createItems;
  final Map<ItemInBranchModel, double> availableValidator;

  const SalesOrderDetailValidationError({
    required this.error,
    required this.createItems,
    required this.availableValidator,
  });
}

/*class SalesOrderDetailInvoicePrepared extends SalesOrderDetailState {
  final InvoiceHistoryHeader invoiceHeader;
  final List<InvoiceHistoryDetail> invoiceDetails;
  final bool enableFinishingProcess;

  const SalesOrderDetailInvoicePrepared({
    required this.invoiceHeader,
    required this.invoiceDetails,
    required this.enableFinishingProcess,
  }); 
}*/

/*class SalesOrderDetailReportGenerated extends SalesOrderDetailState {
  final InvoiceHistoryHeader? invoiceHeader;
  final List<InvoiceHistoryDetail> invoiceDetails;

  const SalesOrderDetailReportGenerated({
    this.invoiceHeader,
    required this.invoiceDetails,
  });
} */

class SalesOrderDetailAvailabilityValidated extends SalesOrderDetailState {
  final Map<ItemInBranchModel, double> availableValidator;

  const SalesOrderDetailAvailabilityValidated(this.availableValidator);
}