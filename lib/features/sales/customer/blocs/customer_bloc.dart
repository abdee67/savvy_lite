// features/sales/customer/blocs/customer_bloc.dart
import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/sales/customer/blocs/customer_event.dart';
import 'package:savvy_stock/features/sales/customer/blocs/customer_state.dart';
import 'package:savvy_stock/features/sales/customer/models/customer_model.dart';
import 'package:savvy_stock/features/sales/customer/repo/customer_repo.dart';

class CustomerBloc extends Bloc<CustomerEvent, CustomerState> {
  final CustomerRepository repository;
  final AuthBloc authBloc;
  StreamSubscription? _authSubscription;

  CustomerBloc({required this.repository, required this.authBloc})
    : super(const CustomerState()) {
    _authSubscription = authBloc.stream.listen((authState) {
      if (authState.isAuthenticated && authState.companyId != null) {
        add(LoadCustomers(authState.companyId!));
      }
    });

    // Event handlers for all Java controller methods
    on<LoadCustomers>(_onLoadCustomers);
    on<SaveCustomer>(_onSaveCustomer);
    on<UpdateCustomer>(_onUpdateCustomer);
    on<DeleteCustomer>(_onDeleteCustomer);
    on<DeleteSelectedCustomers>(_onDeleteMultipleCustomers);
    on<PrepareCreateCustomer>(_onPrepareCreate);
    on<PrepareCopyCustomer>(_onPrepareCopy);
    on<PrepareCreateInCreate>(_onPrepareCreateInCreate);
    on<PrepareCreate1>(_onPrepareCreate1);
    on<PrepareCreateInEdit>(_onPrepareCreateInEdit);
    on<PrepareEdit>(_onPrepareEdit);
    on<PrepareEdit1>(_onPrepareEdit1);
    on<SetSelectedCustomer>(_onSetSelected);
    on<SetMultiSelectionCustomers>(_onSetMultiSelection);
    on<AddToCreateList>(_onAddToCreateList);
    on<RemoveFromCreateList>(_onRemoveFromCreateList);
    on<RemoveFromEditList>(_onRemoveFromEditList);
    on<ClearCreateList>(_onClearCreateList);
    on<ClearSelection>(_onClearSelection);
    on<CancelCreate>(_onCancelCreate);
    on<CancelUpdate>(_onCancelUpdate);
    on<SaveRow>(_onSaveRow);
    on<SaveInEdit>(_onSaveInEdit);
    on<CreateInEdit>(_onCreateInEdit);
    on<RemoveRecord>(_onRemoveRecord);
    on<RemoveList>(_onRemoveList);
    on<CustomerFilter>(_onCustomerFilter);
    on<SearchCustomers>(_onSearchCustomers);
    on<SelectCustomer>(_onSelectCustomer);
    on<SelectAllCustomers>(_onSelectAllCustomers);
    on<SelectBillToCustomer>(_onSelectBillToCustomer);
    on<SelectShipToCustomer>(_onSelectShipToCustomer);
    on<UpdateCustomerDetails>(_onUpdateCustomerDetails);
    on<CheckDefaultCustomer>(_onCheckDefaultCustomer);
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
    emit(state.copyWith(status: CustomerStatus.loading));
    try {
      final customers = await repository.getCustomers(event.companyId);
      emit(
        state.copyWith(
          status: CustomerStatus.loaded,
          customers: customers,

          filteredCustomers: customers,
          companyId: event.companyId,
          message: 'Customers loaded successfully',
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: CustomerStatus.failure,
          message: 'Failed to load customers: $error',
        ),
      );
    }
  }

  Future<void> _onSaveCustomer(
    SaveCustomer event,
    Emitter<CustomerState> emit,
  ) async {
    emit(state.copyWith(status: CustomerStatus.creating));
    try {
      final companyId = authBloc.state.companyId;
      if (companyId == null || companyId == 0) {
        emit(
          state.copyWith(
            status: CustomerStatus.failure,
            message: 'Authentication error: Company ID not found',
          ),
        );
        return;
      }

      // Handle default customer logic (equivalent to Java's flagDisable)
      if (event.customer.defaultsValue == 'Y') {
        await repository.handleDefaultCustomer(event.customer, companyId);
      }

      final customerToSave = event.customer.copyWith(company: companyId);

      if (customerToSave.id == null) {
        await repository.createCustomer(customerToSave);
      } else {
        await repository.updateCustomer(customerToSave);
      }

      add(LoadCustomers(companyId));
      emit(
        state.copyWith(
          status: CustomerStatus.success,
          message: 'Customer saved successfully',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: CustomerStatus.failure,
          message: 'Failed to save customer: $e',
        ),
      );
    }
  }

