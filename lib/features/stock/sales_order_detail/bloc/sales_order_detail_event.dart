// bloc/sales_order_details/sales_order_details_event.dart

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:savvy_stock/features/system_constant/models/system_constant.dart';
import 'package:savvy_stock/features/stock/sales_order_detail/model/sales_order_detail.dart';
import 'package:savvy_stock/features/stock/sales_order_header/model/sales_order_header.dart';

@immutable
abstract class SalesOrderDetailEvent extends Equatable {
  const SalesOrderDetailEvent();
}

// Initialization events
class SalesOrderDetailLoadEvent extends SalesOrderDetailEvent {
  final int companyId;

  const SalesOrderDetailLoadEvent(this.companyId);
  @override
  List<Object?> get props => [companyId];
}

class SalesOrderDetailPrepareCreateEvent extends SalesOrderDetailEvent {
  final int companyId;
  final int userId;
  final int branchId;

  const SalesOrderDetailPrepareCreateEvent({
    required this.companyId,
    required this.userId,
    required this.branchId,
  });
  @override
  List<Object?> get props => [companyId, userId, branchId];
}

class SalesOrderDetailPrepareCreateAfterCreateEvent
    extends SalesOrderDetailEvent {
  final int companyId;
  final int userId;
  final int branchId;

  const SalesOrderDetailPrepareCreateAfterCreateEvent({
    required this.companyId,
    required this.userId,
    required this.branchId,
  });
  @override
  List<Object?> get props => [companyId, userId, branchId];
}

// CRUD events
class SalesOrderDetailCreateEvent extends SalesOrderDetailEvent {
  final SalesOrderDetail details;

  const SalesOrderDetailCreateEvent(this.details);
  @override
  List<Object?> get props => [details];
}

class SalesOrderDetailUpdateEvent extends SalesOrderDetailEvent {
  final SalesOrderDetail details;

  const SalesOrderDetailUpdateEvent(this.details);
  @override
  List<Object?> get props => [details];
}

class SalesOrderDetailDeleteEvent extends SalesOrderDetailEvent {
  final int id;

  const SalesOrderDetailDeleteEvent(this.id);
  @override
  List<Object?> get props => [id];
}

class SalesOrderDetailDeleteCollectionEvent extends SalesOrderDetailEvent {
  final List<SalesOrderDetail> items;

  const SalesOrderDetailDeleteCollectionEvent(this.items);
  @override
  List<Object?> get props => [items];
}

// Multi-selection events
class SalesOrderDetailMultiSelectEvent extends SalesOrderDetailEvent {
  final List<SalesOrderDetail> selectedItems;

  const SalesOrderDetailMultiSelectEvent(this.selectedItems);
  @override
  List<Object?> get props => [selectedItems];
}

class SalesOrderDetailPrepareEditEvent extends SalesOrderDetailEvent {
  final List<SalesOrderDetail> selectedItems;

  const SalesOrderDetailPrepareEditEvent(this.selectedItems);
  @override
  List<Object?> get props => [selectedItems];
}

// Barcode events
class SalesOrderDetailSetBarcodeEvent extends SalesOrderDetailEvent {
  final String barcode;
  final int branchId;
  final int companyId;

  const SalesOrderDetailSetBarcodeEvent({
    required this.barcode,
    required this.branchId,
    required this.companyId,
  });
  @override
  List<Object?> get props => [barcode, branchId, companyId];
}

// Validation events
class SalesOrderDetailValidateAvailabilityEvent extends SalesOrderDetailEvent {
  final SalesOrderDetail item;
  final List<SalesOrderDetail> createItems;
  final int companyId;

  const SalesOrderDetailValidateAvailabilityEvent({
    required this.item,
    required this.createItems,
    required this.companyId,
  });
  @override
  List<Object?> get props => [item, createItems, companyId];
}

// Save events
class SalesOrderDetailSaveEvent extends SalesOrderDetailEvent {
  final List<SalesOrderDetail> createItems;
  final SalesOrderHeader salesOrderHeader;
  final SystemConstant systemConstant;
  final int companyId;
  final int userId;
  final int branchId;
  final String? fsReference;

  const SalesOrderDetailSaveEvent({
    required this.createItems,
    required this.salesOrderHeader,
    required this.systemConstant,
    required this.companyId,
    required this.userId,
    required this.branchId,
    required this.fsReference,
  });
  @override
  List<Object?> get props => [
    createItems,
    salesOrderHeader,
    systemConstant,
    companyId,
    userId,
    branchId,
    fsReference,
  ];
}

class SalesOrderDetailSaveRowEvent extends SalesOrderDetailEvent {
  final List<SalesOrderDetail> editItems;

  const SalesOrderDetailSaveRowEvent(this.editItems);
  @override
  List<Object?> get props => [editItems];
}

// Report events
class SalesOrderDetailReportGenerateEvent extends SalesOrderDetailEvent {
  final SalesOrderHeader salesHeader;
  final int companyId;

  const SalesOrderDetailReportGenerateEvent(this.salesHeader, this.companyId);
  @override
  List<Object?> get props => [salesHeader, companyId];
}

class SalesOrderDetailPrepareInvoiceReviewEvent extends SalesOrderDetailEvent {
  final List<SalesOrderDetail> createItems;
  final SalesOrderHeader salesOrderHeader;
  final SystemConstant systemConstant;
  final int companyId;
  final int branchId;
  final String? cityDesc;
  final String? countryDesc;
  final String? phoneNumbers;
  final String? regionDesc;
  final String? tinNumber;
  final double? totalAmount;
  final double? subTotal;
  final String? fsReference;

  const SalesOrderDetailPrepareInvoiceReviewEvent({
    required this.createItems,
    required this.salesOrderHeader,
    required this.systemConstant,
    required this.companyId,
    required this.branchId,
    this.cityDesc,
    this.countryDesc,
    this.phoneNumbers,
    this.regionDesc,
    this.tinNumber,
    this.totalAmount,
    this.subTotal,
    this.fsReference,
  });
  @override
  List<Object?> get props => [
    createItems,
    salesOrderHeader,
    systemConstant,
    companyId,
    branchId,
    cityDesc,
    countryDesc,
    phoneNumbers,
    regionDesc,
    tinNumber,
    totalAmount,
    subTotal,
    fsReference,
  ];
}

// Navigation events
class SalesOrderDetailDiscardEvent extends SalesOrderDetailEvent {
  const SalesOrderDetailDiscardEvent();
  @override
  List<Object?> get props => [];
}
