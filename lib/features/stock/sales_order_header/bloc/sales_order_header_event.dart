// bloc/sales_order_header_event.dart
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:savvy_stock/features/system_constant/models/system_constant.dart';
import 'package:savvy_stock/features/sales/customer/models/customer_model.dart';
import 'package:savvy_stock/features/stock/sales_order_detail/model/sales_order_detail.dart';
import 'package:savvy_stock/features/stock/sales_order_header/model/sales_order_header.dart';

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

class LoadCreditSalesOrders extends SalesOrderHeaderEvent {
  final int companyId;

  const LoadCreditSalesOrders({required this.companyId});

  @override
  List<Object?> get props => [companyId];
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

class VoidSalesOrder extends SalesOrderHeaderEvent {
  final int id;
  final String voidIndicator;

  const VoidSalesOrder({required this.id, required this.voidIndicator});
  @override
  List<Object?> get props => [id, voidIndicator];
}

class CalculateOrderTotals extends SalesOrderHeaderEvent {
  final SalesOrderHeader header;
  final List<SalesOrderDetail> orderDetails;
  final bool applyWithholding;
  final SystemConstant? systemConstants;

  const CalculateOrderTotals({
    required this.header,
    required this.orderDetails,
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

class PrepareCreate extends SalesOrderHeaderEvent {
  final int companyId;
  final int employeeId;

  const PrepareCreate({required this.companyId, required this.employeeId});
  @override
  List<Object?> get props => [companyId, employeeId];
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

class UpdatePaymentType extends SalesOrderHeaderEvent {
  final String paymentType;

  const UpdatePaymentType({required this.paymentType});
  @override
  List<Object?> get props => [paymentType];
}

class UpdateDateFilters extends SalesOrderHeaderEvent {
  final DateTime? startDate;
  final DateTime? endDate;

  const UpdateDateFilters({this.startDate, this.endDate});

  @override
  List<Object?> get props => [startDate, endDate];
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
