import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:savvy_stock/features/FSNMR/models/fast_slow_nonmoving_rule.dart';

@immutable
abstract class FSNMREvent extends Equatable {
  const FSNMREvent();

  @override
  List<Object> get props => [];
}

class LoadRules extends FSNMREvent {
  final int companyId;
  const LoadRules(this.companyId);

  @override
  List<Object> get props => [companyId];
}

class CreateRule extends FSNMREvent {
  final FastSlowNonMovingRule rule;
  const CreateRule(this.rule);

  @override
  List<Object> get props => [rule];
}

class UpdateRule extends FSNMREvent {
  final FastSlowNonMovingRule rule;
  const UpdateRule(this.rule);

  @override
  List<Object> get props => [rule];
}

class DeleteRule extends FSNMREvent {
  final int ruleId;
  final FastSlowNonMovingRule deletedRule;
  final int deletedIndex;

  const DeleteRule({
    required this.ruleId,
    required this.deletedRule,
    required this.deletedIndex,
  });

  @override
  List<Object> get props => [ruleId, deletedRule, deletedIndex];
}

// Filter and search events
class FilterRuleList extends FSNMREvent {
  const FilterRuleList();
}

class SearchRules extends FSNMREvent {
  final String query;
  const SearchRules(this.query);

  @override
  List<Object> get props => [query];
}

class SelectRule extends FSNMREvent {
  final FastSlowNonMovingRule rule;
  final bool isSelected;
  const SelectRule(this.rule, this.isSelected);

  @override
  List<Object> get props => [rule, isSelected];
}

class SelectAllRules extends FSNMREvent {
  final List<FastSlowNonMovingRule> rules;
  const SelectAllRules(this.rules);

  @override
  List<Object> get props => [rules];
}

class ClearSelection extends FSNMREvent {
  const ClearSelection();

  @override
  List<Object> get props => [];
}

class SetRuleForm extends FSNMREvent {
  final FastSlowNonMovingRule rule;
  const SetRuleForm(this.rule);

  @override
  List<Object> get props => [rule];
}

class DeleteSelectedRules extends FSNMREvent {
  final List<int> selectedRules;
  final List<FastSlowNonMovingRule> deletedRules;
  final List<int> deletedIndexes;

  const DeleteSelectedRules({
    required this.selectedRules,
    required this.deletedRules,
    required this.deletedIndexes,
  });

  @override
  List<Object> get props => [selectedRules, deletedRules, deletedIndexes];
}

// Preparation events (from Java controller)
class PrepareCreate extends FSNMREvent {}

class PrepareCreateInCreate extends FSNMREvent {}

// Complex business operations (from Java controller)
class SaveRow extends FSNMREvent {
  final FastSlowNonMovingRule rule;

  const SaveRow(this.rule);
}

class SaveRowMain extends FSNMREvent {
  final FastSlowNonMovingRule rule;

  const SaveRowMain(this.rule);
}

/// Event for saving/updating a rule with full validation (equivalent to Java's saveInEdit)
class SaveInEdit extends FSNMREvent {
  final FastSlowNonMovingRule rule;

  const SaveInEdit(this.rule);

  @override
  List<Object> get props => [rule];
}

class CancelUpdate extends FSNMREvent {
  const CancelUpdate();
}

class CancelCreate extends FSNMREvent {
  const CancelCreate();
}

class DiscardChanges extends FSNMREvent {
  const DiscardChanges();
}

class RefreshList extends FSNMREvent {
  const RefreshList();
}

class RefreshList1 extends FSNMREvent {
  const RefreshList1();
}

/*class LoadRuleReport extends FSNMREvent {
  final int companyId;
  final RuleReportFilters filters;
  final int page;
  final int pageSize;

  const LoadRuleReport({
    required this.companyId,
    required this.filters,
    this.page = 1,
    this.pageSize = 20,
  });

  @override
  List<Object> get props => [companyId, filters, page, pageSize];
}

class LoadMoreRuleReport extends FSNMREvent {}

class UpdateRuleReportFilters extends FSNMREvent {
  final RuleReportFilters filters;

  const UpdateRuleReportFilters(this.filters);

  @override
  List<Object> get props => [filters];
}

class ClearRuleReportFilters extends FSNMREvent {}

class ExportRuleReportToExcel extends FSNMREvent {
  final RuleReportFilters filters;

  const ExportRuleReportToExcel(this.filters);

  @override
  List<Object> get props => [filters];
}

class ExportRuleReportToPDF extends FSNMREvent {
  final RuleReportFilters filters;

  const ExportRuleReportToPDF(this.filters);

  @override
  List<Object> get props => [filters];
}
*/
