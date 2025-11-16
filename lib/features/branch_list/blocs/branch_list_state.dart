import 'package:equatable/equatable.dart';
import 'package:savvy_stock/features/branch_list/models/branch_list_model.dart';

enum BranchStatus {
  initial,
  loading,
  searching,
  success,
  failure,
  creating,
  updating,
  deleting,
  exporting,
}

enum BranchDetailStatus { hidden, showing, editing }

class BranchState extends Equatable {
  final BranchStatus status;
  final String? message;
  final int? branchId;
  final int? companyId;
  final List<Branch> branchs;
  final List<Branch> filteredBranchs;
  final String searchQuery;
  final List<Branch> selectedBranchs;
  final Branch? branchForm;

  final BranchDetailStatus detailStatus;
  final Branch? branchDetail;

  final List<Branch> recentlyDeleted;
  final List<int> recentlyDeletedIndexes;

  final bool isExporting;
  final List<Branch> exportedBranchs; //export multiple Branchs
  final Branch? exportedBranch; //export single Branch

  // Role management state

  const BranchState({
    this.status = BranchStatus.initial,
    this.message,
    this.branchId,
    this.companyId,
    this.branchs = const [],
    this.filteredBranchs = const [],
    this.searchQuery = '',
    this.selectedBranchs = const [],
    this.branchForm,
    this.detailStatus = BranchDetailStatus.hidden,
    this.branchDetail,
    this.recentlyDeleted = const [],
    this.recentlyDeletedIndexes = const [],
    this.isExporting = false,
    this.exportedBranchs = const [],
    this.exportedBranch,
  });

  // --- Helper Getters ---
  bool get isLoading => status == BranchStatus.loading;
  bool get isSuccess => status == BranchStatus.success;
  bool get isFailure => status == BranchStatus.failure;
  bool get isCreating => status == BranchStatus.creating;
  bool get isUpdating => status == BranchStatus.updating;
  bool get isDeleting => status == BranchStatus.deleting;
  bool get isExportingData => status == BranchStatus.exporting;

  bool get isDetailVisible => detailStatus != BranchDetailStatus.hidden;
  bool get isDetailEditing => detailStatus == BranchDetailStatus.editing;

  bool get hasBranchs => branchs.isNotEmpty;
  bool get hasFilteredBranchs => filteredBranchs.isNotEmpty;
  bool get hasSelection => selectedBranchs.isNotEmpty;
  bool get canEdit => selectedBranchs.length == 1;
  bool get canDelete => selectedBranchs.isNotEmpty;
  bool get canExport => filteredBranchs.isNotEmpty;

  bool get hasRecentDeletions => recentlyDeleted.isNotEmpty;

  // --- CopyWith for immutability ---
  BranchState copyWith({
    BranchStatus? status,
    String? message,
    int? branchId,
    int? companyId,
    List<Branch>? branchs,
    List<Branch>? filteredBranchs,
    String? searchQuery,
    List<Branch>? selectedBranchs,
    Branch? branchForm,
    BranchDetailStatus? detailStatus,
    Branch? branchDetail,
    List<Branch>? recentlyDeleted,
    List<int>? recentlyDeletedIndexes,
    bool? isExporting,
    List<Branch>? exportedBranchs,
    Branch? exportedBranch,
  }) {
    return BranchState(
      status: status ?? this.status,
      message: message ?? this.message,
      branchId: branchId ?? this.branchId,
      companyId: companyId ?? this.companyId,
      branchs: branchs ?? this.branchs,
      filteredBranchs: filteredBranchs ?? this.filteredBranchs,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedBranchs: selectedBranchs ?? this.selectedBranchs,
      branchForm: branchForm ?? this.branchForm,
      detailStatus: detailStatus ?? this.detailStatus,
      branchDetail: branchDetail ?? this.branchDetail,
      recentlyDeleted: recentlyDeleted ?? this.recentlyDeleted,
      recentlyDeletedIndexes:
          recentlyDeletedIndexes ?? this.recentlyDeletedIndexes,
      isExporting: isExporting ?? this.isExporting,
      exportedBranchs: exportedBranchs ?? this.exportedBranchs,
      exportedBranch: exportedBranch ?? this.exportedBranch,
    );
  }

  @override
  List<Object?> get props => [
    status,
    message,
    branchId,
    companyId,
    branchs,
    filteredBranchs,
    searchQuery,
    selectedBranchs,
    branchForm,
    detailStatus,
    branchDetail,
    recentlyDeleted,
    recentlyDeletedIndexes,
    isExporting,
    exportedBranchs,
    exportedBranch,
  ];
}
