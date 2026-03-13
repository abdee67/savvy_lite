// features/sales/invoice_history/bloc/invoice_history_header_bloc.dart
import 'dart:async';
import 'dart:developer' as developer;
import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:savvy_stock/core/repositories/udc_repository.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/sales/sales_order/invoice/header/bloc/invoice_header_event.dart';
import 'package:savvy_stock/features/sales/sales_order/invoice/header/bloc/invoice_header_state.dart';
import 'package:savvy_stock/features/sales/sales_order/invoice/header/model/invoice_header_model.dart';
import 'package:savvy_stock/features/sales/sales_order/invoice/header/repo/invoice_header_repo.dart';

class InvoiceHistoryHeaderBloc
    extends Bloc<InvoiceHistoryHeaderEvent, InvoiceHistoryHeaderState> {
  final InvoiceHistoryHeaderRepository repository;
  final AuthBloc authBloc;
  final UdcRepository udcRepository;

  StreamSubscription? _authSubscription;

  InvoiceHistoryHeaderBloc({
    required this.repository,
    required this.authBloc,
    required this.udcRepository,
  }) : super(const InvoiceHistoryHeaderState()) {
    _authSubscription = authBloc.stream.listen((authState) {
      if (authState.isAuthenticated && authState.companyId != null) {
        add(InvoiceHistoryHeaderInitialized(companyId: authState.companyId!));
      }
    });

    // Event handlers - matching Java controller methods
    on<InvoiceHistoryHeaderInitialized>(_onInitialized);
    on<LoadInvoiceHistoryHeaders>(_onLoadInvoiceHistoryHeaders);
    on<CreateInvoiceHistoryHeader>(_onCreateInvoiceHistoryHeader);
    on<UpdateInvoiceHistoryHeader>(_onUpdateInvoiceHistoryHeader);
    on<DeleteInvoiceHistoryHeader>(_onDeleteInvoiceHistoryHeader);
    on<DeleteMultipleInvoiceHistoryHeaders>(
      _onDeleteMultipleInvoiceHistoryHeaders,
    );

    // Selection Management
    on<SelectInvoiceHistoryHeader>(_onSelectInvoiceHistoryHeader);
    on<SelectMultipleInvoiceHistoryHeaders>(
      _onSelectMultipleInvoiceHistoryHeaders,
    );
    on<ClearSelection>(_onClearSelection);

    // UI State Management (equivalent to Java preparation methods)
    on<PrepareCreate>(_onPrepareCreate);
    on<PrepareEdit>(_onPrepareEdit);
    on<CancelUpdate>(_onCancelUpdate);
    on<CancelCreate>(_onCancelCreate);
    on<DiscardChanges>(_onDiscardChanges);

    // Filtering & Search
    on<FilterInvoiceHistoryHeaders>(_onFilterInvoiceHistoryHeaders);
    on<SearchInvoiceHistoryHeaders>(_onSearchInvoiceHistoryHeaders);
    on<ClearFilters>(_onClearFilters);

    // Batch Operations
    on<SaveRow>(_onSaveRow);
    on<SaveInEdit>(_onSaveInEdit);

    // Item Management in Lists
    on<RemoveInCreate>(_onRemoveInCreate);
    on<RemoveRecord>(_onRemoveRecord);
    on<RemoveList>(_onRemoveList);

    // Utility
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }

  // Initialization
  Future<void> _onInitialized(
    InvoiceHistoryHeaderInitialized event,
    Emitter<InvoiceHistoryHeaderState> emit,
  ) async {
    emit(state.copyWith(companyId: event.companyId));
    add(LoadInvoiceHistoryHeaders(companyId: event.companyId));
  }

  // Load all items - equivalent to Java's getItems()
  Future<void> _onLoadInvoiceHistoryHeaders(
    LoadInvoiceHistoryHeaders event,
    Emitter<InvoiceHistoryHeaderState> emit,
  ) async {
    try {
      emit(state.copyWith(status: InvoiceHistoryHeaderStatus.loading));

      var items = await repository.getInvoiceHistoryHeadersByCompany(
        event.companyId,
      );

      // Filter by company
      items = items.where((item) {
        return item.company == event.companyId;
      }).toList();

      emit(
        state.copyWith(
          status: InvoiceHistoryHeaderStatus.loaded,
          items: items,
          filteredValues: items,
          companyId: event.companyId,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: InvoiceHistoryHeaderStatus.failure,
          errorMessage: 'Failed to load invoice history headers: $e',
        ),
      );
    }
  }

  // CRUD Operations
  Future<void> _onCreateInvoiceHistoryHeader(
    CreateInvoiceHistoryHeader event,
    Emitter<InvoiceHistoryHeaderState> emit,
  ) async {
    try {
      emit(state.copyWith(status: InvoiceHistoryHeaderStatus.creating));

      final id = await repository.createInvoiceHistoryHeader(event.header);
      final createdHeader = event.header.copyWith(id: id);

      // Update state
      final updatedItems = [createdHeader, ...state.items];
      final updatedCreateItems = state.createItems
          .where((item) => item.tempId != createdHeader.tempId)
          .toList();

      emit(
        state.copyWith(
          status: InvoiceHistoryHeaderStatus.success,
          items: updatedItems,
          filteredValues: updatedItems,
          createItems: updatedCreateItems,
          selected: createdHeader,
          successMessage: 'Invoice history header created successfully',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: InvoiceHistoryHeaderStatus.failure,
          errorMessage: 'Failed to create invoice history header: $e',
        ),
      );
      if (kDebugMode) {
        developer.log('Failed to create invoice history header: $e');
      }
    }
  }

  Future<void> _onUpdateInvoiceHistoryHeader(
    UpdateInvoiceHistoryHeader event,
    Emitter<InvoiceHistoryHeaderState> emit,
  ) async {
    try {
      emit(state.copyWith(status: InvoiceHistoryHeaderStatus.updating));

      await repository.updateInvoiceHistoryHeader(event.header);

      // Update the header in the lists
      final updatedItems = state.items
          .map((h) => h.id == event.header.id ? event.header : h)
          .toList();
      final updatedEditItems = state.editItems
          .where((item) => item.id != event.header.id)
          .toList();

      emit(
        state.copyWith(
          status: InvoiceHistoryHeaderStatus.success,
          items: updatedItems,
          filteredValues: updatedItems,
          editItems: updatedEditItems,
          selected: event.header,
          successMessage: 'Invoice history header updated successfully',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: InvoiceHistoryHeaderStatus.failure,
          errorMessage: 'Failed to update invoice history header: $e',
        ),
      );
    }
  }

  Future<void> _onDeleteInvoiceHistoryHeader(
    DeleteInvoiceHistoryHeader event,
    Emitter<InvoiceHistoryHeaderState> emit,
  ) async {
    try {
      emit(state.copyWith(status: InvoiceHistoryHeaderStatus.deleting));

      await repository.deleteInvoiceHistoryHeader(event.id);

      final updatedItems = state.items.where((h) => h.id != event.id).toList();
      final updatedFilteredValues = state.filteredValues
          .where((h) => h.id != event.id)
          .toList();

      emit(
        state.copyWith(
          status: InvoiceHistoryHeaderStatus.success,
          items: updatedItems,
          filteredValues: updatedFilteredValues,
          selected: state.selected?.id == event.id ? null : state.selected,
          successMessage: 'Invoice history header deleted successfully',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: InvoiceHistoryHeaderStatus.failure,
          errorMessage: 'Failed to delete invoice history header: $e',
        ),
      );
    }
  }

  Future<void> _onDeleteMultipleInvoiceHistoryHeaders(
    DeleteMultipleInvoiceHistoryHeaders event,
    Emitter<InvoiceHistoryHeaderState> emit,
  ) async {
    try {
      emit(state.copyWith(status: InvoiceHistoryHeaderStatus.deleting));

      for (final header in event.headers) {
        if (header.id != null) {
          await repository.deleteInvoiceHistoryHeader(header.id!);
        }
      }

      final idsToRemove = event.headers
          .map((h) => h.id)
          .whereType<int>()
          .toSet();
      final updatedItems = state.items
          .where((h) => !idsToRemove.contains(h.id))
          .toList();
      final updatedFilteredValues = state.filteredValues
          .where((h) => !idsToRemove.contains(h.id))
          .toList();

      emit(
        state.copyWith(
          status: InvoiceHistoryHeaderStatus.success,
          items: updatedItems,
          filteredValues: updatedFilteredValues,
          multiselectionItems: const [],
          successMessage:
              '${event.headers.length} invoice history headers deleted successfully',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: InvoiceHistoryHeaderStatus.failure,
          errorMessage: 'Failed to delete invoice history headers: $e',
        ),
      );
    }
  }

  // UI State Management (equivalent to Java preparation methods)
  Future<void> _onPrepareCreate(
    PrepareCreate event,
    Emitter<InvoiceHistoryHeaderState> emit,
  ) async {
    final companyId = authBloc.state.companyId;
    if (companyId == null) return;

    final newItem = InvoiceHistoryHeader(
      tempId: _getNextTempId(state.createItems),
      company: companyId,
    );

    emit(
      state.copyWith(
        createItems: [newItem],
        selected: newItem,
        selected2: InvoiceHistoryHeader(company: companyId),
      ),
    );
  }

  Future<void> _onPrepareEdit(
    PrepareEdit event,
    Emitter<InvoiceHistoryHeaderState> emit,
  ) async {
    if (state.multiselectionItems.isEmpty) return;

    emit(
      state.copyWith(
        editItems: [state.multiselectionItems.first],
        selected: state.multiselectionItems.first,
      ),
    );
  }

  void _onCancelUpdate(
    CancelUpdate event,
    Emitter<InvoiceHistoryHeaderState> emit,
  ) {
    emit(state.copyWith(selected1: null, editItems: const []));
  }

  void _onCancelCreate(
    CancelCreate event,
    Emitter<InvoiceHistoryHeaderState> emit,
  ) {
    emit(
      state.copyWith(selected: null, createItems: const [], items: const []),
    );
  }

  Future<void> _onDiscardChanges(
    DiscardChanges event,
    Emitter<InvoiceHistoryHeaderState> emit,
  ) async {
    // Remove items that have IDs (are saved)
    final itemsToDelete = state.createItems
        .where((item) => item.id != null)
        .toList();

    if (itemsToDelete.isNotEmpty) {
      final idsToDelete = itemsToDelete.map((item) => item.id!).toList();
      add(DeleteMultipleInvoiceHistoryHeaders(headers: itemsToDelete));
    }

    emit(
      state.copyWith(
        selected: null,
        createItems: const [],
        items: const [],
        successMessage: 'All records are removed',
      ),
    );
  }

  // Selection Management
  void _onSelectInvoiceHistoryHeader(
    SelectInvoiceHistoryHeader event,
    Emitter<InvoiceHistoryHeaderState> emit,
  ) {
    emit(state.copyWith(selected: event.header, selected1: event.header));
  }

  void _onSelectMultipleInvoiceHistoryHeaders(
    SelectMultipleInvoiceHistoryHeaders event,
    Emitter<InvoiceHistoryHeaderState> emit,
  ) {
    emit(
      state.copyWith(
        multiselectionItems: event.headers,
        isSelectionMode: event.headers.isNotEmpty,
      ),
    );
  }

  void _onClearSelection(
    ClearSelection event,
    Emitter<InvoiceHistoryHeaderState> emit,
  ) {
    emit(
      state.copyWith(
        selectedItems: const [],
        multiselectionItems: const [],
        isSelectionMode: false,
      ),
    );
  }

  // Filtering & Search
  Future<void> _onFilterInvoiceHistoryHeaders(
    FilterInvoiceHistoryHeaders event,
    Emitter<InvoiceHistoryHeaderState> emit,
  ) async {
    try {
      emit(state.copyWith(status: InvoiceHistoryHeaderStatus.filtering));

      final filteredHeaders = await repository.filterInvoiceHistoryHeaders(
        companyId: state.companyId!,
        customerName: event.filter.customerName,
        startDate: event.startDate,
        endDate: event.endDate,
        tinNumber: event.filter.tinNumber,
        fsNumber: event.filter.fsNumber,
      );

      emit(
        state.copyWith(
          status: InvoiceHistoryHeaderStatus.loaded,
          filteredValues: filteredHeaders,
          selected3: event.filter,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: InvoiceHistoryHeaderStatus.failure,
          errorMessage: 'Failed to filter invoice history headers: $e',
        ),
      );
    }
  }

  void _onSearchInvoiceHistoryHeaders(
    SearchInvoiceHistoryHeaders event,
    Emitter<InvoiceHistoryHeaderState> emit,
  ) {
    if (event.query.isEmpty) {
      emit(state.copyWith(searchQuery: null, filteredValues: state.items));
      return;
    }

    final query = event.query.toLowerCase();
    final filtered = state.items.where((header) {
      return header.mrcNumber?.toLowerCase().contains(query) == true ||
          header.customerName?.toLowerCase().contains(query) == true ||
          header.fsNumber?.toLowerCase().contains(query) == true;
    }).toList();

    emit(state.copyWith(searchQuery: event.query, filteredValues: filtered));
  }

  void _onClearFilters(
    ClearFilters event,
    Emitter<InvoiceHistoryHeaderState> emit,
  ) {
    emit(
      state.copyWith(
        filteredValues: state.items,
        searchQuery: null,
        selected3: null,
      ),
    );
  }

  // Batch Operations
  Future<void> _onSaveRow(
    SaveRow event,
    Emitter<InvoiceHistoryHeaderState> emit,
  ) async {
    try {
      emit(state.copyWith(status: InvoiceHistoryHeaderStatus.saving));

      for (var item in state.editItems) {
        if (item.id == null) {
          item = item.copyWith(company: authBloc.state.companyId);
          await repository.createInvoiceHistoryHeader(item);
        } else {
          await repository.updateInvoiceHistoryHeader(item);
        }
      }

      emit(
        state.copyWith(
          status: InvoiceHistoryHeaderStatus.success,
          successMessage: 'Saved',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: InvoiceHistoryHeaderStatus.failure,
          //errorMessage: 'Failed to save row: $e',
        ),
      );
      if (kDebugMode) {
        developer.log('Failed to save row: $e');
      }
    }
  }

  Future<void> _onSaveInEdit(
    SaveInEdit event,
    Emitter<InvoiceHistoryHeaderState> emit,
  ) async {
    try {
      emit(state.copyWith(status: InvoiceHistoryHeaderStatus.saving));

      for (var item in state.editItems) {
        if (item.id == null) {
          item = item.copyWith(company: authBloc.state.companyId);
          await repository.createInvoiceHistoryHeader(item);
        } else {
          await repository.updateInvoiceHistoryHeader(item);
        }
      }

      // Refresh list like Java
      add(LoadInvoiceHistoryHeaders(companyId: state.companyId!));

      emit(
        state.copyWith(
          status: InvoiceHistoryHeaderStatus.success,
          successMessage: 'Saved',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: InvoiceHistoryHeaderStatus.failure,
          //errorMessage: 'Failed to save in edit: $e',
        ),
      );
      if (kDebugMode) {
        developer.log('Failed to save in edit: $e');
      }
    }
  }

  // Item Management in Lists
  Future<void> _onRemoveInCreate(
    RemoveInCreate event,
    Emitter<InvoiceHistoryHeaderState> emit,
  ) async {
    final updatedCreateItems = state.createItems.where((item) {
      if (item.id == null) {
        return item.tempId != event.item.tempId;
      } else {
        return item.id != event.item.id;
      }
    }).toList();

    // If the item has an ID, delete it from database
    if (event.item.id != null) {
      add(DeleteInvoiceHistoryHeader(id: event.item.id!));
    }

    emit(state.copyWith(createItems: updatedCreateItems));
  }

  Future<void> _onRemoveRecord(
    RemoveRecord event,
    Emitter<InvoiceHistoryHeaderState> emit,
  ) async {
    if (event.item.id != null) {
      add(DeleteInvoiceHistoryHeader(id: event.item.id!));
    }
  }

  Future<void> _onRemoveList(
    RemoveList event,
    Emitter<InvoiceHistoryHeaderState> emit,
  ) async {
    if (event.aList.isNotEmpty) {
      add(DeleteMultipleInvoiceHistoryHeaders(headers: event.aList));
    }
  }

  int _getNextTempId(List<InvoiceHistoryHeader> items) {
    if (items.isEmpty) return 1;
    final maxTempId = items
        .map((e) => e.tempId ?? 0)
        .reduce((a, b) => a > b ? a : b);
    return maxTempId + 1;
  }
}
