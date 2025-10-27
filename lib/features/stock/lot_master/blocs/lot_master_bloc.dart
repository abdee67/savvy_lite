// features/stock/lot_master/blocs/lot_master_bloc.dart
import 'dart:async';
import 'dart:developer' as developer;
import 'package:bloc/bloc.dart';
import 'package:savvy_stock/core/blocs/system_constant/system_constant_bloc.dart';
import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/next_number/bloc/next_number_bloc.dart';
import 'package:savvy_stock/features/purchase/supplier/models/purchase_order_receiver_model.dart';
import 'package:savvy_stock/features/stock/lot_coloring/bloc/lot_coloring_bloc.dart';
import 'package:savvy_stock/features/stock/lot_coloring/model/lot_coloring_model.dart';
import 'package:savvy_stock/features/stock/lot_master/blocs/lot_master_event.dart';
import 'package:savvy_stock/features/stock/lot_master/blocs/lot_master_state.dart';
import 'package:savvy_stock/features/stock/lot_master/models/lot_master_model.dart';
import 'package:savvy_stock/features/udc_detail/models/udc_details.dart';

class LotMasterBloc extends Bloc<LotMasterEvent, LotMasterState> {
  final LocalDatabaseService databaseService;
  final AuthBloc authBloc;
  final SystemConstantBloc systemConstantBloc;
  final NextNumberBloc nextNumberBloc;
  final LotExpirationColorsBloc lotExpirationColorsBloc;
  StreamSubscription? _authSubscription;
  StreamSubscription? _systemConstantSubscription;

