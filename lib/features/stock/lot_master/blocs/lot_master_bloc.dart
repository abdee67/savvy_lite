// features/stock/lot_master/blocs/lot_master_bloc.dart
import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:savvy_stock/core/blocs/system_constant/system_constant_bloc.dart';
import 'package:savvy_stock/core/repositories/udc_repository.dart';
import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/next_number/bloc/next_number_bloc.dart';
import 'package:savvy_stock/features/purchase/supplier/models/purchase_order_receiver_model.dart';
import 'package:savvy_stock/features/stock/lot_master/blocs/lot_master_event.dart';
import 'package:savvy_stock/features/stock/lot_master/blocs/lot_master_state.dart';
import 'package:savvy_stock/features/stock/lot_master/models/lot_master_model.dart';
import 'package:savvy_stock/features/udc_detail/models/udc_details.dart';

class LotMasterBloc extends Bloc<LotMasterEvent, LotMasterState> {
  final LocalDatabaseService databaseService;
  final AuthBloc authBloc;
  final SystemConstantBloc systemConstantBloc;
  final UdcRepository udcRepository;
  final NextNumberBloc nextNumberBloc;
  StreamSubscription? _authSubscription;

  LotMasterBloc({
    required this.databaseService,
    required this.authBloc,
    required this.systemConstantBloc,
    required this.udcRepository,
    required this.nextNumberBloc,
  }) : super(const LotMasterState()) {
    _authSubscription = authBloc.stream.listen((authState) {
      if (authState.isAuthenticated && authState.companyId != null) {
        add(LoadLotMasters(authState.companyId!));
      }
    });

    on<LoadLotMasters>(_onLoadLots);
    on<FilterLotMasters>(_onFilterLots);
    on<ResetLotFilter>(_onResetFilter);
    on<SearchLotMasters>(_onSearchLotMasters);
    on<SaveLotMaster>(_onSaveLot);
    on<UpdateLotMaster>(_onUpdateLot);
    on<DeleteLotMaster>(_onDeleteLot);
    on<DeleteMultipleLotMasters>(_onDeleteMultipleLotMasters);
    on<PrepareCreateLot>(_onPrepareCreate);
    on<PrepareEditLot>(_onPrepareEdit);
    on<SelecteLot>(_onSelecteLot);
    on<SelectMultiSelectionLots>(_onSelectMultiSelectionLots);
    on<ClearSelection>(_onClearSelection);
    on<AutoCreateLotForPO>(_onAutoCreateLotForPO);
    on<CalculateLotStatus>(_onCalculateLotStatus);
    on<ClaculateMultipleLotStatus>(_onClaculateMultipleLotStatus);
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }

  Future<void> _onLoadLots(
    LoadLotMasters event,
    Emitter<LotMasterState> emit,
  ) async {
    emit(state.copyWith(status: LotMasterStatus.loading));
    try {
      final db = await databaseService.database;
      final lots = await db.rawQuery(
        '''
        SELECT lm.*,
               it.items_id as item_id,
               it.item_description,
               b.description as branch_name,
               il.location_name,
               ud.detail_code as status_code,
               ud.description_1 as status_description
        FROM lot_master lm
        LEFT JOIN items_table it ON lm.item_number = it.id
        LEFT JOIN branch_table b ON lm.branch = b.id
        LEFT JOIN item_locations il ON lm.location = il.id
        LEFT JOIN udc_details ud ON lm.lot_status = ud.id
        WHERE lm.company = ?
        ORDER BY it.item_description
      ''',
        [event.companyId],
      );

      final lotList = lots.map((p) => LotMaster.fromMap(p)).toList();
      // Auto-calculate status for all loaded lots
      final systemConstant = systemConstantBloc.state.selected;
      final lotTypeUdcDetail = await _getLotTypeUdcDetail(
        systemConstant?.lotType,
      );

      final updatedLotList = <LotMaster>[];
      for (final lot in lotList) {
        final newStatus = await _calculateLotStatus(lot, lotTypeUdcDetail);
        final updatedLot = lot.copyWith(lotStatus: newStatus);
        updatedLotList.add(updatedLot);
      }
      emit(
        state.copyWith(
          status: LotMasterStatus.loaded,
          items: updatedLotList,
          filteredItems: updatedLotList,
          companyId: authBloc.state.companyId,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: LotMasterStatus.failure,
          message: 'Failed to load lots: $e',
        ),
      );
    }
  }

