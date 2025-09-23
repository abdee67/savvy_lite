import 'package:bloc/bloc.dart';
import 'package:savvy_stock/features/sales/customer/blocs/customer_event.dart';
import 'package:savvy_stock/features/sales/customer/blocs/customer_state.dart';
import 'package:savvy_stock/features/sales/customer/models/customer_model.dart';

class CustomerBloc extends Bloc<CustomerEvent, CustomerState> {
  CustomerBloc() : super(const CustomerState()) {
    on<LoadCustomers>(_onLoadCustomers);
    on<SelectBillToCustomer>(_onSelectBillToCustomer);
    on<SelectShipToCustomer>(_onSelectShipToCustomer);
    on<AddCustomer>(_onAddCustomer);
    on<ClearSelection>(_onClearSelection);
    on<UpdateCustomerDetails>(_onUpdateCustomerDetails);
    on<SelectCustomer>(_onSelectCustomer);
    on<SelectAllCustomers>(_onSelectAllCustomers);
    on<DeleteSelectedCustomers>(_onDeleteSelectedCustomers);
    on<UndoDelete>(_onUndoDelete);
    on<ShowCustomerDetail>(_onShowCustomerDetail);
    on<HideCustomerDetail>(_onHideCustomerDetail);
    on<UpdateCustomer>(_onUpdateCustomer);
    on<ExportCustomer>(_onExportCustomer);
    on<SearchCustomers>(_onSearchCustomers);
  }

