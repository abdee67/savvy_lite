
// bloc/item_cost_bloc.dart
import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:savvy_stock/core/blocs/system_constant/system_constant_bloc.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/branch_list/models/branch_list_model.dart';
import 'package:savvy_stock/features/company/models/company_model.dart';
import 'package:savvy_stock/features/purchase/supplier/models/purchase_order_detail_model.dart';
import 'package:savvy_stock/features/purchase/supplier/models/purchase_order_receiver_model.dart';
import 'package:savvy_stock/features/stock/item_UoM_conversions/item_uom_conv_repo.dart';
import 'package:savvy_stock/features/stock/item_cost/blocs/item_cost_event.dart';
import 'package:savvy_stock/features/stock/item_cost/blocs/item_cost_state.dart';
import 'package:savvy_stock/features/stock/item_cost/repo/item_cost_repository.dart';
import 'package:savvy_stock/features/stock/item_entry/models/item_entry_model.dart';
import 'package:savvy_stock/features/stock/item_in_branch/blocs/item_in_branch_bloc.dart';
import 'package:savvy_stock/features/stock/item_in_branch/models/item_in_branch_model.dart';
import '../models/item_cost_model.dart';

class ItemCostBloc extends Bloc<ItemCostEvent, ItemCostState> {
  final ItemCostRepository repository;
  final AuthBloc authBloc;
  final ItemUomConversionsRepository itemUomConversionsController;
  final StockItemInBranchBloc itemsInBranchController;
  final SystemConstantBloc systemConstantController;

  ItemCostBloc({
    required this.repository,
    required this.authBloc,
    required this.itemUomConversionsController,
    required this.itemsInBranchController,
    required this.systemConstantController,
  }) : super(const ItemCostInitial()) {
    on<LoadItemCosts>(_onLoadItemCosts);
    on<RefreshItemCosts>(_onRefreshItemCosts);
    on<SelectItemCost>(_onSelectItemCost);
    on<SelectMultipleItemCosts>(_onSelectMultipleItemCosts);
    on<ClearSelection>(_onClearSelection);
    on<PrepareCreate>(_onPrepareCreate);
    on<PrepareCopy>(_onPrepareCopy);
    on<PrepareCreateInCreate>(_onPrepareCreateInCreate);
    on<PrepareCreateInEdit>(_onPrepareCreateInEdit);
    on<PrepareEdit>(_onPrepareEdit);
    on<SaveItemCost>(_onSaveItemCost);
    on<SaveRow>(_onSaveRow);
    on<SaveInEdit>(_onSaveInEdit);
    on<CreateInEdit>(_onCreateInEdit);
    on<DeleteItemCost>(_onDeleteItemCost);
    on<DeleteMultipleItemCosts>(_onDeleteMultipleItemCosts);
    on<RemoveInCreate>(_onRemoveInCreate);
    on<RemoveInEdit>(_onRemoveInEdit);
    on<SaveAndClose>(_onSaveAndClose);
    on<SaveAndAddNew>(_onSaveAndAddNew);
    on<SaveAndAddContinue>(_onSaveAndAddContinue);
    on<UpdateItemCosts>(_onUpdateItemCosts);
    //on<UpdateItemCostsForItemMaster>(_onUpdateItemCostsForItemMaster);
    on<UpdateUnitPrice>(_onUpdateUnitPrice);
    on<FilterItemCosts>(_onFilterItemCosts);
    on<CancelUpdate>(_onCancelUpdate);
    on<CancelCreate>(_onCancelCreate);
    on<DiscardChanges>(_onDiscardChanges);
  }

  // Helper method to filter items based on user permissions
  List<ItemCost> _filterItemsByUserPermission(List<ItemCost> items) {
    return items.where((item) {
      final isSameCompany = item.company == authBloc.state.companyId;
      return isSameCompany;
    }).toList();
  }