  Future<void> _onFilterLots(
    FilterLotMasters event,
    Emitter<LotMasterState> emit,
  ) async {
    try {
      final db = await databaseService.database;

      var whereClause = 'WHERE lm.company = ?';
      final whereArgs = <dynamic>[authBloc.state.companyId];

      if (event.itemId != null) {
        whereClause += ' AND lm.item_number = ?';
        whereArgs.add(event.itemId);
      }

      if (event.expStart != null && event.expEnd != null) {
        whereClause += ' AND lm.date_expiration BETWEEN ? AND ?';
        whereArgs.add(event.expStart!.toIso8601String());
        whereArgs.add(event.expEnd!.toIso8601String());
      }

      if (event.locationId != null) {
        whereClause += ' AND lm.location = ?';
        whereArgs.add(event.locationId);
      }

      if (event.statusId != null) {
        whereClause += ' AND lm.lot_status = ?';
        whereArgs.add(event.statusId);
      }

      final lots = await db.rawQuery('''
        SELECT lm.*,
               i.item_description as item_description,
               b.description as branch_name,
               loc.location_description,
               ls.detail_description as status_description
        FROM lot_master lm
        LEFT JOIN items_table i ON lm.item_number = i.id
        LEFT JOIN branch_table b ON lm.branch = b.id
        LEFT JOIN location_master loc ON lm.location = loc.id
        LEFT JOIN udc_details ls ON lm.lot_status = ls.id
        $whereClause
        ORDER BY i.item_description, lm.lot_number
      ''', whereArgs);

      final filteredList = lots.map((p) => LotMaster.fromMap(p)).toList();

      emit(
        state.copyWith(
          filteredItems: filteredList,
          filterItemId: event.itemId,
          filterExpStart: event.expStart,
          filterExpEnd: event.expEnd,
          filterLocationId: event.locationId,
          filterStatusId: event.statusId,
        ),
      );
    } catch (e) {
      emit(state.copyWith(message: 'Failed to filter lots: $e'));
    }
  }

  Future<void> _onResetFilter(
    ResetLotFilter event,
    Emitter<LotMasterState> emit,
  ) async {
    emit(
      state.copyWith(
        filteredItems: state.items,
        filterItemId: null,
        filterExpStart: null,
        filterExpEnd: null,
        filterLocationId: null,
        filterStatusId: null,
      ),
    );
  }

  Future<void> _onSearchLotMasters(
    SearchLotMasters event,
    Emitter<LotMasterState> emit,
  ) async {
    if (event.query.isEmpty) {
      emit(state.copyWith(filteredItems: state.items, searchQuery: ''));
    } else {
      final filtered = state.items.where((item) {
        return item.lotNumber?.toString().toLowerCase().contains(
                  event.query.toLowerCase(),
                ) ==
                true ||
            item.batchNumberSupplier?.toString().toLowerCase().contains(
                  event.query.toLowerCase(),
                ) ==
                true;
      }).toList();

      emit(state.copyWith(filteredItems: filtered, searchQuery: event.query));
    }
  }