  Future<void> _onUpdateCustomer(
    UpdateCustomer event,
    Emitter<CustomerState> emit,
  ) async {
    emit(state.copyWith(status: CustomerStatus.updating));
    try {
      final companyId = authBloc.state.companyId;
      if (companyId == null || companyId == 0) {
        emit(
          state.copyWith(
            status: CustomerStatus.failure,
            message: 'Authentication error: Company ID not found',
          ),
        );
        return;
      }

      // Handle default customer logic
      if (event.customer.defaultsValue == 'Y') {
        await repository.handleDefaultCustomer(event.customer, companyId);
      }

      await repository.updateCustomer(event.customer);
      add(LoadCustomers(companyId));

      emit(
        state.copyWith(
          status: CustomerStatus.success,
          message: 'Customer updated successfully',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: CustomerStatus.failure,
          message: 'Failed to update customer: $e',
        ),
      );
    }
  }

  Future<void> _onDeleteCustomer(
    DeleteCustomer event,
    Emitter<CustomerState> emit,
  ) async {
    emit(state.copyWith(status: CustomerStatus.deleting));
    try {
      final companyId = authBloc.state.companyId;
      if (companyId == null) {
        emit(
          state.copyWith(
            status: CustomerStatus.failure,
            message: 'Authentication error: Company ID not found',
          ),
        );
        return;
      }

      await repository.deleteCustomer(event.deletedItem.id!, companyId);
      add(LoadCustomers(companyId));

      emit(
        state.copyWith(
          status: CustomerStatus.success,
          message: 'Customer deleted successfully',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: CustomerStatus.failure,
          message: 'Failed to delete customer: $e',
        ),
      );
    }
  }

  Future<void> _onDeleteMultipleCustomers(
    DeleteSelectedCustomers event,
    Emitter<CustomerState> emit,
  ) async {
    emit(state.copyWith(status: CustomerStatus.deleting));
    try {
      final companyId = authBloc.state.companyId;
      if (companyId == null) {
        emit(
          state.copyWith(
            status: CustomerStatus.failure,
            message: 'Authentication error: Company ID not found',
          ),
        );
        return;
      }

      final customerIds = event.deletedItems.map((c) => c.id!).toList();
      await repository.deleteMultipleCustomers(customerIds, companyId);
      add(LoadCustomers(companyId));

      emit(
        state.copyWith(
          status: CustomerStatus.success,
          message:
              '${event.deletedItems.length} customers deleted successfully',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: CustomerStatus.failure,
          message: 'Failed to delete customers: $e',
        ),
      );
    }
  }

  // UI State Management Methods (equivalent to Java preparation methods)
  Future<void> _onPrepareCreate(
    PrepareCreateCustomer event,
    Emitter<CustomerState> emit,
  ) async {
    final newCustomer = Customer(
      company: event.companyId,
      country: 'Ethiopia', // Default country like Java
    );

    emit(
      state.copyWith(
        createItems: [newCustomer],
        selected: newCustomer,
        selected2: Customer(company: event.companyId, country: 'Ethiopia'),
      ),
    );
  }

  Future<void> _onPrepareCopy(
    PrepareCopyCustomer event,
    Emitter<CustomerState> emit,
  ) async {
    final copiedCustomer = event.customer.copyWith(id: null);

    emit(
      state.copyWith(
        createItems: [...state.createItems, copiedCustomer],
        selected: copiedCustomer,
      ),
    );
  }

  Future<void> _onPrepareCreateInCreate(
    PrepareCreateInCreate event,
    Emitter<CustomerState> emit,
  ) async {
    final newCustomer = Customer(company: event.companyId, country: 'Ethiopia');

    final nextTempId = _getNextTempId(state.createItems);
    final customerWithTempId = newCustomer.copyWith(tempId: nextTempId);

    emit(
      state.copyWith(
        createItems: [...state.createItems, customerWithTempId],
        selected1: customerWithTempId,
      ),
    );
  }

  Future<void> _onPrepareCreate1(
    PrepareCreate1 event,
    Emitter<CustomerState> emit,
  ) async {
    final nextTempId = _getNextTempId(state.createItems);
    final newCustomer = Customer(
      tempId: nextTempId,
      company: event.companyId,
      country: 'Ethiopia',
    );

    emit(
      state.copyWith(
        createItems: [...state.createItems, newCustomer],
        selected: newCustomer,
      ),
    );
  }

