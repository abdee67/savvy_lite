// lib/features/purchase/supplier/bloc/supplier_bloc.dart
import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/auth/blocs/auth_state.dart';
import 'package:savvy_stock/features/purchase/supplier_entry/blocs/supplier_event.dart';
import 'package:savvy_stock/features/purchase/supplier_entry/blocs/supplier_state.dart';
import 'package:savvy_stock/features/purchase/supplier_entry/models/supplier_model.dart';
import 'package:savvy_stock/features/purchase/supplier_entry/repo/supplier_repo.dart';

class SupplierBloc extends Bloc<SupplierEvent, SupplierState> {
  final SupplierRepository repository;
  final AuthBloc authBloc;
  StreamSubscription<AuthState>? _authSubscription;

  SupplierBloc({required this.repository, required this.authBloc})
    : super(SupplierState.initial()) {
    _authSubscription = authBloc.stream.listen((authState) {
      if (authState.isAuthenticated && authState.companyId != null) {
        add(LoadSuppliers(authState.companyId!));
      }
    });

    // Register all event handlers
    _registerEventHandlers();
  }

  void _registerEventHandlers() {
    // Initialization
    on<LoadSuppliers>(_onLoadSuppliers);
    on<RefreshSuppliers>(_onRefreshSuppliers);

    // CRUD Operations
    on<CreateSupplier>(_onCreateSupplier);
    on<CreateSupplierInEdit>(_onCreateSupplierInEdit);
    on<UpdateSupplier>(_onUpdateSupplier);
    on<DeleteSupplier>(_onDeleteSupplier);
    on<DeleteSelectedSuppliers>(_onDeleteSelectedSuppliers);
    on<SaveSuppliers>(_onSaveSuppliers);
    on<SaveSuppliersInEdit>(_onSaveSuppliersInEdit);

    // Selection Management
    on<SetSelectedSupplier>(_onSetSelectedSupplier);
    on<SetSelectedSupplier1>(_onSetSelectedSupplier1);
    on<SetSelectedSupplier2>(_onSetSelectedSupplier2);
    on<SetMultiSelectionSuppliers>(_onSetMultiSelectionSuppliers);

    // Creation Mode
    on<PrepareCreateSupplier>(_onPrepareCreateSupplier);
    on<PrepareCreateSupplierInCreate>(_onPrepareCreateSupplierInCreate);
    on<PrepareCreateSupplierInEdit>(_onPrepareCreateSupplierInEdit);
    on<PrepareEditSupplier>(_onPrepareEditSupplier);
    on<CopySupplier>(_onCopySupplier);
    on<PrepareCreate1>(_onPrepareCreate1);

    // List Management
    on<AddToCreateList>(_onAddToCreateList);
    on<RemoveFromCreateList>(_onRemoveFromCreateList);
    on<RemoveFromEditList>(_onRemoveFromEditList);
    on<ClearCreateList>(_onClearCreateList);
    on<ClearEditList>(_onClearEditList);
    on<ClearSelection>(_onClearSelection);

    // UI Actions
    on<CancelCreate>(_onCancelCreate);
    on<CancelUpdate>(_onCancelUpdate);
    on<DiscardChanges>(_onDiscardChanges);
    on<SaveRow>(_onSaveRow);
    on<SaveInEdit>(_onSaveInEdit);
    on<RemoveRecord>(_onRemoveRecord);
    on<RemoveList>(_onRemoveList);

    // Search & Filter
    on<FilterSuppliers>(_onFilterSuppliers);
    on<SearchSuppliers>(_onSearchSuppliers);

    // Selection UI
    on<SelectSupplier>(_onSelectSupplier);
    on<SelectAllSuppliers>(_onSelectAllSuppliers);

    // Navigation
    on<SaveAndClose>(_onSaveAndClose);
    on<SaveAndAddNew>(_onSaveAndAddNew);
    on<SaveAndContinue>(_onSaveAndContinue);

    // UI State
    on<SetFirstItemIndex>(_onSetFirstItemIndex);
    on<ClearMessages>(_onClearMessages);
    on<ValidateSupplier>(_onValidateSupplier);
  }