  // Helper method to prepare temp IDs
  List<ItemCost> _preparingTempId(ItemCost item, List<ItemCost> list) {
    int tempId = 0;
    if (list.isNotEmpty) {
      for (final itm in list) {
        if (itm.tempId != null && itm.tempId! > tempId) {
          tempId = itm.tempId!;
        }
      }
    }
    tempId += 1;
    final newItem = item.copyWith(tempId: tempId);
    list.add(newItem);
    return list;
  }

  // Event handlers
  Future<void> _onLoadItemCosts(
    LoadItemCosts event,
    Emitter<ItemCostState> emit,
  ) async {
    emit(ItemCostLoading(
      items: state.items,
      createItems: state.createItems,
      editItems: state.editItems,
      multiselectionItems: state.multiselectionItems,
      filteredValues: state.filteredValues,
      selected: state.selected,
      selected1: state.selected1,
      selected2: state.selected2,
    ));

    try {
      final items = await repository.findAll();
      final filteredItems = _filterItemsByUserPermission(items);
      
      emit(ItemCostLoaded(
        items: filteredItems,
        createItems: state.createItems,
        editItems: state.editItems,
        multiselectionItems: state.multiselectionItems,
        filteredValues: state.filteredValues,
        selected: state.selected,
        selected1: state.selected1,
        selected2: state.selected2,
      ));
    } catch (e) {
      emit(ItemCostError(
        items: state.items,
        createItems: state.createItems,
        editItems: state.editItems,
        multiselectionItems: state.multiselectionItems,
        filteredValues: state.filteredValues,
        selected: state.selected,
        selected1: state.selected1,
        selected2: state.selected2,
        errorMessage: 'Error loading items: $e',
      ));
    }
  }

  Future<void> _onRefreshItemCosts(
    RefreshItemCosts event,
    Emitter<ItemCostState> emit,
  ) async {
    add(LoadItemCosts());
  }

  void _onSelectItemCost(
    SelectItemCost event,
    Emitter<ItemCostState> emit,
  ) {
    emit(state.copyWith(selected: event.itemCost));
  }

  void _onSelectMultipleItemCosts(
    SelectMultipleItemCosts event,
    Emitter<ItemCostState> emit,
  ) {
    emit(state.copyWith(multiselectionItems: event.itemCosts));
  }

  void _onClearSelection(
    ClearSelection event,
    Emitter<ItemCostState> emit,
  ) {
    emit(state.copyWith(
      selected: null,
      multiselectionItems: [],
    ));
  }

  void _onPrepareCreate(
    PrepareCreate event,
    Emitter<ItemCostState> emit,
  ) {
    final createItems = <ItemCost>[];
    final tempId = 1;

    final selected = ItemCost(
      tempId: tempId,
      company: authBloc.state.companyId,
    );
    createItems.add(selected);

    emit(state.copyWith(
      createItems: createItems,
      selected: selected,
    ));
  }

  void _onPrepareCopy(
    PrepareCopy event,
    Emitter<ItemCostState> emit,
  ) {
    final createItems = state.createItems ?? <ItemCost>[];
    
    final selected = event.itemCostToCopy.copyWith(
      id: null,
      company: authBloc.state.companyId,
    );
    createItems.add(selected);

    emit(state.copyWith(
      createItems: createItems,
      selected: selected,
    ));
  }

  void _onPrepareCreateInCreate(
    PrepareCreateInCreate event,
    Emitter<ItemCostState> emit,
  ) {
    final selected1 = ItemCost(company: authBloc.state.companyId);
    final createItems = _preparingTempId(selected1, List.from(state.createItems));

    emit(state.copyWith(
      createItems: createItems,
      selected1: selected1,
    ));
  }

  void _onPrepareCreateInEdit(
    PrepareCreateInEdit event,
    Emitter<ItemCostState> emit,
  ) {
    final selected1 = ItemCost(company: authBloc.state.companyId);
    final editItems = _preparingTempId(selected1, List.from(state.editItems));

    emit(state.copyWith(
      editItems: editItems,
      selected1: selected1,
    ));
  }

