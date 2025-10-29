import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:savvy_stock/features/sales/customer/models/customer_model.dart';

@immutable
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

class SearchCustomers extends CustomerEvent {
  final String query;
  const SearchCustomers(this.query);

  @override
  List<Object> get props => [query];
}

class SelectCustomer extends CustomerEvent {
  final Customer customer;
  final bool isSelected;
  const SelectCustomer(this.customer, {this.isSelected = true});

  @override
  List<Object> get props => [customer, isSelected];
}

class SelectAllCustomers extends CustomerEvent {
  final bool selectAll;
  const SelectAllCustomers(this.selectAll);

  @override
  List<Object> get props => [selectAll];
}

class ClearSelection extends CustomerEvent {}

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
  final int customerId;
  final Customer deletedItem;
  final int deletedIndex;

  const DeleteCustomer({
    required this.customerId,
    required this.deletedItem,
    required this.deletedIndex,
  });

  @override
  List<Object> get props => [customerId, deletedItem, deletedIndex];
}

class SetCustomerForm extends CustomerEvent {
  final Customer customer;
  const SetCustomerForm(this.customer);

  @override
  List<Object> get props => [customer];
}

class UndoDelete extends CustomerEvent {
  final Customer deletedItem;
  final int deletedIndex;

  const UndoDelete({required this.deletedItem, required this.deletedIndex});
}

class ShowCustomerDetail extends CustomerEvent {
  final Customer customer;
  const ShowCustomerDetail(this.customer);

  @override
  List<Object> get props => [customer];
}

class HideCustomerDetail extends CustomerEvent {}

class AddCustomer extends CustomerEvent {
  final Customer customer;
  const AddCustomer(this.customer);

  @override
  List<Object> get props => [customer];
}

class UpdateCustomer extends CustomerEvent {
  final Customer customer;
  const UpdateCustomer(this.customer);

  @override
  List<Object> get props => [customer];
}

class ExportCustomer extends CustomerEvent {
  final Customer customer;
  const ExportCustomer(this.customer);

  @override
  List<Object> get props => [customer];
}