  // Event Handlers Implementation
  Future<void> _onLoadSuppliers(
    LoadSuppliers event,
    Emitter<SupplierState> emit,
  ) async {
    emit(state.loading());

    try {
      final suppliers = await repository.getAllSuppliers(event.companyId);

      emit(
        state.copyWith(
          status: SupplierStatus.loaded,
          suppliers: suppliers,
          filteredSuppliers: suppliers,
          companyId: event.companyId,
          message: 'Suppliers loaded successfully',
        ),
      );
    } catch (e) {
      emit(state.failureState('Failed to load suppliers: $e'));
    }
  }

  Future<void> _onRefreshSuppliers(
    RefreshSuppliers event,
    Emitter<SupplierState> emit,
  ) async {
    try {
      final suppliers = await repository.getAllSuppliers(event.companyId);

      emit(
        state.copyWith(
          suppliers: suppliers,
          filteredSuppliers: suppliers,
          companyId: event.companyId,
        ),
      );
    } catch (e) {
      emit(state.failureState('Failed to refresh suppliers: $e'));
    }
  }

  Future<void> _onCreateSupplier(
    CreateSupplier event,
    Emitter<SupplierState> emit,
  ) async {
    emit(state.creating());

    try {
      final companyId = authBloc.state.companyId;
      if (companyId == null) {
        emit(state.failureState('Authentication error: Company ID not found'));
        return;
      }

      // Validate supplier name uniqueness
      final exists = await repository.validateSupplierExists(
        event.supplier.supplierName ?? '',
        companyId,
      );

      if (exists) {
        emit(state.validationErrorState('Supplier name already exists'));
        return;
      }

      final supplierToSave = event.supplier.copyWith(
        company: companyId,
        dateCreated: DateTime.now(),
        dateUpdated: DateTime.now(),
      );

      await repository.createSupplier(supplierToSave);
      add(LoadSuppliers(companyId));

      emit(state.successState('Supplier created successfully'));
    } catch (e) {
      emit(state.failureState('Failed to create supplier: $e'));
    }
  }

  Future<void> _onCreateSupplierInEdit(
    CreateSupplierInEdit event,
    Emitter<SupplierState> emit,
  ) async {
    emit(state.creating());

    try {
      final companyId = authBloc.state.companyId;
      if (companyId == null) {
        emit(state.failureState('Authentication error: Company ID not found'));
        return;
      }

      final supplierToSave = event.supplier.copyWith(
        company: companyId,
        dateCreated: DateTime.now(),
        dateUpdated: DateTime.now(),
      );

      await repository.createSupplier(supplierToSave);
      add(LoadSuppliers(companyId));

      emit(state.successState('Supplier created successfully'));
    } catch (e) {
      emit(state.failureState('Failed to create supplier: $e'));
    }
  }

  Future<void> _onUpdateSupplier(
    UpdateSupplier event,
    Emitter<SupplierState> emit,
  ) async {
    emit(state.updating());

    try {
      final companyId = authBloc.state.companyId;
      if (companyId == null) {
        emit(state.failureState('Authentication error: Company ID not found'));
        return;
      }

      // Check if supplier exists
      final existingSupplier = await repository.getSupplierById(
        event.supplier.id!,
        companyId,
      );

      if (existingSupplier == null) {
        emit(state.failureState('Supplier not found'));
        return;
      }

      // Validate name uniqueness (excluding current supplier)
      final suppliers = await repository.getAllSuppliers(companyId);
      final duplicate = suppliers.any(
        (s) =>
            s.id != event.supplier.id &&
            s.supplierName?.toLowerCase() ==
                event.supplier.supplierName?.toLowerCase(),
      );

      if (duplicate) {
        emit(state.validationErrorState('Supplier name already exists'));
        return;
      }

      final supplierToUpdate = event.supplier.copyWith(
        dateUpdated: DateTime.now(),
      );

      await repository.updateSupplier(supplierToUpdate);
      add(LoadSuppliers(companyId));

      emit(state.successState('Supplier updated successfully'));
    } catch (e) {
      emit(state.failureState('Failed to update supplier: $e'));
    }
  }

  Future<void> _onDeleteSupplier(
    DeleteSupplier event,
    Emitter<SupplierState> emit,
  ) async {
    emit(state.deleting());

    try {
      final companyId = authBloc.state.companyId;
      if (companyId == null) {
        emit(state.failureState('Authentication error: Company ID not found'));
        return;
      }

      await repository.deleteSupplier(event.deletedItem.id!, companyId);
      add(LoadSuppliers(companyId));

      emit(state.successState('Supplier deleted successfully'));
    } catch (e) {
      emit(state.failureState('Failed to delete supplier: $e'));
    }
  }

