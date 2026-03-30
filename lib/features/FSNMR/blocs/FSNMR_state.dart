import 'package:savvy_stock/features/FSNMR/models/fast_slow_nonmoving_rule.dart';

enum FSNMRStatus {
  initial,
  loading,
  loaded,
  creating,
  updating,
  deleting,
  searching,
  success,
  failure,
  duplication,
  editing,
  loadingRuleReport,
  loadedRuleReport,
  loadingMoreRuleReport,
  exportingReport,
  exportReportSuccess,
}

//enum FSNMRDetailStatus { hidden, showing, editing }

class FSNMRState {
  final FSNMRStatus status;
  final String? message;
  final int? ruleId;
  final int? companyId;
  final List<FastSlowNonMovingRule> rules;
  final List<FastSlowNonMovingRule> filteredRules;
  final String searchQuery;
  final List<FastSlowNonMovingRule> selectedRules;
  final FastSlowNonMovingRule? ruleForm;

  //final FSNMRDetailStatus detailStatus;
  // final FastSlowNonMovingRule? ruleDetail;

  final List<FastSlowNonMovingRule> recentlyDeleted;
  final List<int> recentlyDeletedIndexes;

  //final bool showDetailPanel;

  // Advanced data fields from Java controller
  final List<FastSlowNonMovingRule> multiselectionRules;
  List<FastSlowNonMovingRule> createRules;
  List<FastSlowNonMovingRule> editRules;
  final List<FastSlowNonMovingRule> filteredValues;
  FastSlowNonMovingRule? selected;
  final FastSlowNonMovingRule? selected1;
  final FastSlowNonMovingRule? selected2;
  final FastSlowNonMovingRule? selected3;

  final List<FastSlowNonMovingRule> ruleReportRules;

  ///final RuleReportFilters ruleReportFilters;
  final int ruleReportPage;
  final int ruleReportTotalPages;
  final int ruleReportTotalCount;
  final double ruleReportTotalCost;
  final bool hasMoreRuleReport;
  final String exportReportMessage;

  FSNMRState({
    this.status = FSNMRStatus.initial,
    this.message,
    this.ruleId,
    this.companyId,
    this.rules = const [],
    this.filteredRules = const [],
    this.searchQuery = '',
    this.selectedRules = const [],
    this.ruleForm,
    //  this.detailStatus = FSNMRDetailStatus.hidden,
    //this.ruleDetail,
    this.recentlyDeleted = const [],
    this.recentlyDeletedIndexes = const [],
    // this.showDetailPanel = false,
    this.multiselectionRules = const [],
    this.createRules = const [],
    this.editRules = const [],
    this.filteredValues = const [],
    this.selected,
    this.selected1,
    this.selected2,
    this.selected3,
    this.ruleReportRules = const [],
    //  this.ruleReportFilters = const RuleReportFilters(),
    this.ruleReportPage = 0,
    this.ruleReportTotalPages = 0,
    this.ruleReportTotalCount = 0,
    this.ruleReportTotalCost = 0,
    this.hasMoreRuleReport = false,
    this.exportReportMessage = '',
  });

  // --- Helper Getters ---
  bool get isLoading => status == FSNMRStatus.loading;
  bool get isSuccess => status == FSNMRStatus.success;
  bool get isFailure => status == FSNMRStatus.failure;
  bool get isCreating => status == FSNMRStatus.creating;
  bool get isUpdating => status == FSNMRStatus.updating;
  bool get isDeleting => status == FSNMRStatus.deleting;
  bool get isEditing => status == FSNMRStatus.editing;
  bool get isDuplication => status == FSNMRStatus.duplication;
  bool get isLoaded => status == FSNMRStatus.loaded;
  bool get isSearching => status == FSNMRStatus.searching;
  bool get isInitial => status == FSNMRStatus.initial;

  //  bool get isDetailVisible => detailStatus != FSNMRDetailStatus.hidden;
  //bool get isDetailEditing => detailStatus == FSNMRDetailStatus.editing;

  bool get hasRules => rules.isNotEmpty;
  bool get hasFilteredRules => filteredRules.isNotEmpty;
  bool get hasSelection => selectedRules.isNotEmpty;
  bool get canEdit => selectedRules.length == 1;
  bool get canDelete => selectedRules.isNotEmpty;
  bool get canExport => filteredRules.isNotEmpty;
  bool get hasRuleReport => ruleReportRules.isNotEmpty;
  bool get hasPreviousPage => ruleReportPage > 1;
  bool get hasNextPage => ruleReportPage < ruleReportTotalPages;

