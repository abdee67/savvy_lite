// features/stock/items_table/blocs/items_table_bloc.dart

import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:savvy_stock/core/blocs/system_constant/system_constant_bloc.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/stock/item_entry/blocs/item_entry_event.dart';
import 'package:savvy_stock/features/stock/item_entry/blocs/item_entry_state.dart';
import 'package:savvy_stock/features/stock/item_entry/data/item_repository.dart';
import 'package:savvy_stock/features/stock/item_entry/models/item_entry_model.dart';
import 'package:savvy_stock/features/stock/item_in_branch/blocs/item_in_branch_bloc.dart';

class StockItemsEntryBloc extends Bloc<ItemEntryEvent, ItemEntryState> {
  final StockItemsEntryRepository repository;
  final AuthBloc authBloc;
  final SystemConstantBloc systemConstantBloc;
  final StockItemInBranchBloc itemsInBranchBloc;

  StreamSubscription? _authSubscription;
  StreamSubscription? _systemConstantSubscription;

  StockItemsEntryBloc({
    required this.repository,
    required this.authBloc,
    required this.systemConstantBloc,
    required this.itemsInBranchBloc,
  }) : super(ItemEntryState()) {
    // Listen to auth state changes
    _authSubscription = authBloc.stream.listen((authState) {
      if (authState.isAuthenticated && authState.companyId != null) {
        add(LoadItems(authState.companyId!));
      }
    });

    // Listen to system constant changes
    _systemConstantSubscription = systemConstantBloc.stream.listen((
      systemState,
    ) {
      // Handle system constant changes
    });

    // Event handlers - Core CRUD operations
    on<LoadItems>(_onLoadItems);
    on<CreateItem>(_onCreateItem);
    on<UpdateItem>(_onUpdateItem);
    on<DeleteItem>(_onDeleteItem);
    on<DeleteSelectedItems>(_onDeleteSelectedItems);

    // Event handlers - Preparation operations (from Java controller)
    on<PrepareCreate>(_onPrepareCreate);
    on<PrepareCopy>(_onPrepareCopy);
    on<PrepareCreateInCreate>(_onPrepareCreateInCreate);
    on<PrepareCreateInCreate1>(_onPrepareCreateInCreate1);
    on<PrepareCreateInCreateFormain>(_onPrepareCreateInCreateFormain);
    on<PrepareCreateInEdit>(_onPrepareCreateInEdit);
    on<PrepareEdit>(_onPrepareEdit);
    //on<PrepareEdit1>(_onPrepareEdit1);

    // Event handlers - Complex business operations (from Java controller)
    on<SaveRow>(_onSaveRow);
    on<SaveRow1>(_onSaveRow1);
    on<SaveRowMain>(_onSaveRowMain);
    on<SaveInEdit>(_onSaveInEdit);
    on<CreateInEdit>(_onCreateInEdit);
    on<RemoveInCreate>(_onRemoveInCreate);
    on<RemoveInEdit>(_onRemoveInEdit);
    on<RemoveRecord>(_onRemoveRecord);
    on<CancelUpdate>(_onCancelUpdate);
    on<CancelCreate>(_onCancelCreate);
    on<DiscardChanges>(_onDiscardChanges);
    on<RefreshList>(_onRefreshList);
    on<RefreshList1>(_onRefreshList1);

    // Event handlers - Filter and search operations
    on<FilterItemList>(_onFilterItemList);
    on<SearchItems>(_onSearchItems);
    on<GenerateBarcodes>(_onGenerateBarcodes);

    // Event handlers - Selection and UI operations
    on<SelectItem>(_onSelectItem);
    on<SelectAllItems>(_onSelectAllItems);
    on<ClearSelection>(_onClearSelection);
    on<ShowItemDetail>(_onShowItemDetail);
    on<HideItemDetail>(_onHideItemDetail);
    on<SetItemForm>(_onSetItemForm);

    // Event handlers - Navigation operations
    on<SaveAndClose>(_onSaveAndClose);
    on<SaveAndAddNew>(_onSaveAndAddNew);
    //on<SaveAndAddContinue>(_onSaveAndAddContinue);
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    _systemConstantSubscription?.cancel();
    return super.close();
  }

  // ========== CORE CRUD OPERATIONS ==========

