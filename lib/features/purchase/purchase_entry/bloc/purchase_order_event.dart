// features/purchase_order/bloc/purchase_order_event.dart
import 'package:equatable/equatable.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/models/credit_payment_model.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/models/purchase_order_detail_model.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/models/purchase_order_header_model.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/models/purchase_order_receiver_model.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/models/purchase_report_filter_model.dart';
import 'package:savvy_stock/features/system_constant/models/system_constant.dart';

abstract class PurchaseOrderEvent extends Equatable {
  const PurchaseOrderEvent();

  @override
  List<Object> get props => [];
}

// ============ INITIALIZATION & SYSTEM EVENTS ============
class PurchaseOrderInitialized extends PurchaseOrderEvent {
  final int companyId;
  final int? userId;
  const PurchaseOrderInitialized({required this.companyId, this.userId});

  @override
  List<Object> get props => [companyId];
}

class SystemConstantsUpdated extends PurchaseOrderEvent {
  final SystemConstant systemConstants;
  const SystemConstantsUpdated({required this.systemConstants});

  @override
  List<Object> get props => [systemConstants];
}

// ============ HEADER CRUD EVENTS ============
class LoadPurchaseOrders extends PurchaseOrderEvent {
  final int companyId;
  final bool? isCredit;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? purchaseType;
  const LoadPurchaseOrders({
    required this.companyId,
    this.isCredit,
    this.startDate,
    this.endDate,
    this.purchaseType,
  });

  @override
  List<Object> get props => [companyId];
}

class LoadPurchaseOrderCredit extends PurchaseOrderEvent {
  final int companyId;
  const LoadPurchaseOrderCredit({required this.companyId});

  @override
  List<Object> get props => [companyId];
}

class PrepareCreatePurchaseOrder extends PurchaseOrderEvent {
  final int companyId;
  final int? branchId;
  const PrepareCreatePurchaseOrder({required this.companyId, this.branchId});

  @override
  List<Object> get props => [companyId];
}

class PrepareEditPurchaseOrder extends PurchaseOrderEvent {
  const PrepareEditPurchaseOrder();
}

class PrepareCopyPurchaseOrder extends PurchaseOrderEvent {
  final int companyId;
  const PrepareCopyPurchaseOrder({required this.companyId});
}

class CreatePurchaseOrderHeader extends PurchaseOrderEvent {
  final PurchaseOrderHeader header;
  const CreatePurchaseOrderHeader({required this.header});

  @override
  List<Object> get props => [header];
}

class UpdatePurchaseOrderHeader extends PurchaseOrderEvent {
  final PurchaseOrderHeader header;
  const UpdatePurchaseOrderHeader({required this.header});

  @override
  List<Object> get props => [header];
}

class DeletePurchaseOrderHeader extends PurchaseOrderEvent {
  final int id;
  const DeletePurchaseOrderHeader({required this.id});

  @override
  List<Object> get props => [id];
}

class SavePurchaseOrder extends PurchaseOrderEvent {
  const SavePurchaseOrder();
}

class SavePurchaseOrderAndContinue extends PurchaseOrderEvent {
  const SavePurchaseOrderAndContinue();
}

class SavePurchaseOrderAndAddNew extends PurchaseOrderEvent {
  const SavePurchaseOrderAndAddNew();
}

class CancelPurchaseOrderUpdate extends PurchaseOrderEvent {
  const CancelPurchaseOrderUpdate();
}

class CancelPurchaseOrderCreate extends PurchaseOrderEvent {
  const CancelPurchaseOrderCreate();
}

class DiscardPurchaseOrderChanges extends PurchaseOrderEvent {
  const DiscardPurchaseOrderChanges();
}

// ============ DETAIL CRUD EVENTS ============
class LoadPurchaseOrderDetails extends PurchaseOrderEvent {
  final int headerId;
  final int companyId;
  const LoadPurchaseOrderDetails({
    required this.headerId,
    required this.companyId,
  });

  @override
  List<Object> get props => [headerId, companyId];
}

class AddPurchaseOrderDetail extends PurchaseOrderEvent {
  final PurchaseOrderDetail detail;
  const AddPurchaseOrderDetail({required this.detail});

  @override
  List<Object> get props => [detail];
}

class UpdatePurchaseOrderDetail extends PurchaseOrderEvent {
  final PurchaseOrderDetail detail;
  final int index;
  const UpdatePurchaseOrderDetail({required this.detail, required this.index});

  @override
  List<Object> get props => [detail, index];
}

class RemovePurchaseOrderDetail extends PurchaseOrderEvent {
  final PurchaseOrderDetail detail;
  const RemovePurchaseOrderDetail({required this.detail});

  @override
  List<Object> get props => [detail];
}

