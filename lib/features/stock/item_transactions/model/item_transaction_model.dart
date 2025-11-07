// models/item_transaction_model.dart
import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:savvy_stock/features/branch_list/models/branch_list_model.dart';
import 'package:savvy_stock/features/company/models/company_model.dart';
import 'package:savvy_stock/features/purchase/supplier/models/supplier_model.dart';
import 'package:savvy_stock/features/stock/inventory_transaction_entry/models/inventory_transaction_entry_model.dart';
import 'package:savvy_stock/features/stock/item_entry/models/item_entry_model.dart';
import 'package:savvy_stock/features/stock/item_in_branch/models/item_in_branch_model.dart';
import 'package:savvy_stock/features/stock/item_locations/models/item_locations_model.dart';
import 'package:savvy_stock/features/stock/lot_master/models/lot_master_model.dart';
import 'package:savvy_stock/features/udc_detail/models/udc_details.dart';

class ItemTransactionModel {
  final int? id;
  int? itemLocation;
  final int? createdBy;
  final DateTime dateCreated;
  double quantityTransaction;
  final String? remark;
  final int? company;
  int? lotNumber;
  final int? transactionType;
  final int? itemBranch;
  final int? transactionNumber;
  int? itemNumber;
  final int? lotStatus;
  final int? branch;
  final int? supplier;
  final int? customer;
  final int? orderType;
  int? unitOfMeasure;
  final double beforeStoreQuantityAvailable;
  final double unitCost;
  final double amountCost;
  final double beforeAmountCost;
  final int? tempId;
  bool adjustToIncrease;
  int? itemLocationsTo;

  // Foreign key relationships
  final ItemLocation? location;
  final LotMaster? lot;
  final ItemInBranchModel? itemBranchDetail;
  final ItemEntryModel? item;
  final Branch? branchDetail;
  final UdcDetails? transactionTypeDetail;
  final UdcDetails? lotStatusDetail;
  final UdcDetails? orderTypeDetail;
  final UdcDetails? unitOfMeasureDetail;
  final SupplierModel? supplierDetail;
  final Customer? customerDetail;
  final Company? companyDetail;

  ItemTransactionModel({
    this.id,
    this.itemLocation,
    this.createdBy,
    required this.dateCreated,
    required this.quantityTransaction,
    this.remark,
    this.company,
    this.lotNumber,
    this.transactionType,
    this.itemBranch,
    this.transactionNumber,
    this.itemNumber,
    this.lotStatus,
    this.branch,
    this.supplier,
    this.customer,
    this.orderType,
    this.unitOfMeasure,
    required this.beforeStoreQuantityAvailable,
    required this.unitCost,
    required this.amountCost,
    required this.beforeAmountCost,
    this.tempId,
    this.adjustToIncrease = false,
    this.itemLocationsTo,
    this.location,
    this.lot,
    this.itemBranchDetail,
    this.item,
    this.branchDetail,
    this.transactionTypeDetail,
    this.lotStatusDetail,
    this.orderTypeDetail,
    this.unitOfMeasureDetail,
    this.supplierDetail,
    this.customerDetail,
    this.companyDetail,
  });

  ItemTransactionModel copyWith({
    int? id,
    int? itemLocation,
    int? createdBy,
    DateTime? dateCreated,
    double? quantityTransaction,
    String? remark,
    int? company,
    int? lotNumber,
    int? transactionType,
    int? itemBranch,
    int? transactionNumber,
    int? itemNumber,
    int? lotStatus,
    int? branch,
    int? supplier,
    int? customer,
    int? orderType,
    int? unitOfMeasure,
    double? beforeStoreQuantityAvailable,
    double? unitCost,
    double? amountCost,
    double? beforeAmountCost,
    int? tempId,
    bool? adjustToIncrease,
    int? itemLocationsTo,
    ItemLocation? location,
    LotMaster? lot,
    ItemInBranchModel? itemBranchDetail,
    ItemEntryModel? item,
    Branch? branchDetail,
    UdcDetails? transactionTypeDetail,
    UdcDetails? lotStatusDetail,
    UdcDetails? orderTypeDetail,
    UdcDetails? unitOfMeasureDetail,
    SupplierModel? supplierDetail,
    Customer? customerDetail,
    Company? companyDetail,
  }) {
    return ItemTransactionModel(
      id: id ?? this.id,
      itemLocation: itemLocation ?? this.itemLocation,
      createdBy: createdBy ?? this.createdBy,
      dateCreated: dateCreated ?? this.dateCreated,
      quantityTransaction: quantityTransaction ?? this.quantityTransaction,
      remark: remark ?? this.remark,
      company: company ?? this.company,
      lotNumber: lotNumber ?? this.lotNumber,
      transactionType: transactionType ?? this.transactionType,
      itemBranch: itemBranch ?? this.itemBranch,
      transactionNumber: transactionNumber ?? this.transactionNumber,
      itemNumber: itemNumber ?? this.itemNumber,
      lotStatus: lotStatus ?? this.lotStatus,
      branch: branch ?? this.branch,
      supplier: supplier ?? this.supplier,
      customer: customer ?? this.customer,
      orderType: orderType ?? this.orderType,
      unitOfMeasure: unitOfMeasure ?? this.unitOfMeasure,
      beforeStoreQuantityAvailable:
          beforeStoreQuantityAvailable ?? this.beforeStoreQuantityAvailable,
      unitCost: unitCost ?? this.unitCost,
      amountCost: amountCost ?? this.amountCost,
      beforeAmountCost: beforeAmountCost ?? this.beforeAmountCost,
      tempId: tempId ?? this.tempId,
      adjustToIncrease: adjustToIncrease ?? this.adjustToIncrease,
      itemLocationsTo: itemLocationsTo ?? this.itemLocationsTo,
      location: location ?? this.location,
      lot: lot ?? this.lot,
      itemBranchDetail: itemBranchDetail ?? this.itemBranchDetail,
      item: item ?? this.item,
      branchDetail: branchDetail ?? this.branchDetail,
      transactionTypeDetail:
          transactionTypeDetail ?? this.transactionTypeDetail,
      lotStatusDetail: lotStatusDetail ?? this.lotStatusDetail,
      orderTypeDetail: orderTypeDetail ?? this.orderTypeDetail,
      unitOfMeasureDetail: unitOfMeasureDetail ?? this.unitOfMeasureDetail,
      supplierDetail: supplierDetail ?? this.supplierDetail,
      customerDetail: customerDetail ?? this.customerDetail,
      companyDetail: companyDetail ?? this.companyDetail,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'item_location': itemLocation,
      'created_by': createdBy,
      'date_created': dateCreated.toIso8601String(),
      'quantity_transaction': quantityTransaction,
      'remark': remark,
      'company': company,
      'lot_number': lotNumber,
      'transaction_type': transactionType,
      'item_branch': itemBranch,
      'transaction_number': transactionNumber,
      'item_number': itemNumber,
      'lot_status': lotStatus,
      'branch': branch,
      'supplier': supplier,
      'customer': customer,
      'order_type': orderType,
      'unit_of_measure': unitOfMeasure,
      'before_store_quantity_available': beforeStoreQuantityAvailable,
      'unit_cost': unitCost,
      'amount_cost': amountCost,
      'before_amount_cost': beforeAmountCost,
    };
  }

