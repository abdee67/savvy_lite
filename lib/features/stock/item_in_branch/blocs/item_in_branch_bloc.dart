// features/stock/item_in_branch/blocs/item_in_branch_bloc.dart

import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/stock/item_in_branch/blocs/item_in_branch_event.dart';
import 'package:savvy_stock/features/stock/item_in_branch/blocs/item_in_branch_state.dart';
import 'package:savvy_stock/features/stock/item_in_branch/models/item_in_branch_model.dart';
import 'package:savvy_stock/features/stock/item_in_branch/repo/item_in_branch_repo.dart';

class StockItemInBranchBloc extends Bloc<ItemInBranchEvent, ItemInBranchState> {
  final ItemInBranchRepository repository;
  final AuthBloc authBloc;
  StreamSubscription? _authSubscription;

  StockItemInBranchBloc({
    required this.repository,
    required this.authBloc,
  }) : super(const ItemInBranchState()) {
    // Listen to auth state changes
    _authSubscription = authBloc.stream.listen((authState) {
      if (authState.isAuthenticated && authState.companyId != null) {
        add(LoadItemsFromBranch(authState.companyId!));
      }
    });
    
    // Event handlers
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
    
    // New events for advanced functionality
    on<LoadItemBranchByItemAndBranch>(_onLoadItemBranchByItemAndBranch);
    on<UpdateItemBranchUnitPrice>(_onUpdateItemBranchUnitPrice);
    on<LoadItemsInBranchByItem>(_onLoadItemsInBranchByItem);
    on<LoadItemsInBranchByBranch>(_onLoadItemsInBranchByBranch);
    on<LoadLowStockItems>(_onLoadLowStockItems);
    on<LoadOutOfStockItems>(_onLoadOutOfStockItems);
    on<UpdateItemQuantity>(_onUpdateItemQuantity);
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }

  // ========== CORE CRUD OPERATIONS ==========

  Future<void> _onLoadBranchItems(
    LoadItemsFromBranch event,
    Emitter<ItemInBranchState> emit,
  ) async {
    emit(state.copyWith(status: ItemInBranchStatus.loading));
    
    try {
      final items = await repository.findAll(
        event.companyId,
        branchId: event.branchId,
      );

      emit(state.copyWith(
        status: ItemInBranchStatus.loaded,
        items: items,
        filteredItems: items,
        companyId: event.companyId,
        selectedItems: [],
        searchQuery: '',
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ItemInBranchStatus.failure,
        message: 'Failed to load items: $e',
      ));
    }
  }

  Future<void> _onAddItemToBranch(
    AddItemToBranch event,
    Emitter<ItemInBranchState> emit,
  ) async {
    emit(state.copyWith(
      status: ItemInBranchStatus.creating,
      message: 'Adding item to branch...',
    ));
    
    try {
      final companyId = authBloc.state.companyId;
      if (companyId == null) {
        throw Exception('Company ID not found');
      }

      // Check for duplication
      final exists = await repository.existsByItemAndBranch(
        event.item.itemNumber!,
        event.item.branch!,
        companyId,
      );

      if (exists) {
        emit(state.copyWith(
          status: ItemInBranchStatus.duplication,
          message: 'Item already exists in this branch',
        ));
        return;
      }

      // Set company and create
      final itemToCreate = event.item.copyWith(company: companyId);
      await repository.create(itemToCreate);

      // Reload items
      add(LoadItemsFromBranch(companyId, branchId: event.item.branch));

      emit(state.copyWith(
        status: ItemInBranchStatus.success,
        message: 'Item added to branch successfully',
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ItemInBranchStatus.failure,
        message: 'Failed to add item: $e',
      ));
    }
  }

  Future<void> _onUpdateItem(
    UpdateItem event,
    Emitter<ItemInBranchState> emit,
  ) async {
    emit(state.copyWith(
      status: ItemInBranchStatus.updating,
      message: 'Updating item...',
    ));
    
    try {
      final companyId = authBloc.state.companyId;
      if (companyId == null) {
        throw Exception('Company ID not found');
      }

      // Check for duplication (excluding current item)
      final exists = await repository.existsByItemAndBranch(
        event.item.itemNumber!,
        event.item.branch!,
        companyId,
        excludeId: event.item.id,
      );

      if (exists) {
        emit(state.copyWith(
          status: ItemInBranchStatus.duplication,
          message: 'Item already exists in this branch',
        ));
        return;
      }

      await repository.update(event.item);

      // Reload items
      add(LoadItemsFromBranch(companyId));

      emit(state.copyWith(
        status: ItemInBranchStatus.success,
        message: 'Item updated successfully',
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ItemInBranchStatus.failure,
        message: 'Failed to update item: $e',
      ));
    }
  }

