import 'package:equatable/equatable.dart';
import 'package:savvy_stock/features/sales/customer/models/customer_model.dart';

enum CustomerStatus { initial, loading, success, failure }

class CustomerState extends Equatable {
  final CustomerStatus status;
  final List<Customer> customers;
  final Customer selectedBillToCustomer;
  final Customer selectedShipToCustomer;
  final String tin;
  final String phone;
  final String country;
  final String? errorMessage;

  const CustomerState({
    this.status = CustomerStatus.initial,
    this.customers = const [],
    this.selectedBillToCustomer = Customer.empty,
    this.selectedShipToCustomer = Customer.empty,
    this.tin = '',
    this.phone = '',
    this.country = '',
    this.errorMessage,
  });

  CustomerState copyWith({
    CustomerStatus? status,
    List<Customer>? customers,
    Customer? selectedBillToCustomer,
    Customer? selectedShipToCustomer,
    String? tin,
    String? phone,
    String? country,
    String? errorMessage,
  }) {
    return CustomerState(
      status: status ?? this.status,
      customers: customers ?? this.customers,
      selectedBillToCustomer:
          selectedBillToCustomer ?? this.selectedBillToCustomer,
      selectedShipToCustomer:
          selectedShipToCustomer ?? this.selectedShipToCustomer,
      tin: tin ?? this.tin,
      phone: phone ?? this.phone,
      country: country ?? this.country,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  bool get isBillToCustomerSelected => selectedBillToCustomer.isNotEmpty;
  bool get isShipToCustomerSelected => selectedShipToCustomer.isNotEmpty;
  bool get isValid => isBillToCustomerSelected;

  @override
  List<Object?> get props => [
    status,
    customers,
    selectedBillToCustomer,
    selectedShipToCustomer,
    tin,
    phone,
    country,
    errorMessage,
  ];
}
