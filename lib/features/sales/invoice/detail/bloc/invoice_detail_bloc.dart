// features/sales/invoice_history/bloc/invoice_history_detail_bloc.dart
import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/sales/invoice/detail/bloc/invoice_detail.event.dart';
import 'package:savvy_stock/features/sales/invoice/detail/bloc/invoice_detail_state.dart';
import 'package:savvy_stock/features/sales/invoice/detail/model/invoice_detail_model.dart';
import 'package:savvy_stock/features/sales/invoice/detail/repo/invoice_detail_repo.dart';
import 'package:savvy_stock/features/sales/invoice/header/bloc/invoice_header_bloc.dart';

class InvoiceHistoryDetailBloc
    extends Bloc<InvoiceHistoryDetailEvent, InvoiceHistoryDetailState> {
  final InvoiceHistoryDetailRepository repository;
  final AuthBloc authBloc;
  final InvoiceHistoryHeaderBloc headerBloc;

  StreamSubscription? _authSubscription;

  InvoiceHistoryDetailBloc({
    required this.repository,
    required this.authBloc,
    required this.headerBloc,
  }) : super(const InvoiceHistoryDetailState()) {
    _authSubscription = authBloc.stream.listen((authState) {
      if (authState.isAuthenticated && authState.companyId != null) {
        add(InvoiceHistoryDetailInitialized(companyId: authState.companyId!));
      }
    });

    // Event handlers - matching Java controller methods
    on<InvoiceHistoryDetailInitialized>(_onInitialized);
    on<LoadInvoiceHistoryDetails>(_onLoadInvoiceHistoryDetails);
    on<CreateInvoiceHistoryDetail>(_onCreateInvoiceHistoryDetail);
    on<UpdateInvoiceHistoryDetail>(_onUpdateInvoiceHistoryDetail);
    on<DeleteInvoiceHistoryDetail>(_onDeleteInvoiceHistoryDetail);
    on<DeleteMultipleInvoiceHistoryDetails>(
      _onDeleteMultipleInvoiceHistoryDetails,
    );

    // Selection Management
    on<SelectInvoiceHistoryDetail>(_onSelectInvoiceHistoryDetail);
    on<SelectMultipleInvoiceHistoryDetails>(
      _onSelectMultipleInvoiceHistoryDetails,
    );
    on<ClearSelection>(_onClearSelection);

    // UI State Management (equivalent to Java preparation methods)
    on<PrepareCreate>(_onPrepareCreate);
    on<PrepareCopy>(_onPrepareCopy);
    on<PrepareCreateInCreate>(_onPrepareCreateInCreate);
    on<PrepareCreate1>(_onPrepareCreate1);
    on<PrepareCreateInEdit>(_onPrepareCreateInEdit);
    on<PrepareEdit>(_onPrepareEdit);
    on<CancelUpdate>(_onCancelUpdate);
    on<CancelCreate>(_onCancelCreate);
    on<DiscardChanges>(_onDiscardChanges);

    // Filtering & Search
    on<FilterInvoiceHistoryDetails>(_onFilterInvoiceHistoryDetails);
    on<SearchInvoiceHistoryDetails>(_onSearchInvoiceHistoryDetails);
    on<ClearFilters>(_onClearFilters);

    // Batch Operations
    on<Save>(_onSave);
    on<SaveRow>(_onSaveRow);
    on<SaveInEdit>(_onSaveInEdit);
    on<CreateInEdit>(_onCreateInEdit);

    // Item Management in Lists
    on<RemoveInCreate>(_onRemoveInCreate);
    on<RemoveInEdit>(_onRemoveInEdit);
    on<RemoveRecord>(_onRemoveRecord);
    on<RemoveList>(_onRemoveList);

    // Utility
    on<RefreshList>(_onRefreshList);
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }

  // Initialization
  Future<void> _onInitialized(
    InvoiceHistoryDetailInitialized event,
    Emitter<InvoiceHistoryDetailState> emit,
  ) async {
    emit(state.copyWith(companyId: event.companyId));
    add(LoadInvoiceHistoryDetails(companyId: event.companyId));
  }

  // Load all items - equivalent to Java's getItems()
  Future<void> _onLoadInvoiceHistoryDetails(
    LoadInvoiceHistoryDetails event,
    Emitter<InvoiceHistoryDetailState> emit,
  ) async {
    try {
      emit(state.copyWith(status: InvoiceHistoryDetailStatus.loading));

      var items = await repository.getInvoiceHistoryDetailsByCompany(
        event.companyId,
      );

      // Filter by company and super user like Java
      items = items.where((item) {
        return item.company == event.companyId;
      }).toList();

      emit(
        state.copyWith(
          status: InvoiceHistoryDetailStatus.loaded,
          items: items,
          filteredValues: items,
          companyId: event.companyId,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: InvoiceHistoryDetailStatus.failure,
          errorMessage: 'Failed to load invoice history details: $e',
        ),
      );
    }
  }

  // CRUD Operations
  Future<void> _onCreateInvoiceHistoryDetail(
    CreateInvoiceHistoryDetail event,
    Emitter<InvoiceHistoryDetailState> emit,
  ) async {
    try {
      emit(state.copyWith(status: InvoiceHistoryDetailStatus.creating));

      // Truncate item name like Java (45 characters)
      final truncatedDetail = event.detail.copyWith(
        item: event.detail.item != null && event.detail.item!.length > 45
            ? event.detail.item!.substring(0, 45)
            : event.detail.item,
      );

      final id = await repository.createInvoiceHistoryDetail(truncatedDetail);
      final createdDetail = truncatedDetail.copyWith(id: id);

      // Update state
      final updatedItems = [createdDetail, ...state.items];
      final updatedCreateItems = state.createItems
          .where((item) => item.tempId != createdDetail.tempId)
          .toList();

      emit(
        state.copyWith(
          status: InvoiceHistoryDetailStatus.success,
          items: updatedItems,
          filteredValues: updatedItems,
          createItems: updatedCreateItems,
          selected: createdDetail,
          successMessage: 'Invoice history detail created successfully',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: InvoiceHistoryDetailStatus.failure,
          errorMessage: 'Failed to create invoice history detail: $e',
        ),
      );
    }
  }

  Future<void> _onUpdateInvoiceHistoryDetail(
    UpdateInvoiceHistoryDetail event,
    Emitter<InvoiceHistoryDetailState> emit,
  ) async {
    try {
      emit(state.copyWith(status: InvoiceHistoryDetailStatus.updating));

      // Truncate item name like Java (45 characters)
      final truncatedDetail = event.detail.copyWith(
        item: event.detail.item != null && event.detail.item!.length > 45
            ? event.detail.item!.substring(0, 45)
            : event.detail.item,
      );

      await repository.updateInvoiceHistoryDetail(truncatedDetail);

      // Update the detail in the lists
      final updatedItems = state.items
          .map((h) => h.id == truncatedDetail.id ? truncatedDetail : h)
          .toList();
      final updatedEditItems = state.editItems
          .where((item) => item.id != truncatedDetail.id)
          .toList();

      emit(
        state.copyWith(
          status: InvoiceHistoryDetailStatus.success,
          items: updatedItems,
          filteredValues: updatedItems,
          editItems: updatedEditItems,
          selected: truncatedDetail,
          successMessage: 'Invoice history detail updated successfully',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: InvoiceHistoryDetailStatus.failure,
          errorMessage: 'Failed to update invoice history detail: $e',
        ),
      );
    }
  }

  Future<void> _onDeleteInvoiceHistoryDetail(
    DeleteInvoiceHistoryDetail event,
    Emitter<InvoiceHistoryDetailState> emit,
  ) async {
    try {
      emit(state.copyWith(status: InvoiceHistoryDetailStatus.deleting));

      await repository.deleteInvoiceHistoryDetail(event.id);

      final updatedItems = state.items.where((h) => h.id != event.id).toList();
      final updatedFilteredValues = state.filteredValues
          .where((h) => h.id != event.id)
          .toList();

      emit(
        state.copyWith(
          status: InvoiceHistoryDetailStatus.success,
          items: updatedItems,
          filteredValues: updatedFilteredValues,
          selected: state.selected?.id == event.id ? null : state.selected,
          successMessage: 'Invoice history detail deleted successfully',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: InvoiceHistoryDetailStatus.failure,
          errorMessage: 'Failed to delete invoice history detail: $e',
        ),
      );
    }
  }

  Future<void> _onDeleteMultipleInvoiceHistoryDetails(
    DeleteMultipleInvoiceHistoryDetails event,
    Emitter<InvoiceHistoryDetailState> emit,
  ) async {
    try {
      emit(state.copyWith(status: InvoiceHistoryDetailStatus.deleting));

      for (final detail in event.details) {
        if (detail.id != null) {
          await repository.deleteInvoiceHistoryDetail(detail.id!);
        }
      }

      final idsToRemove = event.details
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
          status: InvoiceHistoryDetailStatus.success,
          items: updatedItems,
          filteredValues: updatedFilteredValues,
          multiselectionItems: const [],
          successMessage:
              '${event.details.length} invoice history details deleted successfully',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: InvoiceHistoryDetailStatus.failure,
          errorMessage: 'Failed to delete invoice history details: $e',
        ),
      );
    }
  }

  // UI State Management (equivalent to Java preparation methods)
  Future<void> _onPrepareCreate(
    PrepareCreate event,
    Emitter<InvoiceHistoryDetailState> emit,
  ) async {
    final companyId = authBloc.state.companyId;
    if (companyId == null) return;

    final newItem = InvoiceHistoryDetail(
      tempId: _getNextTempId(state.createItems),
      company: companyId,
    );

    emit(
      state.copyWith(
        createItems: [newItem],
        selected: newItem,
        selected2: InvoiceHistoryDetail(company: companyId),
      ),
    );
  }

  Future<void> _onPrepareCopy(
    PrepareCopy event,
    Emitter<InvoiceHistoryDetailState> emit,
  ) async {
    if (state.multiselectionItems.isEmpty) return;

    final companyId = authBloc.state.companyId;
    if (companyId == null) return;

    final copiedItem = state.multiselectionItems.first.copyWith(
      id: null,
      company: companyId,
    );

    final updatedCreateItems = [...state.createItems, copiedItem];

    emit(state.copyWith(createItems: updatedCreateItems, selected: copiedItem));
  }

  Future<void> _onPrepareCreateInCreate(
    PrepareCreateInCreate event,
    Emitter<InvoiceHistoryDetailState> emit,
  ) async {
    final companyId = authBloc.state.companyId;
    if (companyId == null) return;

    final newItem = InvoiceHistoryDetail(
      tempId: _getNextTempId(state.createItems),
      company: companyId,
    );

    final updatedCreateItems = [...state.createItems, newItem];

    emit(state.copyWith(createItems: updatedCreateItems, selected1: newItem));
  }

  Future<void> _onPrepareCreate1(
    PrepareCreate1 event,
    Emitter<InvoiceHistoryDetailState> emit,
  ) async {
    final companyId = authBloc.state.companyId;
    if (companyId == null) return;

    final newItem = InvoiceHistoryDetail(
      tempId: _getNextTempId(state.createItems),
      company: companyId,
    );

    final updatedCreateItems = [...state.createItems, newItem];

    emit(state.copyWith(createItems: updatedCreateItems, selected: newItem));
  }

  Future<void> _onPrepareCreateInEdit(
    PrepareCreateInEdit event,
    Emitter<InvoiceHistoryDetailState> emit,
  ) async {
    final companyId = authBloc.state.companyId;
    if (companyId == null) return;

    final newItem = InvoiceHistoryDetail(
      tempId: _getNextTempId(state.editItems),
      company: companyId,
    );

    final updatedEditItems = [...state.editItems, newItem];

    emit(state.copyWith(editItems: updatedEditItems, selected1: newItem));
  }

  Future<void> _onPrepareEdit(
    PrepareEdit event,
    Emitter<InvoiceHistoryDetailState> emit,
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
    Emitter<InvoiceHistoryDetailState> emit,
  ) {
    emit(state.copyWith(selected1: null, editItems: const []));
  }

  void _onCancelCreate(
    CancelCreate event,
    Emitter<InvoiceHistoryDetailState> emit,
  ) {
    emit(
      state.copyWith(selected: null, createItems: const [], items: const []),
    );
  }

  Future<void> _onDiscardChanges(
    DiscardChanges event,
    Emitter<InvoiceHistoryDetailState> emit,
  ) async {
    // Remove items that have IDs (are saved)
    final itemsToDelete = state.createItems
        .where((item) => item.id != null)
        .toList();

    if (itemsToDelete.isNotEmpty) {
      final idsToDelete = itemsToDelete.map((item) => item.id!).toList();
      add(DeleteMultipleInvoiceHistoryDetails(details: itemsToDelete));
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
  void _onSelectInvoiceHistoryDetail(
    SelectInvoiceHistoryDetail event,
    Emitter<InvoiceHistoryDetailState> emit,
  ) {
    emit(state.copyWith(selected: event.detail, selected1: event.detail));
  }

  void _onSelectMultipleInvoiceHistoryDetails(
    SelectMultipleInvoiceHistoryDetails event,
    Emitter<InvoiceHistoryDetailState> emit,
  ) {
    emit(
      state.copyWith(
        multiselectionItems: event.details,
        isSelectionMode: event.details.isNotEmpty,
      ),
    );
  }

  void _onClearSelection(
    ClearSelection event,
    Emitter<InvoiceHistoryDetailState> emit,
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
  Future<void> _onFilterInvoiceHistoryDetails(
    FilterInvoiceHistoryDetails event,
    Emitter<InvoiceHistoryDetailState> emit,
  ) async {
    try {
      emit(state.copyWith(status: InvoiceHistoryDetailStatus.filtering));

      final filteredDetails = await repository.filterInvoiceHistoryDetails(
        companyId: state.companyId!,
        item: event.filter.item,
        unitOfMeasure: event.filter.unitOfMeasure,
      );

      emit(
        state.copyWith(
          status: InvoiceHistoryDetailStatus.loaded,
          filteredValues: filteredDetails,
          selected3: event.filter,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: InvoiceHistoryDetailStatus.failure,
          errorMessage: 'Failed to filter invoice history details: $e',
        ),
      );
    }
  }

  void _onSearchInvoiceHistoryDetails(
    SearchInvoiceHistoryDetails event,
    Emitter<InvoiceHistoryDetailState> emit,
  ) {
    if (event.query.isEmpty) {
      emit(state.copyWith(searchQuery: null, filteredValues: state.items));
      return;
    }

    final query = event.query.toLowerCase();
    final filtered = state.items.where((detail) {
      return detail.item?.toLowerCase().contains(query) == true ||
          detail.unitOfMeasure?.toLowerCase().contains(query) == true;
    }).toList();

    emit(state.copyWith(searchQuery: event.query, filteredValues: filtered));
  }

  void _onClearFilters(
    ClearFilters event,
    Emitter<InvoiceHistoryDetailState> emit,
  ) {
    emit(
      state.copyWith(
        filteredValues: state.items,
        searchQuery: null,
        selected3: null,
      ),
    );
  }

  // Batch Operations - Save method that integrates with header like Java
  Future<void> _onSave(
    Save event,
    Emitter<InvoiceHistoryDetailState> emit,
  ) async {
    try {
      emit(state.copyWith(status: InvoiceHistoryDetailStatus.saving));

      // Save header first like Java
      //headerBloc.add(SaveHeader());

      // Then save all details
      for (final item in state.createItems) {
        if (item.id == null) {
          // Truncate item name like Java
          final truncatedItem = item.item != null && item.item!.length > 45
              ? item.item!.substring(0, 45)
              : item.item;

          final detailToSave = item.copyWith(
            item: truncatedItem,
            invoiceHistory: headerBloc.state.selected?.id,
            company: authBloc.state.companyId,
          );

          await repository.createInvoiceHistoryDetail(detailToSave);
        } else {
          await repository.updateInvoiceHistoryDetail(item);
        }
      }

      emit(
        state.copyWith(
          status: InvoiceHistoryDetailStatus.success,
          successMessage: 'Invoice history saved successfully',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: InvoiceHistoryDetailStatus.failure,
          errorMessage: 'Failed to save invoice history: $e',
        ),
      );
    }
  }

  Future<void> _onSaveRow(
    SaveRow event,
    Emitter<InvoiceHistoryDetailState> emit,
  ) async {
    try {
      emit(state.copyWith(status: InvoiceHistoryDetailStatus.saving));

      for (final item in state.editItems) {
        if (item.id == null) {
          item.company = authBloc.state.companyId;
          await repository.createInvoiceHistoryDetail(item);
        } else {
          await repository.updateInvoiceHistoryDetail(item);
        }
      }

      emit(
        state.copyWith(
          status: InvoiceHistoryDetailStatus.success,
          successMessage: 'Saved',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: InvoiceHistoryDetailStatus.failure,
          errorMessage: 'Failed to save row: $e',
        ),
      );
    }
  }

  Future<void> _onSaveInEdit(
    SaveInEdit event,
    Emitter<InvoiceHistoryDetailState> emit,
  ) async {
    try {
      emit(state.copyWith(status: InvoiceHistoryDetailStatus.saving));

      for (final item in state.editItems) {
        if (item.id == null) {
          item.company = authBloc.state.companyId;
          await repository.createInvoiceHistoryDetail(item);
        } else {
          await repository.updateInvoiceHistoryDetail(item);
        }
      }

      // Refresh list like Java
      add(LoadInvoiceHistoryDetails(companyId: state.companyId!));

      emit(
        state.copyWith(
          status: InvoiceHistoryDetailStatus.success,
          successMessage: 'Saved',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: InvoiceHistoryDetailStatus.failure,
          errorMessage: 'Failed to save in edit: $e',
        ),
      );
    }
  }

  Future<void> _onCreateInEdit(
    CreateInEdit event,
    Emitter<InvoiceHistoryDetailState> emit,
  ) async {
    try {
      state.selected1!.company = authBloc.state.companyId;
      await repository.createInvoiceHistoryDetail(state.selected1!);

      // Refresh list like Java
      add(LoadInvoiceHistoryDetails(companyId: state.companyId!));

      emit(
        state.copyWith(
          status: InvoiceHistoryDetailStatus.success,
          successMessage: 'Created successfully',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: InvoiceHistoryDetailStatus.failure,
          errorMessage: 'Failed to create in edit: $e',
        ),
      );
    }
  }

  // Item Management in Lists
  Future<void> _onRemoveInCreate(
    RemoveInCreate event,
    Emitter<InvoiceHistoryDetailState> emit,
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
      add(DeleteInvoiceHistoryDetail(id: event.item.id!));
    }

    emit(state.copyWith(createItems: updatedCreateItems));
  }

  Future<void> _onRemoveInEdit(
    RemoveInEdit event,
    Emitter<InvoiceHistoryDetailState> emit,
  ) async {
    final updatedEditItems = state.editItems.where((item) {
      if (item.id == null) {
        return item.tempId != event.item.tempId;
      } else {
        return item.id != event.item.id;
      }
    }).toList();

    // If the item has an ID, delete it from database
    if (event.item.id != null) {
      add(DeleteInvoiceHistoryDetail(id: event.item.id!));
    }

    emit(state.copyWith(editItems: updatedEditItems));
  }

  Future<void> _onRemoveRecord(
    RemoveRecord event,
    Emitter<InvoiceHistoryDetailState> emit,
  ) async {
    if (event.item.id != null) {
      add(DeleteInvoiceHistoryDetail(id: event.item.id!));
    }
  }

  Future<void> _onRemoveList(
    RemoveList event,
    Emitter<InvoiceHistoryDetailState> emit,
  ) async {
    if (event.aList.isNotEmpty) {
      add(DeleteMultipleInvoiceHistoryDetails(details: event.aList));
    }
  }

  // Utility
  void _onRefreshList(
    RefreshList event,
    Emitter<InvoiceHistoryDetailState> emit,
  ) {
    if (state.companyId != null) {
      add(LoadInvoiceHistoryDetails(companyId: state.companyId!));
    }
  }

  // Helper Methods
  int _getNextTempId(List<InvoiceHistoryDetail> items) {
    if (items.isEmpty) return 1;
    final maxTempId = items
        .map((e) => e.tempId ?? 0)
        .reduce((a, b) => a > b ? a : b);
    return maxTempId + 1;
  }

  // Navigation methods like Java's saveAndClose, saveAndAddNew, saveAndAddContinue
  String saveAndClose(String linkName) {
    add(const CancelUpdate());
    add(const CancelCreate());
    return '$linkName?faces-redirect=true';
  }

  String saveAndAddNew(String linkName) {
    add(const CancelCreate());
    final companyId = authBloc.state.companyId;
    if (companyId != null) {
      add(PrepareCreate(companyId: companyId));
    }
    return '$linkName?faces-redirect=true';
  }

  String saveAndAddContinue(String linkName) {
    add(const CancelCreate());
    final companyId = authBloc.state.companyId;
    if (companyId != null && state.selected != null) {
      add(PrepareCreate1(companyId: companyId));
    }
    return '$linkName?faces-redirect=true';
  }
}
