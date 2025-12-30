import 'package:equatable/equatable.dart';
import 'package:savvy_stock/features/company/models/company_model.dart';

enum CompanyStatus {
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

enum CompanyDetailStatus { hidden, showing, editing }

class CompanyState extends Equatable {
  final CompanyStatus status;
  final String? message;
  final int? companyId;
  final List<Company> companys;
  final List<Company> filteredCompanys;
  final String searchQuery;
  final List<Company> selectedCompanys;
  final Company? companyForm;

  final CompanyDetailStatus detailStatus;
  final Company? companyDetail;

  final List<Company> recentlyDeleted;
  final List<int> recentlyDeletedIndexes;

  final bool isExporting;
  final List<Company> exportedCompanys; //export multiple Companys
  final Company? exportedCompany; //export single Company

  // Role management state

  const CompanyState({
    this.status = CompanyStatus.initial,
    this.message,
    this.companyId,
    this.companys = const [],
    this.filteredCompanys = const [],
    this.searchQuery = '',
    this.selectedCompanys = const [],
    this.companyForm,
    this.detailStatus = CompanyDetailStatus.hidden,
    this.companyDetail,
    this.recentlyDeleted = const [],
    this.recentlyDeletedIndexes = const [],
    this.isExporting = false,
    this.exportedCompanys = const [],
    this.exportedCompany,
  });

  // --- Helper Getters ---
  bool get isLoading => status == CompanyStatus.loading;
  bool get isSuccess => status == CompanyStatus.success;
  bool get isFailure => status == CompanyStatus.failure;
  bool get isCreating => status == CompanyStatus.creating;
  bool get isUpdating => status == CompanyStatus.updating;
  bool get isDeleting => status == CompanyStatus.deleting;
  bool get isExportingData => status == CompanyStatus.exporting;

  bool get isDetailVisible => detailStatus != CompanyDetailStatus.hidden;
  bool get isDetailEditing => detailStatus == CompanyDetailStatus.editing;

  bool get hasCompanys => companys.isNotEmpty;
  bool get hasFilteredCompanys => filteredCompanys.isNotEmpty;
  bool get hasSelection => selectedCompanys.isNotEmpty;
  bool get canEdit => selectedCompanys.length == 1;
  bool get canDelete => selectedCompanys.isNotEmpty;
  bool get canExport => filteredCompanys.isNotEmpty;

  bool get hasRecentDeletions => recentlyDeleted.isNotEmpty;

  // --- CopyWith for immutability ---
  CompanyState copyWith({
    CompanyStatus? status,
    String? message,
    int? companyId,
    List<Company>? companys,
    List<Company>? filteredCompanys,
    String? searchQuery,
    List<Company>? selectedCompanys,
    Company? companyForm,
    CompanyDetailStatus? detailStatus,
    Company? companyDetail,
    List<Company>? recentlyDeleted,
    List<int>? recentlyDeletedIndexes,
    bool? isExporting,
    List<Company>? exportedCompanys,
    Company? exportedCompany,
  }) {
    return CompanyState(
      status: status ?? this.status,
      message: message ?? this.message,
      companyId: companyId ?? this.companyId,
      companys: companys ?? this.companys,
      filteredCompanys: filteredCompanys ?? this.filteredCompanys,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCompanys: selectedCompanys ?? this.selectedCompanys,
      companyForm: companyForm ?? this.companyForm,
      detailStatus: detailStatus ?? this.detailStatus,
      companyDetail: companyDetail ?? this.companyDetail,
      recentlyDeleted: recentlyDeleted ?? this.recentlyDeleted,
      recentlyDeletedIndexes:
          recentlyDeletedIndexes ?? this.recentlyDeletedIndexes,
      isExporting: isExporting ?? this.isExporting,
      exportedCompanys: exportedCompanys ?? this.exportedCompanys,
      exportedCompany: exportedCompany ?? this.exportedCompany,
    );
  }

  @override
  List<Object?> get props => [
    status,
    message,
    companyId,
    companys,
    filteredCompanys,
    searchQuery,
    selectedCompanys,
    companyForm,
    detailStatus,
    companyDetail,
    recentlyDeleted,
    recentlyDeletedIndexes,
    isExporting,
    exportedCompanys,
    exportedCompany,
  ];
}
