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
  }

  Future<void> _onLoadCustomers(
    LoadCustomers event,
    Emitter<CustomerState> emit,
  ) async {
    emit(state.copyWith(status: CustomerStatus.loading));

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
        ),
        const Customer(
          id: '2',
          name: 'Jane Smith',
          tin: '987654321',
          phone: '555-5678',
          country: 'Canada',
        ),
      ];

      emit(
        state.copyWith(status: CustomerStatus.success, customers: customers),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: CustomerStatus.failure,
          errorMessage: 'Failed to load customers',
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
}