  Future<void> _onLoadItems(
    LoadItems event,
    Emitter<ItemEntryState> emit,
  ) async {
    emit(state.copyWith(status: ItemEntryStatus.loading));

    try {
      final items = await repository.findAll(event.companyId);

      emit(
        state.copyWith(
          status: ItemEntryStatus.loaded,
          items: items,
          filteredItems: items,
          companyId: event.companyId,
          selectedItems: [],
          searchQuery: '',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ItemEntryStatus.failure,
          message: 'Failed to load items: $e',
        ),
      );
    }
  }

  Future<void> _onCreateItem(
    CreateItem event,
    Emitter<ItemEntryState> emit,
  ) async {
    emit(
      state.copyWith(
        status: ItemEntryStatus.creating,
        message: 'Creating item...',
      ),
    );

    try {
      final companyId = authBloc.state.companyId;
      if (companyId == null) {
        throw Exception('Company ID not found');
      }

      // Check for duplication
      final isDuplicate = await _duplicateChecker(event.item, companyId);
      if (isDuplicate) {
        emit(
          state.copyWith(
            status: ItemEntryStatus.duplication,
            message: 'Duplicate Item ID or Barcode Not Allowed!',
          ),
        );
        return;
      }

      // Generate barcode if needed
      var itemToCreate = event.item;
      final selected = systemConstantBloc.state.selected;
      if (selected?.generateBarcodeForItemBoolean == true &&
          (itemToCreate.barcode == null || itemToCreate.barcode!.isEmpty)) {
        final barcode = await repository.generateUniqueBarcode(companyId);
        itemToCreate = itemToCreate.copyWith(barcode: barcode);
      }

      // Set company and create
      itemToCreate = itemToCreate.copyWith(company: companyId);
      await repository.create(itemToCreate);

      // Reload items
      add(LoadItems(companyId));

      emit(
        state.copyWith(
          status: ItemEntryStatus.success,
          message: 'Item created successfully',
        ),
      );
      add(LoadItems(companyId));
    } catch (e) {
      emit(
        state.copyWith(
          status: ItemEntryStatus.failure,
          message: 'Failed to create item: $e',
        ),
      );
    }
  }

  Future<void> _onUpdateItem(
    UpdateItem event,
    Emitter<ItemEntryState> emit,
  ) async {
    emit(
      state.copyWith(
        status: ItemEntryStatus.updating,
        message: 'Updating item...',
      ),
    );

    try {
      final companyId = authBloc.state.companyId;
      if (companyId == null) {
        throw Exception('Company ID not found');
      }

      // Check for duplication
      final isDuplicate = await _duplicateChecker(event.item, companyId);
      if (isDuplicate) {
        emit(
          state.copyWith(
            status: ItemEntryStatus.duplication,
            message: 'Duplicate Item ID or Barcode Not Allowed!',
          ),
        );
        return;
      }

      await repository.update(event.item);

      // Reload items
      add(LoadItems(companyId));

      emit(
        state.copyWith(
          status: ItemEntryStatus.success,
          message: 'Item updated successfully',
        ),
      );
      add(LoadItems(companyId));
    } catch (e) {
      emit(
        state.copyWith(
          status: ItemEntryStatus.failure,
          message: 'Failed to update item: $e',
        ),
      );
    }
  }

  // ========== COMPLEX BUSINESS LOGIC FROM JAVA CONTROLLER ==========

  Future<void> _onSaveRow(SaveRow event, Emitter<ItemEntryState> emit) async {
    emit(
      state.copyWith(
        status: ItemEntryStatus.updating,
        message: 'Saving row...',
      ),
    );

    try {
      final companyId = authBloc.state.companyId;
      if (companyId == null) {
        throw Exception('Company ID not found');
      }

      var itemToSave = event.item;

      // Generate barcode if needed (like in Java controller)
      final selected = systemConstantBloc.state.selected;
      if (selected?.generateBarcodeForItemBoolean == true &&
          (itemToSave.barcode == null || itemToSave.barcode!.isEmpty)) {
        final barcode = await repository.generateUniqueBarcode(companyId);
        itemToSave = itemToSave.copyWith(barcode: barcode);
      }

      // Duplicate checker like in Java controller
      final isValid = await _duplicateChecker(itemToSave, companyId);

      if (!isValid) {
        emit(
          state.copyWith(
            status: ItemEntryStatus.failure,
            message: 'Duplicate Item ID Not Allowed!',
          ),
        );
        return;
      }

      // Handle barcode like in Java controller
      if (itemToSave.barcode == null || itemToSave.barcode!.isEmpty) {
        itemToSave = itemToSave.copyWith(barcode: null);
      }

      if (itemToSave.id == null || itemToSave.id == 0) {
        // Create new
        itemToSave = itemToSave.copyWith(company: companyId);
        await repository.create(itemToSave);
      } else {
        // Update existing
        await repository.update(itemToSave);
      }

      emit(
        state.copyWith(
          status: ItemEntryStatus.success,
          message: 'Saved successfully',
        ),
      );
      add(LoadItems(companyId));
    } catch (e) {
      emit(
        state.copyWith(
          status: ItemEntryStatus.failure,
          message: 'Failed to save row: $e',
        ),
      );
    }
  }