  Future<void> _onDeleteSelectedSuppliers(
    DeleteSelectedSuppliers event,
    Emitter<SupplierState> emit,
  ) async {
    emit(state.deleting());

    try {
      final companyId = authBloc.state.companyId;
      if (companyId == null) {
        emit(state.failureState('Authentication error: Company ID not found'));
        return;
      }

      await repository.deleteMultipleSuppliers(event.selectedItems, companyId);
      add(LoadSuppliers(companyId));

      emit(
        state.successState(
          '${event.selectedItems.length} suppliers deleted successfully',
        ),
      );
    } catch (e) {
      emit(state.failureState('Failed to delete suppliers: $e'));
    }
  }

  Future<void> _onSaveSuppliers(
    SaveSuppliers event,
    Emitter<SupplierState> emit,
  ) async {
    emit(state.saving());

    try {
      final companyId = authBloc.state.companyId;
      if (companyId == null) {
        emit(state.failureState('Authentication error: Company ID not found'));
        return;
      }

      final suppliersToSave = event.suppliers.map((supplier) {
        if (supplier.id == null) {
          return supplier.copyWith(
            company: companyId,
            dateCreated: DateTime.now(),
            dateUpdated: DateTime.now(),
          );
        }
        return supplier.copyWith(dateUpdated: DateTime.now());
      }).toList();

      final newSuppliers = suppliersToSave.where((s) => s.id == null).toList();
      final existingSuppliers = suppliersToSave
          .where((s) => s.id != null)
          .toList();

      if (newSuppliers.isNotEmpty) {
        await repository.batchCreateSuppliers(newSuppliers);
      }
      if (existingSuppliers.isNotEmpty) {
        await repository.batchUpdateSuppliers(existingSuppliers);
      }

      add(LoadSuppliers(companyId));
      emit(state.successState('Suppliers saved successfully'));
    } catch (e) {
      emit(state.failureState('Failed to save suppliers: $e'));
    }
  }

  Future<void> _onSaveSuppliersInEdit(
    SaveSuppliersInEdit event,
    Emitter<SupplierState> emit,
  ) async {
    emit(state.saving());

    try {
      final companyId = authBloc.state.companyId;
      if (companyId == null) {
        emit(state.failureState('Authentication error: Company ID not found'));
        return;
      }

      for (final supplier in event.suppliers) {
        if (supplier.id == null) {
          final supplierToSave = supplier.copyWith(
            company: companyId,
            dateCreated: DateTime.now(),
            dateUpdated: DateTime.now(),
          );
          await repository.createSupplier(supplierToSave);
        } else {
          await repository.updateSupplier(
            supplier.copyWith(dateUpdated: DateTime.now()),
          );
        }
      }

      emit(
        state.copyWith(
          status: SupplierStatus.success,
          editItems: const [],
          message: 'Suppliers saved successfully',
        ),
      );
    } catch (e) {
      emit(state.failureState('Failed to save suppliers: $e'));
    }
  }

  // Selection Event Handlers
  void _onSetSelectedSupplier(
    SetSelectedSupplier event,
    Emitter<SupplierState> emit,
  ) {
    emit(state.copyWith(selected: event.supplier));
  }

  void _onSetSelectedSupplier1(
    SetSelectedSupplier1 event,
    Emitter<SupplierState> emit,
  ) {
    emit(state.copyWith(selected1: event.supplier));
  }

  void _onSetSelectedSupplier2(
    SetSelectedSupplier2 event,
    Emitter<SupplierState> emit,
  ) {
    emit(state.copyWith(selected2: event.supplier));
  }

  void _onSetMultiSelectionSuppliers(
    SetMultiSelectionSuppliers event,
    Emitter<SupplierState> emit,
  ) {
    emit(state.copyWith(multiSelectionItems: event.suppliers));
  }

  // Creation Mode Event Handlers
  void _onPrepareCreateSupplier(
    PrepareCreateSupplier event,
    Emitter<SupplierState> emit,
  ) {
    final newSupplier = SupplierModel(
      tempId: event.tempId,
      company: event.companyId,
      country: 'Ethiopia', // Default as per Java
      dateCreated: DateTime.now(),
    );

    emit(
      state.copyWith(
        createItems: [newSupplier],
        selected: newSupplier,
        selected2: SupplierModel(company: event.companyId, country: 'Ethiopia'),
      ),
    );
  }

