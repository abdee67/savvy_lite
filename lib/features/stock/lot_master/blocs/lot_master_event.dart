// features/stock/lot_master/blocs/lot_master_event.dart

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:savvy_stock/features/purchase/supplier/models/purchase_order_receiver_model.dart';
import 'package:savvy_stock/features/stock/lot_master/models/lot_master_model.dart';
import 'package:savvy_stock/features/udc_detail/models/udc_details.dart';

@immutable
abstract class LotMasterEvent extends Equatable {
  const LotMasterEvent();

  @override
  List<Object> get props => [];
}

class LoadLotMasters extends LotMasterEvent {
  final int companyId;
  const LoadLotMasters(this.companyId);

  @override
  List<Object> get props => [companyId];
}

class FilterLotMasters extends LotMasterEvent {
  final int? itemId;
  final DateTime? expStart;
  final DateTime? expEnd;
  final int? locationId;
  final int? statusId;

  const FilterLotMasters({
    this.itemId,
    this.expStart,
    this.expEnd,
    this.locationId,
    this.statusId,
  });

  @override
  List<Object> get props => [
    itemId ?? Object(),
    expStart ?? Object(),
    expEnd ?? Object(),
    locationId ?? Object(),
    statusId ?? Object(),
  ];
}

class ResetLotFilter extends LotMasterEvent {}

class SaveLotMaster extends LotMasterEvent {
  final LotMaster item;
  final String? transactionType;
  final int? transactionNumber;
  final String? remark;
  const SaveLotMaster(
    this.item, {
    this.transactionType = 'A',
    this.transactionNumber,
    this.remark,
  });

  @override
  List<Object> get props => [
    item,
    transactionType ?? Object(),
    transactionNumber ?? Object(),
    remark ?? Object(),
  ];
}

class UpdateLotMaster extends LotMasterEvent {
  final LotMaster item;
  final String? transactionType;
  final int? transactionNumber;
  final String? remark;
  const UpdateLotMaster(
    this.item, {
    this.transactionType = 'A',
    this.transactionNumber,
    this.remark,
  });

  @override
  List<Object> get props => [
    item,
    transactionType ?? Object(),
    transactionNumber ?? Object(),
    remark ?? Object(),
  ];
}

class DeleteLotMaster extends LotMasterEvent {
  final LotMaster item;
  const DeleteLotMaster(this.item);

  @override
  List<Object> get props => [item];
}

class DeleteMultipleLotMasters extends LotMasterEvent {
  final List<LotMaster> items;

  const DeleteMultipleLotMasters(this.items);

  @override
  List<Object> get props => [items];
}

class SearchLotMasters extends LotMasterEvent {
  final String query;
  const SearchLotMasters(this.query);

  @override
  List<Object> get props => [query];
}

class PrepareCreateLot extends LotMasterEvent {
  final int companyId;
  const PrepareCreateLot(this.companyId);

  @override
  List<Object> get props => [companyId];
}

class PrepareCopyLot extends LotMasterEvent {
  final LotMaster item;
  const PrepareCopyLot(this.item);

  @override
  List<Object> get props => [item];
}

class PrepareEditLot extends LotMasterEvent {
  final LotMaster item;
  const PrepareEditLot(this.item);

  @override
  List<Object> get props => [item];
}

class SelecteLot extends LotMasterEvent {
  final LotMaster? item;
  final bool isSelecting;
  const SelecteLot(this.item, this.isSelecting);

  @override
  List<Object> get props => [item ?? Object(), isSelecting];
}

class SelectMultiSelectionLots extends LotMasterEvent {
  final List<LotMaster> items;
  const SelectMultiSelectionLots(this.items);

  @override
  List<Object> get props => [items];
}

class ClearSelection extends LotMasterEvent {
  const ClearSelection();
}

class AddToCreateList extends LotMasterEvent {
  final LotMaster item;
  const AddToCreateList(this.item);

  @override
  List<Object> get props => [item];
}

class RegenerateLotNumber extends LotMasterEvent {
  const RegenerateLotNumber();
}

class RemoveFromCreateList extends LotMasterEvent {
  final LotMaster item;
  const RemoveFromCreateList(this.item);

  @override
  List<Object> get props => [item];
}

class AutoCreateLotForPO extends LotMasterEvent {
  final PurchaseOrderReceiverModel por;
  final int transactionNumber;
  const AutoCreateLotForPO(this.por, this.transactionNumber);
}

class CalculateLotStatus extends LotMasterEvent {
  final LotMaster item;
  final UdcDetails? lotTypeUdcDetail;
  const CalculateLotStatus(this.item, this.lotTypeUdcDetail);
}

class ClaculateMultipleLotStatus extends LotMasterEvent {
  const ClaculateMultipleLotStatus();
}

class CalculateLotColors extends LotMasterEvent {
  const CalculateLotColors();
}