  Future<void> _onSaveRow1(SaveRow1 event, Emitter<ItemEntryState> emit) async {
    emit(
      state.copyWith(
        status: ItemEntryStatus.updating,
        message: 'Saving row...',
      ),
    );

    try {
      final companyId = authBloc.state.companyId;
      if (companyId == null) {
        throw Exception('Company ID not found');
      }

      var itemToSave = event.item;

      // Generate barcode if needed
      final selected = systemConstantBloc.state.selected;
      if (selected?.generateBarcodeForItemBoolean == true &&
          (itemToSave.barcode == null || itemToSave.barcode!.isEmpty)) {
        final barcode = await repository.generateUniqueBarcode(companyId);
        itemToSave = itemToSave.copyWith(barcode: barcode);
      }

      // Duplicate checker
      final isValid = await _duplicateChecker(itemToSave, companyId);

      if (!isValid) {
        emit(
          state.copyWith(
            status: ItemEntryStatus.failure,
            message: 'Duplicate Item ID Not Allowed!',
          ),
        );
        return;
      }

      if (itemToSave.id == null || itemToSave.id == 0) {
        // Create new
        itemToSave = itemToSave.copyWith(company: companyId);
        await repository.create(itemToSave);
      } else {
        // Update existing
        await repository.update(itemToSave);
      }

      // Refresh and prepare next create like in Java controller
      add(RefreshList());
      add(PrepareCreateInCreate1());

      emit(
        state.copyWith(
          status: ItemEntryStatus.success,
          message: 'Saved successfully',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ItemEntryStatus.failure,
          message: 'Failed to save row: $e',
        ),
      );
    }
  }

  Future<void> _onSaveRowMain(
    SaveRowMain event,
    Emitter<ItemEntryState> emit,
  ) async {
    emit(
      state.copyWith(
        status: ItemEntryStatus.updating,
        message: 'Saving row...',
      ),
    );

    try {
      final companyId = authBloc.state.companyId;
      if (companyId == null) {
        throw Exception('Company ID not found');
      }

      var itemToSave = event.item;

      // Generate barcode if needed
      final selected = systemConstantBloc.state.selected;
      if (selected?.generateBarcodeForItem == 'Y' &&
          (itemToSave.barcode == null || itemToSave.barcode!.isEmpty)) {
        final barcode = await repository.generateUniqueBarcode(companyId);
        itemToSave = itemToSave.copyWith(barcode: barcode);
      }

      // Duplicate checker
      final isValid = await _duplicateChecker(itemToSave, companyId);

      if (!isValid) {
        emit(
          state.copyWith(
            status: ItemEntryStatus.failure,
            message: 'Duplicate Item ID Not Allowed!',
          ),
        );
        return;
      }

      if (itemToSave.id == null || itemToSave.id == 0) {
        // Create new
        itemToSave = itemToSave.copyWith(company: companyId);
        await repository.create(itemToSave);
      } else {
        // Update existing
        await repository.update(itemToSave);
      }

      // Refresh and prepare next create like in Java controller
      add(RefreshList());
      add(PrepareCreateInCreateFormain());

      emit(
        state.copyWith(
          status: ItemEntryStatus.success,
          message: 'Saved successfully',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ItemEntryStatus.failure,
          message: 'Failed to save row: $e',
        ),
      );
    }
  }

