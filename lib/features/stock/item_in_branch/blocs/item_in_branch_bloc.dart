// features/stock/item_in_branch/blocs/item_in_branch_bloc.dart

import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:savvy_stock/features/system_constant/bloc/system_constant_bloc.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/stock/item_UoM_conversions/item_uom_conv_repo.dart';
import 'package:savvy_stock/features/stock/item_in_branch/blocs/item_in_branch_event.dart';
import 'package:savvy_stock/features/stock/item_in_branch/blocs/item_in_branch_state.dart';
import 'package:savvy_stock/features/stock/item_in_branch/models/item_in_branch_model.dart';
import 'package:savvy_stock/features/stock/item_in_branch/repo/item_in_branch_repo.dart';
import 'package:savvy_stock/features/stock/item_transactions/repo/item_transaction_repo.dart';
import 'package:savvy_stock/features/stock/lot_master/blocs/lot_master_bloc.dart';

class StockItemInBranchBloc extends Bloc<ItemInBranchEvent, ItemInBranchState> {
  final StockItemInBranchRepository repository;
  final AuthBloc authBloc;
  final SystemConstantBloc systemConstantBloc;
  final ItemTransactionRepository itemTransactionsRepository;
  final LotMasterBloc lotMasterBloc;
  final ItemUomConversionsRepository itemUomConversionsBloc;
  // final NotificationTableBloc notificationTableBloc;
  //final ItemCostBloc itemCostBloc;

  StreamSubscription? _authSubscription;
  StreamSubscription? _systemConstantSubscription;

  StockItemInBranchBloc({
    required this.repository,
    required this.authBloc,
    required this.systemConstantBloc,
    required this.itemTransactionsRepository,
    required this.lotMasterBloc,
    required this.itemUomConversionsBloc,
    //required this.notificationTableBloc,
    // required this.itemCostBloc,
  }) : super(ItemInBranchState()) {
    // Listen to auth state changes
    _authSubscription = authBloc.stream.listen((authState) {
      if (authState.isAuthenticated && authState.companyId != null) {
        add(LoadItemsFromBranch(authState.companyId!));
      }
    });
    // Listen to system constant changes
    _systemConstantSubscription = systemConstantBloc.stream.listen((
      systemState,
    ) {
      // Handle system constant changes if needed
    });

    // Event handlers - Core CRUD operations
    on<LoadItemsFromBranch>(_onLoadBranchItems);
    on<AddItemToBranch>(_onAddItemToBranch);
    on<UpdateItem>(_onUpdateItem);
    on<DeleteItemFromBranch>(_onDeleteItemFromBranch);
    on<DeleteSelectedItemsFromBranch>(_onDeleteSelectedItemsFromBranch);

    // Event handlers - Selection and UI operations
    on<SelectItemFromBranch>(_onSelectItemFromBranch);
    on<SelectAllItemsFromBranch>(_onSelectAllItemFromBranch);
    on<ClearSelectionFromBranch>(_onClearSelection);
    on<SearchItemsFromBranch>(_onSearchItemFromBranch);
    on<ShowItemDetailFromBranch>(_onShowItemDetailFromBranch);
    on<HideItemDetailFromBranch>(_onHideItemDetailFromBranch);
    on<SetItemFormFromBranch>(_onSetItemFormFromBranch);

    // Event handlers - Preparation operations (from Java controller)
    //on<PrepareCreate>(_onPrepareCreate);
    //on<PrepareEdit>(_onPrepareEdit);

    // Event handlers - Complex business operations (from Java controller)
    on<SaveRow>(_onSaveRow);
    on<SaveInEdit>(_onSaveInEdit);

    // Event handlers - Stock management operations
    on<UpdateStockForSalesOrder>(_onUpdateStockForSalesOrder);
    //on<UpdateStockForSalesOrderVoid>(_onUpdateStockForSalesOrderVoid);
    on<UpdateStockForPurchaseOrder>(_onUpdateStockForPurchaseOrder);
    on<SetDefaultPrice>(_onSetDefaultPrice);

    // Event handlers - Filter operations
    // on<FilterItemsInBranch>(_onFilterItemsInBranch);
    //  on<FilterSelectedItems>(_onFilterSelectedItems);
    //on<ClearDataForFilter>(_onClearDataForFilter);

    // Event handlers - Advanced operations
    on<LoadItemBranchByItemAndBranch>(_onLoadItemBranchByItemAndBranch);
    on<UpdateItemBranchUnitPrice>(_onUpdateItemBranchUnitPrice);
    on<LoadItemsInBranchByItem>(_onLoadItemsInBranchByItem);
    on<LoadItemsInBranchByBranch>(_onLoadItemsInBranchByBranch);
    on<LoadAvailableItemsInBranch>(_onLoadAvailableItemsInBranch);
    on<SendNotification>(_onSendNotification);
    on<LoadOutOfStockItems>(_onLoadOutOfStockItems);
    on<UpdateItemQuantity>(_onUpdateItemQuantity);
    on<ExportItemFromBranch>(_onExportItemFromBranch);
    on<ExportSingleItemFromBranch>(_onExportSingleItemFromBranch);
    on<LoadLowStockItems>(_onLoadLowStockItems);
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

      emit(
        state.copyWith(
          status: ItemInBranchStatus.loaded,
          items: items,
          filteredItems: items,
          companyId: event.companyId,
          selectedItems: [],
          searchQuery: '',
          totalAmountInETB: state.totalAmountInETB,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ItemInBranchStatus.failure,
          message: 'Failed to load items: $e',
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
        message: 'Adding item to branch...',
      ),
    );

    try {
      final companyId = authBloc.state.companyId;
      if (companyId == null) {
        throw Exception('Company ID not found');
      }

      // Check for duplication
      final exists = await repository.existsByItemAndBranch(
        event.item.itemNumber,
        event.item.branch,
        companyId,
      );

      if (exists) {
        emit(
          state.copyWith(
            status: ItemInBranchStatus.duplication,
            message: 'Item already exists in this branch',
          ),
        );
        return;
      }

      // Set company and create
      final itemToCreate = event.item.copyWith(company: companyId);
      await repository.create(itemToCreate);
      // Send notification like in Java controller
      //await _sendNotification(itemToCreate);

      // Reload items
      add(LoadItemsFromBranch(companyId, branchId: event.item.branch));

      emit(
        state.copyWith(
          status: ItemInBranchStatus.success,
          message: 'Item added to branch successfully',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ItemInBranchStatus.failure,
          message: 'Failed to add item: $e',
        ),
      );
    }
  }

