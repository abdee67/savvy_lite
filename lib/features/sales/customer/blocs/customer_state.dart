// features/sales/customer/blocs/customer_state.dart
import 'package:equatable/equatable.dart';
import 'package:savvy_stock/features/sales/customer/models/customer_model.dart';

enum CustomerStatus {
  initial,
  loading,
  loaded,
  creating,
  updating,
  deleting,
  success,
  failure,
  defaultCheck,
}

class CustomerState extends Equatable {
  final CustomerStatus status;
  final List<Customer> customers;
  final List<Customer> filteredCustomers;
  final List<Customer> createItems;
  final List<Customer> editItems;
  final List<Customer> multiSelectionItems;
  final List<Customer> selectedCustomers;
  final Customer? selected;
  final Customer? selected1;
  final Customer? selected2;
  final Customer? selectedBillToCustomer;
  final Customer? selectedShipToCustomer;
  final String message;
  final String errorMessage;
  final int? companyId;
  final String searchQuery;
  final String? tin;
  final String? phone;
  final String? country;
  final bool showDetailPanel;
  final Customer? customerDetail;
  final Customer? customerForm;
  final bool? isDefaultValid;

  const CustomerState({
    this.status = CustomerStatus.initial,
    this.customers = const [],
    this.filteredCustomers = const [],
    this.createItems = const [],
    this.editItems = const [],
    this.multiSelectionItems = const [],
    this.selectedCustomers = const [],
    this.selected,
    this.selected1,
    this.selected2,
    this.selectedBillToCustomer,
    this.selectedShipToCustomer,
    this.message = '',
    this.errorMessage = '',
    this.companyId,
    this.searchQuery = '',
    this.tin,
    this.phone,
    this.country,
    this.showDetailPanel = false,
    this.customerDetail,
    this.customerForm,
    this.isDefaultValid,
  });

  CustomerState copyWith({
    CustomerStatus? status,
    List<Customer>? customers,
    List<Customer>? filteredCustomers,
    List<Customer>? createItems,
    List<Customer>? editItems,
    List<Customer>? multiSelectionItems,
    List<Customer>? selectedCustomers,
    Customer? selected,
    Customer? selected1,
    Customer? selected2,
    Customer? selectedBillToCustomer,
    Customer? selectedShipToCustomer,
    String? message,
    String? errorMessage,
    int? companyId,
    String? searchQuery,
    String? tin,
    String? phone,
    String? country,
    bool? showDetailPanel,
    Customer? customerDetail,
    Customer? customerForm,
    bool? isDefaultValid,
  }) {
    return CustomerState(
      status: status ?? this.status,
      customers: customers ?? this.customers,
      filteredCustomers: filteredCustomers ?? this.filteredCustomers,
      createItems: createItems ?? this.createItems,
      editItems: editItems ?? this.editItems,
      multiSelectionItems: multiSelectionItems ?? this.multiSelectionItems,
      selectedCustomers: selectedCustomers ?? this.selectedCustomers,
      selected: selected ?? this.selected,
      selected1: selected1 ?? this.selected1,
      selected2: selected2 ?? this.selected2,
      selectedBillToCustomer:
          selectedBillToCustomer ?? this.selectedBillToCustomer,
      selectedShipToCustomer:
          selectedShipToCustomer ?? this.selectedShipToCustomer,
      message: message ?? this.message,
      errorMessage: errorMessage ?? this.errorMessage,
      companyId: companyId ?? this.companyId,
      searchQuery: searchQuery ?? this.searchQuery,
      tin: tin ?? this.tin,
      phone: phone ?? this.phone,
      country: country ?? this.country,
      showDetailPanel: showDetailPanel ?? this.showDetailPanel,
      customerDetail: customerDetail ?? this.customerDetail,
      customerForm: customerForm ?? this.customerForm,
      isDefaultValid: isDefaultValid ?? this.isDefaultValid,
    );
  }

  bool get isBillToCustomerSelected => selectedBillToCustomer != null;
  bool get isShipToCustomerSelected => selectedShipToCustomer != null;
  bool get isValid => isBillToCustomerSelected && isShipToCustomerSelected;
  bool get isSelectionMode => selectedCustomers.isNotEmpty;
  bool get canEdit => selectedCustomers.length == 1;
  bool get canDelete => selectedCustomers.isNotEmpty;

  @override
  List<Object?> get props => [
    status,
    customers,
    filteredCustomers,
    createItems,
    editItems,
    multiSelectionItems,
    selectedCustomers,
    selected,
    selected1,
    selected2,
    selectedBillToCustomer,
    selectedShipToCustomer,
    message,
    errorMessage,
    companyId,
    searchQuery,
    tin,
    phone,
    country,
    showDetailPanel,
    customerDetail,
    customerForm,
    isDefaultValid,
  ];
}