  Future<void> _onSaveInEdit(
    SaveInEdit event,
    Emitter<ItemEntryState> emit,
  ) async {
    emit(
      state.copyWith(
        status: ItemEntryStatus.updating,
        message: 'Saving in edit...',
      ),
    );

    try {
      final companyId = authBloc.state.companyId;
      if (companyId == null) {
        throw Exception('Company ID not found');
      }

      for (final item in event.items) {
        var itemToSave = item;

        // Generate barcode if needed
        final selected = systemConstantBloc.state.selected;
        if (selected?.generateBarcodeForItemBoolean == true &&
            (itemToSave.barcode == null || itemToSave.barcode!.isEmpty)) {
          final barcode = await repository.generateUniqueBarcode(companyId);
          itemToSave = itemToSave.copyWith(barcode: barcode);
        }

        // Duplicate checker
        final isValid = await _duplicateChecker(itemToSave, companyId);

        if (!isValid) {
          emit(
            state.copyWith(
              status: ItemEntryStatus.failure,
              message: 'Duplicate Item ID Not Allowed!',
            ),
          );
          return;
        }

        if (itemToSave.id == null || itemToSave.id == 0) {
          // Create new
          itemToSave = itemToSave.copyWith(company: companyId);
          await repository.create(itemToSave);
        } else {
          // Update existing
          await repository.update(itemToSave);
        }
      }

      // Prepare next create/edit like in Java controller

      emit(
        state.copyWith(
          editItems: state.editItems,
          status: ItemEntryStatus.success,
          message: 'Saved successfully',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ItemEntryStatus.failure,
          message: 'Failed to save in edit: $e',
        ),
      );
    }
  }

  // ========== PREPARATION OPERATIONS (FROM JAVA CONTROLLER) ==========

  void _onPrepareCreate(PrepareCreate event, Emitter<ItemEntryState> emit) {
    emit(
      state.copyWith(
        createItems: state.createItems,
        selected: state.selected,
        status: ItemEntryStatus.creating,
      ),
    );
  }

  void _onPrepareCopy(PrepareCopy event, Emitter<ItemEntryState> emit) {
    emit(
      state.copyWith(
        createItems: state.createItems,
        selected: state.selected,
        status: ItemEntryStatus.creating,
      ),
    );

    final selected = event.itemToCopy.copyWith(
      id: null,
      company: authBloc.state.companyId,
    );
    state.createItems.add(selected);

    emit(
      state.copyWith(
        createItems: state.createItems,
        selected: state.selected,
        status: ItemEntryStatus.creating,
      ),
    );
  }

  void _onPrepareCreateInCreate(
    PrepareCreateInCreate event,
    Emitter<ItemEntryState> emit,
  ) {
    emit(
      state.copyWith(
        items: state.items,
        selected1: state.selected1,
        status: ItemEntryStatus.creating,
      ),
    );
  }

  void _onPrepareCreateInCreate1(
    PrepareCreateInCreate1 event,
    Emitter<ItemEntryState> emit,
  ) {
    emit(
      state.copyWith(
        items: state.items,
        selected3: state.selected3,
        status: ItemEntryStatus.creating,
      ),
    );
  }

  void _onPrepareCreateInCreateFormain(
    PrepareCreateInCreateFormain event,
    Emitter<ItemEntryState> emit,
  ) {
    emit(
      state.copyWith(
        editItems: state.editItems,
        selected3: state.selected3,
        status: ItemEntryStatus.creating,
      ),
    );
  }

  void _onPrepareCreateInEdit(
    PrepareCreateInEdit event,
    Emitter<ItemEntryState> emit,
  ) {
    emit(
      state.copyWith(
        editItems: state.editItems,
        selected1: state.selected1,
        status: ItemEntryStatus.creating,
      ),
    );
  }

  void _onPrepareEdit(PrepareEdit event, Emitter<ItemEntryState> emit) {
    emit(
      state.copyWith(
        editItems: state.editItems,
        selected: state.selected,
        status: ItemEntryStatus.editing,
      ),
    );

    final selected = state.multiselectionItems.isNotEmpty
        ? state.multiselectionItems.first
        : null;

    if (selected != null) {
      state.editItems.add(selected);
    }

    emit(
      state.copyWith(
        editItems: state.editItems,
        selected: state.selected,
        status: ItemEntryStatus.editing,
      ),
    );
  }
  /*
  void _onPrepareEdit1(
    PrepareEdit1 event,
    Emitter<ItemEntryState> emit,
  ) {
    itemsInBranchController.getItemsReordersValues();
    itemsInBranchBloc.add(GetItemsReordersValues());
  }
  */

