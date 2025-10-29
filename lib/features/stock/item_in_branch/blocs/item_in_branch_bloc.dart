// features/ItemEntry/blocs/ItemEntry_bloc.dart

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/stock/item_in_branch/blocs/item_in_branch_event.dart';
import 'package:savvy_stock/features/stock/item_in_branch/blocs/item_in_branch_state.dart';
import 'package:savvy_stock/features/stock/item_in_branch/models/item_in_branch_model.dart';

class StockItemInBranchBloc extends Bloc<ItemInBranchEvent, ItemInBranchState> {
  final LocalDatabaseService databaseService;
  final AuthBloc authBloc;
  StreamSubscription? _authSubscription;

  StockItemInBranchBloc({required this.databaseService, required this.authBloc})
    : super(const ItemInBranchState()) {
    // Listen to auth state changes
    _authSubscription = authBloc.stream.listen((authState) {
      if (authState.isAuthenticated && authState.companyId != null) {
        add(LoadItemsFromBranch(authState.companyId!));
      }
    });
    on<LoadItemsFromBranch>(_onLoadBranchItems);
    on<AddItemToBranch>(_onAddItemToBranch);
    on<UpdateItem>(_onUpdateItem);
    on<DeleteItemFromBranch>(_onDeleteItemFromBranch);
    on<SearchItemsFromBranch>(_onSearchItemFromBranch);
    on<SelectItemFromBranch>(_onSelectItemFromBranch);
    on<SelectAllItemsFromBranch>(_onSelectAllItemFromBranch);
    on<ClearSelectionFromBranch>(_onClearSelection);
    on<DeleteSelectedItemsFromBranch>(_onDeleteSelectedItemsFromBranch);
    on<ShowItemDetailFromBranch>(_onShowItemDetailFromBranch);
    on<HideItemDetailFromBranch>(_onHideItemDetailFromBranch);
    on<ExportItemFromBranch>(_onExportItemFromBranch);
    on<ExportSingleItemFromBranch>(_onExportSingleItemFromBranch);
    on<SetItemFormFromBranch>(_onSetItemFormFromBranch);
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }

  Future<void> _onLoadBranchItems(
    LoadItemsFromBranch event,
    Emitter<ItemInBranchState> emit,
  ) async {
    emit(ItemInBranchState(status: ItemInBranchStatus.loading));
    try {
      final db = await databaseService.database;
      // Load branch items with joins to get item and branch details
      final hasBranchFilter = event.branchId != null;
      final whereClause = hasBranchFilter
          ? 'WHERE ib.company = ? AND ib.branch = ?'
          : 'WHERE ib.company = ?';

      final branchItems = await db.rawQuery(
        '''
        SELECT ib.*, 
               i.item_description, i.barcode, i.items_id,
               b.description, b.reference_id
        FROM items_in_branch ib
        LEFT JOIN items_table i ON ib.item_number = i.id
        LEFT JOIN branch_table b ON ib.branch = b.id
        $whereClause
      ''',
        hasBranchFilter
            ? [event.companyId, event.branchId]
            : [event.companyId],
      );

      final itemList = branchItems
          .map((p) => ItemInBranchModel.fromMap(p))
          .toList();

      emit(
        ItemInBranchState(
          status: ItemInBranchStatus.loaded,
          items: itemList,
          filteredItems: itemList,
          searchQuery: '',
          detailStatus: ItemInBranchDetailStatus.hidden,
          companyId: event.companyId,
          selectedItems: [],
        ),
      );
    } catch (e) {
      emit(
        ItemInBranchState(
          status: ItemInBranchStatus.failure,
          message: 'Failed to load Items: $e',
        ),
      );
    }
  }