  bool get hasRecentDeletions => recentlyDeleted.isNotEmpty;

  // --- CopyWith for immutability ---
  FSNMRState copyWith({
    FSNMRStatus? status,
    String? message,
    int? ruleId,
    int? companyId,
    List<FastSlowNonMovingRule>? rules,
    List<FastSlowNonMovingRule>? filteredRules,
    String? searchQuery,
    List<FastSlowNonMovingRule>? selectedRules,
    FastSlowNonMovingRule? ruleForm,
    // FSNMRDetailStatus? detailStatus,
    FastSlowNonMovingRule? ruleDetail,
    List<FastSlowNonMovingRule>? recentlyDeleted,
    List<int>? recentlyDeletedIndexes,
    //bool? showDetailPanel,
    List<FastSlowNonMovingRule>? exportedRules,
    FastSlowNonMovingRule? exportedRule,
    List<FastSlowNonMovingRule>? multiselectionRules,
    List<FastSlowNonMovingRule>? createRules,
    List<FastSlowNonMovingRule>? editRules,
    List<FastSlowNonMovingRule>? filteredValues,
    FastSlowNonMovingRule? selected,
    FastSlowNonMovingRule? selected1,
    FastSlowNonMovingRule? selected2,
    FastSlowNonMovingRule? selected3,
    List<FastSlowNonMovingRule>? barcodeRules,
    List<FastSlowNonMovingRule>? ruleReportRules,
    // RuleReportFilters? ruleReportFilters,
    int? ruleReportPage,
    int? ruleReportTotalPages,
    int? ruleReportTotalCount,
    double? ruleReportTotalCost,
    bool? hasMoreRuleReport,
    String? exportReportMessage,
  }) {
    return FSNMRState(
      status: status ?? this.status,
      message: message ?? this.message,
      ruleId: ruleId ?? this.ruleId,
      companyId: companyId ?? this.companyId,
      rules: rules ?? this.rules,
      filteredRules: filteredRules ?? this.filteredRules,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedRules: selectedRules ?? this.selectedRules,
      ruleForm: ruleForm ?? this.ruleForm,
      // detailStatus: detailStatus ?? this.detailStatus,
      //ruleDetail: ruleDetail ?? this.ruleDetail,
      recentlyDeleted: recentlyDeleted ?? this.recentlyDeleted,
      recentlyDeletedIndexes:
          recentlyDeletedIndexes ?? this.recentlyDeletedIndexes,
      //showDetailPanel: showDetailPanel ?? this.showDetailPanel,
      multiselectionRules: multiselectionRules ?? this.multiselectionRules,
      createRules: createRules ?? this.createRules,
      editRules: editRules ?? this.editRules,
      filteredValues: filteredValues ?? this.filteredValues,
      selected: selected ?? this.selected,
      selected1: selected1 ?? this.selected1,
      selected2: selected2 ?? this.selected2,
      selected3: selected3 ?? this.selected3,
      ruleReportRules: ruleReportRules ?? this.ruleReportRules,
      //  ruleReportFilters: ruleReportFilters ?? this.ruleReportFilters,
      ruleReportPage: ruleReportPage ?? this.ruleReportPage,
      ruleReportTotalPages: ruleReportTotalPages ?? this.ruleReportTotalPages,
      ruleReportTotalCount: ruleReportTotalCount ?? this.ruleReportTotalCount,
      ruleReportTotalCost: ruleReportTotalCost ?? this.ruleReportTotalCost,
      hasMoreRuleReport: hasMoreRuleReport ?? this.hasMoreRuleReport,
      exportReportMessage: exportReportMessage ?? this.exportReportMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    message,
    ruleId,
    companyId,
    rules,
    filteredRules,
    searchQuery,
    selectedRules,
    ruleForm,
    //detailStatus,
    //ruleDetail,
    recentlyDeleted,
    recentlyDeletedIndexes,
    //showDetailPanel,
    multiselectionRules,
    createRules,
    editRules,
    filteredValues,
    selected,
    selected1,
    selected2,
    selected3,
    ruleReportRules,
    //ruleReportFilters,
    ruleReportPage,
    ruleReportTotalPages,
    ruleReportTotalCount,
    ruleReportTotalCost,
    hasMoreRuleReport,
    exportReportMessage,
  ];
}