class RemovePurchaseOrderDetailInCreate extends PurchaseOrderEvent {
  final PurchaseOrderDetail detail;
  const RemovePurchaseOrderDetailInCreate({required this.detail});

  @override
  List<Object> get props => [detail];
}

class RemovePurchaseOrderDetailInEdit extends PurchaseOrderEvent {
  final PurchaseOrderDetail detail;
  const RemovePurchaseOrderDetailInEdit({required this.detail});

  @override
  List<Object> get props => [detail];
}

class SavePurchaseOrderRow extends PurchaseOrderEvent {
  const SavePurchaseOrderRow();
}

class SavePurchaseOrderRow1 extends PurchaseOrderEvent {
  final PurchaseOrderDetail detail;
  const SavePurchaseOrderRow1({required this.detail});

  @override
  List<Object> get props => [detail];
}

class CalculateExtendedCost extends PurchaseOrderEvent {
  final PurchaseOrderDetail detail;
  const CalculateExtendedCost({required this.detail});

  @override
  List<Object> get props => [detail];
}

class SetDefaultUomForDetail extends PurchaseOrderEvent {
  final PurchaseOrderDetail detail;
  const SetDefaultUomForDetail({required this.detail});

  @override
  List<Object> get props => [detail];
}

class SetDefaultSettingForAuto extends PurchaseOrderEvent {
  final PurchaseOrderDetail detail;
  const SetDefaultSettingForAuto({required this.detail});

  @override
  List<Object> get props => [detail];
}

class PrepareCopyPurchaseOrderDetail extends PurchaseOrderEvent {
  const PrepareCopyPurchaseOrderDetail();
}

// ============ RECEIVER CRUD EVENTS ============
class LoadPurchaseOrderReceivers extends PurchaseOrderEvent {
  final int headerId;
  final int companyId;
  const LoadPurchaseOrderReceivers({
    required this.headerId,
    required this.companyId,
  });

  @override
  List<Object> get props => [headerId, companyId];
}

class PreparePurchaseOrderReceipt extends PurchaseOrderEvent {
  final PurchaseOrderDetail? detail;
  const PreparePurchaseOrderReceipt({this.detail});
}

class PrepareAutoReceipt extends PurchaseOrderEvent {
  final List<PurchaseOrderDetail> details;
  const PrepareAutoReceipt({required this.details});

  @override
  List<Object> get props => [details];
}

class PreparePurchaseOrderReceiptForDetail extends PurchaseOrderEvent {
  final PurchaseOrderDetail detail;
  const PreparePurchaseOrderReceiptForDetail({required this.detail});

  @override
  List<Object> get props => [detail];
}

class AddPurchaseOrderReceiver extends PurchaseOrderEvent {
  final PurchaseOrderReceiver receiver;
  const AddPurchaseOrderReceiver({required this.receiver});

  @override
  List<Object> get props => [receiver];
}

class UpdatePurchaseOrderReceiver extends PurchaseOrderEvent {
  final PurchaseOrderReceiver receiver;
  final int index;
  const UpdatePurchaseOrderReceiver({
    required this.receiver,
    required this.index,
  });

  @override
  List<Object> get props => [receiver, index];
}

class SavePurchaseOrderReceipt extends PurchaseOrderEvent {
  const SavePurchaseOrderReceipt();
}

class SavePurchaseOrderReceiptInEdit extends PurchaseOrderEvent {
  const SavePurchaseOrderReceiptInEdit();
}

class ValidateReceiptQuantity extends PurchaseOrderEvent {
  final PurchaseOrderReceiver receiver;
  const ValidateReceiptQuantity({required this.receiver});

  @override
  List<Object> get props => [receiver];
}

class CheckReceiptValidity extends PurchaseOrderEvent {
  const CheckReceiptValidity();
}

// ============ FILTER & SEARCH EVENTS ============
class FilterPurchaseOrders extends PurchaseOrderEvent {
  final int? supplierId;
  final String? invoiceNumber;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? purchaseType;
  const FilterPurchaseOrders({
    this.supplierId,
    this.invoiceNumber,
    this.startDate,
    this.endDate,
    this.purchaseType,
  });
}

class FilterPurchaseOrderDetails extends PurchaseOrderEvent {
  final int? orderNumber;
  final int? supplierId;
  final int? itemNumber;
  final String? invoiceNumber;
  final DateTime? startDate;
  final DateTime? endDate;
  const FilterPurchaseOrderDetails({
    this.orderNumber,
    this.supplierId,
    this.itemNumber,
    this.invoiceNumber,
    this.startDate,
    this.endDate,
  });
}

class SearchPurchaseOrders extends PurchaseOrderEvent {
  final String query;
  const SearchPurchaseOrders({required this.query});

  @override
  List<Object> get props => [query];
}

class ClearPurchaseOrderFilters extends PurchaseOrderEvent {
  const ClearPurchaseOrderFilters();
}

