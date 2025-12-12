// lib/features/purchase/supplier/bloc/supplier_event.dart
import 'package:equatable/equatable.dart';
import 'package:savvy_stock/features/purchase/supplier_entry/models/supplier_model.dart';

abstract class SupplierEvent extends Equatable {
  const SupplierEvent();

  @override
  List<Object?> get props => [];
}

// Initialization Events
class LoadSuppliers extends SupplierEvent {
  final int companyId;
  const LoadSuppliers(this.companyId);

  @override
  List<Object?> get props => [companyId];
}

class RefreshSuppliers extends SupplierEvent {
  final int companyId;
  const RefreshSuppliers(this.companyId);

  @override
  List<Object?> get props => [companyId];
}

// CRUD Events
class CreateSupplier extends SupplierEvent {
  final SupplierModel supplier;
  const CreateSupplier(this.supplier);

  @override
  List<Object?> get props => [supplier];
}

class CreateSupplierInEdit extends SupplierEvent {
  final SupplierModel supplier;
  const CreateSupplierInEdit(this.supplier);

  @override
  List<Object?> get props => [supplier];
}

class UpdateSupplier extends SupplierEvent {
  final SupplierModel supplier;
  const UpdateSupplier(this.supplier);

  @override
  List<Object?> get props => [supplier];
}

class DeleteSupplier extends SupplierEvent {
  final SupplierModel deletedItem;
  final int deletedIndex;
  const DeleteSupplier({required this.deletedItem, required this.deletedIndex});

  @override
  List<Object?> get props => [deletedItem, deletedIndex];
}

class DeleteSelectedSuppliers extends SupplierEvent {
  final List<int> selectedItems;
  final List<SupplierModel> deletedItems;
  final List<int> deletedIndexes;
  const DeleteSelectedSuppliers({
    required this.selectedItems,
    required this.deletedItems,
    required this.deletedIndexes,
  });

  @override
  List<Object?> get props => [selectedItems, deletedItems, deletedIndexes];
}

class SaveSuppliers extends SupplierEvent {
  final List<SupplierModel> suppliers;
  const SaveSuppliers(this.suppliers);

  @override
  List<Object?> get props => [suppliers];
}

class SaveSuppliersInEdit extends SupplierEvent {
  final List<SupplierModel> suppliers;
  const SaveSuppliersInEdit(this.suppliers);

  @override
  List<Object?> get props => [suppliers];
}

// Selection Events
class SetSelectedSupplier extends SupplierEvent {
  final SupplierModel? supplier;
  const SetSelectedSupplier(this.supplier);

  @override
  List<Object?> get props => [supplier];
}

class SetSelectedSupplier1 extends SupplierEvent {
  final SupplierModel supplier;
  const SetSelectedSupplier1(this.supplier);

  @override
  List<Object?> get props => [supplier];
}

class SetSelectedSupplier2 extends SupplierEvent {
  final SupplierModel supplier;
  const SetSelectedSupplier2(this.supplier);

  @override
  List<Object?> get props => [supplier];
}

class SetMultiSelectionSuppliers extends SupplierEvent {
  final List<SupplierModel> suppliers;
  const SetMultiSelectionSuppliers(this.suppliers);

  @override
  List<Object?> get props => [suppliers];
}

// Creation Mode Events
class PrepareCreateSupplier extends SupplierEvent {
  final int companyId;
  final int tempId;
  const PrepareCreateSupplier(this.companyId, this.tempId);

  @override
  List<Object?> get props => [companyId, tempId];
}

class PrepareCreateSupplierInCreate extends SupplierEvent {
  final int companyId;
  const PrepareCreateSupplierInCreate(this.companyId);

  @override
  List<Object?> get props => [companyId];
}

class PrepareCreateSupplierInEdit extends SupplierEvent {
  final int companyId;
  const PrepareCreateSupplierInEdit(this.companyId);

  @override
  List<Object?> get props => [companyId];
}

class PrepareEditSupplier extends SupplierEvent {
  final SupplierModel supplier;
  const PrepareEditSupplier(this.supplier);