  Future<void> _onAddItemToBranch(
    AddItemToBranch event,
    Emitter<ItemInBranchState> emit,
  ) async {
    emit(
      state.copyWith(
        status: ItemInBranchStatus.creating,
        message: 'Creating Item...',
      ),
    );
    try {
      final duplication = await _checkDuplication(event.item);
      if (duplication) {
        emit(
          state.copyWith(
            status: ItemInBranchStatus.duplication,
            message: 'Item already exists in selected store',
          ),
        );
        return;
      }
      final db = await databaseService.database;
      final itemMap = event.item.toMap();

      //remove id for new employee insrtion
      itemMap.remove('id');

      //add creation metadata
      itemMap['company'] = authBloc.state.companyId;

      await db.insert('items_in_branch', itemMap);
      add(LoadItemsFromBranch(authBloc.state.companyId!));
      emit(
        state.copyWith(
          status: ItemInBranchStatus.success,
          message: 'Item added successfully',
        ),
      );
    } catch (e) {
      emit(
        ItemInBranchState(
          status: ItemInBranchStatus.failure,
          message: 'Failed to create Item: $e',
        ),
      );
    }
  }

  // check for item duplication in item branch table
  Future<bool> _checkDuplication(ItemInBranchModel newItem) async {
    try {
      final db = await databaseService.database;
      final item = await db.query(
        'items_in_branch',
        where: 'item_number = ? AND branch = ? AND company = ? AND id != ?',
        whereArgs: [
          newItem.itemNumber,
          newItem.branch,
          newItem.company,
          newItem.id,
        ],
      );
      return item.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<void> _onUpdateItem(
    UpdateItem event,
    Emitter<ItemInBranchState> emit,
  ) async {
    emit(
      state.copyWith(
        status: ItemInBranchStatus.updating,
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
            status: ItemInBranchStatus.failure,
            message: 'Authentication error: Company ID not found',
          ),
        );
        return;
      }

      final itemMap = event.item.toMap();

      // FIX: Ensure company field is included and not null
      itemMap['company'] = companyId; // Make sure company is set

      await db.update(
        'items_in_branch',
        itemMap,
        where: 'id = ? AND company = ?',
        whereArgs: [event.item.id, companyId],
      );

      add(LoadItemsFromBranch(companyId));

      emit(
        state.copyWith(
          status: ItemInBranchStatus.success,
          message: 'Item updated successfully',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ItemInBranchStatus.failure,
          message: 'Failed to update ItemEntry: $e',
        ),
      );
    }
  }