  Future<void> _onSaveLot(
    SaveLotMaster event,
    Emitter<LotMasterState> emit,
  ) async {
    emit(state.copyWith(status: LotMasterStatus.creating));
    try {
      // Validate dates based on lot type
      final systemConstant = systemConstantBloc.state.selected1;
      // Get the actual lot type UDC detail to access detailCode
      final lotTypeUdc = await _getLotTypeUdcDetail(systemConstant?.lotType);

      if (!_validateLotDates(event.item, lotTypeUdc?.detailCode)) {
        emit(
          state.copyWith(
            status: LotMasterStatus.failure,
            message:
                'The Effective Date & Expiration Date not Correct! ${lotTypeUdc?.description1 ?? 'Unknown'}',
          ),
        );
        return;
      }

      // Calculate lot status
      final lotStatus = await _calculateLotStatus(event.item, lotTypeUdc);
      final itemWithStatus = event.item.copyWith(lotStatus: lotStatus);

      final db = await databaseService.database;
      final itemMap = _applySettings(itemWithStatus, false).toMap();
      itemMap.remove('id');

      if (itemWithStatus.lotNumber == null) {
        itemMap['lot_number'] = await _generateLotNumber();
      }

      await db.insert('lot_master', itemMap);

      // Update inventory quantities if lot management is enabled
      if (systemConstant?.applyLotMgmBoolean == true &&
          itemWithStatus.quantityAvailable != null) {
        await _updateItemLocationQuantity(
          event.item,
          event.transactionType!,
          event.transactionNumber,
          event.remark,
          itemWithStatus.quantityAvailable!,
        );
        emit(
          state.copyWith(
            status: LotMasterStatus.success,
            message: 'Lot created successfully',
          ),
        );
      } else {
        final oldLot = await _getLotMaster(event.item.id!);
        final oldQty = oldLot?.quantityAvailable ?? 0.0;
        final newQty = event.item.quantityAvailable!;
        await db.update(
          'lot_master',
          event.item.toMap(),
          where: 'id = ? AND company = ?',
          whereArgs: [event.item.id, authBloc.state.companyId],
        );

        // Update item location quantity if quantity changed and lot management is enabled
        if (systemConstant?.applyLotMgmBoolean == true && oldQty != newQty) {
          final qtyDiff = newQty - oldQty;
          await _updateItemLocationQuantity(
            event.item,
            event.transactionType!,
            event.transactionNumber,
            event.remark,
            qtyDiff,
          );
        }
        emit(
          state.copyWith(
            status: LotMasterStatus.success,
            message: 'Lot updated successfully',
          ),
        );
      }

      add(LoadLotMasters(authBloc.state.companyId!));
    } catch (e) {
      emit(
        state.copyWith(
          status: LotMasterStatus.failure,
          message: 'Failed to create lot: $e',
        ),
      );
    }
  }

  Future<UdcDetails?> _getLotTypeUdcDetail(int? lotType) async {
    if (lotType == null) return null;
    final udcDetails = await udcRepository.getUdcDetailById(lotType);
    return udcDetails;
  }

  Future<void> _onUpdateLot(
    UpdateLotMaster event,
    Emitter<LotMasterState> emit,
  ) async {
    emit(state.copyWith(status: LotMasterStatus.updating));
    try {
      final db = await databaseService.database;
      final companyId = authBloc.state.companyId;
      final systemConstant = systemConstantBloc.state.selected;
      final lotTypeUdcDetail = await _getLotTypeUdcDetail(
        systemConstant?.lotType,
      );

      if (companyId == null) {
        emit(
          state.copyWith(
            status: LotMasterStatus.failure,
            message: 'Company ID is null',
          ),
        );
        return;
      }

      // Get previous quantity for comparison
      final previousLot = await _getLotMaster(event.item.id!);

      final previousQty = previousLot?.quantityAvailable ?? 0.0;

      // Calculate lot status
      final lotStatus = await _calculateLotStatus(event.item, lotTypeUdcDetail);
      final itemWithStatus = event.item.copyWith(lotStatus: lotStatus);

      final itemMap = _applySettings(itemWithStatus, true).toMap();

      await db.update(
        'lot_master',
        itemMap,
        where: 'id = ? AND company = ?',
        whereArgs: [event.item.id, companyId],
      );

      // Update inventory if quantity changed and lot management is enabled
      if (systemConstant?.applyLotMgmBoolean == true &&
          event.item.quantityAvailable != previousQty) {
        final qtyDifference =
            (event.item.quantityAvailable ?? 0.0) - previousQty;
        await _updateItemLocationQuantity(
          event.item,
          event.transactionType!,
          event.transactionNumber,
          event.remark,
          qtyDifference,
        );
      }

      add(LoadLotMasters(companyId));
      emit(
        state.copyWith(
          status: LotMasterStatus.success,
          message: 'Lot updated successfully',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: LotMasterStatus.failure,
          message: 'Failed to update lot: $e',
        ),
      );
    }
  }