  // ========== FILTER AND SEARCH OPERATIONS ==========

  Future<void> _onFilterItemList(
    FilterItemList event,
    Emitter<ItemEntryState> emit,
  ) async {
    emit(state.copyWith(status: ItemEntryStatus.loading));

    try {
      final companyId = authBloc.state.companyId;
      if (companyId == null) {
        throw Exception('Company ID not found');
      }

      final items = await repository.filter(
        companyId: companyId,
        itemsId: state.selected2!.itemsId,
        itemDescription: state.selected2!.itemDescription,
        barcode: state.selected2!.barcode,
      );

      emit(
        state.copyWith(
          status: ItemEntryStatus.loaded,
          items: items,
          filteredItems: items,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ItemEntryStatus.failure,
          message: 'Failed to filter items: $e',
        ),
      );
    }
  }

  Future<void> _onSearchItems(
    SearchItems event,
    Emitter<ItemEntryState> emit,
  ) async {
    final query = event.query.trim();

    if (query.isEmpty) {
      emit(
        state.copyWith(
          filteredItems: state.items,
          searchQuery: '',
          status: ItemEntryStatus.success,
        ),
      );
      return;
    }

    emit(state.copyWith(status: ItemEntryStatus.searching, searchQuery: query));

    try {
      final companyId = authBloc.state.companyId;
      if (companyId != null) {
        final searchResults = await repository.search(query, companyId);
        emit(
          state.copyWith(
            filteredItems: searchResults,
            status: ItemEntryStatus.success,
          ),
        );
      }
    } catch (e) {
      // Fallback to local search
      final filtered = state.items.where((item) {
        return item.barcode?.toLowerCase().contains(query.toLowerCase()) ==
                true ||
            item.itemDescription?.toLowerCase().contains(query.toLowerCase()) ==
                true ||
            item.itemsId?.toLowerCase().contains(query.toLowerCase()) == true;
      }).toList();

      emit(
        state.copyWith(
          filteredItems: filtered,
          status: ItemEntryStatus.success,
        ),
      );
    }
  }

  Future<void> _onGenerateBarcodes(
    GenerateBarcodes event,
    Emitter<ItemEntryState> emit,
  ) async {
    emit(
      state.copyWith(
        status: ItemEntryStatus.loading,
        message: 'Generating barcodes...',
      ),
    );

    try {
      final companyId = authBloc.state.companyId;
      if (companyId == null) {
        throw Exception('Company ID not found');
      }

      final itemsWithBarcodes = await repository.getItemsWithBarcodes(
        companyId,
      );

      emit(
        state.copyWith(
          barcodeItems: itemsWithBarcodes,
          status: ItemEntryStatus.success,
          message: 'Barcodes loaded successfully',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ItemEntryStatus.failure,
          message: 'Failed to generate barcodes: $e',
        ),
      );
    }
  }

  // ========== HELPER METHODS FROM JAVA CONTROLLER ==========

  // Duplicate checker like in Java controller
  Future<bool> _duplicateChecker(ItemEntryModel item, int companyId) async {
    try {
      final hasValidBarcode =
          item.barcode != null && item.barcode!.trim().isNotEmpty;
      final hasItemsId = item.itemsId != null;

      if (hasItemsId && hasValidBarcode) {
        // Check both itemsId and barcode
        final duplicate = await repository.checkDuplicate(
          companyId: companyId,
          itemsId: item.itemsId,
          barcode: item.barcode,
          excludeId: item.id,
        );
        return !duplicate;
      } else if (hasItemsId) {
        // Check only itemsId
        final duplicate = await repository.itemsIdExists(
          item.itemsId!,
          companyId,
          excludeId: item.id,
        );
        return !duplicate;
      }

      return true; // No itemsId to check
    } catch (e) {
      return false;
    }
  }

  // Preparing temp ID like in Java controller
  List<ItemEntryModel> _preparingTempId(
    ItemEntryModel item,
    List<ItemEntryModel> list,
  ) {
    int tempId = 0;
    if (list.isNotEmpty) {
      for (final existingItem in list) {
        if (existingItem.tempId != null && existingItem.tempId! > tempId) {
          tempId = existingItem.tempId!;
        }
      }
    }
    tempId += 1;
    final newItem = item.copyWith(tempId: tempId);
    list.add(newItem);
    return list;
  }