  void _onPrepareEdit(
    PrepareEdit event,
    Emitter<ItemCostState> emit,
  ) {
    final editItems = <ItemCost>[];
    final selected = state.multiselectionItems.isNotEmpty 
        ? state.multiselectionItems.first 
        : null;
    
    if (selected != null) {
      editItems.add(selected);
    }

    emit(state.copyWith(
      editItems: editItems,
      selected: selected,
    ));
  }

  Future<void> _onSaveItemCost(
    SaveItemCost event,
    Emitter<ItemCostState> emit,
  ) async {
    emit(ItemCostLoading(
      items: state.items,
      createItems: state.createItems,
      editItems: state.editItems,
      multiselectionItems: state.multiselectionItems,
      filteredValues: state.filteredValues,
      selected: state.selected,
      selected1: state.selected1,
      selected2: state.selected2,
    ));

    try {
      for (final item in event.items) {
        if (item.id == null) {
          await repository.create(item);
        } else {
          await repository.update(item);
        }
      }

      final updatedItems = await repository.findAll();
      final filteredItems = _filterItemsByUserPermission(updatedItems);

      emit(ItemCostOperationSuccess(
        items: filteredItems,
        createItems: [],
        editItems: [],
        multiselectionItems: [],
        filteredValues: state.filteredValues,
        selected: null,
        selected1: null,
        selected2: state.selected2,
        successMessage: 'Saved successfully',
      ));
    } catch (e) {
      emit(ItemCostError(
        items: state.items,
        createItems: state.createItems,
        editItems: state.editItems,
        multiselectionItems: state.multiselectionItems,
        filteredValues: state.filteredValues,
        selected: state.selected,
        selected1: state.selected1,
        selected2: state.selected2,
        errorMessage: 'Error saving items: $e',
      ));
    }
  }

  Future<void> _onSaveRow(
    SaveRow event,
    Emitter<ItemCostState> emit,
  ) async {
    try {
      for (final item in event.items) {
        if (item.id == null) {
          await repository.create(item);
        } else {
          await repository.update(item);
        }
      }

      emit(ItemCostOperationSuccess(
        items: state.items,
        createItems: state.createItems,
        editItems: state.editItems,
        multiselectionItems: state.multiselectionItems,
        filteredValues: state.filteredValues,
        selected: state.selected,
        selected1: state.selected1,
        selected2: state.selected2,
        successMessage: 'Saved successfully',
      ));
    } catch (e) {
      emit(ItemCostError(
        items: state.items,
        createItems: state.createItems,
        editItems: state.editItems,
        multiselectionItems: state.multiselectionItems,
        filteredValues: state.filteredValues,
        selected: state.selected,
        selected1: state.selected1,
        selected2: state.selected2,
        errorMessage: 'Error saving row: $e',
      ));
    }
  }

  Future<void> _onSaveInEdit(
    SaveInEdit event,
    Emitter<ItemCostState> emit,
  ) async {
    try {
      for (final item in event.items) {
        if (item.id == null) {
          await repository.create(item);
        } else {
          await repository.update(item);
        }
      }

      final updatedItems = await repository.findAll();
      final filteredItems = _filterItemsByUserPermission(updatedItems);

      emit(ItemCostOperationSuccess(
        items: filteredItems,
        createItems: state.createItems,
        editItems: [],
        multiselectionItems: state.multiselectionItems,
        filteredValues: state.filteredValues,
        selected: null,
        selected1: null,
        selected2: state.selected2,
        successMessage: 'Saved successfully',
      ));
    } catch (e) {
      emit(ItemCostError(
        items: state.items,
        createItems: state.createItems,
        editItems: state.editItems,
        multiselectionItems: state.multiselectionItems,
        filteredValues: state.filteredValues,
        selected: state.selected,
        selected1: state.selected1,
        selected2: state.selected2,
        errorMessage: 'Error saving in edit: $e',
      ));
    }
  }