  void _onPrepareCreateSupplierInCreate(
    PrepareCreateSupplierInCreate event,
    Emitter<SupplierState> emit,
  ) {
    final tempId = _calculateNextTempId(state.createItems);
    final newSupplier = SupplierModel(
      tempId: tempId,
      company: event.companyId,
      country: 'Ethiopia',
      dateCreated: DateTime.now(),
    );

    final updatedCreateItems = List<SupplierModel>.from(state.createItems)
      ..add(newSupplier);

    emit(
      state.copyWith(createItems: updatedCreateItems, selected1: newSupplier),
    );
  }

  void _onPrepareCreateSupplierInEdit(
    PrepareCreateSupplierInEdit event,
    Emitter<SupplierState> emit,
  ) {
    final tempId = _calculateNextTempId(state.editItems);
    final newSupplier = SupplierModel(
      tempId: tempId,
      company: event.companyId,
      country: 'Ethiopia',
      dateCreated: DateTime.now(),
    );

    final updatedEditItems = List<SupplierModel>.from(state.editItems)
      ..add(newSupplier);

    emit(state.copyWith(editItems: updatedEditItems, selected1: newSupplier));
  }

  void _onPrepareEditSupplier(
    PrepareEditSupplier event,
    Emitter<SupplierState> emit,
  ) {
    emit(state.copyWith(editItems: [event.supplier], selected: event.supplier));
  }

  void _onCopySupplier(CopySupplier event, Emitter<SupplierState> emit) {
    final copiedSupplier = event.supplier.copyWith(
      id: null,
      company: event.companyId,
      tempId: _calculateNextTempId(state.createItems),
    );

    final updatedCreateItems = List<SupplierModel>.from(state.createItems)
      ..add(copiedSupplier);

    emit(
      state.copyWith(createItems: updatedCreateItems, selected: copiedSupplier),
    );
  }

  void _onPrepareCreate1(PrepareCreate1 event, Emitter<SupplierState> emit) {
    final tempId = _calculateNextTempId(state.createItems);
    final newSupplier = SupplierModel(
      tempId: tempId,
      company: event.companyId,
      country: 'Ethiopia',
      dateCreated: DateTime.now(),
    );

    final updatedCreateItems = List<SupplierModel>.from(state.createItems)
      ..add(newSupplier);

    emit(
      state.copyWith(createItems: updatedCreateItems, selected: newSupplier),
    );
  }

  // List Management Event Handlers
  void _onAddToCreateList(AddToCreateList event, Emitter<SupplierState> emit) {
    final updatedCreateItems = List<SupplierModel>.from(state.createItems)
      ..add(event.supplier);

    emit(
      state.copyWith(
        createItems: updatedCreateItems,
        selected1: event.supplier,
      ),
    );
  }

  void _onRemoveFromCreateList(
    RemoveFromCreateList event,
    Emitter<SupplierState> emit,
  ) {
    final updatedCreateItems = state.createItems
        .where((supplier) => supplier.tempId != event.supplier.tempId)
        .toList();

    emit(state.copyWith(createItems: updatedCreateItems));
  }

  void _onRemoveFromEditList(
    RemoveFromEditList event,
    Emitter<SupplierState> emit,
  ) {
    final updatedEditItems = state.editItems
        .where((supplier) => supplier.tempId != event.supplier.tempId)
        .toList();

    emit(state.copyWith(editItems: updatedEditItems));
  }

  void _onClearCreateList(ClearCreateList event, Emitter<SupplierState> emit) {
    emit(
      state.copyWith(createItems: const [], selected: null, selected1: null),
    );
  }

  void _onClearEditList(ClearEditList event, Emitter<SupplierState> emit) {
    emit(state.copyWith(editItems: const []));
  }

  void _onClearSelection(ClearSelection event, Emitter<SupplierState> emit) {
    emit(
      state.copyWith(
        selected: null,
        selected1: null,
        selectedSuppliers: const [],
        multiSelectionItems: const [],
      ),
    );
  }

  // UI Event Handlers
  void _onCancelCreate(CancelCreate event, Emitter<SupplierState> emit) {
    emit(
      state.copyWith(
        selected: null,
        createItems: const [],
        suppliers: const [],
      ),
    );
  }

  void _onCancelUpdate(CancelUpdate event, Emitter<SupplierState> emit) {
    emit(state.copyWith(selected1: null, editItems: const []));
  }