  // ========== SELECTION AND UI OPERATIONS ==========

  void _onSelectItem(SelectItem event, Emitter<ItemEntryState> emit) {
    final selectedItems = List<ItemEntryModel>.from(state.selectedItems);

    if (event.isSelected) {
      selectedItems.add(event.item);
    } else {
      selectedItems.removeWhere((item) => item.id == event.item.id);
    }

    emit(state.copyWith(selectedItems: selectedItems));
  }

  void _onSelectAllItems(SelectAllItems event, Emitter<ItemEntryState> emit) {
    if (state.selectedItems.length == event.items.length) {
      emit(state.copyWith(selectedItems: []));
    } else {
      emit(state.copyWith(selectedItems: List.from(event.items)));
    }
  }

  void _onClearSelection(ClearSelection event, Emitter<ItemEntryState> emit) {
    emit(state.copyWith(selectedItems: []));
  }

  void _onShowItemDetail(ShowItemDetail event, Emitter<ItemEntryState> emit) {
    emit(
      state.copyWith(
        itemDetail: event.item,
        detailStatus: ItemEntryDetailStatus.showing,
        showDetailPanel: true,
      ),
    );
  }

  void _onHideItemDetail(HideItemDetail event, Emitter<ItemEntryState> emit) {
    emit(
      state.copyWith(
        detailStatus: ItemEntryDetailStatus.hidden,
        itemDetail: null,
        showDetailPanel: false,
      ),
    );
  }

  void _onSetItemForm(SetItemForm event, Emitter<ItemEntryState> emit) {
    emit(state.copyWith(itemForm: event.item));
  }

  // ========== NAVIGATION OPERATIONS ==========

  void _onSaveAndClose(SaveAndClose event, Emitter<ItemEntryState> emit) {
    add(CancelUpdate());
    add(CancelCreate());
    // Navigation would be handled by UI layer
  }

  void _onSaveAndAddNew(SaveAndAddNew event, Emitter<ItemEntryState> emit) {
    emit(
      state.copyWith(
        createItems: state.createItems,
        selected: state.selected,
        selectedItems: [],
        status: ItemEntryStatus.success,
      ),
    );
    // Navigation would be handled by UI layer
  }

  // ========== DELETE OPERATIONS ==========

  Future<void> _onDeleteItem(
    DeleteItem event,
    Emitter<ItemEntryState> emit,
  ) async {
    emit(
      state.copyWith(
        status: ItemEntryStatus.deleting,
        message: 'Deleting item...',
      ),
    );

    try {
      final companyId = authBloc.state.companyId;
      if (companyId == null) {
        throw Exception('Company ID not found');
      }

      await repository.delete(event.itemId, companyId);

      // Update local state
      final updatedItems = state.items
          .where((item) => item.id != event.itemId)
          .toList();
      final updatedFilteredItems = state.filteredItems
          .where((item) => item.id != event.itemId)
          .toList();

      emit(
        state.copyWith(
          items: updatedItems,
          filteredItems: updatedFilteredItems,
          status: ItemEntryStatus.success,
          message: 'Item deleted successfully',
          recentlyDeleted: [...state.recentlyDeleted, event.deletedItem],
          recentlyDeletedIndexes: [
            ...state.recentlyDeletedIndexes,
            event.deletedIndex,
          ],
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ItemEntryStatus.failure,
          message: 'Failed to delete item: $e',
        ),
      );
    }
  }

  Future<void> _onDeleteSelectedItems(
    DeleteSelectedItems event,
    Emitter<ItemEntryState> emit,
  ) async {
    emit(
      state.copyWith(
        status: ItemEntryStatus.deleting,
        message: 'Deleting selected items...',
      ),
    );

    try {
      final companyId = authBloc.state.companyId;
      if (companyId == null) {
        throw Exception('Company ID not found');
      }

      await repository.deleteMultiple(event.selectedItems, companyId);

      // Update local state
      final updatedItems = state.items
          .where((item) => !event.selectedItems.contains(item.id))
          .toList();
      final updatedFilteredItems = state.filteredItems
          .where((item) => !event.selectedItems.contains(item.id))
          .toList();

      emit(
        state.copyWith(
          items: updatedItems,
          filteredItems: updatedFilteredItems,
          selectedItems: [],
          status: ItemEntryStatus.success,
          message: '${event.selectedItems.length} items deleted successfully',
          recentlyDeleted: [...state.recentlyDeleted, ...event.deletedItems],
          recentlyDeletedIndexes: [
            ...state.recentlyDeletedIndexes,
            ...event.deletedIndexes,
          ],
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ItemEntryStatus.failure,
          message: 'Failed to delete selected items: $e',
        ),
      );
    }
  }

