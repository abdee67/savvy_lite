import 'package:equatable/equatable.dart';
import 'package:savvy_stock/features/sales/customer/models/customer_model.dart';

enum CustomerStatus {
  initial,
  loading,
  creating,
  updating,
  deleting,
  success,
  failure,
  searching,
}

class CustomerState extends Equatable {
  final CustomerStatus status;
  final List<Customer> customers;
  final List<Customer> filteredCustomers;
  final List<Customer> selectedCustomers;
  final String searchQuery;
  final Customer? customerDetail;
  final bool showDetailPanel;
  final Customer selectedBillToCustomer;
  final Customer selectedShipToCustomer;
  final String tin;
  final String phone;
  final String country;
  final String? errorMessage;
  final int? companyId;
  final Customer? customerForm;

  const CustomerState({
    this.companyId,
    this.status = CustomerStatus.initial,
    this.customers = const [],
    this.selectedBillToCustomer = Customer.empty,
    this.selectedShipToCustomer = Customer.empty,
    this.customerDetail,
    this.filteredCustomers = const [],
    this.selectedCustomers = const [],
    this.searchQuery = '',
    this.showDetailPanel = false,
    this.tin = '',
    this.phone = '',
    this.country = '',
    this.errorMessage,
    this.customerForm,
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
    List<Customer>? filteredCustomers,
    List<Customer>? selectedCustomers,
    String? searchQuery,
    bool? showDetailPanel,
    int? companyId,
    Customer? customerDetail,
    Customer? customerForm,
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
      filteredCustomers: filteredCustomers ?? this.filteredCustomers,
      selectedCustomers: selectedCustomers ?? this.selectedCustomers,
      searchQuery: searchQuery ?? this.searchQuery,
      showDetailPanel: showDetailPanel ?? this.showDetailPanel,
      customerDetail: customerDetail ?? this.customerDetail,
      companyId: companyId ?? this.companyId,
      customerForm: customerForm ?? this.customerForm,
    );
  }

  bool get isBillToCustomerSelected => selectedBillToCustomer.isNotEmpty;
  bool get isShipToCustomerSelected => selectedShipToCustomer.isNotEmpty;
  bool get isValid => isBillToCustomerSelected;
  bool get isSelectionMode => selectedCustomers.isNotEmpty;
  bool get canEdit => selectedCustomers.length == 1;
  bool get canDelete => selectedCustomers.isNotEmpty;

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
    filteredCustomers,
    selectedCustomers,
    searchQuery,
    showDetailPanel,
    customerDetail,
    companyId,
    customerForm,
  ];
}