  Future<void> _onUpdateItem(
    UpdateItem event,
    Emitter<ItemInBranchState> emit,
  ) async {
    emit(
      state.copyWith(
        status: ItemInBranchStatus.updating,
        message: 'Updating item...',
      ),
    );

    try {
      final companyId = authBloc.state.companyId;
      if (companyId == null) {
        throw Exception('Company ID not found');
      }

      // Check for duplication (excluding current item)
      final exists = await repository.existsByItemAndBranch(
        event.item.itemNumber,
        event.item.branch,
        companyId,
        excludeId: event.item.id,
      );

      if (exists) {
        emit(
          state.copyWith(
            status: ItemInBranchStatus.duplication,
            message: 'Item already exists in this branch',
          ),
        );
        return;
      }

      await repository.update(event.item);

      // Send notification like in Java controller
      //await _sendNotification(event.item);

      // Reload items
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
          message: 'Failed to update item: $e',
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
          status: ItemInBranchStatus.success,
          message: 'Item deleted successfully',
          recentlyDeleted: [...state.recentlyDeleted, event.deletedItem],
          recentlyDeletedIndexes: [
            ...state.recentlyDeletedIndexes,
            event.deletedIndex,
          ],
        ),
      );
      // Send notification like in Java controller
      //await _sendNotification(event.item);

