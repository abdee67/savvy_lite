import 'package:equatable/equatable.dart';
import 'package:savvy_stock/features/sales/customer/models/customer_model.dart';
import 'package:savvy_stock/features/sales/sales_order/header/model/sales_order_header.dart';
import 'package:savvy_stock/features/sales/sales_order/detail/model/sales_order_detail.dart';
import 'package:savvy_stock/features/stock/item_in_branch/models/item_in_branch_model.dart';

// Base event class
abstract class SalesOrderCoordinatorEvent extends Equatable {
  const SalesOrderCoordinatorEvent();

  @override
  List<Object> get props => [];
}

// Create complete sales order with header and details
class CreateCompleteSalesOrder extends SalesOrderCoordinatorEvent {
  final SalesOrderHeader header;
  final List<SalesOrderDetail> details;

  const CreateCompleteSalesOrder({required this.header, required this.details});

  @override
  List<Object> get props => [header, details];
}

// Update existing sales order with details
class UpdateSalesOrderWithDetails extends SalesOrderCoordinatorEvent {
  final SalesOrderHeader header;
  final List<SalesOrderDetail> details;

  const UpdateSalesOrderWithDetails({
    required this.header,
    required this.details,
  });

  @override
  List<Object> get props => [header, details];
}

// Void sales order with all details
class VoidSalesOrderWithDetails extends SalesOrderCoordinatorEvent {
  final SalesOrderHeader header;

  const VoidSalesOrderWithDetails({required this.header});

  @override
  List<Object> get props => [header];
}

// Calculate complete totals for the entire order
class CalculateCompleteTotals extends SalesOrderCoordinatorEvent {
  const CalculateCompleteTotals();
}

// Sync customer information to all details
class SyncCustomerToDetails extends SalesOrderCoordinatorEvent {
  final Customer customer;

  const SyncCustomerToDetails({required this.customer});

  @override
  List<Object> get props => [customer];
}

// Sync header information to details
class SyncHeaderToDetails extends SalesOrderCoordinatorEvent {
  const SyncHeaderToDetails();
}

// Prepare new order by resetting both header and detail blocs
class PrepareNewOrder extends SalesOrderCoordinatorEvent {
  const PrepareNewOrder();
}

// Update unit price from item branch (replicates JSF's unitPriceSetBySelectedItemBranch)
class UpdateUnitPriceFromItemBranch extends SalesOrderCoordinatorEvent {
  final ItemInBranchModel itemBranch;
  final SalesOrderDetail detail;

  const UpdateUnitPriceFromItemBranch({
    required this.itemBranch,
    required this.detail,
  });

  @override
  List<Object> get props => [itemBranch, detail];
}

// Update header financial settings
class UpdateHeaderFinancials extends SalesOrderCoordinatorEvent {
  final bool applyWH;
  final double discountAmount;

  const UpdateHeaderFinancials({
    required this.applyWH,
    required this.discountAmount,
  });

  @override
  List<Object> get props => [applyWH, discountAmount];
}

// Update details list
class UpdateDetails extends SalesOrderCoordinatorEvent {
  final List<SalesOrderDetail> details;

  const UpdateDetails({required this.details});

  @override
  List<Object> get props => [details];
}

// Event for when header selection changes
class HeaderSelectionChanged extends SalesOrderCoordinatorEvent {
  final SalesOrderHeader? selectedHeader;

  const HeaderSelectionChanged({this.selectedHeader});

  @override
  List<Object> get props => [selectedHeader ?? ''];
}

// Event for when details change
class DetailsChanged extends SalesOrderCoordinatorEvent {
  final List<SalesOrderDetail> details;

  const DetailsChanged({required this.details});

  @override
  List<Object> get props => [details];
}

// Event to reverse stock on void (like Java's soVoid)
class ReverseStockOnVoidIntegration extends SalesOrderCoordinatorEvent {
  final SalesOrderHeader header;
  final int salesOrderId;
  final bool applyLotMgm;

  const ReverseStockOnVoidIntegration({
    required this.header,
    required this.salesOrderId,
    required this.applyLotMgm,
  });

  @override
  List<Object> get props => [salesOrderId, applyLotMgm];
}