  @override
  List<Object?> get props => [supplier];
}

class CopySupplier extends SupplierEvent {
  final SupplierModel supplier;
  final int companyId;
  const CopySupplier(this.supplier, this.companyId);

  @override
  List<Object?> get props => [supplier, companyId];
}

class PrepareCreate1 extends SupplierEvent {
  final int companyId;
  const PrepareCreate1(this.companyId);

  @override
  List<Object?> get props => [companyId];
}

// List Management Events
class AddToCreateList extends SupplierEvent {
  final SupplierModel supplier;
  const AddToCreateList(this.supplier);

  @override
  List<Object?> get props => [supplier];
}

class RemoveFromCreateList extends SupplierEvent {
  final SupplierModel supplier;
  final int index;
  const RemoveFromCreateList(this.supplier, this.index);

  @override
  List<Object?> get props => [supplier, index];
}

class RemoveFromEditList extends SupplierEvent {
  final SupplierModel supplier;
  final int index;
  const RemoveFromEditList(this.supplier, this.index);

  @override
  List<Object?> get props => [supplier, index];
}

class ClearCreateList extends SupplierEvent {}

class ClearEditList extends SupplierEvent {}

class ClearSelection extends SupplierEvent {}

// UI Events
class CancelCreate extends SupplierEvent {}

class CancelUpdate extends SupplierEvent {}

class DiscardChanges extends SupplierEvent {}

class SaveRow extends SupplierEvent {
  final SupplierModel supplier;
  const SaveRow(this.supplier);

  @override
  List<Object?> get props => [supplier];
}

class SaveInEdit extends SupplierEvent {
  final List<SupplierModel> suppliers;
  const SaveInEdit(this.suppliers);

  @override
  List<Object?> get props => [suppliers];
}

class RemoveRecord extends SupplierEvent {
  final SupplierModel supplier;
  const RemoveRecord(this.supplier);

  @override
  List<Object?> get props => [supplier];
}

class RemoveList extends SupplierEvent {
  final List<SupplierModel> suppliers;
  const RemoveList(this.suppliers);

  @override
  List<Object?> get props => [suppliers];
}

// Filter & Search Events
class FilterSuppliers extends SupplierEvent {
  final String query;
  final int companyId;
  const FilterSuppliers(this.query, this.companyId);

  @override
  List<Object?> get props => [query, companyId];
}

class SearchSuppliers extends SupplierEvent {
  final String query;
  final int companyId;
  const SearchSuppliers(this.query, this.companyId);

  @override
  List<Object?> get props => [query, companyId];
}

// Selection Events for UI
class SelectSupplier extends SupplierEvent {
  final SupplierModel supplier;
  final bool isSelected;
  const SelectSupplier(this.supplier, this.isSelected);

  @override
  List<Object?> get props => [supplier, isSelected];
}

class SelectAllSuppliers extends SupplierEvent {
  final List<SupplierModel> suppliers;
  const SelectAllSuppliers(this.suppliers);

  @override
  List<Object?> get props => [suppliers];
}

// Navigation Events
class SaveAndClose extends SupplierEvent {
  final String routeName;
  const SaveAndClose(this.routeName);

  @override
  List<Object?> get props => [routeName];
}

class SaveAndAddNew extends SupplierEvent {
  final String routeName;
  final int companyId;
  const SaveAndAddNew(this.routeName, this.companyId);

  @override
  List<Object?> get props => [routeName, companyId];
}

class SaveAndContinue extends SupplierEvent {
  final String routeName;
  final SupplierModel supplier;
  const SaveAndContinue(this.routeName, this.supplier);

  @override
  List<Object?> get props => [routeName, supplier];
}

// UI State Events
class SetFirstItemIndex extends SupplierEvent {
  final int firstIndex;
  const SetFirstItemIndex(this.firstIndex);

  @override
  List<Object?> get props => [firstIndex];
}

class ClearMessages extends SupplierEvent {}

class ValidateSupplier extends SupplierEvent {
  final SupplierModel supplier;
  const ValidateSupplier(this.supplier);

  @override
  List<Object?> get props => [supplier];
}