  void _onDiscardChanges(DiscardChanges event, Emitter<SupplierState> emit) {
    emit(SupplierState.initial());
  }

  Future<void> _onSaveRow(SaveRow event, Emitter<SupplierState> emit) async {
    emit(state.saving());

    try {
      final companyId = authBloc.state.companyId;
      if (companyId == null) {
        emit(state.failureState('Authentication error: Company ID not found'));
        return;
      }

      if (event.supplier.id == null) {
        final supplierToSave = event.supplier.copyWith(
          company: companyId,
          dateCreated: DateTime.now(),
          dateUpdated: DateTime.now(),
        );
        await repository.createSupplier(supplierToSave);
      } else {
        await repository.updateSupplier(
          event.supplier.copyWith(dateUpdated: DateTime.now()),
        );
      }

      add(LoadSuppliers(companyId));
      emit(state.successState('Supplier saved successfully'));
    } catch (e) {
      emit(state.failureState('Failed to save supplier: $e'));
    }
  }

  Future<void> _onSaveInEdit(
    SaveInEdit event,
    Emitter<SupplierState> emit,
  ) async {
    emit(state.saving());

    try {
      final companyId = authBloc.state.companyId;
      if (companyId == null) {
        emit(state.failureState('Authentication error: Company ID not found'));
        return;
      }

      for (final supplier in event.suppliers) {
        if (supplier.id == null) {
          final supplierToSave = supplier.copyWith(
            company: companyId,
            dateCreated: DateTime.now(),
            dateUpdated: DateTime.now(),
          );
          await repository.createSupplier(supplierToSave);
        } else {
          await repository.updateSupplier(
            supplier.copyWith(dateUpdated: DateTime.now()),
          );
        }
      }

      emit(
        state.copyWith(
          status: SupplierStatus.success,
          editItems: const [],
          message: 'Suppliers saved successfully',
        ),
      );
    } catch (e) {
      emit(state.failureState('Failed to save suppliers: $e'));
    }
  }

  void _onRemoveRecord(RemoveRecord event, Emitter<SupplierState> emit) {
    if (event.supplier.id != null) {
      add(
        DeleteSupplier(
          deletedItem: event.supplier,
          deletedIndex: state.suppliers.indexWhere(
            (s) => s.id == event.supplier.id,
          ),
        ),
      );
    }
  }

  void _onRemoveList(RemoveList event, Emitter<SupplierState> emit) {
    final selectedItems = event.suppliers.map((s) => s.id!).toList();
    final deletedIndexes = event.suppliers
        .map((s) => state.suppliers.indexWhere((item) => item.id == s.id))
        .where((index) => index != -1)
        .toList();

    add(
      DeleteSelectedSuppliers(
        selectedItems: selectedItems,
        deletedItems: event.suppliers,
        deletedIndexes: deletedIndexes,
      ),
    );
  }

  // Search & Filter Event Handlers
  Future<void> _onFilterSuppliers(
    FilterSuppliers event,
    Emitter<SupplierState> emit,
  ) async {
    if (event.query.isEmpty) {
      emit(state.copyWith(filteredSuppliers: state.suppliers));
      return;
    }

    try {
      final filteredSuppliers = await repository.searchSuppliers(
        event.query,
        event.companyId,
      );

      emit(state.copyWith(filteredSuppliers: filteredSuppliers));
    } catch (e) {
      // Fallback to local filtering
      final filteredSuppliers = state.suppliers.where((supplier) {
        return supplier.supplierName?.toLowerCase().contains(
                  event.query.toLowerCase(),
                ) ==
                true ||
            supplier.contactPerson?.toLowerCase().contains(
                  event.query.toLowerCase(),
                ) ==
                true ||
            supplier.email?.toLowerCase().contains(event.query.toLowerCase()) ==
                true ||
            supplier.phoneNo1?.toLowerCase().contains(
                  event.query.toLowerCase(),
                ) ==
                true;
      }).toList();

      emit(state.copyWith(filteredSuppliers: filteredSuppliers));
    }
  }

