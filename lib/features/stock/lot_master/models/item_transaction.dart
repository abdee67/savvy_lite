import 'package:equatable/equatable.dart';

class ItemTransactionModel extends Equatable {
  final int? id;
  final int? itemLocation;
  final int? createdBy;
  final DateTime? dateCreated;
  final double? quantityTransaction;
  final String? remark;
  final int? company;
  final int? lotNumber;
  final int? transactionType;
  final int? itemBranch;
  final int? transactionNumber;
  final int? itemNumber;
  final int? lotStatus;
  final int? branch;
  final int? supplier;
  final int? customer;
  final int? orderType;
  final int? unitOfMeasure;
  final double? beforeStoreQuantityAvailable;
  final double? unitCost;
  final double? amountCost;
  final double? beforeAmountCost;

  const ItemTransactionModel({
    this.id,
    this.itemLocation,
    this.createdBy,
    this.dateCreated,
    this.quantityTransaction,
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
    this.beforeStoreQuantityAvailable,
    this.unitCost,
    this.amountCost,
    this.beforeAmountCost,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'item_location': itemLocation,
      'created_by': createdBy,
      'date_created': dateCreated?.toIso8601String(),
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
      id: map['id'] as int?,
      itemLocation: map['item_location'] as int?,
      createdBy: map['created_by'] as int?,
      dateCreated: map['date_created'] != null
          ? DateTime.tryParse(map['date_created'])
          : null,
      quantityTransaction: map['quantity_transaction']?.toDouble(),
      remark: map['remark'] as String?,
      company: map['company'] as int?,
      lotNumber: map['lot_number'] as int?,
      transactionType: map['transaction_type'] as int?,
      itemBranch: map['item_branch'] as int?,
      transactionNumber: map['transaction_number'] as int?,
      itemNumber: map['item_number'] as int?,
      lotStatus: map['lot_status'] as int?,
      branch: map['branch'] as int?,
      supplier: map['supplier'] as int?,
      customer: map['customer'] as int?,
      orderType: map['order_type'] as int?,
      unitOfMeasure: map['unit_of_measure'] as int?,
      beforeStoreQuantityAvailable: map['before_store_quantity_available']
          ?.toDouble(),
      unitCost: map['unit_cost']?.toDouble(),
      amountCost: map['amount_cost']?.toDouble(),
      beforeAmountCost: map['before_amount_cost']?.toDouble(),
    );
  }

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
    );
  }

  @override
  List<Object?> get props => [
    id,
    itemLocation,
    createdBy,
    dateCreated,
    quantityTransaction,
    remark,
    company,
    lotNumber,
    transactionType,
    itemBranch,
    transactionNumber,
    itemNumber,
    lotStatus,
    branch,
    supplier,
    customer,
    orderType,
    unitOfMeasure,
    beforeStoreQuantityAvailable,
    unitCost,
    amountCost,
    beforeAmountCost,
  ];
}