  Future<void> _onDeleteItemFromBranch(
    DeleteItemFromBranch event,
    Emitter<ItemInBranchState> emit,
  ) async {
    emit(state.copyWith(
      status: ItemInBranchStatus.deleting,
      message: 'Deleting item...',
    ));
    
    try {
      final companyId = authBloc.state.companyId;
      if (companyId == null) {
        throw Exception('Company ID not found');
      }

      await repository.delete(event.itemId, companyId);

      // Update local state
      final updatedItems = state.items.where((item) => item.id != event.itemId).toList();
      final updatedFilteredItems = state.filteredItems.where((item) => item.id != event.itemId).toList();

      emit(state.copyWith(
        items: updatedItems,
        filteredItems: updatedFilteredItems,
        status: ItemInBranchStatus.success,
        message: 'Item deleted successfully',
        recentlyDeleted: [...state.recentlyDeleted, event.deletedItem],
        recentlyDeletedIndexes: [...state.recentlyDeletedIndexes, event.deletedIndex],
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ItemInBranchStatus.failure,
        message: 'Failed to delete item: $e',
      ));
    }
  }

  Future<void> _onDeleteSelectedItemsFromBranch(
    DeleteSelectedItemsFromBranch event,
    Emitter<ItemInBranchState> emit,
  ) async {
    emit(state.copyWith(
      status: ItemInBranchStatus.deleting,
      message: 'Deleting selected items...',
    ));
    
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

      emit(state.copyWith(
        items: updatedItems,
        filteredItems: updatedFilteredItems,
        selectedItems: [],
        status: ItemInBranchStatus.success,
        message: '${event.selectedItems.length} items deleted successfully',
        recentlyDeleted: [...state.recentlyDeleted, ...event.deletedItems],
        recentlyDeletedIndexes: [...state.recentlyDeletedIndexes, ...event.deletedIndexes],
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ItemInBranchStatus.failure,
        message: 'Failed to delete selected items: $e',
      ));
    }
  }

  // ========== SEARCH AND SELECTION ==========

  void _onSearchItemFromBranch(
    SearchItemsFromBranch event,
    Emitter<ItemInBranchState> emit,
  ) async {
    final query = event.query.trim();
    
    if (query.isEmpty) {
      emit(state.copyWith(
        filteredItems: state.items,
        searchQuery: '',
        status: ItemInBranchStatus.success,
      ));
      return;
    }

    emit(state.copyWith(
      status: ItemInBranchStatus.searching,
      searchQuery: query,
    ));

    try {
      final companyId = authBloc.state.companyId;
      if (companyId != null) {
        final searchResults = await repository.search(query, companyId);
        emit(state.copyWith(
          filteredItems: searchResults,
          status: ItemInBranchStatus.success,
        ));
      }
    } catch (e) {
      // Fallback to local search if repository search fails
      final filtered = state.items.where((item) {
        return item.item?.itemDescription?.toLowerCase().contains(query.toLowerCase()) == true ||
               item.item?.barcode!.toLowerCase().contains(query.toLowerCase()) == true ||
               item.branchrefrence?.description?.toLowerCase().contains(query.toLowerCase()) == true;
      }).toList();

      emit(state.copyWith(
        filteredItems: filtered,
        status: ItemInBranchStatus.success,
      ));
    }
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
      emit(state.copyWith(selectedItems: []));
    } else {
      emit(state.copyWith(selectedItems: List.from(event.items)));
    }
  }

  void _onClearSelection(
    ClearSelectionFromBranch event,
    Emitter<ItemInBranchState> emit,
  ) {
    emit(state.copyWith(selectedItems: []));
  }

  // ========== DETAIL AND EXPORT OPERATIONS ==========

  void _onShowItemDetailFromBranch(
    ShowItemDetailFromBranch event,
    Emitter<ItemInBranchState> emit,
  ) {
    emit(state.copyWith(
      itemDetail: event.item,
      detailStatus: ItemInBranchDetailStatus.showing,
      showDetailPanel: true,
    ));
  }

  void _onHideItemDetailFromBranch(
    HideItemDetailFromBranch event,
    Emitter<ItemInBranchState> emit,
  ) {
    emit(state.copyWith(
      detailStatus: ItemInBranchDetailStatus.hidden,
      itemDetail: null,
      showDetailPanel: false,
    ));
  }

  void _onSetItemFormFromBranch(
    SetItemFormFromBranch event,
    Emitter<ItemInBranchState> emit,
  ) {
    emit(state.copyWith(itemForm: event.item));
  }

  void _onExportItemFromBranch(
    ExportItemFromBranch event,
    Emitter<ItemInBranchState> emit,
  ) {
    emit(state.copyWith(
      status: ItemInBranchStatus.exporting,
      isExporting: true,
    ));

    // Simulate export process
    Future.delayed(const Duration(seconds: 2), () {
      emit(state.copyWith(
        status: ItemInBranchStatus.success,
        isExporting: false,
        exportedItems: event.itemsToExport,
        message: 'Exported ${event.itemsToExport.length} items successfully',
      ));
    });
  }

  void _onExportSingleItemFromBranch(
    ExportSingleItemFromBranch event,
    Emitter<ItemInBranchState> emit,
  ) {
    emit(state.copyWith(
      status: ItemInBranchStatus.exporting,
      isExporting: true,
    ));

    // Simulate export process
    Future.delayed(const Duration(seconds: 2), () {
      emit(state.copyWith(
        status: ItemInBranchStatus.success,
        isExporting: false,
        exportedItem: event.itemToExport,
        message: 'Item exported successfully',
      ));
    });
  }

  // ========== ADVANCED OPERATIONS ==========

  Future<void> _onLoadItemBranchByItemAndBranch(
    LoadItemBranchByItemAndBranch event,
    Emitter<ItemInBranchState> emit,
  ) async {
    try {
      final companyId = authBloc.state.companyId;
      if (companyId == null) {
        throw Exception('Company ID not found');
      }

      final itemBranch = await repository.findByItemAndBranch(
        event.itemNumber,
        event.branchId,
        companyId,
      );

      emit(state.copyWith(
        currentItemBranch: itemBranch,
        status: ItemInBranchStatus.success,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ItemInBranchStatus.failure,
        message: 'Failed to load item branch: $e',
      ));
    }
  }

  Future<void> _onUpdateItemBranchUnitPrice(
    UpdateItemBranchUnitPrice event,
    Emitter<ItemInBranchState> emit,
  ) async {
    try {
      final companyId = authBloc.state.companyId;
      if (companyId == null) {
        throw Exception('Company ID not found');
      }

      await repository.updateUnitPrice(
        event.itemBranchId,
        event.newPrice,
        companyId,
      );

      // Update local state
      final updatedItems = state.items.map((item) {
        if (item.id == event.itemBranchId) {
          return item.copyWith(unitPrice: event.newPrice);
        }
        return item;
      }).toList();

      final updatedFilteredItems = state.filteredItems.map((item) {
        if (item.id == event.itemBranchId) {
          return item.copyWith(unitPrice: event.newPrice);
        }
        return item;
      }).toList();

      emit(state.copyWith(
        items: updatedItems,
        filteredItems: updatedFilteredItems,
        status: ItemInBranchStatus.success,
        message: 'Unit price updated successfully',
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ItemInBranchStatus.failure,
        message: 'Failed to update unit price: $e',
      ));
    }
  }

  Future<void> _onLoadItemsInBranchByItem(
    LoadItemsInBranchByItem event,
    Emitter<ItemInBranchState> emit,
  ) async {
    try {
      final companyId = authBloc.state.companyId;
      if (companyId == null) {
        throw Exception('Company ID not found');
      }

      final items = await repository.findByItem(event.itemNumber, companyId);

      emit(state.copyWith(
        itemsByItem: items,
        status: ItemInBranchStatus.success,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ItemInBranchStatus.failure,
        message: 'Failed to load items by item: $e',
      ));
    }
  }

  Future<void> _onLoadItemsInBranchByBranch(
    LoadItemsInBranchByBranch event,
    Emitter<ItemInBranchState> emit,
  ) async {
    try {
      final companyId = authBloc.state.companyId;
      if (companyId == null) {
        throw Exception('Company ID not found');
      }

      final items = await repository.findByBranch(event.branchId, companyId);

      emit(state.copyWith(
        itemsByBranch: items,
        status: ItemInBranchStatus.success,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ItemInBranchStatus.failure,
        message: 'Failed to load items by branch: $e',
      ));
    }
  }

  Future<void> _onLoadLowStockItems(
    LoadLowStockItems event,
    Emitter<ItemInBranchState> emit,
  ) async {
    try {
      final companyId = authBloc.state.companyId;
      if (companyId == null) {
        throw Exception('Company ID not found');
      }

      final lowStockItems = await repository.getLowStockItems(
        companyId,
        branchId: event.branchId,
      );

      emit(state.copyWith(
        lowStockItems: lowStockItems,
        status: ItemInBranchStatus.success,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ItemInBranchStatus.failure,
        message: 'Failed to load low stock items: $e',
      ));
    }
  }

  Future<void> _onLoadOutOfStockItems(
    LoadOutOfStockItems event,
    Emitter<ItemInBranchState> emit,
  ) async {
    try {
      final companyId = authBloc.state.companyId;
      if (companyId == null) {
        throw Exception('Company ID not found');
      }

      final outOfStockItems = await repository.getOutOfStockItems(
        companyId,
        branchId: event.branchId,
      );

      emit(state.copyWith(
        outOfStockItems: outOfStockItems,
        status: ItemInBranchStatus.success,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ItemInBranchStatus.failure,
        message: 'Failed to load out of stock items: $e',
      ));
    }
  }

  Future<void> _onUpdateItemQuantity(
    UpdateItemQuantity event,
    Emitter<ItemInBranchState> emit,
  ) async {
    try {
      final companyId = authBloc.state.companyId;
      if (companyId == null) {
        throw Exception('Company ID not found');
      }

      await repository.updateQuantity(
        event.itemId,
        event.quantity,
        companyId,
      );

      // Update local state
      final updatedItems = state.items.map((item) {
        if (item.id == event.itemId) {
          return item.copyWith(quantityAvailable: event.quantity);
        }
        return item;
      }).toList();

      final updatedFilteredItems = state.filteredItems.map((item) {
        if (item.id == event.itemId) {
          return item.copyWith(quantityAvailable: event.quantity);
        }
        return item;
      }).toList();

      emit(state.copyWith(
        items: updatedItems,
        filteredItems: updatedFilteredItems,
        status: ItemInBranchStatus.success,
        message: 'Quantity updated successfully',
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ItemInBranchStatus.failure,
        message: 'Failed to update quantity: $e',
      ));
    }
  }

  // ========== PUBLIC METHODS FOR OTHER BLOCS ==========

  // Get item branch by item and branch (for ItemCost bloc)
  Future<ItemInBranchModel?> itemBranchByItemAndBranch(int itemNumber, int branchId) async {
    try {
      final companyId = authBloc.state.companyId;
      if (companyId == null) return null;

      return await repository.findByItemAndBranch(itemNumber, branchId, companyId);
    } catch (e) {
      return null;
    }
  }

  // Calculate total availability of an item in specific primary unit
  Future<double> totalAvailabilityOfAnItemInSpecificPrimary(int itemNumber) async {
    try {
      final companyId = authBloc.state.companyId;
      if (companyId == null) return 0.0;

      return await repository.getTotalQuantityByItem(itemNumber, companyId);
    } catch (e) {
      return 0.0;
    }
  }

  // Update unit price for item branch
  Future<void> updateUnitPrice(ItemInBranchModel itemBranch, double newPrice) async {
    try {
      final companyId = authBloc.state.companyId;
      if (companyId == null) throw Exception('Company ID not found');

      await repository.updateUnitPrice(itemBranch.id!, newPrice, companyId);
    } catch (e) {
      rethrow;
    }
  }

  // Update item unit price (update all branches for this item)
  Future<void> updateItemUnitPrice(int itemNumber, double newPrice) async {
    try {
      final companyId = authBloc.state.companyId;
      if (companyId == null) throw Exception('Company ID not found');

      final items = await repository.findByItem(itemNumber, companyId);
      for (final item in items) {
        await repository.updateUnitPrice(item.id!, newPrice, companyId);
      }
    } catch (e) {
      rethrow;
    }
  }

  // Get all items in branch by item
  Future<List<ItemInBranchModel>> itemInBranchByItem(int itemNumber) async {
    try {
      final companyId = authBloc.state.companyId;
      if (companyId == null) return [];

      return await repository.findByItem(itemNumber, companyId);
    } catch (e) {
      return [];
    }
  }

  // Get items in branch by item and branch
  Future<List<ItemInBranchModel>> itemInBranchByItemAndBranch(int itemNumber, int branchId) async {
    try {
      final companyId = authBloc.state.companyId;
      if (companyId == null) return [];

      return await repository.findByItemAndBranch(itemNumber, branchId, companyId)
          .then((item) => item != null ? [item] : []);
    } catch (e) {
      return [];
    }
  }

  // Send notification (placeholder implementation)
  void sendNotification(ItemInBranchModel itemBranch) {
    // Implement notification logic here
    print('Notification: Item branch ${itemBranch.id} updated with new unit price');
    
    // In a real app, you might want to:
    // - Show a snackbar
    // - Send a push notification
    // - Log the change
    // - Trigger a UI update
  }
}