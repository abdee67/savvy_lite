// features/stock/lot_master/blocs/lot_master_bloc.dart
import 'dart:async';
import 'dart:developer' as developer;
import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/models/purchase_order_receiver_model.dart';
import 'package:savvy_stock/features/stock/lot_master/models/expiration_report_filters.dart';
import 'package:savvy_stock/features/system_constant/bloc/system_constant_bloc.dart';
import 'package:savvy_stock/core/repositories/udc_repository.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/next_number/bloc/next_number_bloc.dart';
import 'package:savvy_stock/features/stock/lot_coloring/bloc/lot_coloring_bloc.dart';
import 'package:savvy_stock/features/stock/lot_coloring/model/lot_coloring_model.dart';
import 'package:savvy_stock/features/stock/lot_master/blocs/lot_master_event.dart';
import 'package:savvy_stock/features/stock/lot_master/blocs/lot_master_state.dart';
import 'package:savvy_stock/features/stock/lot_master/models/lot_master_model.dart';
import 'package:savvy_stock/features/stock/lot_master/repo/lot_master_repo.dart';
import 'package:savvy_stock/features/udc_detail/models/udc_details.dart';

class LotMasterBloc extends Bloc<LotMasterEvent, LotMasterState> {
  final LotMasterRepository repository;
  final AuthBloc authBloc;
  final SystemConstantBloc systemConstantBloc;
  final NextNumberBloc nextNumberBloc;
  final LotExpirationColorsBloc lotExpirationColorsBloc;
  final UdcRepository udcRepository;
  final int defaultPageSize = 20;

  StreamSubscription? _authSubscription;
  StreamSubscription? _systemConstantSubscription;