  bool _validateLotDates(LotMaster item, String? lotType) {
    if (lotType == null || lotType.toUpperCase() == 'X') {
      return item.dateExpiration != null;
    } else if (lotType.toUpperCase() == 'F') {
      return item.dateEffective != null;
    } else if (lotType.toUpperCase() == 'R') {
      return item.dateReceived != null;
    }
    return false;
  }

  Future<int?> _calculateLotStatus(
    LotMaster item,
    UdcDetails? lotTypeUdcDetail,
  ) async {
    final lotType = lotTypeUdcDetail?.detailCode.toUpperCase();

    if (item.branch == null || item.itemNumber == null) return null;

    DateTime? targetDate;

    if (lotType == 'X') {
      targetDate = item.dateExpiration;
    } else if (lotType == 'F') {
      targetDate = item.dateEffective;
    } else if (lotType == 'R') {
      targetDate = item.dateReceived;
    }

    if (targetDate == null) return item.lotStatus;

    final now = DateTime.now();
    final difference = targetDate.difference(now).inDays;

    if (lotType != 'R') {
      if (difference <= 0) {
        // Expired status
        return await getUdcDetailId('LS', 'E');
      } else {
        // Active status (if current status is expired, keep it expired)
        return (item.lotStatus == await getUdcDetailId('LS', 'E'))
            ? item.lotStatus
            : await getUdcDetailId('LS', 'A');
      }
    } else {
      // For received type, default to active
      return item.lotStatus ?? await getUdcDetailId('LS', 'A');
    }
  }

  // method to calculate status for multiple lots
  Future<void> _recalculateAllLotStatus(Emitter<LotMasterState> emit) async {
    try {
      final systemConstant = systemConstantBloc.state.selected;
      final lotTypeUdcDetail = await _getLotTypeUdcDetail(
        systemConstant?.lotType,
      );

      final updatedItems = <LotMaster>[];

      for (final lot in state.items) {
        final newStatus = await _calculateLotStatus(lot, lotTypeUdcDetail);
        final updatedLot = lot.copyWith(lotStatus: newStatus);
        updatedItems.add(updatedLot);
      }

      emit(state.copyWith(items: updatedItems, filteredItems: updatedItems));
    } catch (e) {
      print('Error recalculating all lot status: $e');
    }
  }

  Future<void> _onCalculateLotStatus(
    CalculateLotStatus event,
    Emitter<LotMasterState> emit,
  ) async {
    try {
      final lotStatus = await _calculateLotStatus(
        event.item,
        event.lotTypeUdcDetail,
      );
      final updatedItem = event.item.copyWith(lotStatus: lotStatus);

      // Update the selected item in state
      if (state.selected?.id == event.item.id) {
        emit(state.copyWith(selected: updatedItem));
      }
    } catch (e) {
      print('Error calculating lot status: $e');
    }
  }

  Future<void> _onClaculateMultipleLotStatus(
    ClaculateMultipleLotStatus event,
    Emitter<LotMasterState> emit,
  ) async {
    await _recalculateAllLotStatus(emit);
  }