// ============ FINANCIAL & CALCULATION EVENTS ============
class CalculatePurchaseOrderTotals extends PurchaseOrderEvent {
  const CalculatePurchaseOrderTotals();
}

class UpdateCreditDueDate extends PurchaseOrderEvent {
  final int? paymentTerm;
  final DateTime? transactionDate;
  const UpdateCreditDueDate({this.paymentTerm, this.transactionDate});
}

class CalculateTaxesAndFees extends PurchaseOrderEvent {
  const CalculateTaxesAndFees();
}

class UpdatePurchaseOrderAmounts extends PurchaseOrderEvent {
  const UpdatePurchaseOrderAmounts();
}

// ============ SELECTION & UI EVENTS ============
class SelectPurchaseOrder extends PurchaseOrderEvent {
  final PurchaseOrderHeader header;
  const SelectPurchaseOrder({required this.header});

  @override
  List<Object> get props => [header];
}

class SelectMultiplePurchaseOrders extends PurchaseOrderEvent {
  final List<PurchaseOrderHeader> headers;
  const SelectMultiplePurchaseOrders({required this.headers});

  @override
  List<Object> get props => [headers];
}

class ClearPurchaseOrderSelection extends PurchaseOrderEvent {
  const ClearPurchaseOrderSelection();
}

// ============ BATCH OPERATION EVENTS ============
class DeleteMultiplePurchaseOrders extends PurchaseOrderEvent {
  final List<PurchaseOrderHeader> headers;
  const DeleteMultiplePurchaseOrders({required this.headers});

  @override
  List<Object> get props => [headers];
}

class SaveMultiplePurchaseOrders extends PurchaseOrderEvent {
  final List<PurchaseOrderHeader> headers;
  const SaveMultiplePurchaseOrders({required this.headers});

  @override
  List<Object> get props => [headers];
}

class RemovePurchaseOrderRecord extends PurchaseOrderEvent {
  final PurchaseOrderDetail? detail;
  final PurchaseOrderReceiver? receiver;
  const RemovePurchaseOrderRecord({this.detail, this.receiver});
}

class RemovePurchaseOrderList extends PurchaseOrderEvent {
  final List<PurchaseOrderDetail>? details;
  final List<PurchaseOrderReceiver>? receivers;
  const RemovePurchaseOrderList({this.details, this.receivers});
}

// ============ UTILITY & OTHER EVENTS ============
class GenerateNextOrderNumber extends PurchaseOrderEvent {
  final int companyId;
  const GenerateNextOrderNumber({required this.companyId});

  @override
  List<Object> get props => [companyId];
}

class RefreshPurchaseOrders extends PurchaseOrderEvent {
  const RefreshPurchaseOrders();
}

class RefreshPurchaseOrderList extends PurchaseOrderEvent {
  const RefreshPurchaseOrderList();
}