  Future<void> _onCreateInEdit(
    CreateInEdit event,
    Emitter<ItemCostState> emit,
  ) async {
    try {
      await repository.create(event.itemCost);
      
      final updatedItems = await repository.findAll();
      final filteredItems = _filterItemsByUserPermission(updatedItems);

      emit(ItemCostOperationSuccess(
        items: filteredItems,
        createItems: state.createItems,
        editItems: state.editItems,
        multiselectionItems: state.multiselectionItems,
        filteredValues: state.filteredValues,
        selected: state.selected,
        selected1: null,
        selected2: state.selected2,
        successMessage: 'Created successfully',
      ));
    } catch (e) {
      emit(ItemCostError(
        items: state.items,
        createItems: state.createItems,
        editItems: state.editItems,
        multiselectionItems: state.multiselectionItems,
        filteredValues: state.filteredValues,
        selected: state.selected,
        selected1: state.selected1,
        selected2: state.selected2,
        errorMessage: 'Error creating item: $e',
      ));
    }
  }

  Future<void> _onDeleteItemCost(
    DeleteItemCost event,
    Emitter<ItemCostState> emit,
  ) async {
    try {
      if (event.itemCost.id != null) {
        await repository.delete(event.itemCost.id!);
      }

      final updatedItems = await repository.findAll();
      final filteredItems = _filterItemsByUserPermission(updatedItems);

      emit(ItemCostOperationSuccess(
        items: filteredItems,
        createItems: state.createItems,
        editItems: state.editItems,
        multiselectionItems: state.multiselectionItems,
        filteredValues: state.filteredValues,
        selected: null,
        selected1: null,
        selected2: state.selected2,
        successMessage: 'Deleted successfully',
      ));
    } catch (e) {
      emit(ItemCostError(
        items: state.items,
        createItems: state.createItems,
        editItems: state.editItems,
        multiselectionItems: state.multiselectionItems,
        filteredValues: state.filteredValues,
        selected: state.selected,
        selected1: state.selected1,
        selected2: state.selected2,
        errorMessage: 'Error deleting item: $e',
      ));
    }
  }

  Future<void> _onDeleteMultipleItemCosts(
    DeleteMultipleItemCosts event,
    Emitter<ItemCostState> emit,
  ) async {
    try {
      await repository.deleteMultiple(event.itemCosts);

      final updatedItems = await repository.findAll();
      final filteredItems = _filterItemsByUserPermission(updatedItems);

      emit(ItemCostOperationSuccess(
        items: filteredItems,
        createItems: state.createItems,
        editItems: state.editItems,
        multiselectionItems: [],
        filteredValues: state.filteredValues,
        selected: null,
        selected1: null,
        selected2: state.selected2,
        successMessage: 'Deleted successfully',
      ));
    } catch (e) {
      emit(ItemCostError(
        items: state.items,
        createItems: state.createItems,
        editItems: state.editItems,
        multiselectionItems: state.multiselectionItems,
        filteredValues: state.filteredValues,
        selected: state.selected,
        selected1: state.selected1,
        selected2: state.selected2,
        errorMessage: 'Error deleting items: $e',
      ));
    }
  }

  void _onRemoveInCreate(
    RemoveInCreate event,
    Emitter<ItemCostState> emit,
  ) {
    final createItems = List<ItemCost>.from(state.createItems);
    
    if (event.itemCost.id == null) {
      createItems.removeWhere((element) => element.tempId == event.itemCost.tempId);
    } else {
      createItems.removeWhere((element) => element.id == event.itemCost.id);
      if (event.itemCost.id != null) {
        repository.delete(event.itemCost.id!);
      }
    }

    emit(state.copyWith(createItems: createItems));
  }

  void _onRemoveInEdit(
    RemoveInEdit event,
    Emitter<ItemCostState> emit,
  ) {
    final editItems = List<ItemCost>.from(state.editItems);
    
    if (event.itemCost.id == null) {
      editItems.removeWhere((element) => element.tempId == event.itemCost.tempId);
    } else {
      editItems.removeWhere((element) => element.id == event.itemCost.id);
      if (event.itemCost.id != null) {
        repository.delete(event.itemCost.id!);
      }
    }

    emit(state.copyWith(editItems: editItems));
  }