  Future<void> _updateItemLocationQuantity(
    LotMaster item,
    String transactionType,
    int? transactionNumber,
    String? remark,
    double quantity,
  ) async {
    final db = await databaseService.database;

    // Calculate total quantity for this item-branch-location
    final lotQuantities = await db.rawQuery(
      '''
      SELECT SUM(quantity_available) as total_qty 
      FROM lot_master 
      WHERE company = ? AND item_number = ? AND branch = ? AND location = ?
    ''',
      [authBloc.state.companyId, item.itemNumber, item.branch, item.location],
    );

    final totalQty =
        (lotQuantities.first['total_qty'] as num?)?.toDouble() ?? 0.0;

    // Update item_locations table
    await db.update(
      'item_locations',
      {'quantity_on_hand': totalQty},
      where: 'company = ? AND item_number = ? AND branch = ? AND location = ?',
      whereArgs: [
        authBloc.state.companyId,
        item.itemNumber,
        item.branch,
        item.location,
      ],
    );

    // Update items_in_branch table
    final branchQuantities = await db.rawQuery(
      '''
      SELECT SUM(quantity_on_hand) as total_qty 
      FROM item_locations 
      WHERE company = ? AND item_number = ? AND branch = ?
    ''',
      [authBloc.state.companyId, item.itemNumber, item.branch],
    );

    final branchQty =
        (branchQuantities.first['total_qty'] as num?)?.toDouble() ?? 0.0;

    await db.update(
      'items_in_branch',
      {'quantity_available': branchQty},
      where: 'company = ? AND item_number = ? AND branch = ?',
      whereArgs: [authBloc.state.companyId, item.itemNumber, item.branch],
    );

    // TODO: Create item transaction record
    await _createItemTransaction(
      item,
      transactionType,
      transactionNumber,
      remark,
      quantity,
    );
  }

  Future<void> _createItemTransaction(
    LotMaster item,
    String transactionType,
    int? transactionNumber,
    String? remark,
    double quantity,
  ) async {
    final db = await databaseService.database;
    final itemTransactionMap = {
      'company': authBloc.state.companyId,
      'created_by': authBloc.state.userId,
      'date_created': DateTime.now().toIso8601String(),
      'quantity_transaction': quantity,
      'remark': remark,
      'item_number': item.itemNumber,
      'branch': item.branch,
      'location': item.location,
      'transaction_type': transactionType,
      'transaction_number': transactionNumber,
      'item_branch': item.branch,
      'lot_number': item.lotNumber,
      'lot_status': item.lotStatus,
      'supplier': item.batchNumberSupplier,
      'customer': '',
      'order_type': '',
      'unit_of_measure': _getItemBranchUoM(item.itemNumber!, item.branch!),
      'before_store_quantity_available': item.quantityAvailable,
      'unit_cost': item.unitPrice,
      'amount_cost': 0,
      'before_amount_cost': 0,
    };
    await db.insert('item_transactions', itemTransactionMap);
  }

  Future<String> _generateLotNumber() async {
    // Use the NextNumberBloc to generate formatted lot number
    return await nextNumberBloc.generateFormattedNumber('LM');
  }

  Future<int?> getUdcDetailId(String headerCode, String detailCode) async {
    final db = await databaseService.database;
    final result = await db.rawQuery(
      '''
    SELECT id FROM udc_details 
      WHERE record_header IN (SELECT id FROM udc_header WHERE header_code = ?)
      AND detail_code = ? AND company = ?
    ''',
      [headerCode, detailCode, authBloc.state.companyId],
    );

    return result.isNotEmpty ? result.first['id'] as int? : null;
  }

  LotMaster _applySettings(LotMaster item, bool isUpdate) {
    return item.copyWith(company: authBloc.state.companyId);
  }

  // Event handlers for state management
  Future<void> _onPrepareCreate(
    PrepareCreateLot event,
    Emitter<LotMasterState> emit,
  ) async {
    final createItems = <LotMaster>[];
    final selected = LotMaster(company: event.companyId);

    createItems.add(selected);

    emit(
      state.copyWith(
        createItems: createItems,
        selected: selected,
        selected2: LotMaster(company: authBloc.state.companyId),
      ),
    );
  }