  LotMasterBloc({
    required this.databaseService,
    required this.authBloc,
    required this.systemConstantBloc,
    required this.nextNumberBloc,
    required this.lotExpirationColorsBloc,
  }) : super(const LotMasterState()) {
    _authSubscription = authBloc.stream.listen((authState) {
      if (authState.isAuthenticated && authState.companyId != null) {
        add(LoadLotMasters(authState.companyId!));
      }
    });

    // Recompute lot colors when system constants change (e.g., lot_type becomes available)
    _systemConstantSubscription = systemConstantBloc.stream.listen((scState) {
      add(CalculateLotColors());
    });

    on<LoadLotMasters>(_onLoadLots);
    on<FilterLotMasters>(_onFilterLots);
    on<ResetLotFilter>(_onResetFilter);
    on<SearchLotMasters>(_onSearchLotMasters);
    on<SaveLotMaster>(_onSaveLot);
    on<UpdateLotMaster>(_onUpdateLot);
    on<DeleteLotMaster>(_onDeleteLot);
    on<DeleteMultipleLotMasters>(_onDeleteMultipleLotMasters);
    on<RegenerateLotNumber>(_onRegenerateLotNumber);
    on<PrepareCreateLot>(_onPrepareCreate);
    on<PrepareEditLot>(_onPrepareEdit);
    on<SelecteLot>(_onSelecteLot);
    on<SelectMultiSelectionLots>(_onSelectMultiSelectionLots);
    on<ClearSelection>(_onClearSelection);
    on<AutoCreateLotForPO>(_onAutoCreateLotForPO);
    on<CalculateLotStatus>(_onCalculateLotStatus);
    on<ClaculateMultipleLotStatus>(_onClaculateMultipleLotStatus);
    on<CalculateLotColors>(_onCalculateLotColors);
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    _systemConstantSubscription?.cancel();
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
               loc.location_description,
               ud.detail_code as status_code,
               ud.description_1 as status_description
        FROM lot_master lm
        LEFT JOIN items_table it ON lm.item_number = it.id
        LEFT JOIN branch_table b ON lm.branch = b.id
        LEFT JOIN location_master loc ON lm.location = loc.id
        LEFT JOIN udc_details ud ON lm.lot_status = ud.id
        WHERE lm.company = ?
        ORDER BY it.item_description
      ''',
        [event.companyId],
      );

      final lotList = lots.map((p) => LotMaster.fromMap(p)).toList();

      // Calculate colors for all lots dynamically
      final lotsWithColors = await _calculateColorsForLots(lotList);

      emit(
        state.copyWith(
          status: LotMasterStatus.loaded,
          items: lotsWithColors,
          filteredItems: lotsWithColors,
          companyId: authBloc.state.companyId,
        ),
      );

      // Debug system constants
      await _debugSystemConstants();
    } catch (e) {
      emit(
        state.copyWith(
          status: LotMasterStatus.failure,
          message: 'Failed to load lots: $e',
        ),
      );
    }
  }

  Future<void> _debugSystemConstants() async {
    try {
      final systemConstant = systemConstantBloc.state.selected;
      print('''
🔧 SYSTEM CONSTANT DEBUG:
  Company ID: ${authBloc.state.companyId}
  System Constant ID: ${systemConstant?.id}
  Lot Type ID: ${systemConstant?.lotType}
  Apply Lot Mgmt: ${systemConstant?.applyLotMgm}
  Is Synced: ${systemConstant?.isSynced}
''');

      if (systemConstant?.lotType != null) {
        final lotTypeUdc = await _getLotTypeUdcDetail(systemConstant?.lotType);
        print(
          '  Lot Type UDC: ${lotTypeUdc?.detailCode} - ${lotTypeUdc?.description1}',
        );
      } else {
        print('  ❌ Lot Type is NULL in system constant');
      }
    } catch (e) {
      print('❌ Error debugging system constants: $e');
    }
  }

  // Call this in your _onLoadLots method
  // await _debugSystemConstants();

  Future<List<LotMaster>> _calculateColorsForLots(List<LotMaster> lots) async {
    final updatedLots = <LotMaster>[];

    final systemConstant = systemConstantBloc.state.selected;
    final applyLot = systemConstant?.applyLotMgmBoolean == true;

    for (final lot in lots) {
      final updatedLot = lot.copyWith();
      if (applyLot) {
        final colorType = await _getLotColorType(lot);
        // Store color type in memory only (not in database)
        updatedLot.tempColorType = colorType;
      } else {
        // When lot management is disabled, do not calculate colors
        updatedLot.tempColorType = null;
      }
      updatedLots.add(updatedLot);
    }

    return updatedLots;
  }

  Future<LotExpirationColor?> _getLotColorType(LotMaster lot) async {
    try {
      final color = await lotExpirationColorsBloc.getLotColorType(
        lot.branch,
        lot.itemNumber,
        lot.dateExpiration,
        lot.dateEffective,
        lot.dateReceived,
      );
      return color;
    } catch (e) {
      print('Error calculating lot color: $e');
      return null;
    }
  }

  Future<void> _onCalculateLotColors(
    CalculateLotColors event,
    Emitter<LotMasterState> emit,
  ) async {
    try {
      final updatedItems = await _calculateColorsForLots(state.items);
      final updatedFilteredItems = await _calculateColorsForLots(
        state.filteredItems,
      );

      emit(
        state.copyWith(
          items: updatedItems,
          filteredItems: updatedFilteredItems,
        ),
      );
    } catch (e) {
      print('Error calculating lot colors: $e');
    }
  }

  // Add temp color calculation to existing methods
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

      // Also recalculate color when status changes
      final colorType = await _getLotColorType(updatedItem);
      updatedItem.tempColorType = colorType;

      // Update the selected item in state
      if (state.selected?.id == event.item.id) {
        emit(state.copyWith(selected: updatedItem));
      }

      // Update in items list
      final updatedItems = state.items.map((item) {
        if (item.id == event.item.id) {
          return updatedItem;
        }
        return item;
      }).toList();

      final updatedFilteredItems = state.filteredItems.map((item) {
        if (item.id == event.item.id) {
          return updatedItem;
        }
        return item;
      }).toList();

      emit(
        state.copyWith(
          items: updatedItems,
          filteredItems: updatedFilteredItems,
        ),
      );
    } catch (e) {
      print('Error calculating lot status: $e');
    }
  }

  // ... REST OF YOUR EXISTING LOT MASTER BLOC METHODS REMAIN THE SAME
  // _onFilterLots, _onResetFilter, _onSearchLotMasters, _onSaveLot, etc.
  // Only adding the color-related methods above

  // Helper method to get color for UI
  Future<LotExpirationColor?> getLotColorTypeForUI(LotMaster lot) async {
    // If we already calculated it, use the temp value
    if (lot.tempColorType != null) {
      return lot.tempColorType;
    }
    // Otherwise calculate it fresh
    return await _getLotColorType(lot);
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
               ls.detail_code as status_code,
               ls.description_1 as status_description
        FROM lot_master lm
        LEFT JOIN items_table i ON lm.item_number = i.id
        LEFT JOIN branch_table b ON lm.branch = b.id
        LEFT JOIN location_master loc ON lm.location = loc.id
        LEFT JOIN udc_details ls ON lm.lot_status = ls.id
        $whereClause
        ORDER BY i.item_description, lm.lot_number
      ''', whereArgs);

      final filteredList = lots.map((p) => LotMaster.fromMap(p)).toList();
      final lotsWithColors = await _calculateColorsForLots(filteredList);

      emit(
        state.copyWith(
          filteredItems: lotsWithColors,
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
      // Validate dates and calculate status only when lot management is enabled
      final systemConstant = systemConstantBloc.state.selected1;
      final applyLot = systemConstant?.applyLotMgmBoolean == true;

      // Get the actual lot type UDC detail to access detailCode (may be null)
      final lotTypeUdc = await _getLotTypeUdcDetail(systemConstant?.lotType);

      if (applyLot) {
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
      }

      // Calculate lot status only when Apply Lot Management is enabled
      final lotStatus = applyLot
          ? await _calculateLotStatus(event.item, lotTypeUdc)
          : null;
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
          event.transactionType ?? 'C',
          event.transactionNumber,
          event.remark,
          itemWithStatus.quantityAvailable!,
        );
      }
      print(
        'item transaction and other tables are updated: ${itemWithStatus.quantityAvailable}',
      );