class GetPurchaseOrderStatistics extends PurchaseOrderEvent {
  final DateTime startDate;
  final DateTime endDate;
  const GetPurchaseOrderStatistics({
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object> get props => [startDate, endDate];
}

class GetPurchaseOrderAgingReport extends PurchaseOrderEvent {
  final DateTime? asOfDate;
  const GetPurchaseOrderAgingReport({this.asOfDate});
}

class GetSupplierPurchaseSummary extends PurchaseOrderEvent {
  final DateTime startDate;
  final DateTime endDate;
  const GetSupplierPurchaseSummary({
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object> get props => [startDate, endDate];
}

class PrepareCreateInCreate extends PurchaseOrderEvent {
  const PrepareCreateInCreate();
}

class PrepareCreateInEdit extends PurchaseOrderEvent {
  const PrepareCreateInEdit();
}

// ============ SPECIALIZED BUSINESS LOGIC EVENTS ============
class CalculateDetailExtendedCost extends PurchaseOrderEvent {
  final PurchaseOrderDetail detail;
  const CalculateDetailExtendedCost({required this.detail});

  @override
  List<Object> get props => [detail];
}

class UpdateDetailReceiptStatus extends PurchaseOrderEvent {
  final int detailId;
  final String statusCode;
  const UpdateDetailReceiptStatus({
    required this.detailId,
    required this.statusCode,
  });

  @override
  List<Object> get props => [detailId, statusCode];
}

class UpdateHeaderReceiptStatus extends PurchaseOrderEvent {
  final int headerId;
  const UpdateHeaderReceiptStatus({required this.headerId});

  @override
  List<Object> get props => [headerId];
}

class UpdateItemCostsForHeader extends PurchaseOrderEvent {
  final int headerId;
  const UpdateItemCostsForHeader({required this.headerId});

  @override
  List<Object> get props => [headerId];
}

class UpdateStockItemAvailability extends PurchaseOrderEvent {
  final PurchaseOrderReceiver receiver;
  const UpdateStockItemAvailability({required this.receiver});

  @override
  List<Object> get props => [receiver];
}

class ValidateSupplierCredit extends PurchaseOrderEvent {
  final int supplierId;
  const ValidateSupplierCredit({required this.supplierId});

  @override
  List<Object> get props => [supplierId];
}

class CheckOrderNumberExists extends PurchaseOrderEvent {
  final int orderNumber;
  const CheckOrderNumberExists({required this.orderNumber});

  @override
  List<Object> get props => [orderNumber];
}

class ValidateReceiptDates extends PurchaseOrderEvent {
  final PurchaseOrderReceiver receiver;
  const ValidateReceiptDates({required this.receiver});

  @override
  List<Object> get props => [receiver];
}

class ProcessAutoReceiptForDetails extends PurchaseOrderEvent {
  final List<PurchaseOrderDetail> details;
  const ProcessAutoReceiptForDetails({required this.details});

  @override
  List<Object> get props => [details];
}

class UpdatePurchaseOrderDetailQuantities extends PurchaseOrderEvent {
  final int detailId;
  final double quantityReceived;
  const UpdatePurchaseOrderDetailQuantities({
    required this.detailId,
    required this.quantityReceived,
  });

  @override
  List<Object> get props => [detailId, quantityReceived];
}

class RecalculatePurchaseOrderTotals extends PurchaseOrderEvent {
  final int headerId;
  const RecalculatePurchaseOrderTotals({required this.headerId});

  @override
  List<Object> get props => [headerId];
}

class GetPurchaseOrderByNumberAndType extends PurchaseOrderEvent {
  final int orderNumber;
  final int orderTypeId;
  const GetPurchaseOrderByNumberAndType({
    required this.orderNumber,
    required this.orderTypeId,
  });

  @override
  List<Object> get props => [orderNumber, orderTypeId];
}

class GetOpenPurchaseOrderDetails extends PurchaseOrderEvent {
  final int? supplierId;
  final int? itemNumber;
  final DateTime? startDate;
  final DateTime? endDate;
  const GetOpenPurchaseOrderDetails({
    this.supplierId,
    this.itemNumber,
    this.startDate,
    this.endDate,
  });
}

class GetPurchaseOrderReceiversByItem extends PurchaseOrderEvent {
  final int itemNumber;
  final int detailId;
  const GetPurchaseOrderReceiversByItem({
    required this.itemNumber,
    required this.detailId,
  });

  @override
  List<Object> get props => [itemNumber, detailId];
}

class GetTotalReceivedQuantityByDetail extends PurchaseOrderEvent {
  final int detailId;
  const GetTotalReceivedQuantityByDetail({required this.detailId});

  @override
  List<Object> get props => [detailId];
}

class ExecuteCustomPurchaseOrderQuery extends PurchaseOrderEvent {
  final String query;
  final List<dynamic> params;
  const ExecuteCustomPurchaseOrderQuery({
    required this.query,
    required this.params,
  });

  @override
  List<Object> get props => [query];
}

class GetCustomPurchaseOrderQueryResults extends PurchaseOrderEvent {
  final String query;
  final List<dynamic> params;
  const GetCustomPurchaseOrderQueryResults({
    required this.query,
    required this.params,
  });

  @override
  List<Object> get props => [query];
}

class ClearAllPurchaseOrderData extends PurchaseOrderEvent {
  final int companyId;
  const ClearAllPurchaseOrderData({required this.companyId});

  @override
  List<Object> get props => [companyId];
}

// ============ UI STATE MANAGEMENT EVENTS ============
class SetPurchaseOrderAutoReceipt extends PurchaseOrderEvent {
  final bool autoReceipt;
  const SetPurchaseOrderAutoReceipt({required this.autoReceipt});

  @override
  List<Object> get props => [autoReceipt];
}

class SetPurchaseOrderDataFetchBy extends PurchaseOrderEvent {
  final String dataFetchBy;
  const SetPurchaseOrderDataFetchBy({required this.dataFetchBy});

  @override
  List<Object> get props => [dataFetchBy];
}

class SetPurchaseOrderReceivingDates extends PurchaseOrderEvent {
  final DateTime receivingDates;
  const SetPurchaseOrderReceivingDates({required this.receivingDates});

  @override
  List<Object> get props => [receivingDates];
}

class SetPurchaseOrderInvoiceNumber extends PurchaseOrderEvent {
  final String invoiceNumber;
  const SetPurchaseOrderInvoiceNumber({required this.invoiceNumber});

  @override
  List<Object> get props => [invoiceNumber];
}

class SetPurchaseOrderSupplierSelection extends PurchaseOrderEvent {
  final int supplierId;
  const SetPurchaseOrderSupplierSelection({required this.supplierId});

  @override
  List<Object> get props => [supplierId];
}

class SetPurchaseOrderItemSelection extends PurchaseOrderEvent {
  final int itemNumber;
  const SetPurchaseOrderItemSelection({required this.itemNumber});

  @override
  List<Object> get props => [itemNumber];
}

class SetPurchaseOrderBranchReceive extends PurchaseOrderEvent {
  final int branchReceive;
  const SetPurchaseOrderBranchReceive({required this.branchReceive});

  @override
  List<Object> get props => [branchReceive];
}

class SetPurchaseOrderItemLocationSelect extends PurchaseOrderEvent {
  final int itemLocationsSelect;
  const SetPurchaseOrderItemLocationSelect({required this.itemLocationsSelect});

  @override
  List<Object> get props => [itemLocationsSelect];
}

class SetPurchaseOrderPaymentType extends PurchaseOrderEvent {
  final String paymentType;
  const SetPurchaseOrderPaymentType({required this.paymentType});

  @override
  List<Object> get props => [paymentType];
}

class SetPurchaseOrderPurchaseType extends PurchaseOrderEvent {
  final String purchaseType;
  const SetPurchaseOrderPurchaseType({required this.purchaseType});

  @override
  List<Object> get props => [purchaseType];
}

// ============ NAVIGATION & FLOW EVENTS ============
class NavigateToPurchaseOrderCreate extends PurchaseOrderEvent {
  const NavigateToPurchaseOrderCreate();
}

class NavigateToPurchaseOrderEdit extends PurchaseOrderEvent {
  final PurchaseOrderHeader header;
  const NavigateToPurchaseOrderEdit({required this.header});

  @override
  List<Object> get props => [header];
}

class NavigateToPurchaseOrderReceipt extends PurchaseOrderEvent {
  final PurchaseOrderDetail detail;
  const NavigateToPurchaseOrderReceipt({required this.detail});

  @override
  List<Object> get props => [detail];
}

class NavigateBackFromPurchaseOrder extends PurchaseOrderEvent {
  const NavigateBackFromPurchaseOrder();
}

class CompletePurchaseOrderWorkflow extends PurchaseOrderEvent {
  const CompletePurchaseOrderWorkflow();
}

// ============ IMPORT/EXPORT EVENTS ============
class ImportPurchaseOrdersFromCSV extends PurchaseOrderEvent {
  final String csvData;
  const ImportPurchaseOrdersFromCSV({required this.csvData});

  @override
  List<Object> get props => [csvData];
}

class ExportPurchaseOrdersToCSV extends PurchaseOrderEvent {
  final List<PurchaseOrderHeader> headers;
  const ExportPurchaseOrdersToCSV({required this.headers});

  @override
  List<Object> get props => [headers];
}

class GeneratePurchaseOrderReport extends PurchaseOrderEvent {
  final DateTime startDate;
  final DateTime endDate;
  final String reportType;
  const GeneratePurchaseOrderReport({
    required this.startDate,
    required this.endDate,
    required this.reportType,
  });

  @override
  List<Object> get props => [startDate, endDate, reportType];
}

// ============ SYNC & CLOUD EVENTS ============
class SyncPurchaseOrdersToCloud extends PurchaseOrderEvent {
  const SyncPurchaseOrdersToCloud();
}

class DownloadPurchaseOrdersFromCloud extends PurchaseOrderEvent {
  const DownloadPurchaseOrdersFromCloud();
}

class ClearLocalPurchaseOrderCache extends PurchaseOrderEvent {
  const ClearLocalPurchaseOrderCache();
}

// ============ VALIDATION EVENTS ============
class ValidatePurchaseOrderHeader extends PurchaseOrderEvent {
  final PurchaseOrderHeader header;
  const ValidatePurchaseOrderHeader({required this.header});

  @override
  List<Object> get props => [header];
}

class ValidatePurchaseOrderDetail extends PurchaseOrderEvent {
  final PurchaseOrderDetail detail;
  const ValidatePurchaseOrderDetail({required this.detail});

  @override
  List<Object> get props => [detail];
}

class ValidatePurchaseOrderReceiver extends PurchaseOrderEvent {
  final PurchaseOrderReceiver receiver;
  const ValidatePurchaseOrderReceiver({required this.receiver});

  @override
  List<Object> get props => [receiver];
}

class CheckPurchaseOrderBusinessRules extends PurchaseOrderEvent {
  final PurchaseOrderHeader header;
  final List<PurchaseOrderDetail> details;
  const CheckPurchaseOrderBusinessRules({
    required this.header,
    required this.details,
  });

  @override
  List<Object> get props => [header];
}

// ============ ERROR HANDLING EVENTS ============
class HandlePurchaseOrderError extends PurchaseOrderEvent {
  final String error;
  final String operation;
  const HandlePurchaseOrderError({
    required this.error,
    required this.operation,
  });

  @override
  List<Object> get props => [error, operation];
}

class ClearPurchaseOrderError extends PurchaseOrderEvent {
  const ClearPurchaseOrderError();
}

class ClearPurchaseOrderSuccessMessage extends PurchaseOrderEvent {
  const ClearPurchaseOrderSuccessMessage();
}

// ============ AUDIT & LOGGING EVENTS ============
class LogPurchaseOrderOperation extends PurchaseOrderEvent {
  final String operation;
  final String details;
  const LogPurchaseOrderOperation({
    required this.operation,
    required this.details,
  });

  @override
  List<Object> get props => [operation, details];
}

class GetPurchaseOrderAuditLog extends PurchaseOrderEvent {
  final int headerId;
  const GetPurchaseOrderAuditLog({required this.headerId});

  @override
  List<Object> get props => [headerId];
}

// ============ BULK UPDATE EVENTS ============
class BulkUpdatePurchaseOrderStatus extends PurchaseOrderEvent {
  final List<int> headerIds;
  final String status;
  const BulkUpdatePurchaseOrderStatus({
    required this.headerIds,
    required this.status,
  });

  @override
  List<Object> get props => [headerIds, status];
}

class BulkUpdatePurchaseOrderDetails extends PurchaseOrderEvent {
  final List<PurchaseOrderDetail> details;
  final Map<String, dynamic> updates;
  const BulkUpdatePurchaseOrderDetails({
    required this.details,
    required this.updates,
  });

  @override
  List<Object> get props => [details];
}

class BulkCreatePurchaseOrderReceivers extends PurchaseOrderEvent {
  final List<PurchaseOrderReceiver> receivers;
  const BulkCreatePurchaseOrderReceivers({required this.receivers});

  @override
  List<Object> get props => [receivers];
}

// ============ TEMPLATE EVENTS ============
class SavePurchaseOrderAsTemplate extends PurchaseOrderEvent {
  final PurchaseOrderHeader header;
  final String templateName;
  const SavePurchaseOrderAsTemplate({
    required this.header,
    required this.templateName,
  });

  @override
  List<Object> get props => [header, templateName];
}

class LoadPurchaseOrderTemplate extends PurchaseOrderEvent {
  final String templateName;
  const LoadPurchaseOrderTemplate({required this.templateName});

  @override
  List<Object> get props => [templateName];
}

class DeletePurchaseOrderTemplate extends PurchaseOrderEvent {
  final String templateName;
  const DeletePurchaseOrderTemplate({required this.templateName});

  @override
  List<Object> get props => [templateName];
}

// ============ SETTINGS & CONFIGURATION EVENTS ============
class UpdatePurchaseOrderSettings extends PurchaseOrderEvent {
  final Map<String, dynamic> settings;
  const UpdatePurchaseOrderSettings({required this.settings});

  @override
  List<Object> get props => [settings];
}

class LoadPurchaseOrderSettings extends PurchaseOrderEvent {
  const LoadPurchaseOrderSettings();
}

class ResetPurchaseOrderSettings extends PurchaseOrderEvent {
  const ResetPurchaseOrderSettings();
}

// ============ HELP & SUPPORT EVENTS ============
class ShowPurchaseOrderHelp extends PurchaseOrderEvent {
  final String topic;
  const ShowPurchaseOrderHelp({required this.topic});

  @override
  List<Object> get props => [topic];
}

class GeneratePurchaseOrderDocumentation extends PurchaseOrderEvent {
  const GeneratePurchaseOrderDocumentation();
}

class ReportPurchaseOrderBug extends PurchaseOrderEvent {
  final String description;
  final String stepsToReproduce;
  const ReportPurchaseOrderBug({
    required this.description,
    required this.stepsToReproduce,
  });

  @override
  List<Object> get props => [description, stepsToReproduce];
}

// ============ MISC UTILITY EVENTS ============
class DuplicatePurchaseOrder extends PurchaseOrderEvent {
  final PurchaseOrderHeader header;
  const DuplicatePurchaseOrder({required this.header});

  @override
  List<Object> get props => [header];
}

class MergePurchaseOrders extends PurchaseOrderEvent {
  final List<PurchaseOrderHeader> headers;
  const MergePurchaseOrders({required this.headers});

  @override
  List<Object> get props => [headers];
}

class SplitPurchaseOrderDetail extends PurchaseOrderEvent {
  final PurchaseOrderDetail detail;
  final int splitCount;
  const SplitPurchaseOrderDetail({
    required this.detail,
    required this.splitCount,
  });

  @override
  List<Object> get props => [detail, splitCount];
}

class ConvertPurchaseOrderToInvoice extends PurchaseOrderEvent {
  final PurchaseOrderHeader header;
  const ConvertPurchaseOrderToInvoice({required this.header});

  @override
  List<Object> get props => [header];
}

class LinkPurchaseOrderToPayment extends PurchaseOrderEvent {
  final int headerId;
  final int paymentId;
  const LinkPurchaseOrderToPayment({
    required this.headerId,
    required this.paymentId,
  });

  @override
  List<Object> get props => [headerId, paymentId];
}

// ============ NOTIFICATION EVENTS ============
class SendPurchaseOrderNotification extends PurchaseOrderEvent {
  final PurchaseOrderHeader header;
  final String notificationType;
  const SendPurchaseOrderNotification({
    required this.header,
    required this.notificationType,
  });

  @override
  List<Object> get props => [header, notificationType];
}

class GetPurchaseOrderNotifications extends PurchaseOrderEvent {
  const GetPurchaseOrderNotifications();
}

class MarkPurchaseOrderNotificationAsRead extends PurchaseOrderEvent {
  final String notificationId;
  const MarkPurchaseOrderNotificationAsRead({required this.notificationId});

  @override
  List<Object> get props => [notificationId];
}

// ============ DEBUG & TESTING EVENTS ============
class DebugPurchaseOrderState extends PurchaseOrderEvent {
  const DebugPurchaseOrderState();
}

class TestPurchaseOrderBusinessLogic extends PurchaseOrderEvent {
  final Map<String, dynamic> testData;
  const TestPurchaseOrderBusinessLogic({required this.testData});

  @override
  List<Object> get props => [testData];
}

class SimulatePurchaseOrderError extends PurchaseOrderEvent {
  final String errorType;
  const SimulatePurchaseOrderError({required this.errorType});

  @override
  List<Object> get props => [errorType];
}

class LoadCreditPayments extends PurchaseOrderEvent {
  final int companyId;
  final int? poHeaderId;
  final DateTime? startDate;
  final DateTime? endDate;

  const LoadCreditPayments({
    required this.companyId,
    this.poHeaderId,
    this.startDate,
    this.endDate,
  });
}

class PrepareCreditPayment extends PurchaseOrderEvent {
  final int poHeaderId;

  const PrepareCreditPayment({required this.poHeaderId});
}

class UpdateCreditPayment extends PurchaseOrderEvent {
  final CreditPayment payment;

  const UpdateCreditPayment({required this.payment});
}

class SaveCreditPayment extends PurchaseOrderEvent {
  final CreditPayment payment;
  final int companyId;

  const SaveCreditPayment({required this.payment, required this.companyId});
}

class DeleteCreditPayment extends PurchaseOrderEvent {
  final int paymentId;

  const DeleteCreditPayment({required this.paymentId});
}

class SelectCreditPayment extends PurchaseOrderEvent {
  final CreditPayment payment;

  const SelectCreditPayment({required this.payment});
}

class FilterCreditPayments extends PurchaseOrderEvent {
  final int companyId;
  final int? supplierId;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? referenceNumber;

  const FilterCreditPayments({
    required this.companyId,
    this.supplierId,
    this.startDate,
    this.endDate,
    this.referenceNumber,
  });
}
// ============================================================================
// PURCHASE ORDER REPORT EVENTS
// ============================================================================

class LoadPurchaseTransactionReport extends PurchaseOrderEvent {
  final int companyId;
  final int page;
  final int pageSize;
  final PurchaseReportFilters filters;

  const LoadPurchaseTransactionReport({
    required this.companyId,
    this.page = 1,
    this.pageSize = 25,
    this.filters = const PurchaseReportFilters(),
  });
}

class LoadMorePurchaseTransactionReport extends PurchaseOrderEvent {
  const LoadMorePurchaseTransactionReport();
}

class UpdatePurchaseTransactionReportFilters extends PurchaseOrderEvent {
  final PurchaseReportFilters filters;

  const UpdatePurchaseTransactionReportFilters(this.filters);
}

class ClearPurchaseTransactionReportFilters extends PurchaseOrderEvent {
  const ClearPurchaseTransactionReportFilters();
}

class ExportPurchaseTransactionReportToExcel extends PurchaseOrderEvent {
  final PurchaseReportFilters filters;

  const ExportPurchaseTransactionReportToExcel(this.filters);
}

class ExportPurchaseTransactionReportToPDF extends PurchaseOrderEvent {
  final PurchaseReportFilters filters;

  const ExportPurchaseTransactionReportToPDF(this.filters);
}
// ============================================================================
// GRN REPORT EVENTS
// ============================================================================

class LoadGRNReport extends PurchaseOrderEvent {
  final int companyId;
  final int page;
  final int pageSize;
  final PurchaseReportFilters filters;

  const LoadGRNReport({
    required this.companyId,
    this.page = 1,
    this.pageSize = 25,
    this.filters = const PurchaseReportFilters(),
  });
}

class LoadMoreGRNReport extends PurchaseOrderEvent {
  const LoadMoreGRNReport();
}

class UpdateGRNReportFilters extends PurchaseOrderEvent {
  final PurchaseReportFilters filters;

  const UpdateGRNReportFilters(this.filters);
}

class ClearGRNReportFilters extends PurchaseOrderEvent {
  const ClearGRNReportFilters();
}

class ExportGRNReportToExcel extends PurchaseOrderEvent {
  final PurchaseReportFilters filters;

  const ExportGRNReportToExcel(this.filters);
}

class ExportGRNReportToPDF extends PurchaseOrderEvent {
  final PurchaseReportFilters filters;

  const ExportGRNReportToPDF(this.filters);
}
// ============================================================================
// PENDING PURCHASE REPORT EVENTS
// ============================================================================

class LoadPendingPurchaseReport extends PurchaseOrderEvent {
  final int companyId;
  final int page;
  final int pageSize;
  final PurchaseReportFilters filters;

  const LoadPendingPurchaseReport({
    required this.companyId,
    this.page = 1,
    this.pageSize = 25,
    this.filters = const PurchaseReportFilters(),
  });
}

class LoadMorePendingPurchaseReport extends PurchaseOrderEvent {
  const LoadMorePendingPurchaseReport();
}

class UpdatePendingPurchaseReportFilters extends PurchaseOrderEvent {
  final PurchaseReportFilters filters;

  const UpdatePendingPurchaseReportFilters(this.filters);
}

class ClearPendingPurchaseReportFilters extends PurchaseOrderEvent {
  const ClearPendingPurchaseReportFilters();
}

class ExportPendingPurchaseReportToExcel extends PurchaseOrderEvent {
  final PurchaseReportFilters filters;

  const ExportPendingPurchaseReportToExcel(this.filters);
}

class ExportPendingPurchaseReportToPDF extends PurchaseOrderEvent {
  final PurchaseReportFilters filters;

  const ExportPendingPurchaseReportToPDF(this.filters);
}

// ============================================================================
// CREDIT PAYMENT REPORT EVENTS
// ============================================================================

class LoadCreditPaymentReport extends PurchaseOrderEvent {
  final int companyId;
  final int page;
  final int pageSize;
  final PurchaseReportFilters filters;
  final String? sortBy;

  const LoadCreditPaymentReport({
    required this.companyId,
    this.page = 1,
    this.pageSize = 25,
    this.filters = const PurchaseReportFilters(),
    this.sortBy,
  });
}

class LoadMoreCreditPaymentReport extends PurchaseOrderEvent {
  const LoadMoreCreditPaymentReport();
}

class UpdateCreditPaymentReportFilters extends PurchaseOrderEvent {
  final PurchaseReportFilters filters;

  const UpdateCreditPaymentReportFilters(this.filters);
}

class ClearCreditPaymentReportFilters extends PurchaseOrderEvent {
  const ClearCreditPaymentReportFilters();
}

class ExportCreditPaymentReportToExcel extends PurchaseOrderEvent {
  final PurchaseReportFilters filters;

  const ExportCreditPaymentReportToExcel(this.filters);
}

class ExportCreditPaymentReportToPDF extends PurchaseOrderEvent {
  final PurchaseReportFilters filters;

  const ExportCreditPaymentReportToPDF(this.filters);
}

// ============================================================================
// Aged Credit Payment Report Events
// ============================================================================
class LoadAgedCreditPaymentReport extends PurchaseOrderEvent {
  final int companyId;
  final int page;
  final int pageSize;
  final PurchaseReportFilters filters;

  const LoadAgedCreditPaymentReport({
    required this.companyId,
    this.page = 1,
    this.pageSize = 25,
    this.filters = const PurchaseReportFilters(),
  });
}

class LoadMoreAgedCreditPaymentReport extends PurchaseOrderEvent {
  const LoadMoreAgedCreditPaymentReport();
}

class UpdateAgedCreditPaymentReportFilters extends PurchaseOrderEvent {
  final PurchaseReportFilters filters;

  const UpdateAgedCreditPaymentReportFilters(this.filters);
}

class ClearAgedCreditPaymentReportFilters extends PurchaseOrderEvent {
  const ClearAgedCreditPaymentReportFilters();
}

class ExportAgedCreditPaymentReportToExcel extends PurchaseOrderEvent {
  final PurchaseReportFilters filters;

  const ExportAgedCreditPaymentReportToExcel(this.filters);
}

class ExportAgedCreditPaymentReportToPDF extends PurchaseOrderEvent {
  final PurchaseReportFilters filters;

  const ExportAgedCreditPaymentReportToPDF(this.filters);
}