  Future<void> _onPrepareEdit(
    PrepareEditLot event,
    Emitter<LotMasterState> emit,
  ) async {
    final selected = event.item;
    final editItems = [selected];
    emit(state.copyWith(editItems: editItems, selected: selected));
  }

  Future<void> _onAutoCreateLotForPO(
    AutoCreateLotForPO event,
    Emitter<LotMasterState> emit,
  ) async {
    try {
      final por = event.por;
      final systemConstant = systemConstantBloc.state.selected;
      final lotTypeUdcDetail = await _getLotTypeUdcDetail(
        systemConstant?.lotType,
      );

      if (!_validatePurchaseOrderDates(por, lotTypeUdcDetail?.detailCode)) {
        emit(
          state.copyWith(message: 'Date validation failed for purchase order'),
        );
        return;
      }

      // Check for existing lots with same criteria
      final lotNumber = await _generateLotNumber();

      // Calculate quantity with UoM conversion
      final uom = await _getItemBranchUoM(por.itemNumber!, por.branchRecieved!);
      final factor = await _getUoMConversionFactor(
        por.itemNumber!,
        por.unitOfMeasure!,
        uom,
      );
      final quantity = factor * (por.quantityRecieved! ?? 0.0);

      final newLot = LotMaster(
        lotNumber: int.parse(lotNumber),
        company: authBloc.state.companyId,
        branch: por.branchRecieved!,
        itemNumber: por.itemNumber!,
        location: por.location!,
        quantityAvailable: quantity,
        dateEffective: por.dateEffective!,
        dateExpiration: por.dateExpiration,
        dateReceived: por.dateReceived,
        batchNumberSupplier: por.batchNumberSupplier,
        unitPrice: await _getItemBranchUnitPrice(
          por.itemNumber!,
          por.branchRecieved!,
        ),
      );

      // Calculate and set lot status
      final lotStatus = await _calculateLotStatus(newLot, lotTypeUdcDetail);
      final lotWithStatus = newLot.copyWith(lotStatus: lotStatus);

      final db = await databaseService.database;
      final lotMap = _applySettings(lotWithStatus, false).toMap();
      final lotId = await db.insert('lot_master', lotMap);

      // Update inventory
      if (systemConstant?.applyLotMgmBoolean == true) {
        await _updateItemLocationQuantity(
          lotWithStatus.copyWith(id: lotId),
          'R', // Receipt transaction
          event.transactionNumber,
          'Purchase',
          quantity,
        );
      }

      add(LoadLotMasters(authBloc.state.companyId!));

      emit(
        state.copyWith(
          status: LotMasterStatus.success,
          message: 'Lot auto-created for purchase order',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: LotMasterStatus.failure,
          message: 'Failed to auto-create lot: $e',
        ),
      );
    }
  }

  bool _validatePurchaseOrderDates(
    PurchaseOrderReceiverModel por,
    String? lotType,
  ) {
    if (lotType == null || lotType.toUpperCase() == 'X') {
      return por.dateExpiration != null;
    } else if (lotType.toUpperCase() == 'F') {
      return por.dateEffective != null;
    } else if (lotType.toUpperCase() == 'R') {
      return por.dateReceived != null;
    }
    return false;
  }

  Future<int?> _getItemBranchUoM(int itemNumber, int branch) async {
    final db = await databaseService.database;
    final result = await db.rawQuery(
      '''
      SELECT unit_of_measure FROM items_in_branch 
      WHERE company = ? AND item_number = ? AND branch = ?
    ''',
      [authBloc.state.companyId, itemNumber, branch],
    );

    return result.isNotEmpty ? result.first['unit_of_measure'] as int? : null;
  }