      // For create flow, we've already inserted. If inventory update wasn't applicable,
      // we still return success without attempting an update branch that expects an id.
      emit(
        state.copyWith(
          status: LotMasterStatus.success,
          message: 'Lot created successfully',
        ),
      );

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
    final udcDetails = await getUdcDetailById(lotType);
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

      // Calculate lot status only when lot management is enabled
      final applyLot = systemConstant?.applyLotMgmBoolean == true;
      final lotStatus = applyLot
          ? await _calculateLotStatus(event.item, lotTypeUdcDetail)
          : null;
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
    // FIXED: Use correct lot type codes
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

      // After status updates, recompute colors so UI has fresh tempColorType
      final itemsWithColors = await _calculateColorsForLots(updatedItems);

      emit(
        state.copyWith(items: itemsWithColors, filteredItems: itemsWithColors),
      );
    } catch (e) {
      print('Error recalculating all lot status: $e');
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

    // Update item_location table (correct table name)
    await db.update(
      'item_location',
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
      FROM item_location 
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
    final uom = await _getItemBranchUoM(item.itemNumber!, item.branch!);
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
      'unit_of_measure': uom,
      'before_store_quantity_available': item.quantityAvailable,
      'unit_cost': item.unitPrice,
      'amount_cost': 0,
      'before_amount_cost': 0,
    };
    await db.insert('item_transactions', itemTransactionMap);
  }

  Future<int> _generateLotNumber() async {
    // Use the NextNumberBloc to generate formatted lot number
    return await nextNumberBloc.generateFormattedNumber('LM');
  }

  Future<int?> getUdcDetailId(String headerCode, String detailCode) async {
    try {
      final db = await databaseService.database;
      final result = await db.rawQuery(
        '''
      SELECT ud.id FROM udc_details ud
      JOIN udc_header uh ON ud.record_header = uh.id
      WHERE uh.header_code = ? AND ud.detail_code = ?
      ''',
        [headerCode, detailCode],
      );

      if (result.isNotEmpty) {
        return result.first['id'] as int?;
      }

      print('❌ No UDC found for header: $headerCode, detail: $detailCode');
      return null;
    } catch (e) {
      print('❌ Error getting UDC detail ID: $e');
      return null;
    }
  }

  Future<UdcDetails?> getUdcDetailById(int? id) async {
    if (id == null) return null;
    try {
      final db = await databaseService.database;
      final result = await db.rawQuery(
        '''
      SELECT * FROM udc_details 
      WHERE id = ?
    ''',
        [id],
      );

      return result.isNotEmpty ? UdcDetails.fromJson(result.first) : null;
    } catch (e) {
      developer.log('Error getting local UDC detail: $e');
      return null;
    }
  }

  LotMaster _applySettings(LotMaster item, bool isUpdate) {
    return item.copyWith(company: authBloc.state.companyId);
  }

  Future<void> _onRegenerateLotNumber(
    RegenerateLotNumber event,
    Emitter<LotMasterState> emit,
  ) async {
    try {
      final lotNumber = await _generateLotNumber();
      emit(
        state.copyWith(
          selected: state.selected?.copyWith(lotNumber: lotNumber),
        ),
      );
    } catch (e) {
      emit(state.copyWith(message: 'Error regenerating lot number: $e'));
    }
  }

  // Event handlers for state management
  Future<void> _onPrepareCreate(
    PrepareCreateLot event,
    Emitter<LotMasterState> emit,
  ) async {
    try {
      //generate lot number automatically
      final lotNumber = await _generateLotNumber();

      final createItems = <LotMaster>[];
      final selected = LotMaster(
        company: event.companyId,
        lotNumber: lotNumber,
      );

      createItems.add(selected);

      emit(
        state.copyWith(
          createItems: createItems,
          selected: selected,
          selected2: LotMaster(company: authBloc.state.companyId),
          message: 'Lot number generated: $lotNumber',
        ),
      );

      print('🔄 Prepared create with lot number: $lotNumber');
    } catch (e) {
      emit(state.copyWith(message: 'Error preparing create: $e'));
    }
  }

  Future<void> _onPrepareEdit(
    PrepareEditLot event,
    Emitter<LotMasterState> emit,
  ) async {
    final selected = event.item;
    final editItems = [selected];
    emit(
      state.copyWith(
        editItems: editItems,
        selected: selected,
        message: 'Lot number generated: ${selected.lotNumber}',
      ),
    );
    print('🔄 Prepared edit with lot number: ${selected.lotNumber}');
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
        lotNumber: lotNumber,
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
    // FIXED: Use correct lot type codes
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
