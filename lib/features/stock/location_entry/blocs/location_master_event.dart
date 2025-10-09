import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:savvy_stock/features/stock/item_in_branch/models/item_in_branch_model.dart';
import 'package:savvy_stock/features/stock/location_entry/models/location_master_model.dart';

@immutable
sealed class LocationMasterEvent extends Equatable {
  const LocationMasterEvent();

  @override
  List<Object?> get props => [];
}

class LoadLocationMasters extends LocationMasterEvent {
  final int companyId;
  const LoadLocationMasters(this.companyId);
}

class SaveLocationMaster extends LocationMasterEvent {
  final LocationMaster item;
  final List<ItemInBranchModel> assignedItems;
  const SaveLocationMaster(this.item, this.assignedItems);
}

class UpdateLocationMaster extends LocationMasterEvent {
  final LocationMaster item;
  final List<ItemInBranchModel> assignedItems;
  const UpdateLocationMaster(this.item, this.assignedItems);
}

class DeleteLocationMaster extends LocationMasterEvent {
  final LocationMaster item;
  const DeleteLocationMaster(this.item);
}

class PrepareCreateLocation extends LocationMasterEvent {
  final int companyId;
  const PrepareCreateLocation(this.companyId);
}

class PrepareCreateInCreate extends LocationMasterEvent {
  final int companyId;
  const PrepareCreateInCreate(this.companyId);
}

class PrepareEditLocation extends LocationMasterEvent {
  final LocationMaster item;
  const PrepareEditLocation(this.item);
}

class AddToCreateList extends LocationMasterEvent {
  final LocationMaster item;
  const AddToCreateList(this.item);
}

class RemoveFromCreateList extends LocationMasterEvent {
  final LocationMaster item;
  const RemoveFromCreateList(this.item);
}

class RemoveFromEditList extends LocationMasterEvent {
  final LocationMaster item;
  const RemoveFromEditList(this.item);
}

class SetSelectedLocation extends LocationMasterEvent {
  final LocationMaster? item;
  const SetSelectedLocation(this.item);
}

class SetMultiSelectionLocations extends LocationMasterEvent {
  final List<LocationMaster> items;
  const SetMultiSelectionLocations(this.items);
}

class ClearCreateList extends LocationMasterEvent {}

class UpdateDualListModel extends LocationMasterEvent {
  final List<ItemInBranchModel> source;
  final List<ItemInBranchModel> target;
  const UpdateDualListModel(this.source, this.target);
}

class LoadItemsForBranch extends LocationMasterEvent {
  final int branchId;
  const LoadItemsForBranch(this.branchId);
}

class LoadLocationsByBranch extends LocationMasterEvent {
  final int branchId;
  const LoadLocationsByBranch(this.branchId);
}

class CancelCreate extends LocationMasterEvent {}

class CancelUpdate extends LocationMasterEvent {}

class ClearLocations extends LocationMasterEvent {
  const ClearLocations();
}