  Future<void> _onLoadCustomers(
    LoadCustomers event,
    Emitter<CustomerState> emit,
  ) async {
    emit(state.copyWith(status: CustomerStatus.loading, selectedCustomers: []));

    try {
      // Simulate API call or database fetch
      await Future.delayed(const Duration(milliseconds: 500));

      final customers = [
        const Customer(
          id: '1',
          name: 'John Doe',
          tin: '123456789',
          phone: '555-1234',
          country: 'USA',
          email: 'john.doe@example.com',
          city: 'New York',
          state: 'New York',
          region: 'New York',
          addressLine1: '123 Main St',
          addressLine2: 'Suite 456',
          addressLine3: 'Apt 789',
          addressLine4: 'Building 101',
          addressLine5: 'Floor 2',
          contactName: 'John Doe',
          title: 'Mr.',
          phone2: '555-1234',
        ),
        const Customer(
          id: '2',
          name: 'Jane Smith',
          tin: '987654321',
          phone: '555-5678',
          country: 'Canada',
          email: 'jane.smith@example.com',
          city: 'Toronto',
          state: 'Ontario',
          region: 'Toronto',
          addressLine1: '456 Elm St',
          addressLine2: 'Suite 789',
          addressLine3: 'Bldg 202',
          addressLine4: 'Floor 3',
          addressLine5: 'Room 4',
          contactName: 'Jane Smith',
          title: 'Ms.',
          phone2: '555-5678',
        ),
        const Customer(
          id: '3',
          name: 'Jane Smith',
          tin: '987654321',
          phone: '555-5678',
          country: 'Canada',
          email: 'jane.smith@example.com',
          city: 'Toronto',
          state: 'Ontario',
          region: 'Toronto',
          addressLine1: '456 Elm St',
          addressLine2: 'Suite 789',
          addressLine3: 'Bldg 202',
          addressLine4: 'Floor 3',
          addressLine5: 'Room 4',
          contactName: 'Jane Smith',
          title: 'Ms.',
          phone2: '555-5678',
        ),
        const Customer(
          id: '4',
          name: 'Jane Smith',
          tin: '987654321',
          phone: '555-5678',
          country: 'Canada',
          email: 'jane.smith@example.com',
          city: 'Toronto',
          state: 'Ontario',
          region: 'Toronto',
          addressLine1: '456 Elm St',
          addressLine2: 'Suite 789',
          addressLine3: 'Bldg 202',
          addressLine4: 'Floor 3',
          addressLine5: 'Room 4',
          contactName: 'Jane Smith',
          title: 'Ms.',
          phone2: '555-5678',
        ),
        const Customer(
          id: '5',
          name: 'Jane Smith',
          tin: '987654321',
          phone: '555-5678',
          country: 'Canada',
          email: 'jane.smith@example.com',
          city: 'Toronto',
          state: 'Ontario',
          region: 'Toronto',
          addressLine1: '456 Elm St',
          addressLine2: 'Suite 789',
          addressLine3: 'Bldg 202',
          addressLine4: 'Floor 3',
          addressLine5: 'Room 4',
          contactName: 'Jane Smith',
          title: 'Ms.',
          phone2: '555-5678',
        ),
        const Customer(
          id: '6',
          name: 'Jane Smith',
          tin: '987654321',
          phone: '555-5678',
          country: 'Canada',
          email: 'jane.smith@example.com',
          city: 'Toronto',
          state: 'Ontario',
          region: 'Toronto',
          addressLine1: '456 Elm St',
          addressLine2: 'Suite 789',
          addressLine3: 'Bldg 202',
          addressLine4: 'Floor 3',
          addressLine5: 'Room 4',
          contactName: 'Jane Smith',
          title: 'Ms.',
          phone2: '555-5678',
        ),
        const Customer(
          id: '7',
          name: 'Jane Smith',
          tin: '987654321',
          phone: '555-5678',
          country: 'Canada',
          email: 'jane.smith@example.com',
          city: 'Toronto',
          state: 'Ontario',
          region: 'Toronto',
          addressLine1: '456 Elm St',
          addressLine2: 'Suite 789',
          addressLine3: 'Bldg 202',
          addressLine4: 'Floor 3',
          addressLine5: 'Room 4',
          contactName: 'Jane Smith',
          title: 'Ms.',
          phone2: '555-5678',
        ),
        const Customer(
          id: '8',
          name: 'Jane Smith',
          tin: '987654321',
          phone: '555-5678',
          country: 'Canada',
          email: 'jane.smith@example.com',
          city: 'Toronto',
          state: 'Ontario',
          region: 'Toronto',
          addressLine1: '456 Elm St',
          addressLine2: 'Suite 789',
          addressLine3: 'Bldg 202',
          addressLine4: 'Floor 3',
          addressLine5: 'Room 4',
          contactName: 'Jane Smith',
          title: 'Ms.',
          phone2: '555-5678',
        ),
      ];

      emit(
        state.copyWith(
          status: CustomerStatus.success,
          customers: customers,
          filteredCustomers: customers,
          selectedCustomers: [],
          selectedBillToCustomer: customers.first,
          selectedShipToCustomer: customers.first,
          tin: customers.first.tin,
          phone: customers.first.phone,
          country: customers.first.country,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: CustomerStatus.failure,
          errorMessage: 'Failed to load customers',
          selectedCustomers: [],
        ),
      );
    }
  }

  void _onSelectBillToCustomer(
    SelectBillToCustomer event,
    Emitter<CustomerState> emit,
  ) {
    emit(
      state.copyWith(
        selectedBillToCustomer: event.customer,
        selectedShipToCustomer:
            event.customer, // Auto-fill ship to same as bill to
        tin: event.customer.tin,
        phone: event.customer.phone,
        country: event.customer.country,
      ),
    );
  }

  void _onSelectShipToCustomer(
    SelectShipToCustomer event,
    Emitter<CustomerState> emit,
  ) {
    emit(state.copyWith(selectedShipToCustomer: event.customer));
  }

  void _onAddCustomer(AddCustomer event, Emitter<CustomerState> emit) {
    final updatedCustomers = List<Customer>.from(state.customers)
      ..add(event.customer);

    emit(
      state.copyWith(
        customers: updatedCustomers,
        selectedBillToCustomer: event.customer,
        selectedShipToCustomer: event.customer,
        tin: event.customer.tin,
        phone: event.customer.phone,
        country: event.customer.country,
        filteredCustomers: updatedCustomers,
      ),
    );
  }