  void _onSaveAndClose(
    SaveAndClose event,
    Emitter<ItemCostState> emit,
  ) {
    _onCancelUpdate(CancelUpdate(), emit);
    _onCancelCreate(CancelCreate(), emit);
    // Navigation would be handled by the UI layer
  }

  void _onSaveAndAddNew(
    SaveAndAddNew event,
    Emitter<ItemCostState> emit,
  ) {
    final createItems = <ItemCost>[ItemCost()];
    emit(state.copyWith(createItems: createItems));
    // Navigation would be handled by the UI layer
  }

  void _onSaveAndAddContinue(
    SaveAndAddContinue event,
    Emitter<ItemCostState> emit,
  ) {
    final createItems = <ItemCost>[state.selected ?? ItemCost()];
    emit(state.copyWith(createItems: createItems));
    // Navigation would be handled by the UI layer
  }

  // Complex business logic methods
  Future<void> _onUpdateItemCosts(
    UpdateItemCosts event,
    Emitter<ItemCostState> emit,
  ) async {
    try {
      final poh = event.purchaseOrderHeader;
      if (poh.id != null) {
        final otherCost = poh.amountOtherCosts ?? 0.0;
        final grossCost = poh.amountGross ?? 1.0;

        // This would need to be implemented based on your PurchaseOrderDetail repository
        // final purchaseOrderDetailList = await purchaseOrderDetailRepository.findByHeader(poh.id!);
        
        // For demonstration, I'll create a mock implementation
        final purchaseOrderDetailList = <PurchaseOrderDetailModel>[]; // Replace with actual data

        for (final p in purchaseOrderDetailList) {
          final unitCost = p.unitCost ?? 0.0;
          final factor = await itemUomConversionsController.fromOtherToPrimary(
              p.itemNumber!, p.unitOfMeasure!, authBloc.state.companyId!);
          final qty = p.quantityTransaction ?? 1.0;
          final w = (p.amountExtendedCost ?? 0.0) / grossCost;
          final cost = (w * otherCost / qty + unitCost) / factor;

          final itemCostTableList = await repository.findByItemNumberAndCompany(
            p.itemNumber!,
            authBloc.state.companyId!,
          );

          if (itemCostTableList.isNotEmpty) {
            // This would need PurchaseOrderReceiver repository implementation
            // final purchaseOrderReceiverList = await purchaseOrderReceiverRepository.findByDetail(p.id!);
            final purchaseOrderReceiverList = <PurchaseOrderReceiverModel>[]; // Replace with actual data

            if (purchaseOrderReceiverList.isEmpty) {
              final item = itemCostTableList.first;
              final qtyTrn = factor * (p.quantityTransaction ?? 0.0);
              final qtyOld = await itemsInBranchController.totalAvailabilityOfAnItemInSpecificPrimary(p.itemNumber!);
              final qtyTotal = qtyOld + qtyTrn;
              final amountOld = (item.amountUnitCost ?? 0.0) * qtyOld;
              final amountN = cost * qtyTrn;
              
              final unitCostAvg = ((amountOld + amountN) / qtyTotal).toStringAsFixed(2);

              final updatedItem = item.copyWith(
                amountUnitCost: double.parse(unitCostAvg),
                dateUpdated: DateTime.now().millisecondsSinceEpoch,
                userId: authBloc.state.userId,
              );

              await repository.update(updatedItem);
            }
          } else {
            final newItem = ItemCost(
              amountUnitCost: double.parse(cost.toStringAsFixed(2)),
              dateUpdated: DateTime.now().millisecondsSinceEpoch,
              userId: authBloc.state.userId,
              company: authBloc.state.companyId,
              itemNumber: p.itemNumber!,
            );

            await repository.create(newItem);
          }
        }
      }

      emit(ItemCostOperationSuccess(
        items: state.items,
        createItems: state.createItems,
        editItems: state.editItems,
        multiselectionItems: state.multiselectionItems,
        filteredValues: state.filteredValues,
        selected: state.selected,
        selected1: state.selected1,
        selected2: state.selected2,
        successMessage: 'Item costs updated successfully',
      ));
    } catch (e) {
      emit(ItemCostError(
        items: state.items,
        createItems: state.createItems,
        editItems: state.editItems,
        multiselectionItems: state.multiselectionItems,
        filteredValues: state.filteredValues,
        selected: state.selected,
        selected1: state.selected1,
        selected2: state.selected2,
        errorMessage: 'Error updating item costs: $e',
      ));
    }
  }
/*
  Future<void> _onUpdateItemCostsForItemMaster(
    UpdateItemCostsForItemMaster event,
    Emitter<ItemCostState> emit,
  ) async {
    try {
      final im = event.itemMaster;
      final it = event.item;

      if (im != null && 
          im.unitCost != null && 
          im.unitCost != 0.0 &&
          im.quantity != null && 
          im.quantity != 0.0 && 
          it != null && 
          it.id != null) {
        
        final factor = await itemUomConversionsController.fromOtherToPrimary(it, im.defualtUom ?? '');
        
        final itemCostTableList = await repository.findByItemNumberAndCompany(
          it.id!,
          authBloc.state.companyId!,
        );

        if (itemCostTableList.isNotEmpty) {
          final item = itemCostTableList.first;
          final qtyNew = factor * im.quantity!;
          final amtNew = qtyNew * im.unitCost!;
          final qtyOld = await itemsInBranchController.totalAvailabilityOfAnItemInSpecificPrimary(it);
          final amtOld = qtyOld * (item.amountUnitCost ?? 0.0);
          final qtyTotal = qtyOld + qtyNew;
          
          final unitCostAvg = ((amtOld + amtNew) / qtyTotal).toStringAsFixed(2);

          final updatedItem = item.copyWith(
            amountUnitCost: double.parse(unitCostAvg),
            dateUpdated: DateTime.now().millisecondsSinceEpoch,
            userId: authBloc.state.userId,
          );

          await repository.update(updatedItem);
        } else {
          final newItem = ItemCost(
            amountUnitCost: double.parse(im.unitCost!.toStringAsFixed(2)),
            dateUpdated: DateTime.now().millisecondsSinceEpoch,
            userId: authBloc.state.userId,
            company: authBloc.state.companyId,
            itemNumber: it.id,
          );

          await repository.create(newItem);
        }
      }

      emit(ItemCostOperationSuccess(
        items: state.items,
        createItems: state.createItems,
        editItems: state.editItems,
        multiselectionItems: state.multiselectionItems,
        filteredValues: state.filteredValues,
        selected: state.selected,
        selected1: state.selected1,
        selected2: state.selected2,
        successMessage: 'Item master costs updated successfully',
      ));
    } catch (e) {
      emit(ItemCostError(
        items: state.items,
        createItems: state.createItems,
        editItems: state.editItems,
        multiselectionItems: state.multiselectionItems,
        filteredValues: state.filteredValues,
        selected: state.selected,
        selected1: state.selected1,
        selected2: state.selected2,
        errorMessage: 'Error updating item master costs: $e',
      ));
    }
  }
  */

