// features/sales/sales_order/coordinator/bloc/sales_order_coordinator_event.dart
import 'package:equatable/equatable.dart';
import 'package:savvy_stock/features/sales/customer/models/customer_model.dart';
import 'package:savvy_stock/features/sales/sales_order/header/model/sales_order_header.dart';
import 'package:savvy_stock/features/sales/sales_order/detail/model/sales_order_detail.dart';

// Base event
abstract class SalesOrderCoordinatorEvent extends Equatable {
  const SalesOrderCoordinatorEvent();

  @override
  List<Object?> get props => [];
}

// Order Lifecycle Events
class CreateCompleteSalesOrder extends SalesOrderCoordinatorEvent {
  final SalesOrderHeader header;
  final List<SalesOrderDetail> details;

  const CreateCompleteSalesOrder({required this.header, required this.details});

  @override
  List<Object?> get props => [header, details];
}

class UpdateCompleteSalesOrder extends SalesOrderCoordinatorEvent {
  final SalesOrderHeader header;
  final List<SalesOrderDetail> details;
  final bool validateStock;

  const UpdateCompleteSalesOrder({
    required this.header,
    required this.details,
    this.validateStock = true,
  });

  @override
  List<Object?> get props => [header, details, validateStock];
}

class VoidCompleteSalesOrder extends SalesOrderCoordinatorEvent {
  final int salesOrderId;
  final bool reverseStock;

  const VoidCompleteSalesOrder({
    required this.salesOrderId,
    this.reverseStock = true,
  });

  @override
  List<Object?> get props => [salesOrderId, reverseStock];
}

class DeleteCompleteSalesOrder extends SalesOrderCoordinatorEvent {
  final int salesOrderId;
  final bool reverseStock;

  const DeleteCompleteSalesOrder({
    required this.salesOrderId,
    this.reverseStock = true,
  });

  @override
  List<Object?> get props => [salesOrderId, reverseStock];
}

// Calculation & Validation Events
class CalculateCompleteOrderTotals extends SalesOrderCoordinatorEvent {
  final bool forceRecalculation;

  const CalculateCompleteOrderTotals({this.forceRecalculation = false});
}

class ValidateCompleteStockAvailability extends SalesOrderCoordinatorEvent {
  final bool validateAllItems;

  const ValidateCompleteStockAvailability({this.validateAllItems = true});
}

class SyncFinancialData extends SalesOrderCoordinatorEvent {
  final double? discountAmount;
  final bool? applyWithholding;

  const SyncFinancialData({this.discountAmount, this.applyWithholding});
}

// Financial Calculations & Payment Events
class UpdateTaxAndFees extends SalesOrderCoordinatorEvent {
  final double subtotal;
  final double discountAmount;
  final bool isWithholdingEnabled;

  const UpdateTaxAndFees({
    required this.subtotal,
    required this.discountAmount,
    required this.isWithholdingEnabled,
  });

  @override
  List<Object> get props => [subtotal, discountAmount, isWithholdingEnabled];
}

class ProcessPayment extends SalesOrderCoordinatorEvent {
  const ProcessPayment();

  @override
  List<Object> get props => [];
}

class UpdatePaymentDetails extends SalesOrderCoordinatorEvent {
  final String paymentType;
  final String paymentMethod;
  final String paymentInstrument;
  final String paymentTerm;

  const UpdatePaymentDetails({
    required this.paymentType,
    required this.paymentMethod,
    required this.paymentInstrument,
    required this.paymentTerm,
  });

  @override
  List<Object> get props => [
    paymentType,
    paymentMethod,
    paymentInstrument,
    paymentTerm,
  ];
}

class LoadFeeSystemConstants extends SalesOrderCoordinatorEvent {
  const LoadFeeSystemConstants();

  @override
  List<Object> get props => [];
}

// Customer & Header Synchronization
class SyncCustomerToOrder extends SalesOrderCoordinatorEvent {
  final Customer customer;

  const SyncCustomerToOrder({required this.customer});

  @override
  List<Object?> get props => [customer];
}

class SyncHeaderToDetails extends SalesOrderCoordinatorEvent {
  final SalesOrderHeader? header;

  const SyncHeaderToDetails({this.header});
}

// Preparation & Initialization
class PrepareNewSalesOrder extends SalesOrderCoordinatorEvent {
  final int companyId;
  final int branchId;
  final int employeeId;
  final Customer? defaultCustomer;

  const PrepareNewSalesOrder({
    required this.companyId,
    required this.branchId,
    required this.employeeId,
    this.defaultCustomer,
  });

  @override
  List<Object?> get props => [companyId, branchId, employeeId, defaultCustomer];
}

class LoadCompleteSalesOrder extends SalesOrderCoordinatorEvent {
  final int salesOrderId;

  const LoadCompleteSalesOrder({required this.salesOrderId});

  @override
  List<Object?> get props => [salesOrderId];
}

// Item & Detail Management
class AddDetailToOrder extends SalesOrderCoordinatorEvent {
  final SalesOrderDetail detail;

  const AddDetailToOrder({required this.detail});

  @override
  List<Object?> get props => [detail];
}

class UpdateDetailInOrder extends SalesOrderCoordinatorEvent {
  final SalesOrderDetail detail;
  final int index;

  const UpdateDetailInOrder({required this.detail, required this.index});

  @override
  List<Object?> get props => [detail, index];
}

class RemoveDetailFromOrder extends SalesOrderCoordinatorEvent {
  final SalesOrderDetail detail;

  const RemoveDetailFromOrder({required this.detail});

  @override
  List<Object?> get props => [detail];
}

class ClearOrderDetails extends SalesOrderCoordinatorEvent {}

// State Synchronization Events
class HeaderStateChanged extends SalesOrderCoordinatorEvent {
  final SalesOrderHeader? selectedHeader;
  final List<SalesOrderHeader> headers;
  final double? subTotal;
  final double? tax;
  final double? withholdAmount;
  final double? totalAmount;
  final double? discountAmount;
  final double? amountOpen;

  const HeaderStateChanged({
    this.selectedHeader,
    required this.headers,
    this.subTotal,
    this.tax,
    this.withholdAmount,
    this.totalAmount,
    this.discountAmount,
    this.amountOpen,
  });

  @override
  List<Object?> get props => [selectedHeader, headers];
}

class DetailStateChanged extends SalesOrderCoordinatorEvent {
  final List<SalesOrderDetail> currentDetails;
  final List<SalesOrderDetail> createItems;
  final List<SalesOrderDetail> editItems;
  final Map<int, StockValidationResult> stockValidationResults;

  const DetailStateChanged({
    required this.currentDetails,
    required this.createItems,
    required this.editItems,
    required this.stockValidationResults,
  });

  @override
  List<Object?> get props => [currentDetails, createItems, editItems];
}

// Utility Events
class ResetCoordinatorState extends SalesOrderCoordinatorEvent {}

class RetryFailedOperation extends SalesOrderCoordinatorEvent {
  final SalesOrderCoordinatorEvent failedEvent;

  const RetryFailedOperation({required this.failedEvent});

  @override
  List<Object?> get props => [failedEvent];
}

class GenerateInvoiceFromSalesOrder extends SalesOrderCoordinatorEvent {
  const GenerateInvoiceFromSalesOrder();

  @override
  List<Object> get props => [];
}
