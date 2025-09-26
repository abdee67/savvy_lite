/*import 'package:bloc/bloc.dart';
import 'package:savvy_stock/core/blocs/base_bloc/base_event.dart';
import 'package:savvy_stock/core/blocs/base_bloc/base_state.dart';

class BaseBloc<T> extends Bloc<BaseEvent, BaseState<T>> {
  BaseBloc() : super( BaseState<T>()) {
    on<LoadBaseData<T>>(_onLoadBaseData);
    on<CreateBaseData<T>>(_onCreateBaseData);
    on<ClearSelection>(_onClearSelection);
    on<UpdateBaseData<T>>(_onUpdateBaseData);
    on<SelectBaseData<T>>(_onSelectBaseData);
    on<SelectAllBaseData<T>>(_onSelectAllBaseData);
    on<DeleteSelectedBaseData<T>>(_onDeleteSelectedBaseData);
    on<UndoDelete<T>>(_onUndoDelete);
    on<ShowBaseDataDetail<T>>(_onShowBaseDataDetail);
    on<HideBaseDataDetail<T>>(_onHideBaseDataDetail);
    on<UpdateBaseData<T>>(_onUpdateBaseData);
    on<ExportBaseData<T>>(_onExportBaseData);
    on<SearchBaseData<T>>(_onSearchBaseData);
  }

  Future<void> _onLoadBaseData(
    LoadBaseData<T> event,
    Emitter<BaseState<T>> emit,
  ) async {
    emit(state.copyWith(status: BaseStatus.loading, selectedData: []));

    try {
      // Simulate API call or database fetch
      await Future.delayed(const Duration(milliseconds: 500));

      emit(
        state.copyWith(
          status: BaseStatus.success,
          data: event.data,
          filteredData: event.data,
          selectedData: [],
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: BaseStatus.failure,
          errorMessage: 'Failed to load customers',
          selectedData: [],
        ),
      );
    }
  }

  void _onClearSelection(ClearSelection event, Emitter<BaseState<T>> emit) {
    emit(state.copyWith(selectedData: []));
  }

  void _onUpdateBaseData(UpdateBaseData<T> event, Emitter<BaseState<T>> emit) {
    emit(
      state.copyWith(
        data: event.data,
        filteredData: event.data,
      ),
    );
  }

  void _onSearchBaseData(SearchBaseData<T> event, Emitter<BaseState<T>> emit) {
    final query = event.query.toLowerCase();

    if (query.isEmpty) {
      emit(
        state.copyWith(
          filteredData: state.data,
          searchQuery: '',
          status: BaseStatus.success,
        ),
      );
      return;
    }

    final filtered = state.data.where((data) {
      return data.name.toLowerCase().contains(query) ||
          data.contactName?.toLowerCase().contains(query) == true ||
          data.phone.toLowerCase().contains(query) ||
          data.email?.toLowerCase().contains(query) == true;
    }).toList();

    emit(
      state.copyWith(
        filteredData: filtered,
        searchQuery: query,
        status: BaseStatus.searching,
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
*/
