// features/sales/customer/blocs/customer_event.dart
import 'package:equatable/equatable.dart';
import 'package:savvy_stock/features/sales/customer/models/customer_model.dart';

abstract class CustomerEvent extends Equatable {
  const CustomerEvent();

  @override
  List<Object> get props => [];
}

class LoadCustomers extends CustomerEvent {
  final int companyId;
  const LoadCustomers(this.companyId);

  @override
  List<Object> get props => [companyId];
}

class SaveCustomer extends CustomerEvent {
  final Customer customer;
  const SaveCustomer(this.customer);

  @override
  List<Object> get props => [customer];
}

class UpdateCustomer extends CustomerEvent {
  final Customer customer;
  const UpdateCustomer(this.customer);

  @override
  List<Object> get props => [customer];
}

class DeleteSelectedCustomers extends CustomerEvent {
  final List<int> selectedItems;
  final List<Customer> deletedItems;
  final List<int> deletedIndexes;

  const DeleteSelectedCustomers({
    required this.selectedItems,
    required this.deletedItems,
    required this.deletedIndexes,
  });

  @override
  List<Object> get props => [selectedItems, deletedItems, deletedIndexes];
}

class DeleteCustomer extends CustomerEvent {
  final Customer deletedItem;
  final int deletedIndex;

  const DeleteCustomer({required this.deletedItem, required this.deletedIndex});

  @override
  List<Object> get props => [deletedItem, deletedIndex];
}

class PrepareCreateCustomer extends CustomerEvent {
  final int companyId;
  const PrepareCreateCustomer(this.companyId);

  @override
  List<Object> get props => [companyId];
}

class PrepareCopyCustomer extends CustomerEvent {
  final Customer customer;
  const PrepareCopyCustomer(this.customer);

  @override
  List<Object> get props => [customer];
}

class PrepareCreateInCreate extends CustomerEvent {
  final int companyId;
  const PrepareCreateInCreate(this.companyId);

  @override
  List<Object> get props => [companyId];
}

class PrepareCreate1 extends CustomerEvent {
  final int companyId;
  const PrepareCreate1(this.companyId);

  @override
  List<Object> get props => [companyId];
}

class PrepareCreateInEdit extends CustomerEvent {
  final int companyId;
  const PrepareCreateInEdit(this.companyId);

  @override
  List<Object> get props => [companyId];
}

class PrepareEdit extends CustomerEvent {
  final Customer customer;
  const PrepareEdit(this.customer);

  @override
  List<Object> get props => [customer];
}

class PrepareEdit1 extends CustomerEvent {
  final Customer customer;
  const PrepareEdit1(this.customer);

  @override
  List<Object> get props => [customer];
}

class SetSelectedCustomer extends CustomerEvent {
  final Customer customer;
  const SetSelectedCustomer(this.customer);

  @override
  List<Object> get props => [customer];
}

class SetMultiSelectionCustomers extends CustomerEvent {
  final List<Customer> customers;
  const SetMultiSelectionCustomers(this.customers);

  @override
  List<Object> get props => [customers];
}

class AddToCreateList extends CustomerEvent {
  final Customer customer;
  const AddToCreateList(this.customer);

  @override
  List<Object> get props => [customer];
}

class RemoveFromCreateList extends CustomerEvent {
  final Customer customer;
  const RemoveFromCreateList(this.customer);

  @override
  List<Object> get props => [customer];
}

class RemoveFromEditList extends CustomerEvent {
  final Customer customer;
  const RemoveFromEditList(this.customer);

  @override
  List<Object> get props => [customer];
}

class ClearCreateList extends CustomerEvent {}

class ClearSelection extends CustomerEvent {}

class CancelCreate extends CustomerEvent {}

class CancelUpdate extends CustomerEvent {}

class SaveRow extends CustomerEvent {
  final Customer customer;
  const SaveRow(this.customer);

  @override
  List<Object> get props => [customer];
}

class SaveInEdit extends CustomerEvent {
  final Customer customer;
  const SaveInEdit(this.customer);

  @override
  List<Object> get props => [customer];
}

class CreateInEdit extends CustomerEvent {
  final Customer customer;
  const CreateInEdit(this.customer);

  @override
  List<Object> get props => [customer];
}

class RemoveRecord extends CustomerEvent {
  final Customer customer;
  final int index;
  const RemoveRecord(this.customer, this.index);

  @override
  List<Object> get props => [customer];
}

class RemoveList extends CustomerEvent {
  final List<Customer> customers;
  final List<int> indexes;
  const RemoveList(this.customers, this.indexes);

  @override
  List<Object> get props => [customers];
}

class CustomerFilter extends CustomerEvent {
  final String customerName;
  const CustomerFilter(this.customerName);

  @override
  List<Object> get props => [customerName];
}

class SearchCustomers extends CustomerEvent {
  final String query;
  const SearchCustomers(this.query);

  @override
  List<Object> get props => [query];
}

class SelectCustomer extends CustomerEvent {
  final Customer customer;
  final bool isSelected;
  const SelectCustomer(this.customer, this.isSelected);

  @override
  List<Object> get props => [customer, isSelected];
}

class SelectAllCustomers extends CustomerEvent {
  final List<Customer> customers;
  const SelectAllCustomers(this.customers);

  @override
  List<Object> get props => [customers];
}

class SelectBillToCustomer extends CustomerEvent {
  final Customer customer;
  const SelectBillToCustomer(this.customer);

  @override
  List<Object> get props => [customer];
}

class SelectShipToCustomer extends CustomerEvent {
  final Customer customer;
  const SelectShipToCustomer(this.customer);

  @override
  List<Object> get props => [customer];
}

class UpdateCustomerDetails extends CustomerEvent {
  final String tin;
  final String phone;
  final String country;
  const UpdateCustomerDetails({
    required this.tin,
    required this.phone,
    required this.country,
  });

  @override
  List<Object> get props => [tin, phone, country];
}

class CheckDefaultCustomer extends CustomerEvent {
  final Customer customer;
  const CheckDefaultCustomer(this.customer);

  @override
  List<Object> get props => [customer];
}
