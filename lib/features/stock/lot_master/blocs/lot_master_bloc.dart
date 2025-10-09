// features/ItemEntry/blocs/ItemEntry_bloc.dart

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/stock/item_entry/blocs/item_entry_event.dart';
import 'package:savvy_stock/features/stock/item_entry/blocs/item_entry_state.dart';
import 'package:savvy_stock/features/stock/item_entry/models/item_entry_model.dart';

class StockItemEntryBloc extends Bloc<ItemEntryEvent, ItemEntryState> {
  final LocalDatabaseService databaseService;
  final AuthBloc authBloc;
  StreamSubscription? _authSubscription;

  StockItemEntryBloc({required this.databaseService, required this.authBloc})
    : super(const ItemEntryState()) {
    // Listen to auth state changes
    _authSubscription = authBloc.stream.listen((authState) {
      if (authState.isAuthenticated && authState.companyId != null) {
        add(LoadItems(authState.companyId!));
      }
    });
    on<LoadItems>(_onLoadItems);
    on<CreateItem>(_onCreateItem);
    on<UpdateItem>(_onUpdateItem);
    on<DeleteItem>(_onDeleteItem);
    on<SearchItems>(_onSearchItem);
    on<SelectItem>(_onSelectItem);
    on<SelectAllItems>(_onSelectAllItemEntrys);
    on<ClearSelection>(_onClearSelection);
    on<DeleteSelectedItems>(_onDeleteSelectedItemEntrys);
    on<ShowItemDetail>(_onShowItemEntryDetail);
    on<HideItemDetail>(_onHideItemEntryDetail);
    on<ExportItem>(_onExportItemEntry);
    on<ExportSingleItem>(_onExportSingleItemEntry);
    on<SetItemForm>(_onSetItemEntryForm);
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }

