import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:savvy_stock/features/sales/customer/models/customer_model.dart';

@immutable
abstract class CustomerEvent extends Equatable {
  const CustomerEvent();

  @override
  List<Object> get props => [];
}

class LoadCustomers extends CustomerEvent {}

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

class AddCustomer extends CustomerEvent {
  final Customer customer;
  const AddCustomer(this.customer);

  @override
  List<Object> get props => [customer];
}

class ClearSelection extends CustomerEvent {}

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
