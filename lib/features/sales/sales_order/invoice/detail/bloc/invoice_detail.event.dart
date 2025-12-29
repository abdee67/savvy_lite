import 'package:equatable/equatable.dart';
import 'package:savvy_stock/features/sales/sales_order/invoice/detail/model/invoice_detail_model.dart';

// Base event class
abstract class InvoiceHistoryDetailEvent extends Equatable {
  const InvoiceHistoryDetailEvent();

  @override
  List<Object> get props => [];
}

// Initialization Events
class InvoiceHistoryDetailInitialized extends InvoiceHistoryDetailEvent {
  final int companyId;
  const InvoiceHistoryDetailInitialized({required this.companyId});

  @override
  List<Object> get props => [companyId];
}

class LoadInvoiceHistoryDetails extends InvoiceHistoryDetailEvent {
  final int companyId;
  const LoadInvoiceHistoryDetails({required this.companyId});

  @override
  List<Object> get props => [companyId];
}

// CRUD Operations
class CreateInvoiceHistoryDetail extends InvoiceHistoryDetailEvent {
  final InvoiceHistoryDetail detail;
  const CreateInvoiceHistoryDetail({required this.detail});

  @override
  List<Object> get props => [detail];
}

class UpdateInvoiceHistoryDetail extends InvoiceHistoryDetailEvent {
  final InvoiceHistoryDetail detail;
  const UpdateInvoiceHistoryDetail({required this.detail});

  @override
  List<Object> get props => [detail];
}

class DeleteInvoiceHistoryDetail extends InvoiceHistoryDetailEvent {
  final int id;
  const DeleteInvoiceHistoryDetail({required this.id});

  @override
  List<Object> get props => [id];
}

class DeleteMultipleInvoiceHistoryDetails extends InvoiceHistoryDetailEvent {
  final List<InvoiceHistoryDetail> details;
  const DeleteMultipleInvoiceHistoryDetails({required this.details});

  @override
  List<Object> get props => [details];
}

// Selection Management
class SelectInvoiceHistoryDetail extends InvoiceHistoryDetailEvent {
  final InvoiceHistoryDetail detail;
  const SelectInvoiceHistoryDetail({required this.detail});

  @override
  List<Object> get props => [detail];
}

class SelectMultipleInvoiceHistoryDetails extends InvoiceHistoryDetailEvent {
  final List<InvoiceHistoryDetail> details;
  const SelectMultipleInvoiceHistoryDetails({required this.details});

  @override
  List<Object> get props => [details];
}

class ClearSelection extends InvoiceHistoryDetailEvent {
  const ClearSelection();
}

// UI State Management
class PrepareCreate extends InvoiceHistoryDetailEvent {
  final int companyId;
  const PrepareCreate({required this.companyId});

  @override
  List<Object> get props => [companyId];
}

class PrepareCopy extends InvoiceHistoryDetailEvent {
  const PrepareCopy();
}

class PrepareCreateInCreate extends InvoiceHistoryDetailEvent {
  const PrepareCreateInCreate();
}

class PrepareCreate1 extends InvoiceHistoryDetailEvent {
  final int companyId;
  const PrepareCreate1({required this.companyId});

  @override
  List<Object> get props => [companyId];
}

class PrepareCreateInEdit extends InvoiceHistoryDetailEvent {
  const PrepareCreateInEdit();
}

class PrepareEdit extends InvoiceHistoryDetailEvent {
  const PrepareEdit();
}

class CancelUpdate extends InvoiceHistoryDetailEvent {
  const CancelUpdate();
}

class CancelCreate extends InvoiceHistoryDetailEvent {
  const CancelCreate();
}

class DiscardChanges extends InvoiceHistoryDetailEvent {
  const DiscardChanges();
}

// Filtering & Search
class FilterInvoiceHistoryDetails extends InvoiceHistoryDetailEvent {
  final InvoiceHistoryDetail filter;
  const FilterInvoiceHistoryDetails({required this.filter});

  @override
  List<Object> get props => [filter];
}

class SearchInvoiceHistoryDetails extends InvoiceHistoryDetailEvent {
  final String query;
  const SearchInvoiceHistoryDetails({required this.query});

  @override
  List<Object> get props => [query];
}

class ClearFilters extends InvoiceHistoryDetailEvent {
  const ClearFilters();
}

// Batch Operations
class Save extends InvoiceHistoryDetailEvent {
  const Save();
}

class SaveRow extends InvoiceHistoryDetailEvent {
  const SaveRow();
}

class SaveInEdit extends InvoiceHistoryDetailEvent {
  const SaveInEdit();
}

class CreateInEdit extends InvoiceHistoryDetailEvent {
  const CreateInEdit();
}

// Item Management in Lists
class RemoveInCreate extends InvoiceHistoryDetailEvent {
  final InvoiceHistoryDetail item;
  const RemoveInCreate({required this.item});

  @override
  List<Object> get props => [item];
}

class RemoveInEdit extends InvoiceHistoryDetailEvent {
  final InvoiceHistoryDetail item;
  const RemoveInEdit({required this.item});

  @override
  List<Object> get props => [item];
}

class RemoveRecord extends InvoiceHistoryDetailEvent {
  final InvoiceHistoryDetail item;
  const RemoveRecord({required this.item});

  @override
  List<Object> get props => [item];
}

class RemoveList extends InvoiceHistoryDetailEvent {
  final List<InvoiceHistoryDetail> aList;
  const RemoveList({required this.aList});

  @override
  List<Object> get props => [aList];
}

// Utility
class RefreshList extends InvoiceHistoryDetailEvent {
  const RefreshList();
}

// Header Integration Event (if needed for the Save method)
class SaveHeader extends InvoiceHistoryDetailEvent {
  const SaveHeader();
}