  Future<double> _getUoMConversionFactor(
    int itemNumber,
    int fromUom,
    int? toUom,
  ) async {
    if (fromUom == toUom) return 1.0;

    final db = await databaseService.database;
    final result = await db.rawQuery(
      '''
      SELECT conversion_factor FROM item_uom_conversions 
      WHERE company = ? AND item_number = ? AND from_uom = ? AND to_uom = ?
    ''',
      [authBloc.state.companyId, itemNumber, fromUom, toUom],
    );

    return result.isNotEmpty
        ? (result.first['conversion_factor'] as double?) ?? 1.0
        : 1.0;
  }

  Future<double> _getItemBranchUnitPrice(int itemNumber, int branch) async {
    final db = await databaseService.database;
    final result = await db.rawQuery(
      '''
      SELECT unit_price FROM items_in_branch 
      WHERE company = ? AND item_number = ? AND branch = ?
    ''',
      [authBloc.state.companyId, itemNumber, branch],
    );

    return result.isNotEmpty
        ? (result.first['unit_price'] as double?) ?? 0.0
        : 0.0;
  }

  Future<LotMaster?> _getLotMaster(int id) async {
    final db = await databaseService.database;
    final result = await db.query(
      'lot_master',
      where: 'id = ? AND company = ?',
      whereArgs: [id, authBloc.state.companyId],
    );

    return result.isNotEmpty ? LotMaster.fromMap(result.first) : null;
  }

  Future<void> _onDeleteLot(
    DeleteLotMaster event,
    Emitter<LotMasterState> emit,
  ) async {
    emit(state.copyWith(status: LotMasterStatus.deleting));
    try {
      final db = await databaseService.database;

      await db.delete(
        'lot_master',
        where: 'id = ? AND company = ?',
        whereArgs: [event.item.id, authBloc.state.companyId],
      );

      add(LoadLotMasters(authBloc.state.companyId!));
      emit(
        state.copyWith(
          status: LotMasterStatus.success,
          message: 'Lot deleted successfully',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: LotMasterStatus.failure,
          message: 'Failed to delete lot: $e',
        ),
      );
    }
  }

  Future<void> _onDeleteMultipleLotMasters(
    DeleteMultipleLotMasters event,
    Emitter<LotMasterState> emit,
  ) async {
    emit(state.copyWith(status: LotMasterStatus.deleting));
    try {
      final db = await databaseService.database;
      final companyId = authBloc.state.companyId;
      final batch = db.batch();

      for (final item in event.items) {
        batch.delete(
          'lot_master',
          where: 'id = ? AND company = ?',
          whereArgs: [item.id, companyId],
        );
      }

      await batch.commit();
      add(LoadLotMasters(companyId!));
      emit(
        state.copyWith(
          status: LotMasterStatus.success,
          message: '${event.items.length} lots deleted successfully',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: LotMasterStatus.failure,
          message: 'Failed to delete lots: $e',
        ),
      );
    }
  }

  // Simple state update handlers
  Future<void> _onSelecteLot(
    SelecteLot event,
    Emitter<LotMasterState> emit,
  ) async {
    final selectedItems = List<LotMaster>.from(state.selectedItems);
    if (event.isSelecting) {
      selectedItems.add(event.item!);
    } else {
      selectedItems.removeWhere((item) => event.item!.id == item.id);
    }
    emit(state.copyWith(selectedItems: selectedItems));
  }

  Future<void> _onSelectMultiSelectionLots(
    SelectMultiSelectionLots event,
    Emitter<LotMasterState> emit,
  ) async {
    if (state.selectedItems.length == event.items.length) {
      // If all are selected, clear selection
      emit(state.copyWith(selectedItems: []));
    } else {
      // Select all
      emit(state.copyWith(selectedItems: List.from(event.items)));
    }
  }

  Future<void> _onClearSelection(
    ClearSelection event,
    Emitter<LotMasterState> emit,
  ) async {
    emit(state.copyWith(selectedItems: []));
  }
}
