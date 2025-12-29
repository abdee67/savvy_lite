// features/sales/quotation_order/bloc/quotation_order_event.dart

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:savvy_stock/features/sales/customer/models/customer_model.dart';
import 'package:savvy_stock/features/sales/quotation_order/model/quotation_order_detail.dart';
import 'package:savvy_stock/features/sales/quotation_order/model/quotation_order_header.dart';
import 'package:savvy_stock/features/stock/item_in_branch/models/item_in_branch_model.dart';
import 'package:savvy_stock/features/system_constant/models/system_constant.dart';

@immutable
sealed class QuotationOrderEvent extends Equatable {
  const QuotationOrderEvent();

  @override
  List<Object?> get props => [];
}

// Header Events
class QuotationOrderInitialized extends QuotationOrderEvent {
  final int companyId;
  final int employeeId;

  const QuotationOrderInitialized({
    required this.companyId,
    required this.employeeId,
  });
}

class LoadQuotationOrders extends QuotationOrderEvent {
  final int companyId;
  final DateTime? startDate;
  final DateTime? endDate;

  const LoadQuotationOrders({
    required this.companyId,
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [companyId, startDate, endDate];
}

class CreateQuotationOrderHeader extends QuotationOrderEvent {
  final QuotationOrderHeader header;

  const CreateQuotationOrderHeader({required this.header});
  @override
  List<Object?> get props => [header];
}

class UpdateQuotationOrderHeader extends QuotationOrderEvent {
  final QuotationOrderHeader header;

  const UpdateQuotationOrderHeader({required this.header});
  @override
  List<Object?> get props => [header];
}

class DeleteQuotationOrderHeader extends QuotationOrderEvent {
  final int id;

  const DeleteQuotationOrderHeader({required this.id});
  @override
  List<Object?> get props => [id];
}

class SelectQuotationOrder extends QuotationOrderEvent {
  final QuotationOrderHeader header;

  const SelectQuotationOrder({required this.header});
  @override
  List<Object?> get props => [header];
}

class CancelQuotationOrder extends QuotationOrderEvent {
  final QuotationOrderHeader header;
  final String commentsReason;

  const CancelQuotationOrder({
    required this.header,
    required this.commentsReason,
  });
  @override
  List<Object?> get props => [header, commentsReason];
}

class PrepareCreateQuotationOrder extends QuotationOrderEvent {
  final int companyId;
  final int employeeId;
  final int branchId;

  const PrepareCreateQuotationOrder({
    required this.companyId,
    required this.employeeId,
    required this.branchId,
  });
  @override
  List<Object?> get props => [companyId, employeeId, branchId];
}

class PrepareEditQuotationOrder extends QuotationOrderEvent {
  final int companyId;
  final int employeeId;
  final int branchId;

  const PrepareEditQuotationOrder({
    required this.companyId,
    required this.employeeId,
    required this.branchId,
  });
  @override
  List<Object?> get props => [companyId, employeeId, branchId];
}

class CancelQuotationUpdate extends QuotationOrderEvent {
  final QuotationOrderHeader header;

  const CancelQuotationUpdate({required this.header});
  @override
  List<Object?> get props => [header];
}

class CancelQuotationCreate extends QuotationOrderEvent {
  final QuotationOrderHeader header;

  const CancelQuotationCreate({required this.header});
  @override
  List<Object?> get props => [header];
}

class DiscardQuotationChanges extends QuotationOrderEvent {}

// Detail Events
class LoadQuotationOrderDetails extends QuotationOrderEvent {
  final int headerId;
  final int companyId;

  const LoadQuotationOrderDetails({
    required this.headerId,
    required this.companyId,
  });
  @override
  List<Object?> get props => [headerId, companyId];
}

class AddQuotationOrderDetail extends QuotationOrderEvent {
  final QuotationOrderDetail detail;

  const AddQuotationOrderDetail({required this.detail});
  @override
  List<Object?> get props => [detail];
}

class UpdateQuotationOrderDetail extends QuotationOrderEvent {
  final QuotationOrderDetail detail;
  final int index;

  const UpdateQuotationOrderDetail({required this.detail, required this.index});
  @override
  List<Object?> get props => [detail, index];
}

class RemoveQuotationOrderDetail extends QuotationOrderEvent {
  final QuotationOrderDetail detail;

  const RemoveQuotationOrderDetail({required this.detail});
  @override
  List<Object?> get props => [detail];
}

class ClearQuotationOrderDetails extends QuotationOrderEvent {}

// Financial Calculation Events
class CalculateQuotationTotals extends QuotationOrderEvent {
  final QuotationOrderHeader header;
  final List<QuotationOrderDetail> details;
  final bool applyWithholding;
  final double discountAmount;
  final SystemConstant? systemConstants;

  const CalculateQuotationTotals({
    required this.header,
    required this.details,
    required this.applyWithholding,
    required this.discountAmount,
    this.systemConstants,
  });
  @override
  List<Object?> get props => [
    header,
    details,
    applyWithholding,
    discountAmount,
  ];
}

class LoadFeeSystemConstants extends QuotationOrderEvent {}

class UpdateCustomerInfo extends QuotationOrderEvent {
  final Customer customer;
  final QuotationOrderHeader? currentHeader;

  const UpdateCustomerInfo({required this.customer, this.currentHeader});

  @override
  List<Object?> get props => [customer, currentHeader];
}

class UpdateUnitPriceWithUom extends QuotationOrderEvent {
  final QuotationOrderDetail detail;
  final ItemInBranchModel itemInBranch;
  final double? manualUnitPrice;

  const UpdateUnitPriceWithUom({
    required this.detail,
    required this.itemInBranch,
    this.manualUnitPrice,
  });

  @override
  List<Object?> get props => [detail, itemInBranch, manualUnitPrice];
}

class CalculateExtendedPrice extends QuotationOrderEvent {
  final QuotationOrderDetail detail;

  const CalculateExtendedPrice({required this.detail});

  @override
  List<Object?> get props => [detail];
}

// Barcode Events
class SetUseBarcode extends QuotationOrderEvent {
  final bool useBarcode;

  const SetUseBarcode({required this.useBarcode});
}

class SetBarcode extends QuotationOrderEvent {
  final String barcode;

  const SetBarcode({required this.barcode});

  @override
  List<Object?> get props => [barcode];
}

class ScanBarcode extends QuotationOrderEvent {}

// Conversion Events
class ConvertToSalesOrder extends QuotationOrderEvent {
  final QuotationOrderHeader quotationHeader;

  const ConvertToSalesOrder({required this.quotationHeader});
  @override
  List<Object?> get props => [quotationHeader];
}

// Filter Events
class FilterQuotationOrders extends QuotationOrderEvent {
  final int? customerBillTo;
  final String? fsNumber;
  final String? conversionStatus;
  final DateTime? startDate;
  final DateTime? endDate;

  const FilterQuotationOrders({
    this.customerBillTo,
    this.fsNumber,
    this.conversionStatus,
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [
    customerBillTo,
    fsNumber,
    conversionStatus,
    startDate,
    endDate,
  ];
}

class ClearQuotationFilters extends QuotationOrderEvent {}

class ResetQuotationState extends QuotationOrderEvent {}

class ResetQuotationDetails extends QuotationOrderEvent {}

class DeleteMultipleQuotationOrders extends QuotationOrderEvent {
  final List<QuotationOrderHeader> headers;

  const DeleteMultipleQuotationOrders({required this.headers});

  @override
  List<Object?> get props => [headers];
}

class SaveMultipleQuotationOrders extends QuotationOrderEvent {
  final List<QuotationOrderHeader> headers;

  const SaveMultipleQuotationOrders({required this.headers});

  @override
  List<Object?> get props => [headers];
}

// Batch Operations
class SaveQuotationOrder extends QuotationOrderEvent {
  final QuotationOrderHeader header;
  final List<QuotationOrderDetail> details;

  const SaveQuotationOrder({required this.header, required this.details});

  @override
  List<Object?> get props => [header, details];
}

class SaveQuotationDetails extends QuotationOrderEvent {
  final int headerId;

  const SaveQuotationDetails({required this.headerId});
}

// Utility Events
class GetNextOrderNumber extends QuotationOrderEvent {
  final int companyId;

  const GetNextOrderNumber({required this.companyId});
}

class RefreshQuotationOrders extends QuotationOrderEvent {}

class LoadQuotations extends QuotationOrderEvent {
  final int companyId;

  const LoadQuotations({required this.companyId});

  @override
  List<Object?> get props => [companyId];
}

class GenerateInvoiceFromQuotation extends QuotationOrderEvent {}

// CRUD
class CreateQuotation extends QuotationOrderEvent {
  final QuotationOrderHeader header;
  final List<QuotationOrderDetail> details;

  const CreateQuotation({required this.header, required this.details});

  @override
  List<Object?> get props => [header, details];
}

class UpdateQuotation extends QuotationOrderEvent {
  final QuotationOrderHeader header;
  final List<QuotationOrderDetail> details;

  const UpdateQuotation({required this.header, required this.details});

  @override
  List<Object?> get props => [header, details];
}

class DeleteQuotation extends QuotationOrderEvent {
  final int id;

  const DeleteQuotation({required this.id});

  @override
  List<Object?> get props => [id];
}

// Preparation
class PrepareCreateQuotation extends QuotationOrderEvent {
  final int companyId;
  final int employeeId;

  const PrepareCreateQuotation({
    required this.companyId,
    required this.employeeId,
  });

  @override
  List<Object?> get props => [companyId, employeeId];
}

class PrepareEditQuotation extends QuotationOrderEvent {
  final QuotationOrderHeader header;

  const PrepareEditQuotation({required this.header});

  @override
  List<Object?> get props => [header];
}

// Detail Management
class AddDetailItem extends QuotationOrderEvent {
  final QuotationOrderDetail detail;

  const AddDetailItem({required this.detail});

  @override
  List<Object?> get props => [detail];
}

class UpdateDetailItem extends QuotationOrderEvent {
  final QuotationOrderDetail detail;
  final int index;

  const UpdateDetailItem({required this.detail, required this.index});

  @override
  List<Object?> get props => [detail, index];
}

class RemoveDetailItem extends QuotationOrderEvent {
  final int index;

  const RemoveDetailItem({required this.index});

  @override
  List<Object?> get props => [index];
}

// Business Logic

class CalculateTotals extends QuotationOrderEvent {
  final QuotationOrderHeader header;
  final List<QuotationOrderDetail> details;
  final SystemConstant? systemConstants;

  const CalculateTotals({
    required this.header,
    required this.details,
    this.systemConstants,
  });

  @override
  List<Object?> get props => [header, details, systemConstants];
}

class UomChanged extends QuotationOrderEvent {
  final QuotationOrderDetail detail;
  final ItemInBranchModel itemInBranch;
  final int newUomId;

  const UomChanged({
    required this.detail,
    required this.itemInBranch,
    required this.newUomId,
  });

  @override
  List<Object?> get props => [detail, itemInBranch, newUomId];
}

class PrepareInvoiceReview extends QuotationOrderEvent {
  final QuotationOrderHeader header;

  const PrepareInvoiceReview({required this.header});

  @override
  List<Object?> get props => [header];
}

class GenerateNextFsNumber extends QuotationOrderEvent {
  final int companyId;
  final int branchId;

  const GenerateNextFsNumber({required this.companyId, required this.branchId});

  @override
  List<Object?> get props => [companyId, branchId];
}

class SystemConstantsUpdated extends QuotationOrderEvent {
  final SystemConstant systemConstants;

  const SystemConstantsUpdated({required this.systemConstants});

  @override
  List<Object?> get props => [systemConstants];
}

class SelectMultipleQuotationOrders extends QuotationOrderEvent {
  final List<QuotationOrderHeader> headers;

  const SelectMultipleQuotationOrders({required this.headers});
}

class ClearQuotationSelection extends QuotationOrderEvent {}

// ============ QUOTATION STATUS MANAGEMENT ============

class DeleteQuotationOrderDetailBatch extends QuotationOrderEvent {
  final List<int> ids;

  const DeleteQuotationOrderDetailBatch({required this.ids});
}

class SaveQuotationDetailRow extends QuotationOrderEvent {}

class ApplyWithholdingTax extends QuotationOrderEvent {
  final bool applyWithholding;

  const ApplyWithholdingTax({required this.applyWithholding});
}

class ApplyDiscount extends QuotationOrderEvent {
  final double discountAmount;

  const ApplyDiscount({required this.discountAmount});
}

class UpdateTaxSettings extends QuotationOrderEvent {
  final double subTotal;
  final bool isWithholdingEnabled;
  final double discountAmount;

  const UpdateTaxSettings({
    required this.subTotal,
    required this.isWithholdingEnabled,
    required this.discountAmount,
  });
}

class SetDefaultCustomer extends QuotationOrderEvent {
  final int companyId;

  const SetDefaultCustomer({required this.companyId});
}

class SearchQuotationOrders extends QuotationOrderEvent {
  final String query;

  const SearchQuotationOrders({required this.query});
}

class UpdateDateFilters extends QuotationOrderEvent {
  final DateTime? startDate;
  final DateTime? endDate;

  const UpdateDateFilters({this.startDate, this.endDate});
}
