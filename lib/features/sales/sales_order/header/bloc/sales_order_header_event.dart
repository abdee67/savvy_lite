// bloc/sales_order_header_event.dart
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:savvy_stock/features/sales/sales_order/detail/model/sales_order_detail.dart';
import 'package:savvy_stock/features/sales/sales_order/header/model/credit_receipt_model.dart';
import 'package:savvy_stock/features/sales/sales_order/header/model/sales_order_header.dart';
import 'package:savvy_stock/features/sales/sales_order/header/model/sales_transaction_filtering_model.dart';
import 'package:savvy_stock/features/stock/lot_master/models/lot_master_model.dart';
import 'package:savvy_stock/features/system_constant/models/system_constant.dart';
import 'package:savvy_stock/features/sales/customer/models/customer_model.dart';

@immutable
abstract class SalesOrderHeaderEvent extends Equatable {
  const SalesOrderHeaderEvent();
}

class LoadSalesOrderHeaders extends SalesOrderHeaderEvent {
  final int companyId;

  const LoadSalesOrderHeaders({required this.companyId});
  @override
  List<Object?> get props => [companyId];
}

class SalesOrderHeaderInitialized extends SalesOrderHeaderEvent {
  final int companyId;
  final int employeeId;

  const SalesOrderHeaderInitialized({
    required this.companyId,
    required this.employeeId,
  });

  @override
  List<Object?> get props => [companyId, employeeId];
}

class LoadCreditSalesOrders extends SalesOrderHeaderEvent {
  final int companyId;

  const LoadCreditSalesOrders({required this.companyId});

  @override
  List<Object?> get props => [companyId];
}

class LoadVoidedSalesOrders extends SalesOrderHeaderEvent {
  final int companyId;
  final int customerBillTo;
  final String fsNumber;

  const LoadVoidedSalesOrders({
    required this.companyId,
    required this.customerBillTo,
    required this.fsNumber,
  });

  @override
  List<Object?> get props => [companyId, customerBillTo, fsNumber];
}

class CreateSalesOrderHeader extends SalesOrderHeaderEvent {
  final SalesOrderHeader header;

  const CreateSalesOrderHeader({required this.header});

  @override
  List<Object?> get props => [header];
}

class UpdateSalesOrderHeader extends SalesOrderHeaderEvent {
  final SalesOrderHeader header;

  const UpdateSalesOrderHeader({required this.header});
  @override
  List<Object?> get props => [header];
}

class DeleteSalesOrderHeader extends SalesOrderHeaderEvent {
  final int id;

  const DeleteSalesOrderHeader({required this.id});
  @override
  List<Object?> get props => [id];
}

class DeleteMultipleSalesOrders extends SalesOrderHeaderEvent {
  final List<SalesOrderHeader> headers;

  const DeleteMultipleSalesOrders({required this.headers});

  @override
  List<Object?> get props => [headers];
}

class PrepareCreateAfterCreate extends SalesOrderHeaderEvent {
  final int companyId;
  final int employeeId;

  const PrepareCreateAfterCreate({
    required this.companyId,
    required this.employeeId,
  });
  @override
  List<Object?> get props => [companyId, employeeId];
}

class PrepareEdit extends SalesOrderHeaderEvent {
  final int id;

  const PrepareEdit({required this.id});
  @override
  List<Object?> get props => [id];
}

class UnvoidSalesOrder extends SalesOrderHeaderEvent {
  final int id;

  const UnvoidSalesOrder({required this.id});
  @override
  List<Object?> get props => [id];
}

class SetDefaultCustomer extends SalesOrderHeaderEvent {
  final int companyId;

  const SetDefaultCustomer({required this.companyId});
  @override
  List<Object?> get props => [companyId];
}

class GenerateNextFsNumber extends SalesOrderHeaderEvent {
  final int companyId;
  final int branchId;

  const GenerateNextFsNumber({required this.companyId, required this.branchId});
  @override
  List<Object?> get props => [companyId, branchId];
}