  Future<void> _onPrepareCreateInEdit(
    PrepareCreateInEdit event,
    Emitter<CustomerState> emit,
  ) async {
    final nextTempId = _getNextTempId(state.editItems);
    final newCustomer = Customer(
      tempId: nextTempId,
      company: event.companyId,
      country: 'Ethiopia',
    );

    emit(
      state.copyWith(
        editItems: [...state.editItems, newCustomer],
        selected1: newCustomer,
      ),
    );
  }

  Future<void> _onPrepareEdit(
    PrepareEdit event,
    Emitter<CustomerState> emit,
  ) async {
    emit(state.copyWith(editItems: [event.customer], selected: event.customer));
  }

  Future<void> _onPrepareEdit1(
    PrepareEdit1 event,
    Emitter<CustomerState> emit,
  ) async {
    emit(state.copyWith(selected1: event.customer));
  }

  Future<void> _onSaveRow(SaveRow event, Emitter<CustomerState> emit) async {
    emit(state.copyWith(status: CustomerStatus.updating));
    try {
      final companyId = authBloc.state.companyId;
      if (companyId == null) {
        emit(
          state.copyWith(
            status: CustomerStatus.failure,
            message: 'Authentication error: Company ID not found',
          ),
        );
        return;
      }

      if (event.customer.id == null) {
        final customerToSave = event.customer.copyWith(company: companyId);
        await repository.createCustomer(customerToSave);
      } else {
        // Handle default customer logic for row save
        if (event.customer.defaultsValue == 'Y') {
          await repository.handleDefaultCustomer(event.customer, companyId);
        }
        await repository.updateCustomer(event.customer);
      }

      add(LoadCustomers(companyId));
      emit(
        state.copyWith(
          status: CustomerStatus.success,
          message: 'Customer saved successfully',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: CustomerStatus.failure,
          message: 'Failed to save customer: $e',
        ),
      );
    }
  }

  Future<void> _onSaveInEdit(
    SaveInEdit event,
    Emitter<CustomerState> emit,
  ) async {
    emit(state.copyWith(status: CustomerStatus.updating));
    try {
      final companyId = authBloc.state.companyId;
      if (companyId == null) {
        emit(
          state.copyWith(
            status: CustomerStatus.failure,
            message: 'Authentication error: Company ID not found',
          ),
        );
        return;
      }

      for (final customer in state.editItems) {
        if (customer.id == null) {
          final customerToSave = customer.copyWith(company: companyId);
          await repository.createCustomer(customerToSave);
        } else {
          await repository.updateCustomer(customer);
        }
      }

      add(LoadCustomers(companyId));
      emit(
        state.copyWith(
          status: CustomerStatus.success,
          message: 'Customers saved successfully',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: CustomerStatus.failure,
          message: 'Failed to save customers: $e',
        ),
      );
    }
  }

  Future<void> _onCreateInEdit(
    CreateInEdit event,
    Emitter<CustomerState> emit,
  ) async {
    emit(state.copyWith(status: CustomerStatus.creating));
    try {
      final companyId = authBloc.state.companyId;
      if (companyId == null) {
        emit(
          state.copyWith(
            status: CustomerStatus.failure,
            message: 'Authentication error: Company ID not found',
          ),
        );
        return;
      }

      final customerToSave = event.customer.copyWith(company: companyId);
      await repository.createCustomer(customerToSave);
      add(LoadCustomers(companyId));

      emit(
        state.copyWith(
          status: CustomerStatus.success,
          message: 'Customer created successfully',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: CustomerStatus.failure,
          message: 'Failed to create customer: $e',
        ),
      );
    }
  }

  Future<void> _onRemoveRecord(
    RemoveRecord event,
    Emitter<CustomerState> emit,
  ) async {
    if (event.customer.id != null) {
      add(
        DeleteCustomer(deletedItem: event.customer, deletedIndex: event.index),
      );
    }
  }

  Future<void> _onRemoveList(
    RemoveList event,
    Emitter<CustomerState> emit,
  ) async {
    add(
      DeleteSelectedCustomers(
        selectedItems: event.customers.map((c) => c.id!).toList(),
        deletedItems: event.customers,
        deletedIndexes: event.indexes,
      ),
    );
  }

  Future<void> _onCustomerFilter(
    CustomerFilter event,
    Emitter<CustomerState> emit,
  ) async {
    try {
      final companyId = authBloc.state.companyId;
      if (companyId == null) return;

      final filteredCustomers = await repository.filterCustomers(
        companyId: companyId,
        customerName: event.customerName,
      );

      emit(
        state.copyWith(
          customers: filteredCustomers,
          filteredCustomers: filteredCustomers,
        ),
      );
    } catch (e) {
      emit(state.copyWith(message: 'Failed to filter customers: $e'));
    }
  }