  void _onClearSelection(ClearSelection event, Emitter<CustomerState> emit) {
    emit(
      state.copyWith(
        selectedBillToCustomer: Customer.empty,
        selectedShipToCustomer: Customer.empty,
        tin: '',
        phone: '',
        country: '',
        selectedCustomers: [],
      ),
    );
  }

  void _onUpdateCustomerDetails(
    UpdateCustomerDetails event,
    Emitter<CustomerState> emit,
  ) {
    emit(
      state.copyWith(
        tin: event.tin,
        phone: event.phone,
        country: event.country,
      ),
    );
  }

  void _onSearchCustomers(SearchCustomers event, Emitter<CustomerState> emit) {
    final query = event.query.toLowerCase();

    if (query.isEmpty) {
      emit(
        state.copyWith(
          filteredCustomers: state.customers,
          searchQuery: '',
          status: CustomerStatus.success,
        ),
      );
      return;
    }

    final filtered = state.customers.where((customer) {
      return customer.name.toLowerCase().contains(query) ||
          customer.contactName?.toLowerCase().contains(query) == true ||
          customer.phone.toLowerCase().contains(query) ||
          customer.email?.toLowerCase().contains(query) == true;
    }).toList();

    emit(
      state.copyWith(
        filteredCustomers: filtered,
        searchQuery: query,
        status: CustomerStatus.searching,
      ),
    );
  }

  void _onSelectCustomer(SelectCustomer event, Emitter<CustomerState> emit) {
    final selectedCustomers = List<Customer>.from(state.selectedCustomers);
    if (event.isSelected) {
      selectedCustomers.add(event.customer);
    } else {
      selectedCustomers.removeWhere(
        (customer) => customer.id == event.customer.id,
      );
    }
    emit(state.copyWith(selectedCustomers: selectedCustomers));
  }

  void _onSelectAllCustomers(
    SelectAllCustomers event,
    Emitter<CustomerState> emit,
  ) {
    final selectedCustomers = List<Customer>.from(state.filteredCustomers);
    emit(state.copyWith(selectedCustomers: selectedCustomers));
  }

  void _onDeleteSelectedCustomers(
    DeleteSelectedCustomers event,
    Emitter<CustomerState> emit,
  ) {
    final remainingCustomers = state.customers
        .where((customer) => !state.selectedCustomers.contains(customer))
        .toList();

    final remainingFiltered = state.filteredCustomers
        .where((customer) => !state.selectedCustomers.contains(customer))
        .toList();

    emit(
      state.copyWith(
        customers: remainingCustomers,
        filteredCustomers: remainingFiltered,
        selectedCustomers: [],
      ),
    );
  }

  void _onUndoDelete(UndoDelete event, Emitter<CustomerState> emit) {
    final updatedCustomers = List<Customer>.from(state.customers);
    updatedCustomers.insert(event.deletedIndex, event.deletedItem);
    emit(state.copyWith(customers: updatedCustomers));
  }

  void _onShowCustomerDetail(
    ShowCustomerDetail event,
    Emitter<CustomerState> emit,
  ) {
    emit(state.copyWith(customerDetail: event.customer, showDetailPanel: true));
  }

  void _onHideCustomerDetail(
    HideCustomerDetail event,
    Emitter<CustomerState> emit,
  ) {
    emit(state.copyWith(showDetailPanel: false));
  }

  void _onUpdateCustomer(UpdateCustomer event, Emitter<CustomerState> emit) {
    final updatedCustomers = state.customers
        .map(
          (customer) =>
              customer.id == event.customer.id ? event.customer : customer,
        )
        .toList();

    final updatedFiltered = state.filteredCustomers
        .map(
          (customer) =>
              customer.id == event.customer.id ? event.customer : customer,
        )
        .toList();

    emit(
      state.copyWith(
        customers: updatedCustomers,
        filteredCustomers: updatedFiltered,
      ),
    );
  }

  void _onExportCustomer(ExportCustomer event, Emitter<CustomerState> emit) {
    emit(
      state.copyWith(
        customers: state.customers,
        filteredCustomers: state.filteredCustomers,
      ),
    );
  }

  Customer get selectedBillToCustomer => state.selectedBillToCustomer;
}
