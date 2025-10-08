import 'package:equatable/equatable.dart';
import 'package:savvy_stock/features/stock/item_in_branch/models/item_in_branch_model.dart';
import 'package:savvy_stock/features/stock/location_entry/models/location_master_model.dart';

enum LocationMasterStatus {
  initial,
  loading,
  loaded,
  creating,
  updating,
  deleting,
  success,
  failure,
  duplication,
}

class LocationMasterState extends Equatable {
  final LocationMasterStatus status;
  final List<LocationMaster> items;
  final List<LocationMaster> filteredItems;
  final List<LocationMaster> createItems;
  final List<LocationMaster> editItems;
  final List<LocationMaster> multiSelectionItems;
  final LocationMaster? selected;
  final LocationMaster? selected1;
  final LocationMaster? selected2;
  final String message;
  final String? error;
  final int companyId;

  // Dual List Model for item assignments
  final List<ItemInBranchModel> dualListSource;
  final List<ItemInBranchModel> dualListTarget;

  // UI State
  final int first;
  final String dataName;

  const LocationMasterState({
    this.status = LocationMasterStatus.initial,
    this.items = const [],
    this.filteredItems = const [],
    this.createItems = const [],
    this.editItems = const [],
    this.multiSelectionItems = const [],
    this.selected,
    this.selected1,
    this.selected2,
    this.message = '',
    this.error,
    this.companyId = 0,
    this.dualListSource = const [],
    this.dualListTarget = const [],
    this.first = 0,
    this.dataName = 'LocationMaster',
  });

  LocationMasterState copyWith({
    LocationMasterStatus? status,
    List<LocationMaster>? items,
    List<LocationMaster>? filteredItems,
    List<LocationMaster>? createItems,
    List<LocationMaster>? editItems,
    List<LocationMaster>? multiSelectionItems,
    LocationMaster? selected,
    LocationMaster? selected1,
    LocationMaster? selected2,
    String? message,
    String? error,
    int? companyId,
    List<ItemInBranchModel>? dualListSource,
    List<ItemInBranchModel>? dualListTarget,
    int? first,
    String? dataName,
  }) {
    return LocationMasterState(
      status: status ?? this.status,
      items: items ?? this.items,
      filteredItems: filteredItems ?? this.filteredItems,
      createItems: createItems ?? this.createItems,
      editItems: editItems ?? this.editItems,
      multiSelectionItems: multiSelectionItems ?? this.multiSelectionItems,
      selected: selected ?? this.selected,
      selected1: selected1 ?? this.selected1,
      selected2: selected2 ?? this.selected2,
      message: message ?? this.message,
      error: error ?? this.error,
      companyId: companyId ?? this.companyId,
      dualListSource: dualListSource ?? this.dualListSource,
      dualListTarget: dualListTarget ?? this.dualListTarget,
      first: first ?? this.first,
      dataName: dataName ?? this.dataName,
    );
  }

  @override
  List<Object?> get props => [
    status,
    message,
    companyId,
    items,
    filteredItems,
    createItems,
    editItems,
    multiSelectionItems,
    selected,
    selected1,
    selected2,
    dualListSource,
    dualListTarget,
    first,
    dataName,
  ];
}