  Future<void> _onSearchCustomers(
    SearchCustomers event,
    Emitter<CustomerState> emit,
  ) async {
    if (event.query.isEmpty) {
      emit(state.copyWith(filteredCustomers: state.customers, searchQuery: ''));
    } else {
      try {
        final companyId = authBloc.state.companyId;
        if (companyId == null) return;

        final searchedCustomers = await repository.searchCustomers(
          companyId: companyId,
          query: event.query,
        );

        emit(
          state.copyWith(
            filteredCustomers: searchedCustomers,
            searchQuery: event.query,
          ),
        );
      } catch (e) {
        // Fallback to local search
        final filtered = state.customers.where((customer) {
          return customer.customerName?.toLowerCase().contains(
                    event.query.toLowerCase(),
                  ) ==
                  true ||
              customer.contactName?.toLowerCase().contains(
                    event.query.toLowerCase(),
                  ) ==
                  true ||
              customer.phoneNumber?.toLowerCase().contains(
                    event.query.toLowerCase(),
                  ) ==
                  true ||
              customer.address?.toLowerCase().contains(
                    event.query.toLowerCase(),
                  ) ==
                  true;
        }).toList();

        emit(
          state.copyWith(filteredCustomers: filtered, searchQuery: event.query),
        );
      }
    }
  }

  Future<void> _onCheckDefaultCustomer(
    CheckDefaultCustomer event,
    Emitter<CustomerState> emit,
  ) async {
    try {
      final companyId = authBloc.state.companyId;
      if (companyId == null) return;

      final isValid = await repository.isDefaultCustomerSettingValid(
        event.customer,
        companyId,
      );

      emit(
        state.copyWith(
          status: CustomerStatus.defaultCheck,
          isDefaultValid: isValid,
          message: isValid
              ? 'Default setting is valid'
              : 'Another customer is already set as default',
        ),
      );
    } catch (e) {
      emit(state.copyWith(message: 'Error checking default customer: $e'));
    }
  }

  // Simple state update handlers
  void _onSetSelected(SetSelectedCustomer event, Emitter<CustomerState> emit) {
    emit(state.copyWith(selected: event.customer));
  }

  void _onSetMultiSelection(
    SetMultiSelectionCustomers event,
    Emitter<CustomerState> emit,
  ) {
    emit(state.copyWith(multiSelectionItems: event.customers));
  }

  void _onAddToCreateList(AddToCreateList event, Emitter<CustomerState> emit) {
    final nextTempId = _getNextTempId(state.createItems);
    final newCustomer = event.customer.copyWith(tempId: nextTempId);

    emit(
      state.copyWith(
        createItems: [...state.createItems, newCustomer],
        selected1: newCustomer,
      ),
    );
  }

  void _onRemoveFromCreateList(
    RemoveFromCreateList event,
    Emitter<CustomerState> emit,
  ) {
    final updatedCreateItems = state.createItems
        .where((customer) => customer.tempId != event.customer.tempId)
        .toList();

    emit(state.copyWith(createItems: updatedCreateItems));
  }

  void _onRemoveFromEditList(
    RemoveFromEditList event,
    Emitter<CustomerState> emit,
  ) {
    final updatedEditItems = state.editItems
        .where((customer) => customer.tempId != event.customer.tempId)
        .toList();

    emit(state.copyWith(editItems: updatedEditItems));
  }

  void _onClearCreateList(ClearCreateList event, Emitter<CustomerState> emit) {
    emit(
      state.copyWith(createItems: const [], selected: null, selected1: null),
    );
  }

  void _onClearSelection(ClearSelection event, Emitter<CustomerState> emit) {
    emit(
      state.copyWith(
        selectedBillToCustomer: null,
        selectedShipToCustomer: null,
        selectedCustomers: const [],
        tin: '',
        phone: '',
        country: '',
      ),
    );
  }

  void _onCancelCreate(CancelCreate event, Emitter<CustomerState> emit) {
    emit(
      state.copyWith(
        selected: null,
        createItems: const [],
        customers: const [],
      ),
    );
  }

  void _onCancelUpdate(CancelUpdate event, Emitter<CustomerState> emit) {
    emit(state.copyWith(selected1: null, editItems: const []));
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
    if (state.selectedCustomers.length == event.customers.length) {
      emit(state.copyWith(selectedCustomers: const []));
    } else {
      emit(state.copyWith(selectedCustomers: List.from(event.customers)));
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

  // Helper methods
  int _getNextTempId(List<Customer> customers) {
    if (customers.isEmpty) return 1;
    final maxTempId = customers
        .map((e) => e.tempId ?? 0)
        .reduce((a, b) => a > b ? a : b);
    return maxTempId + 1;
  }
}
