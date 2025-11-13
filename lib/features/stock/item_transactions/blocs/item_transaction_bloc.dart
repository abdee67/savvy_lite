import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:savvy_stock/features/sales/sales_order/header/bloc/sales_order_header_bloc.dart';
import 'package:savvy_stock/features/system_constant/bloc/system_constant_bloc.dart';
import 'package:savvy_stock/core/repositories/udc_repository.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/next_number/bloc/next_number_bloc.dart';
import 'package:savvy_stock/features/stock/item_entry/blocs/item_entry_bloc.dart';
import 'package:savvy_stock/features/stock/item_transactions/blocs/item_transaction_event.dart';
import 'package:savvy_stock/features/stock/item_transactions/blocs/item_transaction_state.dart';
import 'package:savvy_stock/features/stock/item_transactions/model/item_transaction_model.dart';
import 'package:savvy_stock/features/stock/item_transactions/repo/item_transaction_repo.dart';

class ItemTransactionsBloc
    extends Bloc<ItemTransactionsEvent, ItemTransactionsState> {
  final ItemTransactionRepository repository;
  final AuthBloc authBloc;
  final SystemConstantBloc systemConstantBloc;
  final NextNumberBloc nextNumberBloc;
  final StockItemsEntryBloc itemsTableController;
  final SalesOrderHeaderBloc salesOrderHeaderController;
  final UdcRepository udcRepository;
  StreamSubscription? _authSubscription;

  ItemTransactionsBloc({
    required this.salesOrderHeaderController,
    required this.authBloc,
    required this.systemConstantBloc,
    required this.nextNumberBloc,
    required this.itemsTableController,
    required this.repository,
    required this.udcRepository,
  }) : super(const ItemTransactionsState()) {
    _authSubscription = authBloc.stream.listen((authState) {
      if (authState.isAuthenticated && authState.companyId != null) {
        add(
          LoadItemTransactions(
            companyId: authState.companyId!,
            branchId: authState.branchId,
          ),
        );
      }
    });

    on<LoadItemTransactions>(_onLoadTransactions);
    on<SaveItemTransaction>(_onSaveTransaction);
    on<SaveRowTransaction>(_onSaveRow);
    on<CreateItemTransaction>(_onCreateTransaction);
    on<SaveAndClose>(_onSaveAndClose);
    on<SaveAndAddNew>(_onSaveAndAddNew);
    on<ExportTransactions>(_onExportTransactions);
    on<UpdateItemTransaction>(_onUpdateTransaction);
    on<DeleteItemTransaction>(_onDeleteTransaction);
    on<DeleteMultipleItemTransactions>(_onDeleteMultipleTransactions);
    on<FilterItemTransactions>(_onFilterTransactions);
    on<SelectItemTransaction>(_onSelectTransaction);
    on<SelectMultipleItemTransactions>(_onSelectMultipleTransactions);
    on<ClearSelection>(_onClearSelection);
    on<PrepareCreate>(_onPrepareCreate);
    on<PrepareEdit>(_onPrepareEdit);
    on<ExecuteInventoryTransaction>(_onExecuteInventoryTransaction);
    on<CalculateOpeningAmount>(_onCalculateOpeningAmount);
    on<GetTotalOpening>(_onGetTotalOpening);

    on<CancelCreate>(_onCancelCreate);
    on<CancelUpdate>(_onCancelUpdate);
    on<Discard>(_onDiscard);

    on<LoadLocationsForItem>(_onLoadLocationsForItem);
    on<SelectLocation>(_onSelectLocation);
    on<LoadLotsForItem>(_onLoadLotsForItem);
    on<SelectLot>(_onSelectLot);
    on<LoadToLocationsForItem>(_onLoadToLocationsForItem);
    on<SelectToLocation>(_onSelectToLocation);
    on<LoadItemsForBranch>(_onLoadItemsForBranch);
    on<SelectItem>(_onSelectItem);
    on<LoadUoMDescription>(_onLoadUoMDescription);
  }

  Future<void> _onLoadTransactions(
    LoadItemTransactions event,
    Emitter<ItemTransactionsState> emit,
  ) async {
    emit(state.copyWith(status: ItemTransactionsStatus.loading));
    try {
      final transactions = await repository.getTransactionsByCompany(
        event.companyId,
      );
      emit(
        state.copyWith(
          status: ItemTransactionsStatus.loaded,
          transactions: transactions,
          filteredTransactions: transactions,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ItemTransactionsStatus.error,
          error: 'Failed to load transactions: $e',
        ),
      );
    }
  }

  Future<void> _onSaveTransaction(
    SaveItemTransaction event,
    Emitter<ItemTransactionsState> emit,
  ) async {
    emit(state.copyWith(status: ItemTransactionsStatus.saving));
    try {
      final batch = <Future>[];
      for (final transaction in event.transactions) {
        if (transaction.id == null) {
          batch.add(repository.createTransaction(transaction));
        } else {
          batch.add(repository.updateTransaction(transaction));
        }
      }
      await Future.wait(batch);

      emit(
        state.copyWith(
          status: ItemTransactionsStatus.success,
          successmessage: 'Saved',
          createItems: const [],
          editItems: const [],
        ),
      );
      add(LoadItemTransactions(companyId: authBloc.state.companyId!));
    } catch (e) {
      emit(
        state.copyWith(
          status: ItemTransactionsStatus.error,
          error: 'Failed to save transactions: $e',
        ),
      );
    }
  }

  Future<void> _onSaveRow(
    SaveRowTransaction event,
    Emitter<ItemTransactionsState> emit,
  ) async {
    emit(state.copyWith(status: ItemTransactionsStatus.saving));
    try {
      final batch = <Future>[];
      for (final transaction in state.editItems) {
        if (transaction.id == null) {
          batch.add(repository.createTransaction(transaction));
        } else {
          batch.add(repository.updateTransaction(transaction));
        }
      }
      await Future.wait(batch);

      emit(
        state.copyWith(
          status: ItemTransactionsStatus.success,
          successmessage: 'Saved',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ItemTransactionsStatus.error,
          error: 'Failed to save row: $e',
        ),
      );
    }
  }

  Future<void> _onUpdateTransaction(
    UpdateItemTransaction event,
    Emitter<ItemTransactionsState> emit,
  ) async {
    emit(state.copyWith(status: ItemTransactionsStatus.updating));
    try {
      await repository.updateTransaction(event.transaction);
      emit(
        state.copyWith(
          status: ItemTransactionsStatus.success,
          successmessage: 'Transaction updated successfully',
        ),
      );
      add(
        LoadItemTransactions(
          companyId: event.transaction.company!,
          branchId: event.transaction.branch,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ItemTransactionsStatus.error,
          error: 'Failed to update transaction: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _onDeleteTransaction(
    DeleteItemTransaction event,
    Emitter<ItemTransactionsState> emit,
  ) async {
    emit(state.copyWith(status: ItemTransactionsStatus.deleting));

    try {
      await repository.deleteTransaction(event.transaction.id!);
      emit(
        state.copyWith(
          status: ItemTransactionsStatus.success,
          successmessage: 'Transaction deleted successfully',
          selectedItems: [],
        ),
      );
      add(
        LoadItemTransactions(
          companyId: event.transaction.company!,
          branchId: event.transaction.branch,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ItemTransactionsStatus.error,
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> _onDeleteMultipleTransactions(
    DeleteMultipleItemTransactions event,
    Emitter<ItemTransactionsState> emit,
  ) async {
    emit(state.copyWith(status: ItemTransactionsStatus.deleting));
    try {
      await repository.deleteTransactions(event.transactions);

      emit(
        state.copyWith(
          status: ItemTransactionsStatus.success,
          successmessage: 'Transactions deleted successfully',
          selectedItems: [],
        ),
      );
      if (event.transactions.isNotEmpty) {
        add(LoadItemTransactions(companyId: event.transactions.first.company!));
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: ItemTransactionsStatus.error,
          error: e.toString(),
        ),
      );
    }
  }

  void _onFilterTransactions(
    FilterItemTransactions event,
    Emitter<ItemTransactionsState> emit,
  ) {
    final query = event.query.toLowerCase();
    final filters = event.filters;

    var filtered = state.transactions.where((transaction) {
      bool matchesSearch =
          query.isEmpty ||
          transaction.remark?.toLowerCase().contains(query) == true ||
          transaction.transactionNumber?.toString().contains(query) == true;

      if (!matchesSearch) return false;

      if (filters != null) {
        // Apply additional filters
        if (filters['branch'] != null &&
            transaction.branch != filters['branch']) {
          return false;
        }
        if (filters['itemNumber'] != null &&
            transaction.itemNumber != filters['itemNumber']) {
          return false;
        }
        if (filters['transactionType'] != null &&
            transaction.transactionType != filters['transactionType']) {
          return false;
        }
        if (filters['dateRange'] != null) {
          final dateRange = filters['dateRange'] as DateTimeRange;
          if (transaction.dateCreated.isBefore(dateRange.start) ||
              transaction.dateCreated.isAfter(dateRange.end)) {
            return false;
          }
        }
      }

      return true;
    }).toList();

    // Calculate filtered totals
    double totalQuantity = 0;
    double totalCost = 0;
    for (var item in filtered) {
      totalQuantity += item.quantityTransaction ?? 0;
      totalCost += (item.amountCost ?? 0);
    }

    emit(
      state.copyWith(
        filteredTransactions: filtered,
        searchQuery: query,
        filters: filters,
        totalQuantity: totalQuantity,
        totalCost: totalCost,
      ),
    );
  }

  void _onSelectTransaction(
    SelectItemTransaction event,
    Emitter<ItemTransactionsState> emit,
  ) {
    final isAlreadySelected = state.selectedItems.any(
      (item) => item.id == event.transaction.id,
    );

    final updatedSelection = isAlreadySelected
        ? state.selectedItems
              .where((item) => item.id != event.transaction.id)
              .toList()
        : [...state.selectedItems, event.transaction];

    emit(
      state.copyWith(
        selectedItems: updatedSelection,
        isSelectionMode: updatedSelection.isNotEmpty,
      ),
    );
  }

  void _onSelectMultipleTransactions(
    SelectMultipleItemTransactions event,
    Emitter<ItemTransactionsState> emit,
  ) {
    emit(
      state.copyWith(
        selectedItems: event.transactions,
        isSelectionMode: event.transactions.isNotEmpty,
      ),
    );
  }

  void _onClearSelection(
    ClearSelection event,
    Emitter<ItemTransactionsState> emit,
  ) {
    emit(state.copyWith(selectedItems: [], isSelectionMode: false));
  }

  Future<void> _onPrepareCreate(
    PrepareCreate event,
    Emitter<ItemTransactionsState> emit,
  ) async {
    try {
      final user = authBloc.state.userId;
      if (user == null || authBloc.state.companyId == null) {
        throw Exception('User not authenticated');
      }

      final createItems = <ItemTransactionModel>[];
      final tempId = 1;
      final transactionNumber = await nextNumberBloc.generateFormattedNumber(
        'TN',
      );

      final selected = ItemTransactionModel(
        transactionNumber: transactionNumber,
        dateCreated: DateTime.now(),
        quantityTransaction: 0.0,
        beforeStoreQuantityAvailable: 0.0,
        unitCost: 0.0,
        amountCost: 0.0,
        beforeAmountCost: 0.0,
        company: authBloc.state.companyId,
        createdBy: user,
        tempId: tempId,
      );
      createItems.add(selected);

      emit(state.copyWith(createItems: createItems, selected: selected));
    } catch (e) {
      emit(state.copyWith(error: 'Failed to prepare create: $e'));
    }
  }

  Future<void> _onPrepareEdit(
    PrepareEdit event,
    Emitter<ItemTransactionsState> emit,
  ) async {
    try {
      final editItems = <ItemTransactionModel>[event.transaction];
      emit(state.copyWith(editItems: editItems, selected: event.transaction));
    } catch (e) {
      emit(state.copyWith(error: 'Failed to prepare edit: $e'));
    }
  }

  Future<void> _onExecuteInventoryTransaction(
    ExecuteInventoryTransaction event,
    Emitter<ItemTransactionsState> emit,
  ) async {
    emit(state.copyWith(status: ItemTransactionsStatus.processing));
    try {
      await repository.executeInventoryTransactions(
        masterTransaction: event.masterTransaction,
        detailTransactions: event.detailTransactions,
      );

      emit(
        state.copyWith(
          status: ItemTransactionsStatus.success,
          successmessage: 'Transaction successfully created!',
        ),
      );

      // Refresh data
      if (authBloc.state.companyId != null) {
        add(LoadItemTransactions(companyId: authBloc.state.companyId!));
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: ItemTransactionsStatus.error,
          error: 'Error occurred, please contact vendor!',
        ),
      );
    }
  }

  Future<void> _onCalculateOpeningAmount(
    CalculateOpeningAmount event,
    Emitter<ItemTransactionsState> emit,
  ) async {
    try {
      final openingAmount = await repository.calculateOpeningAmount(
        itemId: event.itemId,
        branchId: event.branchId,
        dateFrom: event.dateFrom,
        dateThru: event.dateThru,
      );

      emit(state.copyWith(openingAmount: openingAmount));
    } catch (e) {
      emit(state.copyWith(error: 'Failed to calculate opening amount: $e'));
    }
  }

  Future<void> _onGetTotalOpening(
    GetTotalOpening event,
    Emitter<ItemTransactionsState> emit,
  ) async {
    try {
      final opening = await repository.calculateOpeningAmount(
        itemId: event.itemIds,
        branchId: event.branchId,
        dateFrom: event.dateFrom,
        dateThru: event.dateThru,
      );

      emit(
        state.copyWith(
          status: ItemTransactionsStatus.loaded,
          totlaAmount: opening,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ItemTransactionsStatus.error,
          error: 'Failed to calculate total opening: $e',
        ),
      );
    }
  }

  Future<void> _onCreateTransaction(
    CreateItemTransaction event,
    Emitter<ItemTransactionsState> emit,
  ) async {
    emit(state.copyWith(status: ItemTransactionsStatus.creating));
    try {
      await repository.createTransaction(event.transaction);
      emit(
        state.copyWith(
          status: ItemTransactionsStatus.success,
          successmessage: 'Transaction created successfully',
        ),
      );
      add(LoadItemTransactions(companyId: authBloc.state.companyId!));
    } catch (e) {
      emit(
        state.copyWith(
          status: ItemTransactionsStatus.error,
          error: 'Failed to create transaction: $e',
        ),
      );
    }
  }

  Future<void> _onSaveAndClose(
    SaveAndClose event,
    Emitter<ItemTransactionsState> emit,
  ) async {
    emit(state.copyWith(status: ItemTransactionsStatus.saving));
    try {
      await _onCreateTransaction(
        CreateItemTransaction(state.createItems.first),
        emit,
      );
      emit(
        state.copyWith(
          selected: null,
          editingItem: null,
          createItems: [],
          editItems: [],
        ),
      );
      // Navigation should be handled in the UI
    } catch (e) {
      emit(
        state.copyWith(
          status: ItemTransactionsStatus.failure,
          successmessage: e.toString(),
        ),
      );
    }
  }

  void _onExportTransactions(
    ExportTransactions event,
    Emitter<ItemTransactionsState> emit,
  ) {
    emit(state.copyWith(status: ItemTransactionsStatus.exporting));

    // Simulate export process
    Future.delayed(const Duration(seconds: 2), () {
      emit(
        state.copyWith(
          status: ItemTransactionsStatus.success,
          exportedTransactions: event.transactions,
          successmessage:
              'Exported ${event.transactions.length} items successfully',
        ),
      );
    });
  }

  Future<void> _onSaveAndAddNew(
    SaveAndAddNew event,
    Emitter<ItemTransactionsState> emit,
  ) async {
    try {
      await _onCreateTransaction(
        CreateItemTransaction(state.createItems.first),
        emit,
      );
      ();
      add(PrepareCreate());
      // Navigation should be handled in the UI
    } catch (e) {
      emit(
        state.copyWith(
          status: ItemTransactionsStatus.failure,
          successmessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onCancelCreate(
    CancelCreate event,
    Emitter<ItemTransactionsState> emit,
  ) async {
    emit(state.copyWith(selected: null, createItems: [], transactions: []));
  }

  void _onCancelUpdate(
    CancelUpdate event,
    Emitter<ItemTransactionsState> emit,
  ) {
    emit(state.copyWith(editingItem: null, editItems: []));
  }

  Future<void> _onDiscard(
    Discard event,
    Emitter<ItemTransactionsState> emit,
  ) async {
    try {
      // Remove items that have been created but not saved
      final itemsToDelete = state.createItems
          .where((item) => item.id != null)
          .toList();
      if (itemsToDelete.isNotEmpty) {
        await repository.deleteTransactions(itemsToDelete);
      }

      emit(
        state.copyWith(
          selected: null,
          createItems: const [],
          transactions: const [],
          successmessage: 'All records are removed',
        ),
      );
    } catch (e) {
      emit(state.copyWith(error: 'Failed to discard transactions: $e'));
    }
  }

  Future<void> _onLoadLocationsForItem(
    LoadLocationsForItem event,
    Emitter<ItemTransactionsState> emit,
  ) async {
    emit(state.copyWith(loadingLocations: true));
    try {
      final locations = await repository.itemLocationsRepository
          .getItemLocationsByBranchAndItem(
            branchId: event.branchId,
            itemId: event.itemNumber,
            companyId: authBloc.state.companyId!,
          );
      emit(
        state.copyWith(loadingLocations: false, availableLocations: locations),
      );
    } catch (e) {
      emit(
        state.copyWith(
          loadingLocations: false,
          error: 'Failed to load locations: $e',
        ),
      );
    }
  }

  Future<void> _onSelectLocation(
    SelectLocation event,
    Emitter<ItemTransactionsState> emit,
  ) async {
    // Update the selected location in createItems or editItems
    final updatedCreateItems = state.createItems.map((item) {
      if (item.tempId == state.selected?.tempId) {
        return item.copyWith(itemLocation: event.locationId);
      }
      return item;
    }).toList();

    final updatedEditItems = state.editItems.map((item) {
      if (item.tempId == state.selected?.tempId) {
        return item.copyWith(itemLocation: event.locationId);
      }
      return item;
    }).toList();

    emit(
      state.copyWith(
        createItems: updatedCreateItems,
        editItems: updatedEditItems,
      ),
    );

    if (event.locationId != null) {
      add(LoadLotsForItem(event.itemNumber, event.branchId, event.locationId!));
    } else {
      add(LoadLotsForItem(event.itemNumber, event.branchId, null));
    }
  }

  Future<void> _onLoadLotsForItem(
    LoadLotsForItem event,
    Emitter<ItemTransactionsState> emit,
  ) async {
    emit(state.copyWith(loadingLots: true));
    try {
      final lots = await repository.lotMasterRepository
          .getLotMastersByItemAndBranch(
            itemNumber: event.itemNumber,
            branch: event.branchId,
            location: event.locationId,
            companyId: authBloc.state.companyId!,
          );
      emit(state.copyWith(loadingLots: false, availableLots: lots));
    } catch (e) {
      emit(
        state.copyWith(loadingLots: false, error: 'Failed to load lots: $e'),
      );
    }
  }

  Future<void> _onSelectLot(
    SelectLot event,
    Emitter<ItemTransactionsState> emit,
  ) async {
    // Update the selected lot in createItems or editItems
    final updatedCreateItems = state.createItems.map((item) {
      if (item.tempId == state.selected?.tempId) {
        return item.copyWith(lotNumber: event.lotId);
      }
      return item;
    }).toList();

    final updatedEditItems = state.editItems.map((item) {
      if (item.tempId == state.selected?.tempId) {
        return item.copyWith(lotNumber: event.lotId);
      }
      return item;
    }).toList();

    emit(
      state.copyWith(
        createItems: updatedCreateItems,
        editItems: updatedEditItems,
      ),
    );
  }

  Future<void> _onLoadToLocationsForItem(
    LoadToLocationsForItem event,
    Emitter<ItemTransactionsState> emit,
  ) async {
    emit(state.copyWith(loadingToLocations: true));
    try {
      final locations = await repository.itemLocationsRepository
          .getItemLocationsByBranchAndItem(
            itemId: event.itemNumber,
            branchId: event.toBranchId,
            companyId: authBloc.state.companyId!,
          );
      emit(
        state.copyWith(
          loadingToLocations: false,
          availableToLocations: locations,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          loadingToLocations: false,
          error: 'Failed to load to locations: $e',
        ),
      );
    }
  }

  Future<void> _onSelectToLocation(
    SelectToLocation event,
    Emitter<ItemTransactionsState> emit,
  ) async {
    // Update the selected to location in createItems or editItems
    final updatedCreateItems = state.createItems.map((item) {
      if (item.tempId == state.selected?.tempId) {
        return item.copyWith(itemLocation: event.toLocationId);
      }
      return item;
    }).toList();

    final updatedEditItems = state.editItems.map((item) {
      if (item.tempId == state.selected?.tempId) {
        return item.copyWith(itemLocation: event.toLocationId);
      }
      return item;
    }).toList();

    emit(
      state.copyWith(
        createItems: updatedCreateItems,
        editItems: updatedEditItems,
      ),
    );
  }

  Future<void> _onLoadItemsForBranch(
    LoadItemsForBranch event,
    Emitter<ItemTransactionsState> emit,
  ) async {
    emit(state.copyWith(loadingItems: true));
    try {
      final items = await repository.itemInBranchRepository.findByBranch(
        event.branchId,
        authBloc.state.companyId!,
      );
      emit(state.copyWith(loadingItems: false, availableItems: items));
    } catch (e) {
      emit(
        state.copyWith(loadingItems: false, error: 'Failed to load items: $e'),
      );
    }
  }

  Future<void> _onSelectItem(
    SelectItem event,
    Emitter<ItemTransactionsState> emit,
  ) async {
    // Update the selected item in createItems or editItems
    final updatedCreateItems = state.createItems.map((item) {
      if (item.tempId == state.selected?.tempId) {
        return item.copyWith(itemNumber: event.itemNumber);
      }
      return item;
    }).toList();

    final updatedEditItems = state.editItems.map((item) {
      if (item.tempId == state.selected?.tempId) {
        return item.copyWith(itemNumber: event.itemNumber);
      }
      return item;
    }).toList();

    emit(
      state.copyWith(
        createItems: updatedCreateItems,
        editItems: updatedEditItems,
      ),
    );
    if (event.itemNumber != null) {
      add(
        LoadLocationsForItem(
          event.itemNumber!,
          event.branchId,
          event.locationId,
        ),
      );
    }
  }

  Future<void> _onLoadUoMDescription(
    LoadUoMDescription event,
    Emitter<ItemTransactionsState> emit,
  ) async {
    emit(state.copyWith(loadingUoMDescription: true));
    try {
      final description = await udcRepository.getUdcDetailById(event.uomId);
      final updatedUomDescriptions = Map<int, String>.from(
        state.uomDescriptions,
      )..[event.uomId] = description?.description1 ?? '';

      emit(
        state.copyWith(
          loadingUoMDescription: false,
          uomDescriptions: updatedUomDescriptions,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          loadingUoMDescription: false,
          error: 'Failed to load UoM description: $e',
        ),
      );
    }
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}

class DateTimeRange {
  final DateTime start;
  final DateTime end;

  DateTimeRange({required this.start, required this.end});
}
