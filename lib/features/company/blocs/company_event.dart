import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:savvy_stock/features/company/models/company_model.dart';

@immutable
abstract class CompanyEvent extends Equatable {
  const CompanyEvent();

  @override
  List<Object> get props => [];
}

class LoadCompanys extends CompanyEvent {
  final int companyId;
  const LoadCompanys(this.companyId);

  @override
  List<Object> get props => [companyId];
}

class CreateCompany extends CompanyEvent {
  final Company company;
  const CreateCompany(this.company);

  @override
  List<Object> get props => [Company];
}

class UpdateCompany extends CompanyEvent {
  final Company company;
  const UpdateCompany(this.company);

  @override
  List<Object> get props => [Company];
}

class DeleteCompany extends CompanyEvent {
  final int companyId;
  final Company deletedCompany;
  final int deletedIndex;

  const DeleteCompany({
    required this.companyId,
    required this.deletedCompany,
    required this.deletedIndex,
  });

  @override
  List<Object> get props => [companyId, deletedCompany, deletedIndex];
}

class SearchCompanys extends CompanyEvent {
  final String query;
  const SearchCompanys(this.query);

  @override
  List<Object> get props => [query];
}

class SelectCompany extends CompanyEvent {
  final Company company;
  final bool isSelected;
  const SelectCompany(this.company, this.isSelected);

  @override
  List<Object> get props => [Company, isSelected];
}

class SelectAllCompanys extends CompanyEvent {
  final List<Company> companys;
  const SelectAllCompanys(this.companys);

  @override
  List<Object> get props => [companys];
}

class ClearSelection extends CompanyEvent {
  const ClearSelection();

  @override
  List<Object> get props => [];
}

class SetCompanyForm extends CompanyEvent {
  final Company company;
  const SetCompanyForm(this.company);

  @override
  List<Object> get props => [company];
}

class DeleteSelectedCompanys extends CompanyEvent {
  final List<int> selectedCompanys;
  final List<Company> deletedCompanys;
  final List<int> deletedIndexes;

  const DeleteSelectedCompanys({
    required this.selectedCompanys,
    required this.deletedCompanys,
    required this.deletedIndexes,
  });

  @override
  List<Object> get props => [selectedCompanys, deletedCompanys, deletedIndexes];
}

class UndoDelete extends CompanyEvent {
  final List<Company> deletedItems;
  final List<int> deletedIndexes;

  const UndoDelete({required this.deletedItems, required this.deletedIndexes});

  @override
  List<Object> get props => [deletedItems, deletedIndexes];
}

class ShowCompanyDetail extends CompanyEvent {
  final Company company;
  const ShowCompanyDetail(this.company);

  @override
  List<Object> get props => [company];
}

class HideCompanyDetail extends CompanyEvent {
  const HideCompanyDetail();
}

class ExportCompany extends CompanyEvent {
  final List<Company> companysToExport;
  const ExportCompany(this.companysToExport);

  @override
  List<Object> get props => [companysToExport];
}

class ExportSingleCompany extends CompanyEvent {
  final Company companyToExport;
  const ExportSingleCompany(this.companyToExport);

  @override
  List<Object> get props => [companyToExport];
}