  Future<void> _onSearchSuppliers(
    SearchSuppliers event,
    Emitter<SupplierState> emit,
  ) async {
    if (event.query.isEmpty) {
      emit(state.copyWith(filteredSuppliers: state.suppliers, searchQuery: ''));
      return;
    }

    try {
      final searchedSuppliers = await repository.searchSuppliers(
        event.query,
        event.companyId,
      );

      emit(
        state.copyWith(
          filteredSuppliers: searchedSuppliers,
          searchQuery: event.query,
        ),
      );
    } catch (e) {
      // Fallback to local search
      final filteredSuppliers = state.suppliers.where((supplier) {
        return supplier.supplierName?.toLowerCase().contains(
                  event.query.toLowerCase(),
                ) ==
                true ||
            supplier.contactPerson?.toLowerCase().contains(
                  event.query.toLowerCase(),
                ) ==
                true ||
            supplier.email?.toLowerCase().contains(event.query.toLowerCase()) ==
                true ||
            supplier.phoneNo1?.toLowerCase().contains(
                  event.query.toLowerCase(),
                ) ==
                true;
      }).toList();

      emit(
        state.copyWith(
          filteredSuppliers: filteredSuppliers,
          searchQuery: event.query,
        ),
      );
    }
  }

  // Selection UI Event Handlers
  void _onSelectSupplier(SelectSupplier event, Emitter<SupplierState> emit) {
    final selectedSuppliers = List<SupplierModel>.from(state.selectedSuppliers);

    if (event.isSelected) {
      selectedSuppliers.add(event.supplier);
    } else {
      selectedSuppliers.removeWhere((s) => s.id == event.supplier.id);
    }

    emit(state.copyWith(selectedSuppliers: selectedSuppliers));
  }

  void _onSelectAllSuppliers(
    SelectAllSuppliers event,
    Emitter<SupplierState> emit,
  ) {
    if (state.selectedSuppliers.length == event.suppliers.length) {
      emit(state.copyWith(selectedSuppliers: const []));
    } else {
      emit(state.copyWith(selectedSuppliers: List.from(event.suppliers)));
    }
  }

  // Navigation Event Handlers
  void _onSaveAndClose(SaveAndClose event, Emitter<SupplierState> emit) {
    emit(state.copyWith(message: 'Saved and closed'));
  }

  void _onSaveAndAddNew(SaveAndAddNew event, Emitter<SupplierState> emit) {
    final newSupplier = SupplierModel(company: event.companyId);
    emit(
      state.copyWith(
        createItems: [newSupplier],
        message: 'Saved and ready for new entry',
      ),
    );
  }

  void _onSaveAndContinue(SaveAndContinue event, Emitter<SupplierState> emit) {
    emit(
      state.copyWith(
        createItems: [event.supplier],
        message: 'Saved and continuing',
      ),
    );
  }

  // UI State Event Handlers
  void _onSetFirstItemIndex(
    SetFirstItemIndex event,
    Emitter<SupplierState> emit,
  ) {
    emit(state.copyWith(firstItemIndex: event.firstIndex));
  }

  void _onClearMessages(ClearMessages event, Emitter<SupplierState> emit) {
    emit(state.clearMessages());
  }

  Future<void> _onValidateSupplier(
    ValidateSupplier event,
    Emitter<SupplierState> emit,
  ) async {
    emit(state.copyWith(status: SupplierStatus.validating));

    try {
      final companyId = authBloc.state.companyId;
      if (companyId == null) {
        emit(state.validationErrorState('Company ID not found'));
        return;
      }

      if (event.supplier.supplierName?.isEmpty ?? true) {
        emit(state.validationErrorState('Supplier name is required'));
        return;
      }

      // Check for duplicate name
      final exists = await repository.validateSupplierExists(
        event.supplier.supplierName!,
        companyId,
      );

      if (exists) {
        emit(state.validationErrorState('Supplier name already exists'));
        return;
      }

      emit(
        state.copyWith(status: SupplierStatus.success, validationError: null),
      );
    } catch (e) {
      emit(state.validationErrorState('Validation error: $e'));
    }
  }

  // Helper Methods
  int _calculateNextTempId(List<SupplierModel> suppliers) {
    if (suppliers.isEmpty) return 1;

    int maxTempId = 0;
    for (final supplier in suppliers) {
      if (supplier.tempId != null && supplier.tempId! > maxTempId) {
        maxTempId = supplier.tempId!;
      }
    }

    return maxTempId + 1;
  }

  // Getters for Java controller equivalents
  List<SupplierModel> getItemsAvailableSelectOne() => state.suppliers;
  List<SupplierModel> getItemsAvailableSelectMany() => state.suppliers;

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
