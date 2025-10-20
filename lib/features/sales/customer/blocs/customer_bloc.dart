import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/sales/customer/blocs/customer_event.dart';
import 'package:savvy_stock/features/sales/customer/blocs/customer_state.dart';
import 'package:savvy_stock/features/sales/customer/models/customer_model.dart';

class CustomerBloc extends Bloc<CustomerEvent, CustomerState> {
  final LocalDatabaseService databaseService;
  final AuthBloc authBloc;
  StreamSubscription? _authSubscription;

  CustomerBloc({required this.databaseService, required this.authBloc})
    : super(const CustomerState()) {
    // Listen to auth state changes
    _authSubscription = authBloc.stream.listen((authState) {
      if (authState.isAuthenticated && authState.companyId != null) {
        add(LoadCustomers(authState.companyId!));
      }
    });
    on<LoadCustomers>(_onLoadCustomers);
    on<SelectBillToCustomer>(_onSelectBillToCustomer);
    on<SelectShipToCustomer>(_onSelectShipToCustomer);
    on<AddCustomer>(_onAddCustomer);
    on<ClearSelection>(_onClearSelection);
    on<UpdateCustomerDetails>(_onUpdateCustomerDetails);
    on<SelectCustomer>(_onSelectCustomer);
    on<SelectAllCustomers>(_onSelectAllCustomers);
    on<DeleteSelectedCustomers>(_onDeleteSelectedCustomers);
    on<DeleteCustomer>(_onDeleteCustomer);
    on<UndoDelete>(_onUndoDelete);
    on<ShowCustomerDetail>(_onShowCustomerDetail);
    on<HideCustomerDetail>(_onHideCustomerDetail);
    on<UpdateCustomer>(_onUpdateCustomer);
    on<ExportCustomer>(_onExportCustomer);
    on<SearchCustomers>(_onSearchCustomers);
    on<SetCustomerForm>(_onSetCustomerForm);
  }
  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }

  Future<void> _onLoadCustomers(
    LoadCustomers event,
    Emitter<CustomerState> emit,
  ) async {
    emit(state.copyWith(status: CustomerStatus.loading, selectedCustomers: []));

    try {
      // Simulate API call or database fetch
      await Future.delayed(const Duration(milliseconds: 500));
      final db = await databaseService.database;
      final customers = await db.query(
        'customer_table',
        where: 'company = ?',
        whereArgs: [event.companyId],
      );

      final customerList = customers.map((e) => Customer.fromMap(e)).toList();

      emit(
        state.copyWith(
          status: CustomerStatus.success,
          customers: customerList,
          filteredCustomers: customerList,
          companyId: event.companyId,
          searchQuery: '',
          errorMessage: 'Customers loaded successfully',
          selectedCustomers: [],
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
        tin: event.customer.tinNumber,
        phone: event.customer.phoneNumber,
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

  Future<void> _onAddCustomer(
    AddCustomer event,
    Emitter<CustomerState> emit,
  ) async {
    emit(
      state.copyWith(
        status: CustomerStatus.creating,
        errorMessage: 'Creating customer...',
      ),
    );
    try {
      final db = await databaseService.database;
      final customerMap = event.customer.toMap();

      // Remove ID for auto increment
      customerMap.remove('id');

      // Add company ID from auth
      customerMap['company'] = authBloc.state.companyId;

      await db.insert('customer_table', customerMap);

      // Reload customers
      add(LoadCustomers(authBloc.state.companyId!));

      emit(
        state.copyWith(
          status: CustomerStatus.success,
          errorMessage: 'Customer created successfully',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: CustomerStatus.failure,
          errorMessage: 'Failed to create customer: $e',
        ),
      );
    }
  }

  Future<void> _onDeleteCustomer(
    DeleteCustomer event,
    Emitter<CustomerState> emit,
  ) async {
    emit(
      state.copyWith(
        status: CustomerStatus.deleting,
        errorMessage: 'Deleting customer...',
      ),
    );
    try {
      final db = await databaseService.database;
      final companyId = authBloc.state.companyId;
      if (companyId == null) {
        emit(
          state.copyWith(
            status: CustomerStatus.failure,
            errorMessage: 'Authentication error: Company ID not found',
          ),
        );
        return;
      }
      await db.delete(
        'customer_table',
        where: 'id = ? AND company = ?',
        whereArgs: [event.customerId, companyId],
      );
      add(LoadCustomers(companyId));
      emit(
        state.copyWith(
          status: CustomerStatus.success,
          errorMessage: 'Customer deleted successfully',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: CustomerStatus.failure,
          errorMessage: 'Failed to delete customer: $e',
        ),
      );
    }
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
      return customer.customerName!.toLowerCase().contains(query) ||
          customer.contactName!.toLowerCase().contains(query) == true ||
          customer.phoneNumber!.toLowerCase().contains(query) ||
          customer.address!.toLowerCase().contains(query) == true;
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

  Future<void> _onDeleteSelectedCustomers(
    DeleteSelectedCustomers event,
    Emitter<CustomerState> emit,
  ) async {
    emit(
      state.copyWith(
        status: CustomerStatus.deleting,
        errorMessage: 'Deleting customers...',
      ),
    );
    try {
      final db = await databaseService.database;
      final companyId = authBloc.state.companyId;
      final placeholders = List.filled(
        event.selectedItems.length,
        '?',
      ).join(',');
      final whereArgs = [...event.selectedItems, companyId];
      await db.delete(
        'customer_table',
        where: 'id IN ($placeholders) AND company = ?',
        whereArgs: whereArgs,
      );
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
      add(LoadCustomers(authBloc.state.companyId!));
      emit(
        state.copyWith(
          status: CustomerStatus.success,
          errorMessage: 'Customers deleted successfully',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: CustomerStatus.failure,
          errorMessage: 'Failed to delete customers: $e',
        ),
      );
    }
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

  Future<void> _onUpdateCustomer(
    UpdateCustomer event,
    Emitter<CustomerState> emit,
  ) async {
    emit(
      state.copyWith(
        status: CustomerStatus.updating,
        errorMessage: 'Updating customer...',
      ),
    );
    try {
      final db = await databaseService.database;
      final companyId = authBloc.state.companyId;
      if (companyId == null) {
        emit(
          state.copyWith(
            status: CustomerStatus.failure,
            errorMessage: 'Authentication error: Company ID not found',
          ),
        );
        return;
      }
      final customerMap = event.customer.toMap();
      customerMap['company'] = companyId;
      await db.update(
        'customer_table',
        customerMap,
        where: 'id = ? AND company = ?',
        whereArgs: [event.customer.id, companyId],
      );
      add(LoadCustomers(companyId));
      emit(
        state.copyWith(
          status: CustomerStatus.success,
          errorMessage: 'Customer updated successfully',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: CustomerStatus.failure,
          errorMessage: 'Failed to update customer: $e',
        ),
      );
    }
  }

  void _onExportCustomer(ExportCustomer event, Emitter<CustomerState> emit) {
    emit(
      state.copyWith(
        customers: state.customers,
        filteredCustomers: state.filteredCustomers,
      ),
    );
  }

  void _onSetCustomerForm(SetCustomerForm event, Emitter<CustomerState> emit) {
    emit(state.copyWith(customerForm: event.customer));
  }

  Customer get selectedBillToCustomer => state.selectedBillToCustomer;
}