class RefreshSalesOrderHeaders extends SalesOrderHeaderEvent {
  final int companyId;

  const RefreshSalesOrderHeaders({required this.companyId});
  @override
  List<Object?> get props => [companyId];
}

class VoidSalesOrder extends SalesOrderHeaderEvent {
  final int id;
  final String voidIndicator;

  const VoidSalesOrder({required this.id, required this.voidIndicator});
  @override
  List<Object?> get props => [id, voidIndicator];
}

class CalculateUomConversion extends SalesOrderHeaderEvent {
  final int itemId;
  final int fromUomId;
  final int toUomId;
  final double quantity;
  final int companyId;

  const CalculateUomConversion({
    required this.itemId,
    required this.fromUomId,
    required this.toUomId,
    required this.quantity,
    required this.companyId,
  });
  @override
  List<Object?> get props => [itemId, fromUomId, toUomId, quantity, companyId];
}

class ValidateStockForOrder extends SalesOrderHeaderEvent {
  final List<SalesOrderDetail> orderDetails;

  const ValidateStockForOrder({required this.orderDetails});
  @override
  List<Object?> get props => [orderDetails];
}

class CheckLotAvailability extends SalesOrderHeaderEvent {
  final double quantity;
  final LotMaster selectedLot;
  final List<SalesOrderDetail> orderDetail;
  final int itemId;
  final int branchId;

  const CheckLotAvailability({
    required this.quantity,
    required this.selectedLot,
    required this.orderDetail,
    required this.itemId,
    required this.branchId,
  });
  @override
  List<Object?> get props => [quantity, selectedLot, itemId, branchId];
}

class SystemConstantsUpdated extends SalesOrderHeaderEvent {
  final SystemConstant systemConstants;

  const SystemConstantsUpdated({required this.systemConstants});
  @override
  List<Object?> get props => [systemConstants];
}

class CalculateOrderTotals extends SalesOrderHeaderEvent {
  final SalesOrderHeader header;
  final List<SalesOrderDetail> orderDetails;
  final double discountAmount;
  final bool applyWithholding;
  final SystemConstant? systemConstants;

  const CalculateOrderTotals({
    required this.header,
    required this.orderDetails,
    required this.discountAmount,
    required this.applyWithholding,
    this.systemConstants,
  });
  @override
  List<Object?> get props => [
    header,
    orderDetails,
    applyWithholding,
    systemConstants,
  ];
}

class UpdateTaxSettings extends SalesOrderHeaderEvent {
  final SalesOrderHeader header;
  final bool applyWithholding;
  final double discountAmount;
  final SystemConstant systemConstants;

  const UpdateTaxSettings({
    required this.header,
    required this.applyWithholding,
    required this.discountAmount,
    required this.systemConstants,
  });

  @override
  List<Object?> get props => [
    header,
    applyWithholding,
    discountAmount,
    systemConstants,
  ];
}

class CalculateCreditDueDate extends SalesOrderHeaderEvent {
  final int? paymentTerm;
  final DateTime? orderDate;

  const CalculateCreditDueDate({this.paymentTerm, this.orderDate});

  @override
  List<Object?> get props => [paymentTerm, orderDate];
}

class GetNextOrderNumber extends SalesOrderHeaderEvent {
  final int companyId;

  const GetNextOrderNumber({required this.companyId});

  @override
  List<Object?> get props => [companyId];
}

class FilterSalesOrders extends SalesOrderHeaderEvent {
  final SalesOrderHeader filter;
  final DateTime? startDate;
  final DateTime? endDate;
  final int companyId;

  const FilterSalesOrders({
    required this.filter,
    this.startDate,
    this.endDate,
    required this.companyId,
  });
  @override
  List<Object?> get props => [filter, startDate, endDate, companyId];
}

class ClearFilters extends SalesOrderHeaderEvent {
  const ClearFilters();
  @override
  List<Object?> get props => [];
}

class SearchSalesOrders extends SalesOrderHeaderEvent {
  final String query;

