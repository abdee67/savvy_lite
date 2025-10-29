import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:savvy_stock/features/branch_list/models/branch_list_model.dart';

@immutable
abstract class BranchEvent extends Equatable {
  const BranchEvent();

  @override
  List<Object> get props => [];
}

class LoadBranchs extends BranchEvent {
  final int companyId;
  const LoadBranchs(this.companyId);

  @override
  List<Object> get props => [companyId];
}

class CreateBranch extends BranchEvent {
  final Branch branch;
  const CreateBranch(this.branch);

  @override
  List<Object> get props => [Branch];
}

class UpdateBranch extends BranchEvent {
  final Branch branch;
  const UpdateBranch(this.branch);

  @override
  List<Object> get props => [Branch];
}

class DeleteBranch extends BranchEvent {
  final int branchId;
  final Branch deletedBranch;
  final int deletedIndex;

  const DeleteBranch({
    required this.branchId,
    required this.deletedBranch,
    required this.deletedIndex,
  });

  @override
  List<Object> get props => [branchId, deletedBranch, deletedIndex];
}

class SearchBranchs extends BranchEvent {
  final String query;
  const SearchBranchs(this.query);

  @override
  List<Object> get props => [query];
}

class SelectBranch extends BranchEvent {
  final Branch branch;
  final bool isSelected;
  const SelectBranch(this.branch, this.isSelected);

  @override
  List<Object> get props => [Branch, isSelected];
}

class SelectAllBranchs extends BranchEvent {
  final List<Branch> branchs;
  const SelectAllBranchs(this.branchs);

  @override
  List<Object> get props => [branchs];
}

class ClearSelection extends BranchEvent {
  const ClearSelection();

  @override
  List<Object> get props => [];
}

class SetBranchForm extends BranchEvent {
  final Branch branch;
  const SetBranchForm(this.branch);

  @override
  List<Object> get props => [branch];
}

class DeleteSelectedBranchs extends BranchEvent {
  final List<int> selectedBranchs;
  final List<Branch> deletedBranchs;
  final List<int> deletedIndexes;

  const DeleteSelectedBranchs({
    required this.selectedBranchs,
    required this.deletedBranchs,
    required this.deletedIndexes,
  });

  @override
  List<Object> get props => [selectedBranchs, deletedBranchs, deletedIndexes];
}

class UndoDelete extends BranchEvent {
  final List<Branch> deletedItems;
  final List<int> deletedIndexes;

  const UndoDelete({required this.deletedItems, required this.deletedIndexes});

  @override
  List<Object> get props => [deletedItems, deletedIndexes];
}

class ShowBranchDetail extends BranchEvent {
  final Branch branch;
  const ShowBranchDetail(this.branch);

  @override
  List<Object> get props => [branch];
}

class HideBranchDetail extends BranchEvent {
  const HideBranchDetail();
}

class ExportBranch extends BranchEvent {
  final List<Branch> branchsToExport;
  const ExportBranch(this.branchsToExport);

  @override
  List<Object> get props => [branchsToExport];
}

class ExportSingleBranch extends BranchEvent {
  final Branch branchToExport;
  const ExportSingleBranch(this.branchToExport);

  @override
  List<Object> get props => [branchToExport];
}
