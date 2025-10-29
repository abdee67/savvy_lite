// features/ItemEntry/blocs/ItemEntry_bloc.dart

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/stock/item_locations/blocs/item_locations_event.dart';
import 'package:savvy_stock/features/stock/item_locations/blocs/item_locations_state.dart';
import 'package:savvy_stock/features/stock/item_locations/models/item_locations_model.dart';

class StockItemLocationBloc
    extends Bloc<ItemLocationsEvent, ItemLocationsState> {
  final LocalDatabaseService databaseService;
  final AuthBloc authBloc;
  StreamSubscription? _authSubscription;

  StockItemLocationBloc({required this.databaseService, required this.authBloc})
    : super(const ItemLocationsState()) {
    // Listen to auth state changes
    _authSubscription = authBloc.stream.listen((authState) {
      if (authState.isAuthenticated && authState.companyId != null) {
        add(LoadItems(authState.companyId!));
      }
    });
    on<LoadItems>(_onLoadItems);
    on<LoadItemLocationsByBranchAndItem>(_onLoadItemLocationsByBranchAndItem);
    on<CreateItem>(_onCreateItem);
    on<UpdateItem>(_onUpdateItem);
    on<DeleteItem>(_onDeleteItem);
    on<SearchItems>(_onSearchItem);
    on<SelectItem>(_onSelectItem);
    on<SelectAllItems>(_onSelectAllItemEntrys);
    on<ClearSelection>(_onClearSelection);
    on<DeleteSelectedItems>(_onDeleteSelectedItemEntrys);
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }

  Future<void> _onLoadItems(
    LoadItems event,
    Emitter<ItemLocationsState> emit,
  ) async {
    emit(ItemLocationsState(status: ItemLocationsStatus.loading));
    try {
      final db = await databaseService.database;
      final items = await db.query(
        'item_location',
        where: 'company = ?',
        whereArgs: [event.companyId],
      );

      final itemList = items.map((p) => ItemLocation.fromMap(p)).toList();

      emit(
        ItemLocationsState(
          status: ItemLocationsStatus.success,
          items: itemList,
          filteredItems: itemList,
          searchQuery: '',
          detailStatus: ItemLocationsDetailStatus.hidden,
          companyId: event.companyId,
          selectedItems: [],
        ),
      );
    } catch (e) {
      emit(
        ItemLocationsState(
          status: ItemLocationsStatus.failure,
          message: 'Failed to load Items: $e',
        ),
      );
    }
  }

  Future<void> _onLoadItemLocationsByBranchAndItem(
    LoadItemLocationsByBranchAndItem event,
    Emitter<ItemLocationsState> emit,
  ) async {
    emit(ItemLocationsState(status: ItemLocationsStatus.loading));
    try {
      final db = await databaseService.database;
      final items = await db.rawQuery(
        '''SELECT il.*,
             lm.location_description,
             it.item_description,
             b.description as branch_name
      FROM item_location il
      LEFT JOIN location_master lm ON il.location = lm.id
      LEFT JOIN items_table it ON il.item_number = it.id
      LEFT JOIN branch_table b ON il.branch = b.id
      WHERE il.company = ? AND il.branch = ? AND il.item_number = ?
        ''',
        [event.companyId, event.branchId, event.itemId],
      );

      final itemList = items.map((p) => ItemLocation.fromMap(p)).toList();

      emit(
        ItemLocationsState(
          status: ItemLocationsStatus.success,
          items: itemList,
          filteredItems: itemList,
          searchQuery: '',
          detailStatus: ItemLocationsDetailStatus.hidden,
          companyId: event.companyId,
          selectedItems: [],
        ),
      );
    } catch (e) {
      print('Error loading item location: $e');
      emit(
        ItemLocationsState(
          status: ItemLocationsStatus.failure,
          message: 'Failed to load Items: $e',
        ),
      );
    }
  }

  Future<void> _onCreateItem(
    CreateItem event,
    Emitter<ItemLocationsState> emit,
  ) async {
    emit(
      state.copyWith(
        status: ItemLocationsStatus.creating,
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

      await db.insert('item_location', itemMap);
      add(LoadItems(authBloc.state.companyId!));
      emit(
        state.copyWith(
          status: ItemLocationsStatus.success,
          message: 'Item created successfully',
        ),
      );
    } catch (e) {
      emit(
        ItemLocationsState(
          status: ItemLocationsStatus.failure,
          message: 'Failed to create Item: $e',
        ),
      );
    }
  }

  Future<void> _onUpdateItem(
    UpdateItem event,
    Emitter<ItemLocationsState> emit,
  ) async {
    emit(
      state.copyWith(
        status: ItemLocationsStatus.updating,
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
            status: ItemLocationsStatus.failure,
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
          status: ItemLocationsStatus.success,
          message: 'Item updated successfully',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ItemLocationsStatus.failure,
          message: 'Failed to update ItemEntry: $e',
        ),
      );
    }
  }

  Future<void> _onDeleteItem(
    DeleteItem event,
    Emitter<ItemLocationsState> emit,
  ) async {
    emit(
      state.copyWith(
        status: ItemLocationsStatus.deleting,
        message: 'Deleting..',
      ),
    );
    try {
      final db = await databaseService.database;
      await db.delete(
        'items_table',
        where: 'id = ? AND company = ?',
        whereArgs: [event.itemId, authBloc.state.companyId],
      );
      final updateItemEntrys = List<ItemLocation>.from(state.items)
        ..removeWhere((p) => p.id == event.itemId);
      final updateFilteredItemEntrys = List<ItemLocation>.from(
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
        ItemLocationsState(
          status: ItemLocationsStatus.failure,
          message: 'Failed to delete Item: $e',
        ),
      );
    }
  }

  void _onClearSelection(
    ClearSelection event,
    Emitter<ItemLocationsState> emit,
  ) {
    emit(state.copyWith(selectedItems: []));
  }

  void _onSearchItem(SearchItems event, Emitter<ItemLocationsState> emit) {
    final query = event.query.toLowerCase().trim();

    if (query.isEmpty) {
      emit(
        state.copyWith(
          filteredItems: state.items,
          selectedItems: [],
          searchQuery: '',
          status: ItemLocationsStatus.success,
        ),
      );
      return;
    }

    final filtered = state.items.where((item) {
      return item.location!.toString().toLowerCase().contains(query) ||
          item.itemNumber!.toString().toLowerCase().contains(query);
    }).toList();

    emit(
      state.copyWith(
        filteredItems: filtered,
        searchQuery: query,
        selectedItems: [],
        status: ItemLocationsStatus.searching,
      ),
    );
  }

  void _onSelectItem(SelectItem event, Emitter<ItemLocationsState> emit) {
    final selectedItems = List<ItemLocation>.from(state.selectedItems);
    if (event.isSelected) {
      selectedItems.add(event.item);
    } else {
      selectedItems.removeWhere((item) => item.id == event.item.id);
    }
    emit(state.copyWith(selectedItems: selectedItems));
  }

  void _onSelectAllItemEntrys(
    SelectAllItems event,
    Emitter<ItemLocationsState> emit,
  ) {
    if (state.selectedItems.length == event.items.length) {
      // If all are selected, clear selection
      emit(state.copyWith(selectedItems: []));
    } else {
      // Select all
      emit(state.copyWith(selectedItems: List.from(event.items)));
    }
  }

  void _onDeleteSelectedItemEntrys(
    DeleteSelectedItems event,
    Emitter<ItemLocationsState> emit,
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
        ItemLocationsState(
          status: ItemLocationsStatus.failure,
          message: 'Failed to delete selected Items: $e',
        ),
      );
    }
  }
}