  const SearchSalesOrders({required this.query});
  @override
  List<Object?> get props => [query];
}

class PrepareCreateSalesOrderHeader extends SalesOrderHeaderEvent {
  final int companyId;
  final int branchId;
  final int employeeId;

  const PrepareCreateSalesOrderHeader({
    required this.companyId,
    required this.branchId,
    required this.employeeId,
  });
  @override
  List<Object?> get props => [companyId, branchId, employeeId];
}

class RemoveSalesOrder extends SalesOrderHeaderEvent {
  final SalesOrderHeader header;

  const RemoveSalesOrder({required this.header});
  @override
  List<Object?> get props => [header];
}

class SaveSalesOrder extends SalesOrderHeaderEvent {
  final SalesOrderHeader header;
  final List<SalesOrderDetail> orderDetails;

  const SaveSalesOrder({required this.header, required this.orderDetails});
  @override
  List<Object?> get props => [header, orderDetails];
}

class UpdateCustomerInfo extends SalesOrderHeaderEvent {
  final Customer customer;
  final SalesOrderHeader? currentHeader;

  const UpdateCustomerInfo({required this.customer, this.currentHeader});
  @override
  List<Object?> get props => [customer, currentHeader];
}

class UpdatePaymentMethod extends SalesOrderHeaderEvent {
  final String paymentMethod;

  const UpdatePaymentMethod({required this.paymentMethod});
  @override
  List<Object?> get props => [paymentMethod];
}

class UpdatePaymentStatus extends SalesOrderHeaderEvent {
  final int paymentStatusId;

  const UpdatePaymentStatus({required this.paymentStatusId});
  @override
  List<Object?> get props => [paymentStatusId];
}

class SetPaymentTerm extends SalesOrderHeaderEvent {
  final int paymentTermId;

  const SetPaymentTerm({required this.paymentTermId});
  @override
  List<Object?> get props => [paymentTermId];
}

class ApplyWithholdingTax extends SalesOrderHeaderEvent {
  final bool applyWithholding;

  const ApplyWithholdingTax({required this.applyWithholding});
  @override
  List<Object?> get props => [applyWithholding];
}

class ApplyDiscount extends SalesOrderHeaderEvent {
  final double discountAmount;

  const ApplyDiscount({required this.discountAmount});
  @override
  List<Object?> get props => [discountAmount];
}

class UpdateDateFilters extends SalesOrderHeaderEvent {
  final DateTime? startDate;
  final DateTime? endDate;

  const UpdateDateFilters({this.startDate, this.endDate});

  @override
  List<Object?> get props => [startDate, endDate];
}

class FilterCreditSalesOrders extends SalesOrderHeaderEvent {
  final SalesOrderHeader filter;
  final DateTime? startDate;
  final DateTime? endDate;
  final int companyId;

  const FilterCreditSalesOrders({
    required this.filter,
    this.startDate,
    this.endDate,
    required this.companyId,
  });
  @override
  List<Object?> get props => [filter, startDate, endDate, companyId];
}

class FilterVoidedSalesOrders extends SalesOrderHeaderEvent {
  final SalesOrderHeader filter;
  final DateTime? startDate;
  final DateTime? endDate;
  final int companyId;

  const FilterVoidedSalesOrders({
    required this.filter,
    this.startDate,
    this.endDate,
    required this.companyId,
  });
  @override
  List<Object?> get props => [filter, startDate, endDate, companyId];
}

class CancelUpdate extends SalesOrderHeaderEvent {
  const CancelUpdate();
  @override
  List<Object?> get props => [];
}

class CancelCreate extends SalesOrderHeaderEvent {
  const CancelCreate();
  @override
  List<Object?> get props => [];
}

class DiscardChanges extends SalesOrderHeaderEvent {
  const DiscardChanges();
  @override
  List<Object?> get props => [];
}

class ConvertAmountToWords extends SalesOrderHeaderEvent {
  final double amount;

  const ConvertAmountToWords({required this.amount});

  @override
  List<Object?> get props => [amount];
}