  // ========== REMOVE OPERATIONS ==========

  void _onRemoveInCreate(RemoveInCreate event, Emitter<ItemEntryState> emit) {
    if (event.item.id == null) {
      state.createItems.removeWhere(
        (element) => element.tempId == event.item.tempId,
      );
    } else {
      state.createItems.removeWhere((element) => element.id == event.item.id);
      if (event.item.id != null) {
        repository.delete(event.item.id!, authBloc.state.companyId!);
      }
    }

    emit(state.copyWith(createItems: state.createItems));
  }

  void _onRemoveInEdit(RemoveInEdit event, Emitter<ItemEntryState> emit) {
    if (event.item.id == null) {
      state.editItems.removeWhere(
        (element) => element.tempId == event.item.tempId,
      );
    } else {
      state.editItems.removeWhere((element) => element.id == event.item.id);
      if (event.item.id != null) {
        repository.delete(event.item.id!, authBloc.state.companyId!);
      }
    }

    emit(state.copyWith(editItems: state.editItems));
  }

  void _onRemoveRecord(RemoveRecord event, Emitter<ItemEntryState> emit) {
    if (event.item.id != null) {
      repository.delete(event.item.id!, authBloc.state.companyId!);
    }

    emit(state.copyWith(items: null));
  }

  // ========== CANCEL AND REFRESH OPERATIONS ==========

  void _onCancelUpdate(CancelUpdate event, Emitter<ItemEntryState> emit) {
    emit(state.copyWith(selected1: null, editItems: []));
  }

  void _onCancelCreate(CancelCreate event, Emitter<ItemEntryState> emit) {
    emit(state.copyWith(selected: null, editItems: []));
  }

  void _onDiscardChanges(DiscardChanges event, Emitter<ItemEntryState> emit) {
    for (final item in state.createItems) {
      if (item.id != null) {
        repository.delete(item.id!, authBloc.state.companyId!);
      }
    }

    emit(
      state.copyWith(
        selected: null,
        createItems: [],
        items: null,
        message: 'All records are removed',
      ),
    );
  }

  void _onRefreshList(RefreshList event, Emitter<ItemEntryState> emit) {
    emit(state.copyWith(selected: null, editItems: []));

    add(LoadItems(authBloc.state.companyId!));
  }

  void _onRefreshList1(RefreshList1 event, Emitter<ItemEntryState> emit) {
    emit(state.copyWith(selected: null, selected2: null, editItems: []));

    add(LoadItems(authBloc.state.companyId!));
  }

  void _onCreateInEdit(CreateInEdit event, Emitter<ItemEntryState> emit) async {
    try {
      final companyId = authBloc.state.companyId;
      if (companyId == null) throw Exception('Company ID not found');

      final itemToCreate = state.selected1!.copyWith(company: companyId);
      await repository.create(itemToCreate);

      final updatedItems = await repository.findAll(companyId);

      emit(
        state.copyWith(
          items: updatedItems,
          filteredItems: updatedItems,
          status: ItemEntryStatus.success,
          message: 'Created successfully',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ItemEntryStatus.failure,
          message: 'Failed to create item: $e',
        ),
      );
    }
  }

  // ========== PUBLIC METHODS FOR OTHER BLOCS ==========

  Future<ItemEntryModel?> getItemEntryModel(int id) async {
    try {
      final companyId = authBloc.state.companyId;
      if (companyId == null) return null;

      return await repository.findById(id, companyId);
    } catch (e) {
      return null;
    }
  }

  Future<List<ItemEntryModel>> getItemsAvailableSelectMany() async {
    try {
      final companyId = authBloc.state.companyId;
      if (companyId == null) return [];

      return await repository.getItemsForSelectMany(companyId);
    } catch (e) {
      return [];
    }
  }

  Future<List<ItemEntryModel>> getItemsAvailableSelectOne() async {
    try {
      final companyId = authBloc.state.companyId;
      if (companyId == null) return [];

      return await repository.getItemsForSelectOne(companyId);
    } catch (e) {
      return [];
    }
  }
}