  Future<void> _onLoadItems(
    LoadItems event,
    Emitter<ItemEntryState> emit,
  ) async {
    emit(ItemEntryState(status: ItemEntryStatus.loading));
    try {
      final db = await databaseService.database;
      final items = await db.query(
        'items_table',
        where: 'company = ?',
        whereArgs: [event.companyId],
      );

      final itemList = items.map((p) => ItemEntryModel.fromMap(p)).toList();

      emit(
        ItemEntryState(
          status: ItemEntryStatus.success,
          items: itemList,
          filteredItems: itemList,
          searchQuery: '',
          detailStatus: ItemEntryDetailStatus.hidden,
          companyId: event.companyId,
          selectedItems: [],
        ),
      );
    } catch (e) {
      emit(
        ItemEntryState(
          status: ItemEntryStatus.failure,
          message: 'Failed to load Items: $e',
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
        message: 'Creating Item...',
      ),
    );
    try {
      final db = await databaseService.database;
      final itemMap = event.item.toMap();

      //remove id for new employee insrtion
      itemMap.remove('id');

      //add creation metadata
      itemMap['company'] = authBloc.state.companyId;

      await db.insert('items_table', itemMap);
      add(LoadItems(authBloc.state.companyId!));
      emit(
        state.copyWith(
          status: ItemEntryStatus.success,
          message: 'Item created successfully',
        ),
      );
    } catch (e) {
      emit(
        ItemEntryState(
          status: ItemEntryStatus.failure,
          message: 'Failed to create Item: $e',
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
        message: 'Updating Item...',
      ),
    );
    try {
      final db = await databaseService.database;
      final companyId = authBloc.state.companyId;

      // FIX: Add null checks
      if (companyId == null) {
        emit(
          state.copyWith(
            status: ItemEntryStatus.failure,
            message: 'Authentication error: Company ID not found',
          ),
        );
        return;
      }

      final itemMap = event.item.toMap();

      // FIX: Ensure company field is included and not null
      itemMap['company'] = companyId; // Make sure company is set

      await db.update(
        'items_table',
        itemMap,
        where: 'id = ? AND company = ?',
        whereArgs: [event.item.id, companyId],
      );

      add(LoadItems(companyId));

      emit(
        state.copyWith(
          status: ItemEntryStatus.success,
          message: 'Item updated successfully',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ItemEntryStatus.failure,
          message: 'Failed to update ItemEntry: $e',
        ),
      );
    }
  }

  Future<void> _onDeleteItem(
    DeleteItem event,
    Emitter<ItemEntryState> emit,
  ) async {
    emit(
      state.copyWith(status: ItemEntryStatus.deleting, message: 'Deleting..'),
    );
    try {
      final db = await databaseService.database;
      await db.delete(
        'items_table',
        where: 'id = ? AND company = ?',
        whereArgs: [event.itemId, authBloc.state.companyId],
      );
      final updateItemEntrys = List<ItemEntryModel>.from(state.items)
        ..removeWhere((p) => p.id == event.itemId);
      final updateFilteredItemEntrys = List<ItemEntryModel>.from(
        state.filteredItems,
      )..removeWhere((p) => p.id == event.itemId);
      emit(
        state.copyWith(
          items: updateItemEntrys,
          filteredItems: updateFilteredItemEntrys,
          recentlyDeleted: [...state.recentlyDeleted, event.deletedItem],
          recentlyDeletedIndexes: [
            ...state.recentlyDeletedIndexes,
            event.deletedIndex,
          ],
          message: 'Item deleted successfully',
        ),
      );
      add(LoadItems(authBloc.state.companyId!));
    } catch (e) {
      emit(
        ItemEntryState(
          status: ItemEntryStatus.failure,
          message: 'Failed to delete Item: $e',
        ),
      );
    }
  }

  void _onClearSelection(ClearSelection event, Emitter<ItemEntryState> emit) {
    emit(state.copyWith(selectedItems: []));
  }

  void _onSearchItem(SearchItems event, Emitter<ItemEntryState> emit) {
    final query = event.query.toLowerCase().trim();

    if (query.isEmpty) {
      emit(
        state.copyWith(
          filteredItems: state.items,
          selectedItems: [],
          searchQuery: '',
          status: ItemEntryStatus.success,
        ),
      );
      return;
    }

    final filtered = state.items.where((item) {
      return item.barcode!.toLowerCase().contains(query) ||
          item.itemDescription!.toLowerCase().contains(query) ||
          item.itemsId!.toLowerCase().contains(query);
    }).toList();

    emit(
      state.copyWith(
        filteredItems: filtered,
        searchQuery: query,
        selectedItems: [],
        status: ItemEntryStatus.searching,
      ),
    );
  }

  void _onSelectItem(SelectItem event, Emitter<ItemEntryState> emit) {
    final selectedItems = List<ItemEntryModel>.from(state.selectedItems);
    if (event.isSelected) {
      selectedItems.add(event.item);
    } else {
      selectedItems.removeWhere((item) => item.id == event.item.id);
    }
    emit(state.copyWith(selectedItems: selectedItems));
  }

  void _onSelectAllItemEntrys(
    SelectAllItems event,
    Emitter<ItemEntryState> emit,
  ) {
    if (state.selectedItems.length == event.items.length) {
      // If all are selected, clear selection
      emit(state.copyWith(selectedItems: []));
    } else {
      // Select all
      emit(state.copyWith(selectedItems: List.from(event.items)));
    }
  }

  void _onSetItemEntryForm(SetItemForm event, Emitter<ItemEntryState> emit) {
    emit(state.copyWith(itemForm: event.item));
  }

  void _onDeleteSelectedItemEntrys(
    DeleteSelectedItems event,
    Emitter<ItemEntryState> emit,
  ) async {
    try {
      final db = await databaseService.database;
      final placeholders = List.filled(
        event.selectedItems.length,
        '?',
      ).join(',');
      final whereArgs = [...event.selectedItems, authBloc.state.companyId];
      await db.delete(
        'items_table',
        where: 'id IN ($placeholders) AND company = ?',
        whereArgs: whereArgs,
      );
      final updatedItemEntrys = state.items
          .where((e) => !event.selectedItems.contains(e.id))
          .toList();
      final updatedFiltered = state.filteredItems
          .where((e) => !event.selectedItems.contains(e.id))
          .toList();

      emit(
        state.copyWith(
          items: updatedItemEntrys,
          filteredItems: updatedFiltered,
          selectedItems: [],
          recentlyDeleted: [...state.recentlyDeleted, ...event.deletedItems],
          recentlyDeletedIndexes: [
            ...state.recentlyDeletedIndexes,
            ...event.deletedIndexes,
          ],
          message: '${event.selectedItems.length} items deleted successfully',
        ),
      );
      add(LoadItems(authBloc.state.companyId!));
    } catch (e) {
      emit(
        ItemEntryState(
          status: ItemEntryStatus.failure,
          message: 'Failed to delete selected Items: $e',
        ),
      );
    }
  }

  void _onShowItemEntryDetail(
    ShowItemDetail event,
    Emitter<ItemEntryState> emit,
  ) {
    emit(
      state.copyWith(
        itemDetail: event.item,
        detailStatus: ItemEntryDetailStatus.showing,
        showDetailPanel: true,
      ),
    );
  }

  void _onHideItemEntryDetail(
    HideItemDetail event,
    Emitter<ItemEntryState> emit,
  ) {
    emit(
      state.copyWith(
        detailStatus: ItemEntryDetailStatus.hidden,
        itemDetail: null,
        showDetailPanel: false,
      ),
    );
  }

  void _onExportItemEntry(ExportItem event, Emitter<ItemEntryState> emit) {
    emit(state.copyWith(status: ItemEntryStatus.exporting, isExporting: true));

    // Simulate export process
    Future.delayed(const Duration(seconds: 2), () {
      emit(
        state.copyWith(
          status: ItemEntryStatus.success,
          isExporting: false,
          exportedItems: event.itemsToExport,
          message: 'Exported ${event.itemsToExport.length} items successfully',
        ),
      );
    });
  }

  void _onExportSingleItemEntry(
    ExportSingleItem event,
    Emitter<ItemEntryState> emit,
  ) {
    emit(state.copyWith(status: ItemEntryStatus.exporting, isExporting: true));

    // Simulate export process
    Future.delayed(const Duration(seconds: 2), () {
      emit(
        state.copyWith(
          status: ItemEntryStatus.success,
          isExporting: false,
          exportedItem: event.itemToExport,
          message: 'Exported ${event.itemToExport} items successfully',
        ),
      );
    });
  }
}
