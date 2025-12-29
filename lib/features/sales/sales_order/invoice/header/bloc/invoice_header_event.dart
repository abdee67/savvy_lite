import 'package:equatable/equatable.dart';
import 'package:savvy_stock/features/sales/sales_order/invoice/header/model/invoice_header_model.dart';

// Base event class
abstract class InvoiceHistoryHeaderEvent extends Equatable {
  const InvoiceHistoryHeaderEvent();

  @override
  List<Object> get props => [];
}

// Initialization Events
class InvoiceHistoryHeaderInitialized extends InvoiceHistoryHeaderEvent {
  final int companyId;
  const InvoiceHistoryHeaderInitialized({required this.companyId});

  @override
  List<Object> get props => [companyId];
}

class LoadInvoiceHistoryHeaders extends InvoiceHistoryHeaderEvent {
  final int companyId;
  const LoadInvoiceHistoryHeaders({required this.companyId});

  @override
  List<Object> get props => [companyId];
}

// CRUD Operations
class CreateInvoiceHistoryHeader extends InvoiceHistoryHeaderEvent {
  final InvoiceHistoryHeader header;
  const CreateInvoiceHistoryHeader({required this.header});

  @override
  List<Object> get props => [header];
}

class UpdateInvoiceHistoryHeader extends InvoiceHistoryHeaderEvent {
  final InvoiceHistoryHeader header;
  const UpdateInvoiceHistoryHeader({required this.header});

  @override
  List<Object> get props => [header];
}

class DeleteInvoiceHistoryHeader extends InvoiceHistoryHeaderEvent {
  final int id;
  const DeleteInvoiceHistoryHeader({required this.id});

  @override
  List<Object> get props => [id];
}

class DeleteMultipleInvoiceHistoryHeaders extends InvoiceHistoryHeaderEvent {
  final List<InvoiceHistoryHeader> headers;
  const DeleteMultipleInvoiceHistoryHeaders({required this.headers});

  @override
  List<Object> get props => [headers];
}

// Selection Management
class SelectInvoiceHistoryHeader extends InvoiceHistoryHeaderEvent {
  final InvoiceHistoryHeader header;
  const SelectInvoiceHistoryHeader({required this.header});

  @override
  List<Object> get props => [header];
}

class SelectMultipleInvoiceHistoryHeaders extends InvoiceHistoryHeaderEvent {
  final List<InvoiceHistoryHeader> headers;
  const SelectMultipleInvoiceHistoryHeaders({required this.headers});

  @override
  List<Object> get props => [headers];
}

class ClearSelection extends InvoiceHistoryHeaderEvent {
  const ClearSelection();
}

// UI State Management
class PrepareCreate extends InvoiceHistoryHeaderEvent {
  final int companyId;
  const PrepareCreate({required this.companyId});

  @override
  List<Object> get props => [companyId];
}

class PrepareCopy extends InvoiceHistoryHeaderEvent {
  const PrepareCopy();
}

class PrepareCreateInCreate extends InvoiceHistoryHeaderEvent {
  const PrepareCreateInCreate();
}

class PrepareCreate1 extends InvoiceHistoryHeaderEvent {
  final int companyId;
  const PrepareCreate1({required this.companyId});

  @override
  List<Object> get props => [companyId];
}

class PrepareCreateInEdit extends InvoiceHistoryHeaderEvent {
  const PrepareCreateInEdit();
}

class PrepareEdit extends InvoiceHistoryHeaderEvent {
  const PrepareEdit();
}

class CancelUpdate extends InvoiceHistoryHeaderEvent {
  const CancelUpdate();
}

class CancelCreate extends InvoiceHistoryHeaderEvent {
  const CancelCreate();
}

class DiscardChanges extends InvoiceHistoryHeaderEvent {
  const DiscardChanges();
}

// Filtering & Search
class FilterInvoiceHistoryHeaders extends InvoiceHistoryHeaderEvent {
  final InvoiceHistoryHeader filter;
  final DateTime? startDate;
  final DateTime? endDate;
  const FilterInvoiceHistoryHeaders({
    required this.filter,
    this.startDate,
    this.endDate,
  });

  @override
  List<Object> get props => [filter, startDate ?? '', endDate ?? ''];
}

class SearchInvoiceHistoryHeaders extends InvoiceHistoryHeaderEvent {
  final String query;
  const SearchInvoiceHistoryHeaders({required this.query});

  @override
  List<Object> get props => [query];
}

class ClearFilters extends InvoiceHistoryHeaderEvent {
  const ClearFilters();
}

// Batch Operations
class SaveRow extends InvoiceHistoryHeaderEvent {
  const SaveRow();
}

class SaveInEdit extends InvoiceHistoryHeaderEvent {
  const SaveInEdit();
}

class CreateInEdit extends InvoiceHistoryHeaderEvent {
  const CreateInEdit();
}

// Item Management in Lists
class RemoveInCreate extends InvoiceHistoryHeaderEvent {
  final InvoiceHistoryHeader item;
  const RemoveInCreate({required this.item});

  @override
  List<Object> get props => [item];
}

class RemoveInEdit extends InvoiceHistoryHeaderEvent {
  final InvoiceHistoryHeader item;
  const RemoveInEdit({required this.item});

  @override
  List<Object> get props => [item];
}

class RemoveRecord extends InvoiceHistoryHeaderEvent {
  final InvoiceHistoryHeader item;
  const RemoveRecord({required this.item});

  @override
  List<Object> get props => [item];
}

class RemoveList extends InvoiceHistoryHeaderEvent {
  final List<InvoiceHistoryHeader> aList;
  const RemoveList({required this.aList});

  @override
  List<Object> get props => [aList];
}

// Utility
class RefreshList extends InvoiceHistoryHeaderEvent {
  const RefreshList();
}