      // Reload items
      add(LoadItemsFromBranch(companyId));
    } catch (e) {
      emit(
        state.copyWith(
          status: ItemInBranchStatus.failure,
          message: 'Failed to delete item: $e',
        ),
      );
    }
  }

  Future<void> _onDeleteSelectedItemsFromBranch(
    DeleteSelectedItemsFromBranch event,
    Emitter<ItemInBranchState> emit,
  ) async {
    emit(
      state.copyWith(
        status: ItemInBranchStatus.deleting,
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
          status: ItemInBranchStatus.success,
          message: '${event.selectedItems.length} items deleted successfully',
          recentlyDeleted: [...state.recentlyDeleted, ...event.deletedItems],
          recentlyDeletedIndexes: [
            ...state.recentlyDeletedIndexes,
            ...event.deletedIndexes,
          ],
        ),
      );
      // Send notification like in Java controller
      //await _sendNotification(event.item);
      // Reload items
      add(LoadItemsFromBranch(companyId));
    } catch (e) {
      emit(
        state.copyWith(
          status: ItemInBranchStatus.failure,
          message: 'Failed to delete selected items: $e',
        ),
      );
    }
  }

  // ========== COMPLEX BUSINESS LOGIC FROM JAVA CONTROLLER ==========

  Future<void> _onSaveRow(
    SaveRow event,
    Emitter<ItemInBranchState> emit,
  ) async {
    emit(
      state.copyWith(
        status: ItemInBranchStatus.updating,
        message: 'Saving row...',
      ),
    );

    try {
      for (final item in event.items) {
        // Duplicate checker like in Java controller
        final isValid = await _duplicateChecker(item);

        if (isValid) {
          await repository.update(item);
          //await _sendNotification(item);
        } else {
          emit(
            state.copyWith(
              status: ItemInBranchStatus.failure,
              message: 'Duplicate Branch Not Allowed!',
            ),
          );
          return;
        }
      }

      emit(
        state.copyWith(
          status: ItemInBranchStatus.success,
          message: 'Saved successfully',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ItemInBranchStatus.failure,
          message: 'Failed to save row: $e',
        ),
      );
    }
  }

  Future<void> _onSaveInEdit(
    SaveInEdit event,
    Emitter<ItemInBranchState> emit,
  ) async {
    emit(
      state.copyWith(
        status: ItemInBranchStatus.updating,
        message: 'Saving in edit...',
      ),
    );

    try {
      final companyId = authBloc.state.companyId;
      if (companyId == null) {
        throw Exception('Company ID not found');
      }

      // Duplicate checker like in Java controller
      final isValid = await _duplicateChecker(event.item);

      if (!isValid) {
        emit(
          state.copyWith(
            status: ItemInBranchStatus.failure,
            message: 'Duplicate Branch Not Allowed!',
          ),
        );
        return;
      }

      // Set default values like in Java controller
      var itemToSave = event.item;
      if (itemToSave.unitOfMeasure == null) {
        // This would need item table lookup

        itemToSave = itemToSave.copyWith(
          unitOfMeasure: itemToSave.unitOfMeasure,
        );
      }

      if (itemToSave.unitPrice == null) {
        // This would need item table lookup
        itemToSave = itemToSave.copyWith(unitPrice: itemToSave.unitPrice);
      }

      // Update existing
      final oldItem = await repository.findById(itemToSave.id, companyId);
      final oldQty = oldItem?.quantityAvailable ?? 0.0;
      final newQty = itemToSave.quantityAvailable ?? 0.0;

      await repository.update(itemToSave);

      final systemConstant = systemConstantBloc.state.selected;
      final applyLotMgmt = systemConstant?.applyLotMgmBoolean ?? false;
      final applyLocationMgmt =
          systemConstant?.applyLocationMgmBoolean ?? false;
      if (!applyLotMgmt && !applyLocationMgmt) {
        await itemTransactionsRepository.stockCardCreation(
          ib: itemToSave,
          transactionType: 'A',
          remark: null,
          loc: null,
          lm: null,
          trNo: null,
          qty: newQty - oldQty,
          soD: null,
          por: null,
        );
      }

      //  await _sendNotification(itemToSave);

      emit(
        state.copyWith(
          status: ItemInBranchStatus.success,
          message: 'Saved successfully',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ItemInBranchStatus.failure,
          message: 'Failed to save: $e',
        ),
      );
    }
  }

  // ========== STOCK MANAGEMENT OPERATIONS ==========

  Future<void> _onUpdateStockForSalesOrder(
    UpdateStockForSalesOrder event,
    Emitter<ItemInBranchState> emit,
  ) async {
    // Implementation of updatingStockItemAvailablitySo from Java controller
    try {
      final salesOrderDetail = event.salesOrderDetail;
      if (salesOrderDetail.itemsTableId != null &&
          salesOrderDetail.quantity != null &&
          salesOrderDetail.quantity != 0.0 &&
          salesOrderDetail.itemInBranch != null) {
        // This would need integration with your sales order system
        // The Java controller has complex logic for different scenarios:
        // - Without location/lot management
        // - With location management only
        // - With both location and lot management

        // For now, this is a placeholder implementation
        final factor = await itemUomConversionsBloc.fromOtherToPrimary(
          salesOrderDetail.itemsTableId!,
          salesOrderDetail.itemBranch!.unitOfMeasure!,
          authBloc.state.companyId!,
        );

        final itemsInBranch = await repository.findByItemAndBranch(
          salesOrderDetail.itemsTableId!,
          salesOrderDetail.itemBranch!.branch,
          authBloc.state.companyId!,
        );

        if (itemsInBranch != null) {
          final qtyToSubtract = factor * salesOrderDetail.quantity!;
          final newQty =
              (itemsInBranch.quantityAvailable ?? 0.0) - qtyToSubtract;

          await repository.updateQuantity(
            itemsInBranch.id,
            newQty,
            authBloc.state.companyId!,
          );

          // Create stock card entry
          await itemTransactionsRepository.stockCardCreation(
            ib: itemsInBranch,
            transactionType: 'S',
            remark: 'Sales Order Stock Deduction',
            loc: null,
            lm: null,
            trNo: salesOrderDetail.orderHeader!.orderNumber,
            qty: -qtyToSubtract,
            soD: salesOrderDetail,
            por: null,
          );
        }
      }

      emit(
        state.copyWith(
          status: ItemInBranchStatus.success,
          message: 'Stock updated for sales order',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ItemInBranchStatus.failure,
          message: 'Failed to update stock for sales order: $e',
        ),
      );
    }
  }

  Future<void> _onUpdateStockForPurchaseOrder(
    UpdateStockForPurchaseOrder event,
    Emitter<ItemInBranchState> emit,
  ) async {
    // Implementation of updatingStockItemAvailablityPor from Java controller
    try {
      final purchaseOrderReceiver = event.purchaseOrderReceiver;
      if (purchaseOrderReceiver.itemNumber != null &&
          purchaseOrderReceiver.quantityRecieved != null &&
          purchaseOrderReceiver.quantityRecieved != 0.0 &&
          purchaseOrderReceiver.branchRecieved != null) {
        // Complex logic from Java controller for different scenarios
        final itemsInBranch = await repository.findByItemAndBranch(
          purchaseOrderReceiver.itemNumber!,
          purchaseOrderReceiver.branchRecieved!,
          authBloc.state.companyId!,
        );

        if (itemsInBranch != null) {
          final factor = await itemUomConversionsBloc.fromOtherToAnother(
            purchaseOrderReceiver.itemNumber!,
            purchaseOrderReceiver.unitOfMeasure!,
            itemsInBranch.unitOfMeasure!,
            authBloc.state.companyId!,
          );

          final qtyToAdd = factor * purchaseOrderReceiver.quantityRecieved!;
          final newQty = (itemsInBranch.quantityAvailable ?? 0.0) + qtyToAdd;

          await repository.updateQuantity(
            itemsInBranch.id,
            newQty,
            authBloc.state.companyId!,
          );

          // Create stock card entry
          await itemTransactionsRepository.stockCardCreation(
            ib: itemsInBranch,
            transactionType: 'R',
            remark: 'Purchase Order Stock Addition',
            loc: null,
            lm: null,
            trNo: purchaseOrderReceiver.poDetailRef!.orderNumber,
            qty: qtyToAdd,
            soD: null,
            por: purchaseOrderReceiver,
          );
        }
      }

      emit(
        state.copyWith(
          status: ItemInBranchStatus.success,
          message: 'Stock updated for purchase order',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ItemInBranchStatus.failure,
          message: 'Failed to update stock for purchase order: $e',
        ),
      );
    }
  }

  void _onSetDefaultPrice(
    SetDefaultPrice event,
    Emitter<ItemInBranchState> emit,
  ) {
    // This would need item table lookup
    final updatedItem = event.item.copyWith(
      unitPrice: event.item.itemRef!.unitPrice,
      unitOfMeasure: event.item.unitOfMeasure,
    );
    emit(state.copyWith(itemForm: updatedItem));
  }

  /* // ========== FILTER OPERATIONS ==========

  Future<void> _onFilterItemsInBranch(
    FilterItemsInBranch event,
    Emitter<ItemInBranchState> emit,
  ) async {
    emit(state.copyWith(status: ItemInBranchStatus.loading));
    
    try {
      final items = await repository.filterItems(
        companyId: authBloc.state.companyId!,
        branchId: state.branchId,
        itemNumber: state.itemId,
        reachesReorderPointsOrUnder: _event.reachesReorderPointsOrUnder,
        noAvailability: state.!,
      );

      // Calculate total amount
      for (final item in items) {
        state.totalAmountInETB += await _totalCostsInStore(item);
      }

      emit(state.copyWith(
        status: ItemInBranchStatus.loaded,
        items: items,
        filteredItems: items,
        totalAmountInETB: state.totalAmountInETB,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ItemInBranchStatus.failure,
        message: 'Failed to filter items: $e',
      ));
    }
  }
  */

  // ========== HELPER METHODS FROM JAVA CONTROLLER ==========

  // Duplicate checker like in Java controller
  Future<bool> _duplicateChecker(ItemInBranchModel item) async {
    try {
      final existing = await repository.findByItemAndBranch(
        item.itemNumber,
        item.branch,
        item.company!,
      );

      if (existing != null && existing.id != item.id) {
        return false; // Duplicate found
      }
      return true; // No duplicate
    } catch (e) {
      return false;
    }
  }

  // Send notification like in Java controller
  Future<void> _sendNotification(ItemInBranchModel item) async {
    try {
      // This would need integration with your notification system
      // The Java controller has complex logic for reorder point notifications

      final availability = await _calculateAvailability(item);
      final reorderPoint = await _calculateReorderPoint(item);

      if (availability <= reorderPoint) {
        // Create notification
        final description =
            "The Item ${item.itemRef!.itemDescription} at ${item.branchRef!.description} reach its reorder point!";
        // await notificationTableBloc.createNotification(...);
      }
    } catch (e) {
      // Handle error silently
    }
  }

  // Calculate availability like in Java controller
  Future<double> _calculateAvailability(ItemInBranchModel item) async {
    double quantityAvailable = item.quantityAvailable ?? 0.0;

    // This would need integration with LotMaster for expiration logic
    // For now, return the quantity available
    return quantityAvailable;
  }

  // Calculate reorder point like in Java controller
  Future<double> _calculateReorderPoint(ItemInBranchModel item) async {
    // This would need integration with item, branch, and company reorder points
    // For now, return the item's reorder point
    return item.reorderPoint ?? 0.0;
  }
  /*
  // Calculate total costs in store like in Java controller
  Future<double> _totalCostsInStore(ItemInBranchModel item) async {
    if (item.quantityAvailable == null || item.itemNumber == null) {
      return 0.0;
    }
    
    // This would need integration with ItemCostTable
     final itemCost = await itemCostBloc.getItemCostByItem(item.itemNumber!);
     if (itemCost?.amountUnitCost != null) {
       final factor = await itemUomConversionsBloc.fromOtherToPrimary(
         item.itemNumber, 
         item.unitOfMeasure!,
           authBloc.state.companyId!,
       );
       return item.quantityAvailable! * factor * itemCost!.amountUnitCost!;
     }
    
    return 0.0;
  }
*/
  // ========== SEARCH AND SELECTION ==========

  void _onSearchItemFromBranch(
    SearchItemsFromBranch event,
    Emitter<ItemInBranchState> emit,
  ) async {
    final query = event.query.trim();

    if (query.isEmpty) {
      emit(
        state.copyWith(
          filteredItems: state.items,
          searchQuery: '',
          status: ItemInBranchStatus.success,
        ),
      );
      return;
    }

    emit(
      state.copyWith(status: ItemInBranchStatus.searching, searchQuery: query),
    );

    try {
      final companyId = authBloc.state.companyId;
      if (companyId != null) {
        final searchResults = await repository.search(query, companyId);
        emit(
          state.copyWith(
            filteredItems: searchResults,
            status: ItemInBranchStatus.success,
          ),
        );
      }
    } catch (e) {
      // Fallback to local search if repository search fails
      final filtered = state.items.where((item) {
        return item.item?.itemDescription?.toLowerCase().contains(
                  query.toLowerCase(),
                ) ==
                true ||
            item.item?.barcode!.toLowerCase().contains(query.toLowerCase()) ==
                true ||
            item.branchRef?.description?.toLowerCase().contains(
                  query.toLowerCase(),
                ) ==
                true;
      }).toList();

      emit(
        state.copyWith(
          filteredItems: filtered,
          status: ItemInBranchStatus.success,
        ),
      );
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
          message: 'Item exported successfully',
        ),
      );
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

      emit(
        state.copyWith(
          currentItemBranch: itemBranch,
          status: ItemInBranchStatus.success,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ItemInBranchStatus.failure,
          message: 'Failed to load item branch: $e',
        ),
      );
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

      emit(
        state.copyWith(
          items: updatedItems,
          filteredItems: updatedFilteredItems,
          status: ItemInBranchStatus.success,
          message: 'Unit price updated successfully',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ItemInBranchStatus.failure,
          message: 'Failed to update unit price: $e',
        ),
      );
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

      emit(
        state.copyWith(itemsByItem: items, status: ItemInBranchStatus.success),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ItemInBranchStatus.failure,
          message: 'Failed to load items by item: $e',
        ),
      );
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

      emit(
        state.copyWith(
          itemsByBranch: items,
          status: ItemInBranchStatus.success,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ItemInBranchStatus.failure,
          message: 'Failed to load items by branch: $e',
        ),
      );
    }
  }

  void _onLoadAvailableItemsInBranch(
    LoadAvailableItemsInBranch event,
    Emitter<ItemInBranchState> emit,
  ) async {
    try {
      // Implementation of itemInBranchVailablesOnly from Java controller
      final items = await repository.findByItem(
        event.itemNumber,
        authBloc.state.companyId!,
      );

      // Filter available items based on complex business logic
      final availableItems = items.where((item) {
        // Add complex availability logic here
        return (item.quantityAvailable ?? 0.0) > 0;
      }).toList();

      emit(
        state.copyWith(
          availableItems: availableItems,
          status: ItemInBranchStatus.success,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ItemInBranchStatus.failure,
          message: 'Failed to load available items: $e',
        ),
      );
    }
  }

  void _onSendNotification(
    SendNotification event,
    Emitter<ItemInBranchState> emit,
  ) async {
    try {
      await _sendNotification(event.item);
      emit(
        state.copyWith(
          status: ItemInBranchStatus.success,
          message: 'Notification sent',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ItemInBranchStatus.failure,
          message: 'Failed to send notification: $e',
        ),
      );
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

      emit(
        state.copyWith(
          lowStockItems: lowStockItems,
          status: ItemInBranchStatus.success,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ItemInBranchStatus.failure,
          message: 'Failed to load low stock items: $e',
        ),
      );
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

      emit(
        state.copyWith(
          outOfStockItems: outOfStockItems,
          status: ItemInBranchStatus.success,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ItemInBranchStatus.failure,
          message: 'Failed to load out of stock items: $e',
        ),
      );
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

      await repository.updateQuantity(event.itemId, event.quantity, companyId);

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

      emit(
        state.copyWith(
          items: updatedItems,
          filteredItems: updatedFilteredItems,
          status: ItemInBranchStatus.success,
          message: 'Quantity updated successfully',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ItemInBranchStatus.failure,
          message: 'Failed to update quantity: $e',
        ),
      );
    }
  }

  // ========== PUBLIC METHODS FOR OTHER BLOCS ==========

  // Get item branch by item and branch (for ItemCost bloc)
  Future<ItemInBranchModel?> itemBranchByItemAndBranch(
    int itemNumber,
    int branchId,
  ) async {
    try {
      final companyId = authBloc.state.companyId;
      if (companyId == null) return null;

      return await repository.findByItemAndBranch(
        itemNumber,
        branchId,
        companyId,
      );
    } catch (e) {
      return null;
    }
  }

  // Calculate total availability of an item in specific primary unit
  Future<double> totalAvailabilityOfAnItemInSpecificPrimary(
    int itemNumber,
  ) async {
    try {
      final companyId = authBloc.state.companyId;
      if (companyId == null) return 0.0;

      return await repository.getTotalQuantityByItem(itemNumber, companyId);
    } catch (e) {
      return 0.0;
    }
  }

  // Update unit price for item branch
  Future<void> updateUnitPrice(
    ItemInBranchModel itemBranch,
    double newPrice,
  ) async {
    try {
      final companyId = authBloc.state.companyId;
      if (companyId == null) throw Exception('Company ID not found');

      await repository.updateUnitPrice(itemBranch.id, newPrice, companyId);
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
        await repository.updateUnitPrice(item.id, newPrice, companyId);
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
  Future<List<ItemInBranchModel>> itemInBranchByItemAndBranch(
    int itemNumber,
    int branchId,
  ) async {
    try {
      final companyId = authBloc.state.companyId;
      if (companyId == null) return [];

      return await repository
          .findByItemAndBranch(itemNumber, branchId, companyId)
          .then((item) => item != null ? [item] : []);
    } catch (e) {
      return [];
    }
  }

  // Send notification (placeholder implementation)
  void sendNotification(ItemInBranchModel itemBranch) {
    // Implement notification logic here
    print(
      'Notification: Item branch ${itemBranch.id} updated with new unit price',
    );

    // In a real app, you might want to:
    // - Show a snackbar
    // - Send a push notification
    // - Log the change
    // - Trigger a UI update
  }
}