// Selection events
class SelectSalesOrder extends SalesOrderHeaderEvent {
  final SalesOrderHeader header;

  const SelectSalesOrder({required this.header});
  @override
  List<Object?> get props => [header];
}

class SelectMultipleSalesOrders extends SalesOrderHeaderEvent {
  final List<SalesOrderHeader> headers;

  const SelectMultipleSalesOrders({required this.headers});
  @override
  List<Object?> get props => [headers];
}

class ClearSelection extends SalesOrderHeaderEvent {
  const ClearSelection();
  @override
  List<Object?> get props => [];
}

class ExportSaleOrder extends SalesOrderHeaderEvent {
  final SalesOrderHeader salesOrder;
  final String format;
  const ExportSaleOrder({required this.salesOrder, required this.format});
  @override
  List<Object?> get props => [salesOrder, format];
}

// Add to SalesOrderHeaderEvent class:

// Credit Receipt Events
class LoadCreditReceipts extends SalesOrderHeaderEvent {
  final int companyId;
  final int? soHeaderId;
  final DateTime? startDate;
  final DateTime? endDate;

  const LoadCreditReceipts({
    required this.companyId,
    this.soHeaderId,
    this.startDate,
    this.endDate,
  });
  @override
  List<Object?> get props => [companyId, soHeaderId, startDate, endDate];
}

class PrepareCreditReceipt extends SalesOrderHeaderEvent {
  final int soHeaderId;

  const PrepareCreditReceipt({required this.soHeaderId});
  @override
  List<Object?> get props => [soHeaderId];
}

class UpdateCreditReceipt extends SalesOrderHeaderEvent {
  final CreditReceipt receipt;

  const UpdateCreditReceipt({required this.receipt});
  @override
  List<Object?> get props => [receipt];
}

class SaveCreditReceipt extends SalesOrderHeaderEvent {
  final CreditReceipt receipt;
  final int companyId;

  const SaveCreditReceipt({required this.receipt, required this.companyId});
  @override
  List<Object?> get props => [receipt, companyId];
}

class DeleteCreditReceipt extends SalesOrderHeaderEvent {
  final int receiptId;

  const DeleteCreditReceipt({required this.receiptId});
  @override
  List<Object?> get props => [receiptId];
}

class SelectCreditReceipt extends SalesOrderHeaderEvent {
  final CreditReceipt receipt;

  const SelectCreditReceipt({required this.receipt});
  @override
  List<Object?> get props => [receipt];
}

class FilterCreditReceipts extends SalesOrderHeaderEvent {
  final int companyId;
  final int? customerId;
  final String? fsNumber;

  const FilterCreditReceipts({
    required this.companyId,
    this.customerId,
    this.fsNumber,
  });
  @override
  List<Object?> get props => [companyId, customerId, fsNumber];
}

class ClearCreditReceiptFilters extends SalesOrderHeaderEvent {
  const ClearCreditReceiptFilters();
  @override
  List<Object?> get props => [];
}

// ============================================================================
// SALES TRANSACTION REPORT EVENTS
// ============================================================================

class LoadSalesTransactionReport extends SalesOrderHeaderEvent {
  final int companyId;
  final int page;
  final int pageSize;
  final SalesTransactionReportFilters filters;

  const LoadSalesTransactionReport({
    required this.companyId,
    this.page = 1,
    this.pageSize = 25,
    this.filters = const SalesTransactionReportFilters(),
  });

  @override
  List<Object?> get props => [companyId, page, pageSize, filters];
}

class LoadMoreSalesTransactionReport extends SalesOrderHeaderEvent {
  const LoadMoreSalesTransactionReport();

  @override
  List<Object?> get props => [];
}

class UpdateSalesTransactionFilters extends SalesOrderHeaderEvent {
  final SalesTransactionReportFilters filters;

  const UpdateSalesTransactionFilters(this.filters);

  @override
  List<Object?> get props => [filters];
}

class ClearSalesTransactionFilters extends SalesOrderHeaderEvent {
  const ClearSalesTransactionFilters();