  Future<void> _onUpdateUnitPrice(
    UpdateUnitPrice event,
    Emitter<ItemCostState> emit,
  ) async {
    try {
      final itCost = event.itemCost;
      final poR = event.purchaseOrderReceiver;
        final systemConstant = systemConstantController.state.selected;
        final autoSalesPriceBoolean = systemConstant!.autoSalesPrice ?? false;

      if (itCost.id != null &&
          itCost.amountUnitCost != null &&
          itCost.amountUnitCost != 0.0 && 
          poR.id != null && (autoSalesPriceBoolean == true)) {

        double price = 0.0;
        final itemBranch = await itemsInBranchController.itemBranchByItemAndBranch(
          itCost.itemNumber!, 
          poR.branchRecieved!,
        );

        // Step 1: Item Branch Level
        if (itemBranch != null &&
            itemBranch.marginType != null &&
            itemBranch.marginRate != null &&
            itemBranch.marginRate != 0.0) {
          
          switch (itemBranch.marginType) {
            case 'F': // Flat
              final factorib = await itemUomConversionsController.fromOtherToAnother(
                itCost.itemNumber!,
                itCost.fromUOM!.unitOfMeasure!,
                itemBranch.unitOfMeasure!,
                authBloc.state.companyId!
              );
              final unitPriceF = (factorib * (itCost.amountUnitCost! + itemBranch.marginRate!)).toStringAsFixed(2);
              price = double.parse(unitPriceF);
              await _updatingToItemBranchCompany(price, itemBranch, null, null, null);
              break;
            
            case 'P': // Percentage
              final factoribP = await itemUomConversionsController.fromOtherToAnother(
                itCost.itemNumber!,
                itCost.fromUOM!.unitOfMeasure!,
                itemBranch.unitOfMeasure!,
                authBloc.state.companyId!
              );
              final unitPriceP = (factoribP * (itCost.amountUnitCost! * (1 + itemBranch.marginRate! / 100.0))).toStringAsFixed(2);
              price = double.parse(unitPriceP);
              await _updatingToItemBranchCompany(price, itemBranch, null, null, null);
              break;
          }
        }
        // Additional steps would continue here following the same pattern...

        emit(ItemCostOperationSuccess(
          items: state.items,
          createItems: state.createItems,
          editItems: state.editItems,
          multiselectionItems: state.multiselectionItems,
          filteredValues: state.filteredValues,
          selected: state.selected,
          selected1: state.selected1,
          selected2: state.selected2,
          successMessage: 'Unit price updated successfully',
        ));
      }
    } catch (e) {
      emit(ItemCostError(
        items: state.items,
        createItems: state.createItems,
        editItems: state.editItems,
        multiselectionItems: state.multiselectionItems,
        filteredValues: state.filteredValues,
        selected: state.selected,
        selected1: state.selected1,
        selected2: state.selected2,
        errorMessage: 'Error updating unit price: $e',
      ));
    }
  }