  Future<void> _onDeleteItemFromBranch(
    DeleteItemFromBranch event,
    Emitter<ItemInBranchState> emit,
  ) async {
    emit(
      state.copyWith(
        status: ItemInBranchStatus.deleting,
        message: 'Deleting..',
      ),
    );
    try {
      final db = await databaseService.database;
      await db.delete(
        'items_in_branch',
        where: 'id = ? AND company = ?',
        whereArgs: [event.itemId, authBloc.state.companyId],
      );
      final updateItemEntrys = List<ItemInBranchModel>.from(state.items)
        ..removeWhere((p) => p.id == event.itemId);
      final updateFilteredItemEntrys = List<ItemInBranchModel>.from(
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
          message: 'Item deleted from branch successfully',
        ),
      );
      add(LoadItemsFromBranch(authBloc.state.companyId!));
    } catch (e) {
      emit(
        ItemInBranchState(
          status: ItemInBranchStatus.failure,
          message: 'Failed to delete Item: $e',
        ),
      );
    }
  }

  void _onClearSelection(
    ClearSelectionFromBranch event,
    Emitter<ItemInBranchState> emit,
  ) {
    emit(state.copyWith(selectedItems: []));
  }

  void _onSearchItemFromBranch(
    SearchItemsFromBranch event,
    Emitter<ItemInBranchState> emit,
  ) {
    final query = event.query.toLowerCase().trim();

    if (query.isEmpty) {
      emit(
        state.copyWith(
          filteredItems: state.items,
          selectedItems: [],
          searchQuery: '',
          status: ItemInBranchStatus.success,
        ),
      );
      return;
    }

    final filtered = state.items.where((item) {
      return item.branch.toString().toLowerCase().contains(query) ||
          item.itemNumber.toString().toLowerCase().contains(query) ||
          item.marginType!.toString().toLowerCase().contains(query);
    }).toList();

    emit(
      state.copyWith(
        filteredItems: filtered,
        searchQuery: query,
        selectedItems: [],
        status: ItemInBranchStatus.searching,
      ),
    );
  }

  void _onSelectItemFromBranch(
    SelectItemFromBranch event,
    Emitter<ItemInBranchState> emit,
  ) {
    final selectedItems = List<ItemInBranchModel>.from(state.selectedItems);
    if (event.isSelected) {
      selectedItems.add(event.item);
    } else {
      selectedItems.removeWhere((item) => item.id == event.item.id);
    }
    emit(state.copyWith(selectedItems: selectedItems));
  }

  void _onSelectAllItemFromBranch(
    SelectAllItemsFromBranch event,
    Emitter<ItemInBranchState> emit,
  ) {
    if (state.selectedItems.length == event.items.length) {
      // If all are selected, clear selection
      emit(state.copyWith(selectedItems: []));
    } else {
      // Select all
      emit(state.copyWith(selectedItems: List.from(event.items)));
    }
  }

  void _onSetItemFormFromBranch(
    SetItemFormFromBranch event,
    Emitter<ItemInBranchState> emit,
  ) {
    emit(state.copyWith(itemForm: event.item));
  }

  void _onDeleteSelectedItemsFromBranch(
    DeleteSelectedItemsFromBranch event,
    Emitter<ItemInBranchState> emit,
  ) async {
    try {
      final db = await databaseService.database;
      final placeholders = List.filled(
        event.selectedItems.length,
        '?',
      ).join(',');
      final whereArgs = [...event.selectedItems, authBloc.state.companyId];
      await db.delete(
        'items_in_branch',
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
      add(LoadItemsFromBranch(authBloc.state.companyId!));
    } catch (e) {
      emit(
        ItemInBranchState(
          status: ItemInBranchStatus.failure,
          message: 'Failed to delete selected Items: $e',
        ),
      );
    }
  }

  void _onShowItemDetailFromBranch(
    ShowItemDetailFromBranch event,
    Emitter<ItemInBranchState> emit,
  ) {
    emit(
      state.copyWith(
        itemDetail: event.item,
        detailStatus: ItemInBranchDetailStatus.showing,
        showDetailPanel: true,
      ),
    );
  }

  void _onHideItemDetailFromBranch(
    HideItemDetailFromBranch event,
    Emitter<ItemInBranchState> emit,
  ) {
    emit(
      state.copyWith(
        detailStatus: ItemInBranchDetailStatus.hidden,
        itemDetail: null,
        showDetailPanel: false,
      ),
    );
  }

  void _onExportItemFromBranch(
    ExportItemFromBranch event,
    Emitter<ItemInBranchState> emit,
  ) {
    emit(
      state.copyWith(status: ItemInBranchStatus.exporting, isExporting: true),
    );

    // Simulate export process
    Future.delayed(const Duration(seconds: 2), () {
      emit(
        state.copyWith(
          status: ItemInBranchStatus.success,
          isExporting: false,
          exportedItems: event.itemsToExport,
          message: 'Exported ${event.itemsToExport.length} items successfully',
        ),
      );
    });
  }

  void _onExportSingleItemFromBranch(
    ExportSingleItemFromBranch event,
    Emitter<ItemInBranchState> emit,
  ) {
    emit(
      state.copyWith(status: ItemInBranchStatus.exporting, isExporting: true),
    );

    // Simulate export process
    Future.delayed(const Duration(seconds: 2), () {
      emit(
        state.copyWith(
          status: ItemInBranchStatus.success,
          isExporting: false,
          exportedItem: event.itemToExport,
          message: 'Exported ${event.itemToExport} items successfully',
        ),
      );
    });
  }
}