  @override
  List<Object?> get props => [];
}

class ExportSalesTransactionToExcel extends SalesOrderHeaderEvent {
  final SalesTransactionReportFilters filters;

  const ExportSalesTransactionToExcel(this.filters);

  @override
  List<Object?> get props => [filters];
}

class ExportSalesTransactionToPDF extends SalesOrderHeaderEvent {
  final SalesTransactionReportFilters filters;

  const ExportSalesTransactionToPDF(this.filters);

  @override
  List<Object?> get props => [filters];
}

// ============================================================================
// CREDIT RECEIPT REPORT EVENTS
// ============================================================================

class LoadCreditReceiptsReport extends SalesOrderHeaderEvent {
  final int companyId;
  final int page;
  final int pageSize;
  final SalesTransactionReportFilters filters;
  final String? sortBy;

  const LoadCreditReceiptsReport({
    required this.companyId,
    this.page = 1,
    this.pageSize = 25,
    this.filters = const SalesTransactionReportFilters(),
    this.sortBy,
  });

  @override
  List<Object?> get props => [companyId, page, pageSize, filters, sortBy];
}

class LoadMoreCreditReceiptsReport extends SalesOrderHeaderEvent {
  const LoadMoreCreditReceiptsReport();

  @override
  List<Object?> get props => [];
}

class UpdateCreditReceiptReportFilters extends SalesOrderHeaderEvent {
  final SalesTransactionReportFilters filters;

  const UpdateCreditReceiptReportFilters(this.filters);

  @override
  List<Object?> get props => [filters];
}

class ClearCreditReceiptsReportFilters extends SalesOrderHeaderEvent {
  const ClearCreditReceiptsReportFilters();

  @override
  List<Object?> get props => [];
}

class ExportCreditReceiptReportToExcel extends SalesOrderHeaderEvent {
  final SalesTransactionReportFilters filters;

  const ExportCreditReceiptReportToExcel(this.filters);

  @override
  List<Object?> get props => [filters];
}

class ExportCreditReceiptReportToPDF extends SalesOrderHeaderEvent {
  final SalesTransactionReportFilters filters;

  const ExportCreditReceiptReportToPDF(this.filters);

  @override
  List<Object?> get props => [filters];
}

// ============================================================================
// Aged Credit Receipt Report Events
// ============================================================================
class LoadAgedCreditReceiptReport extends SalesOrderHeaderEvent {
  final int companyId;
  final int page;
  final int pageSize;
  final SalesTransactionReportFilters filters;

  const LoadAgedCreditReceiptReport({
    required this.companyId,
    this.page = 1,
    this.pageSize = 25,
    this.filters = const SalesTransactionReportFilters(),
  });

  @override
  List<Object?> get props => [companyId, page, pageSize, filters];
}

class LoadMoreAgedCreditReceiptReport extends SalesOrderHeaderEvent {
  const LoadMoreAgedCreditReceiptReport();

  @override
  List<Object?> get props => [];
}

class UpdateAgedCreditReceiptReportFilters extends SalesOrderHeaderEvent {
  final SalesTransactionReportFilters filters;

  const UpdateAgedCreditReceiptReportFilters(this.filters);

  @override
  List<Object?> get props => [filters];
}

class ClearAgedCreditReceiptReportFilters extends SalesOrderHeaderEvent {
  const ClearAgedCreditReceiptReportFilters();

  @override
  List<Object?> get props => [];
}

class ExportAgedCreditReceiptReportToExcel extends SalesOrderHeaderEvent {
  final SalesTransactionReportFilters filters;

  const ExportAgedCreditReceiptReportToExcel(this.filters);

  @override
  List<Object?> get props => [filters];
}

class ExportAgedCreditReceiptReportToPDF extends SalesOrderHeaderEvent {
  final SalesTransactionReportFilters filters;

  const ExportAgedCreditReceiptReportToPDF(this.filters);

  @override
  List<Object?> get props => [filters];
}