  // Helper method for updating item branch/company prices
  Future<void> _updatingToItemBranchCompany(
    double newPrice,
    ItemInBranchModel? ib,
    ItemEntryModel? it,
    Branch? b,
    Company? c,
  ) async {
    try {
      if (newPrice != 0.0) {
        if (ib != null) {
          // Item Branch Level Update
          await itemsInBranchController.updateUnitPrice(ib, newPrice);
          itemsInBranchController.sendNotification(ib);
        } else if (it != null && (b == null || c != null)) {
          // Item Level Update
          await itemsInBranchController.updateItemUnitPrice(it.id, newPrice);
          final itemsInBranchList = await itemsInBranchController.itemInBranchByItem(it.id);
          for (final itB in itemsInBranchList) {
            await itemsInBranchController.updateUnitPrice(itB, newPrice);
            itemsInBranchController.sendNotification(itB);
          }
        } else if (b != null && it != null) {
          // Branch Level Update
          final itemsInBranchList = await itemsInBranchController.itemInBranchByItemAndBranch(it.id, b.id);
          for (final itB in itemsInBranchList) {
            await itemsInBranchController.updateUnitPrice(itB, newPrice);
            itemsInBranchController.sendNotification(itB);
          }
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  void _onFilterItemCosts(
    FilterItemCosts event,
    Emitter<ItemCostState> emit,
  ) {
    emit(state.copyWith(filteredValues: event.filteredItems));
  }

  void _onCancelUpdate(
    CancelUpdate event,
    Emitter<ItemCostState> emit,
  ) {
    emit(state.copyWith(
      selected1: null,
      editItems: null,
    ));
  }

  void _onCancelCreate(
    CancelCreate event,
    Emitter<ItemCostState> emit,
  ) {
    emit(state.copyWith(
      selected: null,
      createItems: null,
    ));
  }

  void _onDiscardChanges(
    DiscardChanges event,
    Emitter<ItemCostState> emit,
  ) {
    final createItems = state.createItems ?? [];
    for (final item in createItems) {
      if (item.id != null) {
        repository.delete(item.id!);
      }
    }

    emit(state.copyWith(
      selected: null,
      createItems: null,
      items: null,
    ));

    // This would typically show a success message in the UI
  }
}