  LotMasterBloc({
    required this.repository,
    required this.authBloc,
    required this.systemConstantBloc,
    required this.nextNumberBloc,
    required this.lotExpirationColorsBloc,
    required this.udcRepository,
  }) : super(const LotMasterState()) {
    _authSubscription = authBloc.stream.listen((authState) {
      if (authState.isAuthenticated && authState.companyId != null) {
        add(LoadLotMasters(authState.companyId!));
      }
    });

    _systemConstantSubscription = systemConstantBloc.stream.listen((_) {
      add(CalculateLotColors());
    });

    // Event handlers
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
    on<SelecteLot>(_onSelectLot);
    on<SelectMultiSelectionLots>(_onSelectMultiSelectionLots);
    on<ClearSelection>(_onClearSelection);
    on<AutoCreateLotForPO>(_onAutoCreateLotForPO);
    on<CalculateLotStatus>(_onCalculateLotStatus);
    on<CalculateMultipleLotStatus>(_onCalculateMultipleLotStatus);
    on<CalculateLotColors>(_onCalculateLotColors);
    on<ValidateLotDates>(_onValidateLotDates);
    on<CheckLotNumberDuplication>(_onCheckLotNumberDuplication);
    on<GetExpiringLots>(_onGetExpiringLots);
    on<GetLotQuantitySummary>(_onGetLotQuantitySummary);
    on<LoadExpirationReport>(_onLoadExpirationReport);
    on<LoadMoreExpirationReport>(_onLoadMoreExpirationReport);
    on<UpdateExpirationReportFilters>(_onUpdateExpirationReportFilters);
    on<ClearExpirationReportFilters>(_onClearFilters);
    on<ExportExpirationReportToExcel>(_onExportToExcel);
    on<ExportExpirationReportToPDF>(_onExportToPDF);
    on<LoadUpcomingExpiryReport>(_onLoadUpcomingExpiryReport);
    on<LoadMoreUpcomingExpiryReport>(_onLoadMoreUpcomingExpiryReport);
    on<UpdateUpcomingExpiryReportFilters>(_onUpdateUpcomingExpiryReportFilters);
    on<ClearUpcomingExpiryReportFilters>(_onClearUpcomingExpiryReportFilters);
    // on<ExportUpcomingExpiryReportToExcel>(_onExportUpcomingExpiryToExcel);
    //  on<ExportUpcomingExpiryReportToPDF>(_onExportUpcomingExpiryToPDF);
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
      final items = await repository.getLotMasters(event.companyId);
      final itemsWithColors = await _calculateColorsForLots(items);

      emit(
        state.copyWith(
          status: LotMasterStatus.loaded,
          items: itemsWithColors,
          filteredItems: itemsWithColors,
          companyId: event.companyId,
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
      final filteredItems = await repository.getFilteredLotMasters(
        companyId: authBloc.state.companyId!,
        itemId: event.itemId,
        expStart: event.expStart,
        expEnd: event.expEnd,
        locationId: event.locationId,
        statusId: event.statusId,
      );

      final filteredWithColors = await _calculateColorsForLots(filteredItems);

      emit(
        state.copyWith(
          filteredItems: filteredWithColors,
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
      try {
        final searchedItems = await repository.searchLotMasters(
          companyId: authBloc.state.companyId!,
          query: event.query,
        );

        final searchedWithColors = await _calculateColorsForLots(searchedItems);

        emit(
          state.copyWith(
            filteredItems: searchedWithColors,
            searchQuery: event.query,
          ),
        );
      } catch (e) {
        // Fallback to local search if repository search fails
        final filtered = state.items.where((item) {
          return item.lotNumber?.toString().toLowerCase().contains(
                    event.query.toLowerCase(),
                  ) ==
                  true ||
              item.batchNumberSupplier?.toString().toLowerCase().contains(
                    event.query.toLowerCase(),
                  ) ==
                  true ||
              (item.statusDescription?.toLowerCase().contains(
                    event.query.toLowerCase(),
                  ) ??
                  false);
        }).toList();

        emit(state.copyWith(filteredItems: filtered, searchQuery: event.query));
      }
    }
  }

  Future<void> _onSaveLot(
    SaveLotMaster event,
    Emitter<LotMasterState> emit,
  ) async {
    emit(state.copyWith(status: LotMasterStatus.creating));
    try {
      final systemConstant = systemConstantBloc.state.selected;
      final applyLot = systemConstant?.applyLotMgmBoolean == true;
      final lotTypeUdc = await _getLotTypeUdcDetail(systemConstant?.lotType);

      // Validate dates if lot management is enabled
      if (applyLot && !_validateLotDates(event.item, lotTypeUdc?.detailCode)) {
        emit(
          state.copyWith(
            status: LotMasterStatus.dateValidationFailed,
            message:
                'The Effective Date & Expiration Date not Correct! ${lotTypeUdc?.description1 ?? 'Unknown'}',
            datesValid: false,
          ),
        );
        return;
      }

      // Check for lot number duplication
      final hasDuplication = await repository.checkLotNumberDuplication(
        companyId: authBloc.state.companyId!,
        lotNumber: event.item.lotNumber!,
      );

      if (hasDuplication) {
        emit(
          state.copyWith(
            status: LotMasterStatus.duplicationFound,
            message: 'Lot number already exists',
            hasDuplication: true,
          ),
        );
        return;
      }

      // Calculate lot status
      final lotStatus = applyLot
          ? await _calculateLotStatus(event.item, lotTypeUdc)
          : null;
      final itemWithStatus = event.item.copyWith(
        lotStatus: lotStatus,
        company: authBloc.state.companyId,
      );

      // Generate lot number if not provided
      if (itemWithStatus.lotNumber == null) {
        final lotNumber = await _generateLotNumber();
        itemWithStatus.lotNumber = lotNumber;
      }

      final lotId = await repository.createLotMaster(itemWithStatus);

      // Update inventory if lot management is enabled
      if (applyLot && itemWithStatus.quantityAvailable != null) {
        await _updateInventoryQuantities(
          itemWithStatus.copyWith(id: lotId),
          event.transactionType ?? 'C',
          event.transactionNumber,
          event.remark,
          itemWithStatus.quantityAvailable!,
        );
      }

      add(LoadLotMasters(authBloc.state.companyId!));

      emit(
        state.copyWith(
          status: LotMasterStatus.success,
          message: 'Lot created successfully',
          datesValid: true,
          hasDuplication: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: LotMasterStatus.failure,
          message: 'Failed to create lot: $e',
        ),
      );
    }
  }

  Future<void> _onUpdateLot(
    UpdateLotMaster event,
    Emitter<LotMasterState> emit,
  ) async {
    emit(state.copyWith(status: LotMasterStatus.updating));
    try {
      final systemConstant = systemConstantBloc.state.selected;
      final applyLot = systemConstant?.applyLotMgmBoolean == true;
      final lotTypeUdc = await _getLotTypeUdcDetail(systemConstant?.lotType);

      // Get previous quantity for comparison
      final previousLot = await repository.getLotMasterById(
        event.item.id!,
        authBloc.state.companyId!,
      );
      final previousQty = previousLot?.quantityAvailable ?? 0.0;

      // Calculate lot status
      final lotStatus = applyLot
          ? await _calculateLotStatus(event.item, lotTypeUdc)
          : null;
      final itemWithStatus = event.item.copyWith(lotStatus: lotStatus);

      await repository.updateLotMaster(itemWithStatus);

      // Update inventory if quantity changed and lot management is enabled
      if (applyLot && event.item.quantityAvailable != previousQty) {
        final qtyDifference =
            (event.item.quantityAvailable ?? 0.0) - previousQty;
        await _updateInventoryQuantities(
          event.item,
          event.transactionType!,
          event.transactionNumber,
          event.remark,
          qtyDifference,
        );
      }

      add(LoadLotMasters(authBloc.state.companyId!));

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

  Future<void> _onDeleteLot(
    DeleteLotMaster event,
    Emitter<LotMasterState> emit,
  ) async {
    emit(state.copyWith(status: LotMasterStatus.deleting));
    try {
      await repository.deleteLotMaster(
        event.item.id!,
        authBloc.state.companyId!,
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
      final lotIds = event.items.map((lot) => lot.id!).toList();
      await repository.deleteMultipleLotMasters(
        lotIds,
        authBloc.state.companyId!,
      );

      add(LoadLotMasters(authBloc.state.companyId!));

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

  Future<void> _onRegenerateLotNumber(
    RegenerateLotNumber event,
    Emitter<LotMasterState> emit,
  ) async {
    try {
      final lotNumber = await _generateLotNumber();
      final updatedSelected = state.selected?.copyWith(lotNumber: lotNumber);

      emit(
        state.copyWith(
          selected: updatedSelected,
          message: 'New lot number generated: $lotNumber',
        ),
      );
    } catch (e) {
      emit(state.copyWith(message: 'Error regenerating lot number: $e'));
    }
  }

  Future<void> _onPrepareCreate(
    PrepareCreateLot event,
    Emitter<LotMasterState> emit,
  ) async {
    try {
      final lotNumber = await _generateLotNumber();
      final newLot = LotMaster(company: event.companyId, lotNumber: lotNumber);

      emit(
        state.copyWith(
          createItems: [newLot],
          selected: newLot,
          selected2: LotMaster(company: event.companyId),
          message: 'Lot creation prepared with number: $lotNumber',
        ),
      );
    } catch (e) {
      emit(state.copyWith(message: 'Error preparing create: $e'));
    }
  }

  Future<void> _onPrepareEdit(
    PrepareEditLot event,
    Emitter<LotMasterState> emit,
  ) async {
    emit(
      state.copyWith(
        editItems: [event.item],
        selected: event.item,
        message: 'Editing lot: ${event.item.lotNumber}',
      ),
    );
  }

  Future<void> _onSelectLot(
    SelecteLot event,
    Emitter<LotMasterState> emit,
  ) async {
    final selectedItems = List<LotMaster>.from(state.selectedItems);
    if (event.isSelecting && event.item != null) {
      selectedItems.add(event.item!);
    } else if (event.item != null) {
      selectedItems.removeWhere((item) => event.item!.id == item.id);
    }

    emit(state.copyWith(selectedItems: selectedItems));
  }

  Future<void> _onSelectMultiSelectionLots(
    SelectMultiSelectionLots event,
    Emitter<LotMasterState> emit,
  ) async {
    if (state.selectedItems.length == event.items.length) {
      emit(state.copyWith(selectedItems: []));
    } else {
      emit(state.copyWith(selectedItems: List.from(event.items)));
    }
  }

  Future<void> _onClearSelection(
    ClearSelection event,
    Emitter<LotMasterState> emit,
  ) async {
    emit(state.copyWith(selectedItems: []));
  }

  Future<void> _onAutoCreateLotForPO(
    AutoCreateLotForPO event,
    Emitter<LotMasterState> emit,
  ) async {
    emit(state.copyWith(status: LotMasterStatus.creating));
    try {
      final por = event.por;
      final systemConstant = systemConstantBloc.state.selected;
      final lotTypeUdc = await _getLotTypeUdcDetail(systemConstant?.lotType);

      if (!_validatePurchaseOrderDates(por, lotTypeUdc?.detailCode)) {
        emit(
          state.copyWith(
            status: LotMasterStatus.dateValidationFailed,
            message: 'Date validation failed for purchase order',
          ),
        );
        return;
      }

      final lotNumber = await _generateLotNumber();

      // Calculate quantity with UoM conversion
      final uom = await repository.getItemBranchUoM(
        por.itemNumber!,
        por.branchRecieved!,
        authBloc.state.companyId!,
      );
      final factor = await repository.getUoMConversionFactor(
        companyId: authBloc.state.companyId!,
        itemNumber: por.itemNumber!,
        fromUom: por.unitOfMeasure!,
        toUom: uom ?? por.unitOfMeasure!,
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
        unitPrice: await repository.getItemBranchUnitPrice(
          por.itemNumber!,
          por.branchRecieved!,
          authBloc.state.companyId!,
        ),
      );

      // Calculate and set lot status
      final lotStatus = await _calculateLotStatus(newLot, lotTypeUdc);
      final lotWithStatus = newLot.copyWith(lotStatus: lotStatus);

      final lotId = await repository.createLotMaster(lotWithStatus);

      // Update inventory
      if (systemConstant?.applyLotMgmBoolean == true) {
        await _updateInventoryQuantities(
          lotWithStatus.copyWith(id: lotId),
          'R', // Receipt transaction
          event.transactionNumber,
          'Purchase Order Receipt',
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

      // Update color when status changes
      final colorType = await _getLotColorType(updatedItem);
      updatedItem.tempColorType = colorType;

      // Update state
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
          selected: state.selected?.id == event.item.id
              ? updatedItem
              : state.selected,
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        developer.log('Error calculating lot status: $e');
      }
    }
  }

  Future<void> _onCalculateMultipleLotStatus(
    CalculateMultipleLotStatus event,
    Emitter<LotMasterState> emit,
  ) async {
    try {
      final systemConstant = systemConstantBloc.state.selected;
      final lotTypeUdc = await _getLotTypeUdcDetail(systemConstant?.lotType);

      final updatedItems = <LotMaster>[];
      for (final lot in state.items) {
        final newStatus = await _calculateLotStatus(lot, lotTypeUdc);
        final updatedLot = lot.copyWith(lotStatus: newStatus);
        updatedItems.add(updatedLot);
      }

      final itemsWithColors = await _calculateColorsForLots(updatedItems);
      emit(
        state.copyWith(items: itemsWithColors, filteredItems: itemsWithColors),
      );
    } catch (e) {
      if (kDebugMode) {
        developer.log('Error recalculating all lot status: $e');
      }
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
      if (kDebugMode) {
        developer.log('Error calculating lot colors: $e');
      }
    }
  }

  Future<void> _onValidateLotDates(
    ValidateLotDates event,
    Emitter<LotMasterState> emit,
  ) async {
    final isValid = _validateLotDates(event.item, event.lotType);
    emit(state.copyWith(datesValid: isValid));
  }

  Future<void> _onCheckLotNumberDuplication(
    CheckLotNumberDuplication event,
    Emitter<LotMasterState> emit,
  ) async {
    final hasDuplication = await repository.checkLotNumberDuplication(
      companyId: authBloc.state.companyId!,
      lotNumber: event.lotNumber,
      excludeId: event.excludeId,
    );
    emit(state.copyWith(hasDuplication: hasDuplication));
  }

  Future<void> _onGetExpiringLots(
    GetExpiringLots event,
    Emitter<LotMasterState> emit,
  ) async {
    try {
      final expiringLots = await repository.getExpiringLotMasters(
        companyId: authBloc.state.companyId!,
        daysThreshold: event.daysThreshold,
      );

      final expiringWithColors = await _calculateColorsForLots(expiringLots);
      emit(state.copyWith(expiringLots: expiringWithColors));
    } catch (e) {
      if (kDebugMode) {
        developer.log('Error getting expiring lots: $e');
      }
    }
  }

  Future<void> _onGetLotQuantitySummary(
    GetLotQuantitySummary event,
    Emitter<LotMasterState> emit,
  ) async {
    try {
      final quantitySummary = await repository.getLotQuantitySummaryByItem(
        event.companyId,
      );
      emit(state.copyWith(quantitySummary: quantitySummary));
    } catch (e) {
      if (kDebugMode) {
        developer.log('Error getting lot quantity summary: $e');
      }
    }
  }

  // Helper Methods
  Future<List<LotMaster>> _calculateColorsForLots(List<LotMaster> lots) async {
    final systemConstant = systemConstantBloc.state.selected;
    final applyLot = systemConstant?.applyLotMgmBoolean == true;

    final updatedLots = <LotMaster>[];
    for (final lot in lots) {
      final updatedLot = lot.copyWith();
      if (applyLot) {
        final colorType = await _getLotColorType(lot);
        updatedLot.tempColorType = colorType;
      } else {
        updatedLot.tempColorType = null;
      }
      updatedLots.add(updatedLot);
    }
    return updatedLots;
  }

  Future<LotExpirationColor?> _getLotColorType(LotMaster lot) async {
    try {
      return await lotExpirationColorsBloc.getLotColorType(
        lot.branch,
        lot.itemNumber,
        lot.dateExpiration,
        lot.dateEffective,
        lot.dateReceived,
      );
    } catch (e) {
      if (kDebugMode) {
        developer.log('Error calculating lot color: $e');
      }
      return null;
    }
  }

  Future<int?> _calculateLotStatus(
    LotMaster item,
    UdcDetails? lotTypeUdcDetail,
  ) async {
    final lotType = lotTypeUdcDetail?.detailCode.toUpperCase();

    if (item.branch == null || item.itemNumber == null) return item.lotStatus;

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
        return await _getUdcDetailId('LS', 'E'); // Expired
      } else {
        return (item.lotStatus == await _getUdcDetailId('LS', 'E'))
            ? item.lotStatus
            : await _getUdcDetailId('LS', 'A'); // Active
      }
    } else {
      return item.lotStatus ?? await _getUdcDetailId('LS', 'A');
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

  bool _validatePurchaseOrderDates(PurchaseOrderReceiver por, String? lotType) {
    if (lotType == null || lotType.toUpperCase() == 'X') {
      return por.dateExpiration != null;
    } else if (lotType.toUpperCase() == 'F') {
      return por.dateEffective != null;
    } else if (lotType.toUpperCase() == 'R') {
      return por.dateReceived != null;
    }
    return false;
  }

  Future<void> _updateInventoryQuantities(
    LotMaster item,
    String transactionType,
    int? transactionNumber,
    String? remark,
    double quantity,
  ) async {
    // Update item location quantity
    final totalQty = await repository.getTotalQuantityForLocation(
      authBloc.state.companyId!,
      item.itemNumber!,
      item.branch!,
      item.location!,
    );

    await repository.updateItemLocationQuantity(
      companyId: authBloc.state.companyId!,
      itemNumber: item.itemNumber!,
      branch: item.branch!,
      location: item.location!,
      quantity: totalQty,
    );

    // Create item transaction
    final uom = await repository.getItemBranchUoM(
      item.itemNumber!,
      item.branch!,
      authBloc.state.companyId!,
    );

    await repository.createItemTransaction({
      'company': authBloc.state.companyId,
      'created_by': authBloc.state.userId!.id,
      'date_created': DateTime.now().toIso8601String(),
      'quantity_transaction': quantity,
      'remark': remark,
      'item_number': item.itemNumber,
      'branch': item.branch,
      'item_location': item.location,
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
    });
  }

  Future<int> _generateLotNumber() async {
    return await nextNumberBloc.generateFormattedNumber('LM');
  }

  Future<UdcDetails?> _getLotTypeUdcDetail(int? lotType) async {
    if (lotType == null) return null;
    return await udcRepository.getUdcDetailById(lotType);
  }

  Future<int?> _getUdcDetailId(String headerCode, String detailCode) async {
    return await udcRepository.getUdcDetailId(headerCode, detailCode);
  }

  // Public methods for external use
  Future<LotExpirationColor?> getLotColorTypeForUI(LotMaster lot) async {
    if (lot.tempColorType != null) {
      return lot.tempColorType;
    }
    return await _getLotColorType(lot);
  }

  Future<List<LotMaster>> getLotsByItemAndBranch({
    required int itemNumber,
    required int branch,
  }) async {
    return await repository.getLotMastersByItemAndBranch(
      companyId: authBloc.state.companyId!,
      itemNumber: itemNumber,
      branch: branch,
    );
  }

  Future<void> _onLoadExpirationReport(
    LoadExpirationReport event,
    Emitter<LotMasterState> emit,
  ) async {
    emit(state.copyWith(status: LotMasterStatus.loadingExpirationReport));
    try {
      final companyId = event.companyId;

      final result = await repository.getExpirationReport(
        companyId: companyId,
        filters: event.filters,
        page: event.page,
        pageSize: event.pageSize,
      );

      final totalPages = (result.totalCount / event.pageSize).ceil();

      emit(
        state.copyWith(
          status: LotMasterStatus.loadedExpirationReport,
          expirationReportLots: result.lots,
          expirationReportTotalCount: result.totalCount,
          expirationReportTotalPages: totalPages,
          expirationReportPage: event.page,
          expirationReportTotalCost: result.totalCost,
          expirationReportFilters: event.filters,
          hasMoreExpirationReport: event.page < totalPages,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: LotMasterStatus.failure,
          message: 'Failed to load expiration report: $e',
        ),
      );
    }
  }

  Future<void> _onLoadMoreExpirationReport(
    LoadMoreExpirationReport event,
    Emitter<LotMasterState> emit,
  ) async {
    if (!state.hasMoreExpirationReport) return;

    emit(state.copyWith(status: LotMasterStatus.loadingMoreExpirationReport));

    try {
      final nextPage = state.expirationReportPage + 1;
      final result = await repository.getExpirationReport(
        companyId: authBloc.state.companyId!,
        filters: state.expirationReportFilters,
        page: nextPage,
        pageSize: 20,
      );

      final updatedLots = [...state.expirationReportLots, ...result.lots];
      final totalPages = (result.totalCount / 20).ceil();

      emit(
        state.copyWith(
          status: LotMasterStatus.loadedExpirationReport,
          expirationReportLots: updatedLots,
          expirationReportPage: nextPage,
          expirationReportTotalCost:
              state.expirationReportTotalCost + result.totalCost,
          hasMoreExpirationReport: nextPage < totalPages,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: LotMasterStatus.failure,
          message: 'Failed to load more reports: $e',
        ),
      );
    }
  }

  Future<void> _onUpdateExpirationReportFilters(
    UpdateExpirationReportFilters event,
    Emitter<LotMasterState> emit,
  ) async {
    // Reset to page 1 when filters change
    add(
      LoadExpirationReport(
        companyId: authBloc.state.companyId!,
        filters: event.filters,
        page: 1,
        pageSize: defaultPageSize,
      ),
    );
  }

  Future<void> _onClearFilters(
    ClearExpirationReportFilters event,
    Emitter<LotMasterState> emit,
  ) async {
    add(
      LoadExpirationReport(
        companyId: authBloc.state.companyId!,
        filters: const ExpirationReportFilters(),
        page: 1,
        pageSize: defaultPageSize,
      ),
    );
  }

  Future<void> _onExportToExcel(
    ExportExpirationReportToExcel event,
    Emitter<LotMasterState> emit,
  ) async {
    emit(state.copyWith(status: LotMasterStatus.exporting));

    try {
      // Get all data (without pagination) for export
      final companyId = authBloc.state.companyId;
      if (companyId == null) throw Exception('Company ID not found');

      final result = await repository.getExpirationReport(
        companyId: companyId,
        filters: event.filters,
        page: 1,
        pageSize: 10000, // Large number to get all records
      );

      // Prepare data for Excel export
      final exportData = _prepareExcelData(result.lots);

      // In a real app, you would use a package like excel or csv
      // For now, we'll just simulate
      await _simulateExcelExport(exportData);

      emit(
        state.copyWith(
          status: LotMasterStatus.success,
          message: 'Exported ${result.lots.length} records to Excel',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: LotMasterStatus.failure,
          message: 'Export failed: $e',
        ),
      );
    }
  }

  Future<void> _onExportToPDF(
    ExportExpirationReportToPDF event,
    Emitter<LotMasterState> emit,
  ) async {
    emit(state.copyWith(status: LotMasterStatus.exporting));

    try {
      final companyId = authBloc.state.companyId;
      if (companyId == null) throw Exception('Company ID not found');

      final result = await repository.getExpirationReport(
        companyId: companyId,
        filters: event.filters,
        page: 1,
        pageSize: 10000,
      );

      // Prepare PDF data
      await _simulatePDFExport(result.lots, result.totalCost);

      emit(
        state.copyWith(
          status: LotMasterStatus.success,
          message: 'Generated PDF report with ${result.lots.length} records',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: LotMasterStatus.failure,
          message: 'PDF generation failed: $e',
        ),
      );
    }
  }

  //upcoming expiry report
  Future<void> _onLoadUpcomingExpiryReport(
    LoadUpcomingExpiryReport event,
    Emitter<LotMasterState> emit,
  ) async {
    emit(state.copyWith(status: LotMasterStatus.loadingUpcomingExpiryReport));

    try {
      final result = await repository.getUpComingExpirationReport(
        companyId: event.companyId,
        filters: event.filters,
        daysThreshold: event.daysThreshold, // Pass threshold
        page: event.page,
        pageSize: event.pageSize,
      );

      final totalPages = (result.totalCount / event.pageSize).ceil();

      emit(
        state.copyWith(
          status: LotMasterStatus.loadedUpcomingExpiryReport,
          upcomingExpiryLots: result.lots,
          upcomingExpiryTotalCount: result.totalCount,
          upcomingExpiryTotalPages: totalPages,
          upcomingExpiryPage: event.page,
          upcomingExpiryTotalCost: result.totalCost,
          upcomingExpiryFilters: event.filters,
          upcomingExpiryDaysThreshold: event.daysThreshold, // Store threshold
          hasMoreUpcomingExpiry: event.page < totalPages,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: LotMasterStatus.failure,
          message: 'Failed to load upcoming expiry report: $e',
        ),
      );
    }
  }

  Future<void> _onUpdateUpcomingExpiryReportFilters(
    UpdateUpcomingExpiryReportFilters event,
    Emitter<LotMasterState> emit,
  ) async {
    add(
      LoadUpcomingExpiryReport(
        companyId: authBloc.state.companyId!,
        filters: const ExpirationReportFilters(),
        page: 1,
        pageSize: defaultPageSize,
        daysThreshold: event.daysThreshold,
      ),
    );
  }

  Future<void> _onLoadMoreUpcomingExpiryReport(
    LoadMoreUpcomingExpiryReport event,
    Emitter<LotMasterState> emit,
  ) async {
    emit(
      state.copyWith(status: LotMasterStatus.loadingMoreUpcomingExpiryReport),
    );

    try {
      final result = await repository.getUpComingExpirationReport(
        companyId: authBloc.state.companyId!,
        filters: state.upcomingExpiryFilters,
        daysThreshold: state.upcomingExpiryDaysThreshold,
        page: state.upcomingExpiryPage + 1,
        pageSize: state.upcomingExpiryTotalPages,
      );

      final totalPages = (result.totalCount / state.upcomingExpiryTotalPages)
          .ceil();
      //final daysLeft = repository.calculateDaysUntilExpiry(result.lots.first.dateExpiration);

      emit(
        state.copyWith(
          status: LotMasterStatus.loadedUpcomingExpiryReport,
          upcomingExpiryLots: [...state.upcomingExpiryLots, ...result.lots],
          upcomingExpiryTotalCount: result.totalCount,
          upcomingExpiryTotalPages: totalPages,
          upcomingExpiryPage: state.upcomingExpiryPage + 1,
          upcomingExpiryTotalCost: result.totalCost,
          upcomingExpiryFilters: state.upcomingExpiryFilters,
          upcomingExpiryDaysThreshold: state.upcomingExpiryDaysThreshold,
          hasMoreUpcomingExpiry: state.upcomingExpiryPage < totalPages,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: LotMasterStatus.failure,
          message: 'Failed to load more upcoming expiry report: $e',
        ),
      );
    }
  }

  Future<void> _onClearUpcomingExpiryReportFilters(
    ClearUpcomingExpiryReportFilters event,
    Emitter<LotMasterState> emit,
  ) async {
    add(
      LoadUpcomingExpiryReport(
        companyId: authBloc.state.companyId!,
        filters: const ExpirationReportFilters(),
        page: 1,
        pageSize: defaultPageSize,
        daysThreshold: systemConstantBloc.state.selected!.daysLeft!,
      ),
    );
  }

  // Helper methods for export
  List<Map<String, dynamic>> _prepareExcelData(List<LotMaster> lots) {
    return lots.map((lot) {
      return {
        'Batch': lot.batchNumberSupplier ?? '',
        'Item ID': lot.itemRef?.itemsId ?? '',
        'Item Description': lot.itemRef?.itemDescription ?? '',
        'Branch/Store': lot.branchRef?.description ?? '',
        'Location': lot.locationRef?.locationDescription ?? '',
        'Unit of Measure': lot.itemRef?.unitOfMeasure ?? '',
        'Expiration Date': lot.dateExpiration?.toIso8601String() ?? '',
        'Available Quantity': lot.quantityAvailable ?? 0.0,
        'Status': lot.statusDescription ?? '',
      };
    }).toList();
  }

  Future<void> _simulateExcelExport(List<Map<String, dynamic>> data) async {
    // In production, use a package like:
    // - excel: ^2.0.0-null-safety-3
    // - csv: ^5.0.0
    await Future.delayed(const Duration(seconds: 1));
    if (kDebugMode) {
      developer.log('Exporting ${data.length} rows to Excel');
    }
  }

  Future<void> _simulatePDFExport(
    List<LotMaster> lots,
    double totalCost,
  ) async {
    // In production, use a package like:
    // - pdf: ^3.10.6
    // - printing: ^5.11.2
    await Future.delayed(const Duration(seconds: 2));
    if (kDebugMode) {
      developer.log(
        'Generating PDF for ${lots.length} lots, total cost: $totalCost',
      );
    }
  }

  // Public methods for pagination
  void loadNextPage() {
    if (state.hasMoreExpirationReport) {
      add(LoadMoreExpirationReport());
    }
  }

  void loadPreviousPage() {
    if (state.hasPreviousPage) {
      add(LoadMoreExpirationReport());
    }
  }

  void loadPage(int page) {
    if (page > 0 && page <= state.expirationReportTotalPages) {
      add(
        LoadExpirationReport(
          companyId: authBloc.state.companyId!,
          filters: state.expirationReportFilters,
          page: page,
          pageSize: defaultPageSize,
        ),
      );
    }
  }
}
