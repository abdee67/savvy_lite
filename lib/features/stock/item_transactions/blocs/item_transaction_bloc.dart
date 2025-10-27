import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/stock/item_transactions/blocs/item_transaction_event.dart';
import 'package:savvy_stock/features/stock/item_transactions/blocs/item_transaction_state.dart';
import 'package:savvy_stock/features/stock/item_transactions/model/item_transaction_model.dart';

class ItemTransactionsBloc
    extends Bloc<ItemTransactionsEvent, ItemTransactionsState> {
  final LocalDatabaseService databaseService;
  final AuthBloc authBloc;
  StreamSubscription? _authSubscription;

  ItemTransactionsBloc({
    required this.databaseService,
    required this.authBloc,
  }) : super(const ItemTransactionsState()) {
    _authSubscription = authBloc.stream.listen((authState) {
      if (authState.isAuthenticated && authState.companyId != null) {
        add(LoadItemTransactions(
          companyId: authState.companyId!,
          branchId: authState.branchId,
        ));
      }
    });

    on<LoadItemTransactions>(_onLoadTransactions);
    on<SaveItemTransaction>(_onSaveTransaction);
    on<UpdateItemTransaction>(_onUpdateTransaction);
    on<DeleteItemTransaction>(_onDeleteTransaction);
    on<DeleteMultipleItemTransactions>(_onDeleteMultipleTransactions);
    on<FilterItemTransactions>(_onFilterTransactions);
    on<SelectItemTransaction>(_onSelectTransaction);
    on<SelectMultipleItemTransactions>(_onSelectMultipleTransactions);
    on<ClearSelection>(_onClearSelection);
    on<PrepareCreate>(_onPrepareCreate);
    on<PrepareCreateInEdit>(_onPrepareCreateInEdit);
    on<PrepareEdit>(_onPrepareEdit);
    on<PrepareCopy>(_onPrepareCopy);
    on<CreateStockCardTransaction>(_onCreateStockCard);
    on<CalculateOpeningAmount>(_onCalculateOpeningAmount);
    on<SaveAndClose>(_onSaveAndClose);
    on<SaveAndAddNew>(_onSaveAndAddNew);
    on<CancelCreate>(_onCancelCreate);
    on<CancelUpdate>(_onCancelUpdate);
    on<Discard>(_onDiscard);
  }

  Future<void> _onLoadTransactions(
    LoadItemTransactions event,
    Emitter<ItemTransactionsState> emit,
  ) async {
    try {
      emit(state.copyWith(status: ItemTransactionsStatus.loading));
      
      final db = await databaseService.database;
      final transactions = await db.rawQuery('''
        SELECT t.*, 
               b.name as branch_name,
               i.description as item_description,
               l.name as location_name,
               lot.description as lot_description
        FROM item_transactions t
        LEFT JOIN branch_table b ON t.branch = b.id
        LEFT JOIN items_table i ON t.item_number = i.id
        LEFT JOIN item_locations l ON t.item_location = l.id
        LEFT JOIN lot_master lot ON t.lot_number = lot.id
        WHERE t.company = ? ${event.branchId != null ? 'AND t.branch = ?' : ''}
        ORDER BY t.date_created DESC
      ''', [
        event.companyId,
        if (event.branchId != null) event.branchId,
      ]);

      final items = transactions
          .map((map) => ItemTransactionModel.fromMap(map))
          .toList();

      // Calculate totals
      double totalQuantity = 0;
      double totalCost = 0;
      for (var item in items) {
        totalQuantity += item.quantityTransaction ?? 0;
        totalCost += (item.amountCost ?? 0);
      }

      emit(state.copyWith(
        status: ItemTransactionsStatus.loaded,
        items: items,
        filteredItems: items,
        totalQuantity: totalQuantity,
        totalCost: totalCost,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ItemTransactionsStatus.failure,
        message: e.toString(),
      ));
    }
  }

  Future<void> _onSaveTransaction(
    SaveItemTransaction event,
    Emitter<ItemTransactionsState> emit,
  ) async {
    try {
      emit(state.copyWith(status: ItemTransactionsStatus.saving));

      final db = await databaseService.database;
      await db.insert(
        'item_transactions',
        event.transaction.toMap(),
      );

      add(LoadItemTransactions(
        companyId: event.transaction.company!,
        branchId: event.transaction.branch,
      ));

      emit(state.copyWith(
        status: ItemTransactionsStatus.success,
        message: 'Transaction saved successfully',
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ItemTransactionsStatus.failure,
        message: e.toString(),
      ));
    }
  }

  Future<void> _onUpdateTransaction(
    UpdateItemTransaction event,
    Emitter<ItemTransactionsState> emit,
  ) async {
    try {
      emit(state.copyWith(status: ItemTransactionsStatus.saving));

      final db = await databaseService.database;
      await db.update(
        'item_transactions',
        event.transaction.toMap(),
        where: 'id = ?',
        whereArgs: [event.transaction.id],
      );

      add(LoadItemTransactions(
        companyId: event.transaction.company!,
        branchId: event.transaction.branch,
      ));

      emit(state.copyWith(
        status: ItemTransactionsStatus.success,
        message: 'Transaction updated successfully',
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ItemTransactionsStatus.failure,
        message: e.toString(),
      ));
    }
  }

  Future<void> _onDeleteTransaction(
    DeleteItemTransaction event,
    Emitter<ItemTransactionsState> emit,
  ) async {
    try {
      emit(state.copyWith(status: ItemTransactionsStatus.deleting));

      final db = await databaseService.database;
      await db.delete(
        'item_transactions',
        where: 'id = ?',
        whereArgs: [event.transaction.id],
      );

      add(LoadItemTransactions(
        companyId: event.transaction.company!,
        branchId: event.transaction.branch,
      ));

      emit(state.copyWith(
        status: ItemTransactionsStatus.success,
        message: 'Transaction deleted successfully',
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ItemTransactionsStatus.failure,
        message: e.toString(),
      ));
    }
  }

  Future<void> _onDeleteMultipleTransactions(
    DeleteMultipleItemTransactions event,
    Emitter<ItemTransactionsState> emit,
  ) async {
    try {
      emit(state.copyWith(status: ItemTransactionsStatus.deleting));

      final db = await databaseService.database;
      final batch = db.batch();
      for (var transaction in event.transactions) {
        batch.delete(
          'item_transactions',
          where: 'id = ?',
          whereArgs: [transaction.id],
        );
      }
      await batch.commit();

      if (event.transactions.isNotEmpty) {
        add(LoadItemTransactions(
          companyId: event.transactions.first.company!,
          branchId: event.transactions.first.branch,
        ));
      }

      emit(state.copyWith(
        status: ItemTransactionsStatus.success,
        message: 'Transactions deleted successfully',
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ItemTransactionsStatus.failure,
        message: e.toString(),
      ));
    }
  }

  void _onFilterTransactions(
    FilterItemTransactions event,
    Emitter<ItemTransactionsState> emit,
  ) {
    final query = event.query.toLowerCase();
    final filters = event.filters;

    var filtered = state.items.where((transaction) {
      bool matchesSearch = query.isEmpty ||
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
          if (transaction.dateCreated == null ||
              transaction.dateCreated!.isBefore(dateRange.start) ||
              transaction.dateCreated!.isAfter(dateRange.end)) {
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

    emit(state.copyWith(
      filteredItems: filtered,
      searchQuery: query,
      filters: filters,
      totalQuantity: totalQuantity,
      totalCost: totalCost,
    ));
  }

  void _onSelectTransaction(
    SelectItemTransaction event,
    Emitter<ItemTransactionsState> emit,
  ) {
    final isAlreadySelected = state.selectedItems
        .any((item) => item.id == event.transaction.id);

    final updatedSelection = isAlreadySelected
        ? state.selectedItems
            .where((item) => item.id != event.transaction.id)
            .toList()
        : [...state.selectedItems, event.transaction];

    emit(state.copyWith(
      selectedItems: updatedSelection,
      isSelectionMode: updatedSelection.isNotEmpty,
    ));
  }

  void _onSelectMultipleTransactions(
    SelectMultipleItemTransactions event,
    Emitter<ItemTransactionsState> emit,
  ) {
    emit(state.copyWith(
      selectedItems: event.transactions,
      isSelectionMode: event.transactions.isNotEmpty,
    ));
  }

  void _onClearSelection(
    ClearSelection event,
    Emitter<ItemTransactionsState> emit,
  ) {
    emit(state.copyWith(
      selectedItems: [],
      isSelectionMode: false,
    ));
  }

  void _onPrepareCreate(
    PrepareCreate event,
    Emitter<ItemTransactionsState> emit,
  ) {
    final newTransaction = ItemTransactionModel(
      dateCreated: DateTime.now(),
      company: authBloc.state.companyId,
      branch: authBloc.state.branchId,
    );
    emit(state.copyWith(
      selected: newTransaction,
      createItems: [...state.createItems, newTransaction],
    ));
  }

  void _onPrepareCreateInEdit(
    PrepareCreateInEdit event,
    Emitter<ItemTransactionsState> emit,
  ) {
    final newTransaction = ItemTransactionModel(
      dateCreated: DateTime.now(),
      company: authBloc.state.companyId,
      branch: authBloc.state.branchId,
    );
    emit(state.copyWith(
      editingItem: newTransaction,
      editItems: [...state.editItems, newTransaction],
    ));
  }

  void _onPrepareEdit(
    PrepareEdit event,
    Emitter<ItemTransactionsState> emit,
  ) {
    emit(state.copyWith(
      editingItem: event.transaction,
      editItems: [event.transaction],
    ));
  }

  void _onPrepareCopy(
    PrepareCopy event,
    Emitter<ItemTransactionsState> emit,
  ) {
    final copy = ItemTransactionModel(
      itemNumber: event.transaction.itemNumber,
      branch: event.transaction.branch,
      company: event.transaction.company,
      transactionType: event.transaction.transactionType,
      quantityTransaction: event.transaction.quantityTransaction,
      unitCost: event.transaction.unitCost,
      dateCreated: DateTime.now(),
    );
    emit(state.copyWith(
      selected: copy,
      isDuplicate: true,
    ));
  }

  Future<void> _onCreateStockCard(
    CreateStockCardTransaction event,
    Emitter<ItemTransactionsState> emit,
  ) async {
    try {
      emit(state.copyWith(status: ItemTransactionsStatus.saving));

      final db = await databaseService.database;
      final transaction = ItemTransactionModel(
        itemLocation: event.locationId,
        itemBranch: event.itemBranchId,
        lotNumber: event.lotId,
        transactionType: int.tryParse(event.transactionType),
        transactionNumber: event.transactionNumber,
        quantityTransaction: event.quantity,
        remark: event.remark,
        dateCreated: DateTime.now(),
        company: authBloc.state.companyId,
        branch: authBloc.state.branchId,
        createdBy: authBloc.state.userId,
      );

      await db.insert('item_transactions', transaction.toMap());

      add(LoadItemTransactions(
        companyId: authBloc.state.companyId!,
        branchId: authBloc.state.branchId,
      ));

      emit(state.copyWith(
        status: ItemTransactionsStatus.success,
        message: 'Stock card created successfully',
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ItemTransactionsStatus.failure,
        message: e.toString(),
      ));
    }
  }

  Future<void> _onCalculateOpeningAmount(
    CalculateOpeningAmount event,
    Emitter<ItemTransactionsState> emit,
  ) async {
    try {
      emit(state.copyWith(status: ItemTransactionsStatus.loading));

      final db = await databaseService.database;
      final result = await db.rawQuery('''
        SELECT SUM(quantity_transaction * unit_cost) as opening_amount
        FROM item_transactions
        WHERE item_number = ? 
        AND branch = ?
        AND date_created >= ?
        AND date_created <= ?
      ''', [
        event.itemId,
        event.branchId,
        event.fromDate.toIso8601String(),
        event.toDate.toIso8601String(),
      ]);

      final openingAmount = result.first['opening_amount'] as double? ?? 0.0;

      emit(state.copyWith(
        status: ItemTransactionsStatus.loaded,
        openingBalance: openingAmount,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ItemTransactionsStatus.failure,
        message: e.toString(),
      ));
    }
  }

  Future<void> _onSaveAndClose(
    SaveAndClose event,
    Emitter<ItemTransactionsState> emit,
  ) async {
    try {
      await _saveCurrentTransaction();
      emit(state.copyWith(
        selected: null,
        editingItem: null,
        createItems: [],
        editItems: [],
      ));
      // Navigation should be handled in the UI
    } catch (e) {
      emit(state.copyWith(
        status: ItemTransactionsStatus.failure,
        message: e.toString(),
      ));
    }
  }

  Future<void> _onSaveAndAddNew(
    SaveAndAddNew event,
    Emitter<ItemTransactionsState> emit,
  ) async {
    try {
      await _saveCurrentTransaction();
      add(PrepareCreate());
      // Navigation should be handled in the UI
    } catch (e) {
      emit(state.copyWith(
        status: ItemTransactionsStatus.failure,
        message: e.toString(),
      ));
    }
  }

  void _onCancelCreate(
    CancelCreate event,
    Emitter<ItemTransactionsState> emit,
  ) {
    emit(state.copyWith(
      selected: null,
      createItems: [],
    ));
  }

  void _onCancelUpdate(
    CancelUpdate event,
    Emitter<ItemTransactionsState> emit,
  ) {
    emit(state.copyWith(
      editingItem: null,
      editItems: [],
    ));
  }

  void _onDiscard(
    Discard event,
    Emitter<ItemTransactionsState> emit,
  ) {
    emit(state.copyWith(
      selected: null,
      editingItem: null,
      createItems: [],
      editItems: [],
      selectedItems: [],
      isSelectionMode: false,
    ));
  }

  Future<void> _saveCurrentTransaction() async {
    final db = await databaseService.database;
    final transaction = state.selected ?? state.editingItem;
    if (transaction == null) return;

    if (transaction.id == null) {
      await db.insert('item_transactions', transaction.toMap());
    } else {
      await db.update(
        'item_transactions',
        transaction.toMap(),
        where: 'id = ?',
        whereArgs: [transaction.id],
      );
    }

    add(LoadItemTransactions(
      companyId: transaction.company!,
      branchId: transaction.branch,
    ));
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
