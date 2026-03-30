// features/sales/sales_return/bloc/sales_return_event.dart

import 'package:flutter/foundation.dart';
import 'package:savvy_stock/features/sales/sales_return/models/void_sales_details.dart';
import 'package:savvy_stock/features/sales/sales_return/models/void_sales_header.dart';

@immutable
abstract class SalesReturnEvent {}

// Initialization & Loading
class SalesReturnInitialized extends SalesReturnEvent {
  final int companyId;
  final int employeeId;

  SalesReturnInitialized({required this.companyId, required this.employeeId});
}

class LoadSalesReturns extends SalesReturnEvent {
  final int companyId;

  LoadSalesReturns({required this.companyId});
}

class LoadSalesReturnByFsNumber extends SalesReturnEvent {
  final String fsNumber;
  final String invoiceNumber;
  final int companyId;

  LoadSalesReturnByFsNumber({
    required this.fsNumber,
    required this.invoiceNumber,
    required this.companyId,
  });
}

// Header CRUD Operations
class CreateSalesReturnHeader extends SalesReturnEvent {
  final SalesReturnHeader header;

  CreateSalesReturnHeader({required this.header});
}

class UpdateSalesReturnHeader extends SalesReturnEvent {
  final SalesReturnHeader header;

  UpdateSalesReturnHeader({required this.header});
}

class DeleteSalesReturnHeader extends SalesReturnEvent {
  final int id;

  DeleteSalesReturnHeader({required this.id});
}

class VoidSalesReturn extends SalesReturnEvent {
  final int id;
  final String voidIndicator;

  VoidSalesReturn({required this.id, required this.voidIndicator});
}

// Detail CRUD Operations
class AddSalesReturnDetail extends SalesReturnEvent {
  final SalesReturnDetails detail;

  AddSalesReturnDetail({required this.detail});
}

class UpdateSalesReturnDetail extends SalesReturnEvent {
  final SalesReturnDetails detail;

  UpdateSalesReturnDetail({required this.detail});
}

class RemoveSalesReturnDetail extends SalesReturnEvent {
  final SalesReturnDetails detail;

  RemoveSalesReturnDetail({required this.detail});
}

class SaveAllSalesReturnDetails extends SalesReturnEvent {
  final List<SalesReturnDetails> details;

  SaveAllSalesReturnDetails({required this.details});
}

// UI State Management
class PrepareCreateSalesReturn extends SalesReturnEvent {
  final int companyId;
  final int employeeId;
  final int branchId;

  PrepareCreateSalesReturn({
    required this.companyId,
    required this.employeeId,
    required this.branchId,
  });
}

class SetSelectedHeader extends SalesReturnEvent {
  final SalesReturnHeader? header;

  SetSelectedHeader({this.header});
}

class SetSelectedDetail extends SalesReturnEvent {
  final SalesReturnDetails? detail;

  SetSelectedDetail({this.detail});
}

// Financial Calculations
class CalculateReturnTotals extends SalesReturnEvent {
  final List<SalesReturnDetails> details;
  final bool applyWithholding;
  final double discountAmount;

  CalculateReturnTotals({
    required this.details,
    required this.applyWithholding,
    required this.discountAmount,
  });
}

class CalculateExtendedPrice extends SalesReturnEvent {
  final SalesReturnDetails detail;

  CalculateExtendedPrice({required this.detail});
}

// Stock Management
class ValidateReturnStock extends SalesReturnEvent {
  final SalesReturnDetails detail;

  ValidateReturnStock({required this.detail});
}

class UpdateStockForReturn extends SalesReturnEvent {
  final SalesReturnDetails detail;

  UpdateStockForReturn({required this.detail});
}

class ReverseReturnStock extends SalesReturnEvent {
  final int salesReturnId;
  final bool applyLotMgm;

  ReverseReturnStock({required this.salesReturnId, required this.applyLotMgm});
}

// Return Submission
class SubmitSalesReturn extends SalesReturnEvent {
  final SalesReturnHeader header;
  final List<SalesReturnDetails> details;
  final String returnReason;

  SubmitSalesReturn({
    required this.header,
    required this.details,
    required this.returnReason,
  });
}

// Search & Filter
class SearchSalesReturns extends SalesReturnEvent {
  final String query;
  final int companyId;

  SearchSalesReturns({required this.query, required this.companyId});
}

class FilterSalesReturns extends SalesReturnEvent {
  final String fsNumber;
  final DateTime? startDate;
  final DateTime? endDate;
  final int companyId;

  FilterSalesReturns({
    required this.fsNumber,
    this.startDate,
    this.endDate,
    required this.companyId,
  });
}

// Utility
class RefreshSalesReturns extends SalesReturnEvent {
  final int companyId;

  RefreshSalesReturns({required this.companyId});
}

class ResetSalesReturnState extends SalesReturnEvent {}