  factory ItemTransactionModel.fromMap(Map<String, dynamic> map) {
    return ItemTransactionModel(
      id: _toInt(map['id']),
      itemLocation: _toInt(map['item_location']),
      createdBy: _toInt(map['created_by']),
      dateCreated: DateTime.parse(map['date_created'].toString()),
      quantityTransaction: _toDouble(map['quantity_transaction']) ?? 0.0,
      remark: map['remark']?.toString(),
      company: _toInt(map['company']),
      lotNumber: _toInt(map['lot_number']),
      transactionType: _toInt(map['transaction_type']),
      itemBranch: _toInt(map['item_branch']),
      transactionNumber: _toInt(map['transaction_number']),
      itemNumber: _toInt(map['item_number']),
      lotStatus: _toInt(map['lot_status']),
      branch: _toInt(map['branch']),
      supplier: _toInt(map['supplier']),
      customer: _toInt(map['customer']),
      orderType: _toInt(map['order_type']),
      unitOfMeasure: _toInt(map['unit_of_measure']),
      beforeStoreQuantityAvailable:
          _toDouble(map['before_store_quantity_available']) ?? 0.0,
      unitCost: _toDouble(map['unit_cost']) ?? 0.0,
      amountCost: _toDouble(map['amount_cost']) ?? 0.0,
      beforeAmountCost: _toDouble(map['before_amount_cost']) ?? 0.0,
    );
  }

  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  // Helper method to load relationships
  Future<ItemTransactionModel> loadRelationships(
    LocalDatabaseService databaseService,
  ) async {
    final db = await databaseService.database;

    // Load location
    ItemLocation? location;
    if (itemLocation != null) {
      final locationData = await db.query(
        'item_location',
        where: 'id = ?',
        whereArgs: [itemLocation],
      );
      if (locationData.isNotEmpty) {
        location = ItemLocation.fromMap(locationData.first);
      }
    }

    // Load lot
    LotMaster? lot;
    if (lotNumber != null) {
      final lotData = await db.query(
        'lot_master',
        where: 'id = ?',
        whereArgs: [lotNumber],
      );
      if (lotData.isNotEmpty) {
        lot = LotMaster.fromMap(lotData.first);
      }
    }

    // Load item branch
    ItemInBranchModel? itemBranchDetail;
    if (itemBranch != null) {
      final itemBranchData = await db.query(
        'items_in_branch',
        where: 'id = ?',
        whereArgs: [itemBranch],
      );
      if (itemBranchData.isNotEmpty) {
        itemBranchDetail = ItemInBranchModel.fromMap(itemBranchData.first);
      }
    }

    // Load item
    ItemEntryModel? item;
    if (itemNumber != null) {
      final itemData = await db.query(
        'item_entry',
        where: 'id = ?',
        whereArgs: [itemNumber],
      );
      if (itemData.isNotEmpty) {
        item = ItemEntryModel.fromMap(itemData.first);
      }
    }

    // Load transaction type
    UdcDetails? transactionTypeDetail;
    if (transactionType != null) {
      final transactionTypeData = await db.query(
        'udc_details',
        where: 'id = ?',
        whereArgs: [transactionType],
      );
      if (transactionTypeData.isNotEmpty) {
        transactionTypeDetail = UdcDetails.fromJson(transactionTypeData.first);
      }
    }
    //

    return copyWith(
      location: location,
      lot: lot,
      itemBranchDetail: itemBranchDetail,
      item: item,
      transactionTypeDetail: transactionTypeDetail,
    );
  }
}
