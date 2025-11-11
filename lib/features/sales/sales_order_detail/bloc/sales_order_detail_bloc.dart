// features/sales/sales_order_details/blocs/sales_order_details_bloc.dart
import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:savvy_stock/core/repositories/udc_repository.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/sales/sales_order_detail/bloc/sales_order_detail_event.dart';
import 'package:savvy_stock/features/sales/sales_order_detail/bloc/sales_order_detail_state.dart';
import 'package:savvy_stock/features/sales/sales_order_detail/model/sales_order_detail.dart';
import 'package:savvy_stock/features/sales/sales_order_detail/repo/sales_order_detail_repo.dart';
import 'package:savvy_stock/features/sales/sales_order_header/repo/sales_order_header_repo.dart';
import 'package:savvy_stock/features/stock/item_UoM_conversions/repo/item_uom_conv_repo.dart';
import 'package:savvy_stock/features/stock/item_cost/repo/item_cost_repository.dart';
import 'package:savvy_stock/features/stock/item_entry/data/item_repository.dart';
import 'package:savvy_stock/features/stock/item_in_branch/repo/item_in_branch_repo.dart';
import 'package:savvy_stock/features/stock/lot_master/repo/lot_master_repo.dart';
import 'package:savvy_stock/features/system_constant/bloc/system_constant_bloc.dart';
import 'package:savvy_stock/features/system_constant/bloc/system_constant_state.dart';

class SalesOrderDetailBloc
    extends Bloc<SalesOrderDetailsEvent, SalesOrderDetailState> {
  final SalesOrderDetailRepository repository;
  final SalesOrderHeaderRepository salesOrderHeaderRepository;
  final StockItemsEntryRepository itemsTableRepository;
  final StockItemInBranchRepository itemsInBranchRepository;
  final ItemUomConversionsRepository itemUOMConversionsRepository;
  final SystemConstantBloc systemConstantBloc;
  final ItemCostRepository itemCostRepository;
  final LotMasterRepository lotMasterRepository;
  final UdcRepository udcDetailsRepository;
  final AuthBloc authBloc;

  StreamSubscription? _authSubscription;
  StreamSubscription? _systemConstantSubscription;

  SalesOrderDetailBloc({
    required this.repository,
    required this.salesOrderHeaderRepository,
    required this.itemsTableRepository,
    required this.itemsInBranchRepository,
    required this.itemCostRepository,
    required this.itemUOMConversionsRepository,
    required this.systemConstantBloc,
    required this.lotMasterRepository,
    required this.udcDetailsRepository,
    required this.authBloc,
  }) : super(const SalesOrderDetailState()) {
    _authSubscription = authBloc.stream.listen((authState) {
      if (authState.isAuthenticated && authState.companyId != null) {
        add(SalesOrderDetailsInitialized(companyId: authState.companyId!));
      }
    });

    _systemConstantSubscription = systemConstantBloc.stream.listen((state) {
      if (state.status == SystemConstantStatus.loaded) {
        add(
          SystemConstantsUpdated(systemConstants: state.systemConstants.first),
        );
      }
    });

    // Event handlers
    on<SalesOrderDetailsInitialized>(_onInitialized);
    on<SystemConstantsUpdated>(_onSystemConstantsUpdated);
    on<LoadSalesOrderDetails>(_onLoadSalesOrderDetails);
    on<LoadSalesOrderDetailsByHeader>(_onLoadSalesOrderDetailsByHeader);
    on<CreateSalesOrderDetails>(_onCreateSalesOrderDetails);
    on<UpdateSalesOrderDetails>(_onUpdateSalesOrderDetails);
    on<DeleteSalesOrderDetails>(_onDeleteSalesOrderDetails);
    on<DeleteSalesOrderDetailsBatch>(_onDeleteSalesOrderDetailsBatch);

    // ✅ DETAIL-ONLY: Stock Validation & Business Logic
    on<ValidateStockAvailability>(_onValidateStockAvailability);
    on<ValidateAllStockAvailability>(_onValidateAllStockAvailability);
    on<AvailableValidatorMethod>(_onAvailableValidatorMethod);

    // UI State Management
    on<PrepareCreate>(_onPrepareCreate);
    on<PrepareCreateAfterCreate>(_onPrepareCreateAfterCreate);
    on<PrepareCopy>(_onPrepareCopy);
    on<PrepareCreateInCreate>(_onPrepareCreateInCreate);
    on<PrepareCreate1>(_onPrepareCreate1);
    on<PrepareCreateInEdit>(_onPrepareCreateInEdit);
    on<PrepareEdit>(_onPrepareEdit);
    on<CancelUpdate>(_onCancelUpdate);
    on<CancelCreate>(_onCancelCreate);
    on<Discard>(_onDiscard);

    // Item Management
    on<AddToCreateItems>(_onAddToCreateItems);
    on<UpdateInCreateItems>(_onUpdateInCreateItems);
    on<RemoveFromCreateItems>(_onRemoveFromCreateItems);
    on<RemoveFromEditItems>(_onRemoveFromEditItems);
    on<ClearCreateItems>(_onClearCreateItems);
    on<ClearEditItems>(_onClearEditItems);

    // Selection Management
    on<SetSelected>(_onSetSelected);
    on<SetSelected1>(_onSetSelected1);
    on<SetSelected2>(_onSetSelected2);
    on<SetMultiSelectionItems>(_onSetMultiSelectionItems);

    // Barcode and Stock Validation
    on<SetUseBarcode>(_onSetUseBarcode);
    on<SetBarCode>(_onSetBarCode);
    on<ScanBarcode>(_onScanBarcode);
    on<SettingSOByBarcode>(_onSettingSOByBarcode);

    // Calculations
    on<CalculateExtendedPrice>(_onCalculateExtendedPrice);
    on<CalculateAllExtendedPrices>(_onCalculateAllExtendedPrices);
    on<CalculateUomConversion>(_onCalculateUomConversion);
    on<UpdateUnitPriceWithUom>(_onUpdateUnitPriceWithUom);

    // ✅ DETAIL-ONLY: Lot Management
    on<CheckLotAvailability>(_onCheckLotAvailability);
    on<AutoAssignLotNumber>(_onAutoAssignLotNumber);
    on<ValidateLotQuantities>(_onValidateLotQuantities);

    // ✅ DETAIL-ONLY: Cost Calculations
    on<CalculateItemCost>(_onCalculateItemCost);
    on<CalculateAllItemCosts>(_onCalculateAllItemCosts);

    // ✅ DETAIL-ONLY: Stock Reversal
    on<ReverseStockOnVoid>(_onReverseStockOnVoid);

    // Filtering
    on<FilterSalesOrderDetails>(_onFilterSalesOrderDetails);
    on<SetFilteredValues>(_onSetFilteredValues);

    // Batch Operations
    on<SaveCreateItems>(_onSaveCreateItems);
    on<SaveEditItems>(_onSaveEditItems);
    on<SaveRow>(_onSaveRow);

    // Utility
    on<RefreshSalesOrderDetails>(_onRefreshSalesOrderDetails);
    on<SetFirst>(_onSetFirst);
    on<SetAvailablitySelections>(_onSetAvailablitySelections);
    on<ResetSalesOrderDetails>(_onResetSalesOrderDetails);
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }

  // Initialization
  Future<void> _onInitialized(
    SalesOrderDetailsInitialized event,
    Emitter<SalesOrderDetailState> emit,
  ) async {
    emit(state.copyWith(companyId: event.companyId));
    add(LoadSalesOrderDetails(companyId: event.companyId));
  }

  Future<void> _onLoadSalesOrderDetails(
    LoadSalesOrderDetails event,
    Emitter<SalesOrderDetailState> emit,
  ) async {
    emit(state.copyWith(status: SalesOrderDetailStatus.loading));

    try {
      final items = await repository.getSalesOrderDetailByCompany(
        event.companyId,
      );
      emit(
        state.copyWith(
          status: SalesOrderDetailStatus.loaded,
          items: items,
          filteredValues: items,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: SalesOrderDetailStatus.failure,
          errorMessage: 'Failed to load sales order details: $e',
        ),
      );
    }
  }

  Future<void> _onLoadSalesOrderDetailsByHeader(
    LoadSalesOrderDetailsByHeader event,
    Emitter<SalesOrderDetailState> emit,
  ) async {
    emit(state.copyWith(status: SalesOrderDetailStatus.loading));

    try {
      final items = await repository.getSalesOrderDetailsByHeaderId(
        event.headerId,
        authBloc.state.companyId!,
      );
      emit(
        state.copyWith(
          status: SalesOrderDetailStatus.loaded,
          items: items,
          filteredValues: items,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: SalesOrderDetailStatus.failure,
          errorMessage: 'Failed to load sales order details: $e',
        ),
      );
    }
  }

  // CRUD Operations
  Future<void> _onCreateSalesOrderDetails(
    CreateSalesOrderDetails event,
    Emitter<SalesOrderDetailState> emit,
  ) async {
    emit(state.copyWith(status: SalesOrderDetailStatus.creating));

    try {
      await repository.createSalesOrderDetail(event.details);
      emit(
        state.copyWith(
          status: SalesOrderDetailStatus.success,
          successMessage: 'Sales order details created successfully',
        ),
      );
      add(RefreshSalesOrderDetails());
    } catch (e) {
      emit(
        state.copyWith(
          status: SalesOrderDetailStatus.failure,
          errorMessage: 'Failed to create sales order details: $e',
        ),
      );
    }
  }

  Future<void> _onUpdateSalesOrderDetails(
    UpdateSalesOrderDetails event,
    Emitter<SalesOrderDetailState> emit,
  ) async {
    emit(state.copyWith(status: SalesOrderDetailStatus.updating));

    try {
      await repository.updateSalesOrderDetail(event.details);
      emit(
        state.copyWith(
          status: SalesOrderDetailStatus.success,
          successMessage: 'Sales order details updated successfully',
        ),
      );
      add(RefreshSalesOrderDetails());
    } catch (e) {
      emit(
        state.copyWith(
          status: SalesOrderDetailStatus.failure,
          errorMessage: 'Failed to update sales order details: $e',
        ),
      );
    }
  }

  Future<void> _onDeleteSalesOrderDetails(
    DeleteSalesOrderDetails event,
    Emitter<SalesOrderDetailState> emit,
  ) async {
    emit(state.copyWith(status: SalesOrderDetailStatus.deleting));

    try {
      await repository.deleteSalesOrderDetail(event.id);
      emit(
        state.copyWith(
          status: SalesOrderDetailStatus.success,
          successMessage: 'Sales order details deleted successfully',
        ),
      );
      add(RefreshSalesOrderDetails());
    } catch (e) {
      emit(
        state.copyWith(
          status: SalesOrderDetailStatus.failure,
          errorMessage: 'Failed to delete sales order details: $e',
        ),
      );
    }
  }

  Future<void> _onDeleteSalesOrderDetailsBatch(
    DeleteSalesOrderDetailsBatch event,
    Emitter<SalesOrderDetailState> emit,
  ) async {
    emit(state.copyWith(status: SalesOrderDetailStatus.deleting));

    try {
      await repository.deleteSalesOrderDetailBatch(event.ids);
      emit(
        state.copyWith(
          status: SalesOrderDetailStatus.success,
          successMessage:
              '${event.ids.length} sales order details deleted successfully',
        ),
      );
      add(RefreshSalesOrderDetails());
    } catch (e) {
      emit(
        state.copyWith(
          status: SalesOrderDetailStatus.failure,
          errorMessage: 'Failed to delete sales order details: $e',
        ),
      );
    }
  }

  // UI State Management (equivalent to Java preparation methods)
  Future<void> _onPrepareCreate(
    PrepareCreate event,
    Emitter<SalesOrderDetailState> emit,
  ) async {
    final companyId = authBloc.state.companyId;
    if (companyId == null) return;

    final newItem = SalesOrderDetail(
      tempId: _getNextTempId(state.createItems),
      quantity: 1.0,
      company: companyId,
      salesOrderHeaderId: state.selected!.salesOrderHeaderId,
      itemsTableId: state.selected!.itemsTableId,
    );

    emit(
      state.copyWith(
        createItems: [newItem],
        selected: newItem,
        selected2: SalesOrderDetail(
          company: companyId,
          salesOrderHeaderId: state.selected!.salesOrderHeaderId,
          itemsTableId: state.selected!.itemsTableId,
        ),
        availableValidator: {},
        barCode: '',
        useBarcode: false,
      ),
    );
  }

  Future<void> _onPrepareCreateAfterCreate(
    PrepareCreateAfterCreate event,
    Emitter<SalesOrderDetailState> emit,
  ) async {
    final companyId = authBloc.state.companyId;
    if (companyId == null) return;

    final newItem = SalesOrderDetail(
      tempId: _getNextTempId(state.createItems),
      quantity: 1.0,
      salesOrderHeaderId: state.selected!.salesOrderHeaderId,
      itemsTableId: state.selected!.itemsTableId,
      company: companyId,
    );

    emit(
      state.copyWith(
        createItems: [newItem],
        selected: newItem,
        availableValidator: {},
        barCode: '',
        useBarcode: false,
      ),
    );
  }

  Future<void> _onPrepareCopy(
    PrepareCopy event,
    Emitter<SalesOrderDetailState> emit,
  ) async {
    if (state.multiselectionItems.isEmpty) return;

    final companyId = authBloc.state.companyId;
    if (companyId == null) return;

    final copiedItem = state.multiselectionItems.first.copyWith(
      id: null,
      company: companyId,
    );

    final updatedCreateItems = [...state.createItems, copiedItem];

    emit(state.copyWith(createItems: updatedCreateItems, selected: copiedItem));
  }

  Future<void> _onPrepareCreateInCreate(
    PrepareCreateInCreate event,
    Emitter<SalesOrderDetailState> emit,
  ) async {
    final companyId = authBloc.state.companyId;
    if (companyId == null) return;

    final newItem = SalesOrderDetail(
      tempId: _getNextTempId(state.createItems),
      quantity: 1.0,
      company: companyId,
      salesOrderHeaderId: state.selected!.salesOrderHeaderId,
      itemsTableId: state.selected!.itemsTableId,
    );

    final updatedCreateItems = [...state.createItems, newItem];

    emit(state.copyWith(createItems: updatedCreateItems, selected1: newItem));
  }

  Future<void> _onPrepareCreate1(
    PrepareCreate1 event,
    Emitter<SalesOrderDetailState> emit,
  ) async {
    final companyId = authBloc.state.companyId;
    if (companyId == null) return;

    final newItem = SalesOrderDetail(
      tempId: _getNextTempId(state.createItems),
      company: companyId,
      salesOrderHeaderId: state.selected!.salesOrderHeaderId,
      itemsTableId: state.selected!.itemsTableId,
    );

    final updatedCreateItems = [...state.createItems, newItem];

    emit(state.copyWith(createItems: updatedCreateItems, selected: newItem));
  }

  Future<void> _onPrepareCreateInEdit(
    PrepareCreateInEdit event,
    Emitter<SalesOrderDetailState> emit,
  ) async {
    final companyId = authBloc.state.companyId;
    if (companyId == null) return;

    final newItem = SalesOrderDetail(
      tempId: _getNextTempId(state.editItems),
      company: companyId,
      salesOrderHeaderId: state.selected!.salesOrderHeaderId,
      itemsTableId: state.selected!.itemsTableId,
    );

    final updatedEditItems = [...state.editItems, newItem];

    emit(state.copyWith(editItems: updatedEditItems, selected1: newItem));
  }

  Future<void> _onPrepareEdit(
    PrepareEdit event,
    Emitter<SalesOrderDetailState> emit,
  ) async {
    if (state.multiselectionItems.isEmpty) return;

    emit(
      state.copyWith(
        editItems: [state.multiselectionItems.first],
        selected: state.multiselectionItems.first,
      ),
    );
  }

  void _onCancelUpdate(
    CancelUpdate event,
    Emitter<SalesOrderDetailState> emit,
  ) {
    emit(state.copyWith(selected1: null, editItems: const []));
  }

  void _onCancelCreate(
    CancelCreate event,
    Emitter<SalesOrderDetailState> emit,
  ) {
    emit(
      state.copyWith(selected: null, createItems: const [], items: const []),
    );
  }

  Future<void> _onDiscard(
    Discard event,
    Emitter<SalesOrderDetailState> emit,
  ) async {
    // Remove items that have IDs (are saved)
    final itemsToDelete = state.createItems
        .where((item) => item.id != null)
        .toList();

    if (itemsToDelete.isNotEmpty) {
      final idsToDelete = itemsToDelete.map((item) => item.id!).toList();
      add(DeleteSalesOrderDetailsBatch(ids: idsToDelete));
    }

    emit(
      state.copyWith(
        selected: null,
        createItems: const [],
        items: const [],
        successMessage: 'All records are removed',
      ),
    );
  }

  // Item Management in Lists
  void _onAddToCreateItems(
    AddToCreateItems event,
    Emitter<SalesOrderDetailState> emit,
  ) {
    final newItem = event.item.copyWith(
      tempId: _getNextTempId(state.createItems),
    );

    final updatedCreateItems = [...state.createItems, newItem];

    emit(state.copyWith(createItems: updatedCreateItems, selected1: newItem));
  }

  void _onUpdateInCreateItems(
    UpdateInCreateItems event,
    Emitter<SalesOrderDetailState> emit,
  ) {
    final updatedCreateItems = List<SalesOrderDetail>.from(state.createItems);
    if (event.index < updatedCreateItems.length) {
      updatedCreateItems[event.index] = event.item;
    }

    emit(state.copyWith(createItems: updatedCreateItems));
  }

  Future<void> _onRemoveFromCreateItems(
    RemoveFromCreateItems event,
    Emitter<SalesOrderDetailState> emit,
  ) async {
    final updatedCreateItems = state.createItems.where((item) {
      if (item.id == null) {
        return item.tempId != event.item.tempId;
      } else {
        return item.id != event.item.id;
      }
    }).toList();

    // If the item has an ID, delete it from database
    if (event.item.id != null) {
      add(DeleteSalesOrderDetails(id: event.item.id!));
    }

    emit(state.copyWith(createItems: updatedCreateItems));
  }

  Future<void> _onRemoveFromEditItems(
    RemoveFromEditItems event,
    Emitter<SalesOrderDetailState> emit,
  ) async {
    final updatedEditItems = List<SalesOrderDetail>.from(
      state.editItems.where((item) {
        if (item.id == null) {
          return item.tempId != event.item.tempId;
        } else {
          return item.id != event.item.id;
        }
      }).toList(),
    );

    // If the item has an ID, delete it from database
    if (event.item.id != null) {
      add(DeleteSalesOrderDetails(id: event.item.id!));
    }

    emit(state.copyWith(editItems: updatedEditItems));
  }

  void _onClearCreateItems(
    ClearCreateItems event,
    Emitter<SalesOrderDetailState> emit,
  ) {
    emit(state.copyWith(createItems: const []));
  }

  void _onClearEditItems(
    ClearEditItems event,
    Emitter<SalesOrderDetailState> emit,
  ) {
    emit(state.copyWith(editItems: const []));
  }

  // Selection Management
  void _onSetSelected(SetSelected event, Emitter<SalesOrderDetailState> emit) {
    emit(state.copyWith(selected: event.selected));
  }

  void _onSetSelected1(
    SetSelected1 event,
    Emitter<SalesOrderDetailState> emit,
  ) {
    emit(state.copyWith(selected1: event.selected1));
  }

  void _onSetSelected2(
    SetSelected2 event,
    Emitter<SalesOrderDetailState> emit,
  ) {
    emit(state.copyWith(selected2: event.selected2));
  }

  void _onSetMultiSelectionItems(
    SetMultiSelectionItems event,
    Emitter<SalesOrderDetailState> emit,
  ) {
    emit(state.copyWith(multiselectionItems: event.items));
  }

  // Barcode and Stock Validation
  void _onSetUseBarcode(
    SetUseBarcode event,
    Emitter<SalesOrderDetailState> emit,
  ) {
    emit(state.copyWith(useBarcode: event.useBarcode));
  }

  void _onSetBarCode(SetBarCode event, Emitter<SalesOrderDetailState> emit) {
    emit(state.copyWith(barCode: event.barCode));
  }

  Future<void> _onScanBarcode(
    ScanBarcode event,
    Emitter<SalesOrderDetailState> emit,
  ) async {
    if (state.barCode.isEmpty) return;

    emit(state.copyWith(status: SalesOrderDetailStatus.validatingStock));

    try {
      // Find item by barcode
      final itemsInBranch = await itemsInBranchRepository.findByBarcode(
        state.barCode,
        state.companyId!,
      );

      if (itemsInBranch.isNotEmpty) {
        final itemInBranch = itemsInBranch.first;
        final itemsTable = await itemsTableRepository.findById(
          itemInBranch.itemNumber,
          state.companyId!,
        );

        if (itemsTable != null) {
          SalesOrderDetail newItem;

          if (state.createItems.length == 1 &&
              state.createItems.first.itemsTableId == 0) {
            // Update the first empty item
            newItem = state.createItems.first.copyWith(
              itemsTableId: itemsTable.id,
              itemInBranch: itemInBranch.id,
              quantity: 1.0,
            );

            final updatedCreateItems = [newItem];
            emit(
              state.copyWith(
                createItems: updatedCreateItems,
                selected: newItem,
              ),
            );
          } else {
            // Add new item
            newItem = SalesOrderDetail(
              tempId: _getNextTempId(state.createItems),
              itemsTableId: itemsTable.id,
              itemInBranch: itemInBranch.id,
              quantity: 1.0,
              company: state.companyId!,
              salesOrderHeaderId: state.selected!.salesOrderHeaderId,
            );

            final updatedCreateItems = [...state.createItems, newItem];
            emit(
              state.copyWith(
                createItems: updatedCreateItems,
                selected: newItem,
              ),
            );
          }

          // Validate stock availability
          add(ValidateStockAvailability(item: newItem));
        }
      }

      emit(state.copyWith(barCode: '', status: SalesOrderDetailStatus.loaded));
    } catch (e) {
      emit(
        state.copyWith(
          status: SalesOrderDetailStatus.failure,
          errorMessage: 'Error scanning barcode: $e',
          barCode: '',
        ),
      );
    }
  }

  Future<void> _onValidateStockAvailability(
    ValidateStockAvailability event,
    Emitter<SalesOrderDetailState> emit,
  ) async {
    if (event.item.itemInBranch == null) return;

    emit(state.copyWith(status: SalesOrderDetailStatus.validatingStock));

    try {
      final itemInBranch = await itemsInBranchRepository.findById(
        event.item.itemInBranch!,
        state.companyId!,
      );
      if (itemInBranch == null) return;

      // Get all create items using the same item in branch
      final sameBranchItems = state.createItems
          .where((item) => item.itemInBranch == event.item.itemInBranch)
          .toList();

      double totalRequestedQuantity = 0.0;
      for (final item in sameBranchItems) {
        totalRequestedQuantity += item.quantity ?? 0;
      }

      final availableQuantity = itemInBranch.quantityAvailable ?? 0;
      final beyondQuantity = totalRequestedQuantity - availableQuantity;

      final validationResult = StockValidationResult(
        isValid: beyondQuantity <= 0,
        availableQuantity: availableQuantity,
        requestedQuantity: totalRequestedQuantity,
        beyondQuantity: beyondQuantity,
        message: beyondQuantity > 0
            ? 'Quantity Beyond Available (Beyond Quantity is ${beyondQuantity.abs()})!'
            : 'Stock is sufficient',
      );

      final updatedValidationResults = Map<int, StockValidationResult>.from(
        state.stockValidationResults,
      );
      updatedValidationResults[event.item.itemInBranch!] = validationResult;

      final updatedAvailableValidator = Map<int, double>.from(
        state.availableValidator,
      );
      updatedAvailableValidator[event.item.itemInBranch!] = beyondQuantity;

      emit(
        state.copyWith(
          status: SalesOrderDetailStatus.loaded,
          stockValidationResults: updatedValidationResults,
          availableValidator: updatedAvailableValidator,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: SalesOrderDetailStatus.failure,
          errorMessage: 'Error validating stock: $e',
        ),
      );
    }
  }

  Future<void> _onValidateAllStockAvailability(
    ValidateAllStockAvailability event,
    Emitter<SalesOrderDetailState> emit,
  ) async {
    emit(state.copyWith(status: SalesOrderDetailStatus.validatingStock));

    try {
      final updatedValidationResults = <int, StockValidationResult>{};
      final updatedAvailableValidator = <int, double>{};
      bool allValid = true;

      for (final item in state.createItems) {
        if (item.itemInBranch != null) {
          await _onValidateStockAvailability(
            ValidateStockAvailability(item: item),
            emit,
          );

          final result = state.stockValidationResults[item.itemInBranch!];
          if (result != null && !result.isValid) {
            allValid = false;
          }
        }
      }

      emit(
        state.copyWith(
          status: SalesOrderDetailStatus.loaded,
          enablePreview: allValid,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: SalesOrderDetailStatus.failure,
          errorMessage: 'Error validating all stock: $e',
        ),
      );
    }
  }

  // Calculations
  void _onCalculateExtendedPrice(
    CalculateExtendedPrice event,
    Emitter<SalesOrderDetailState> emit,
  ) {
    final unitPrice = event.item.unitPrice ?? 0;
    final quantity = event.item.quantity ?? 0;
    final extendedPrice = unitPrice * quantity;

    final updatedItem = event.item.copyWith(extendedPrice: extendedPrice);

    // Update in create items if it exists there
    final itemIndex = state.createItems.indexWhere(
      (item) =>
          (item.id != null && item.id == updatedItem.id) ||
          (item.tempId != null && item.tempId == updatedItem.tempId),
    );

    if (itemIndex != -1) {
      add(UpdateInCreateItems(item: updatedItem, index: itemIndex));
    }
  }

  void _onCalculateAllExtendedPrices(
    CalculateAllExtendedPrices event,
    Emitter<SalesOrderDetailState> emit,
  ) {
    for (final item in state.createItems) {
      add(CalculateExtendedPrice(item: item));
    }
  }

  // Filtering
  Future<void> _onFilterSalesOrderDetails(
    FilterSalesOrderDetails event,
    Emitter<SalesOrderDetailState> emit,
  ) async {
    emit(state.copyWith(status: SalesOrderDetailStatus.loading));

    try {
      final filteredItems = await repository.findRangedSalesOrderDetail(
        first: state.first,
        pageSize: 20, // Adjust as needed
        companyId: state.companyId!,
        customerTableId: event.customerTableId,
        itemsTableId: event.itemsTableId,
        fsNumber: event.fsNumber,
        proformaNumber: event.proformaNumber,
        startDate: event.startDate,
        endDate: event.endDate,
        orderStatus: event.orderStatus,
        voidIndicator: event.voidIndicator,
        detailTransaction: event.detailTransaction,
        salesRepresent: event.salesRepresent,
      );

      emit(
        state.copyWith(
          status: SalesOrderDetailStatus.loaded,
          filteredValues: filteredItems,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: SalesOrderDetailStatus.failure,
          errorMessage: 'Failed to filter sales order details: $e',
        ),
      );
    }
  }

  void _onSetFilteredValues(
    SetFilteredValues event,
    Emitter<SalesOrderDetailState> emit,
  ) {
    emit(state.copyWith(filteredValues: event.filteredValues));
  }

  // Batch Operations
  Future<void> _onSaveCreateItems(
    SaveCreateItems event,
    Emitter<SalesOrderDetailState> emit,
  ) async {
    emit(state.copyWith(status: SalesOrderDetailStatus.saving));

    try {
      // First validate all stock
      bool allStockValid = true;
      for (final item in state.createItems) {
        if (item.itemInBranch != null) {
          final result = state.stockValidationResults[item.itemInBranch!];
          if (result == null || !result.isValid) {
            allStockValid = false;
            break;
          }
        }
      }

      if (!allStockValid) {
        emit(
          state.copyWith(
            status: SalesOrderDetailStatus.failure,
            errorMessage:
                'Some items have insufficient stock. Please check quantities.',
          ),
        );
        return;
      }

      // Save all create items
      final itemsToSave = state.createItems
          .map(
            (item) =>
                item.copyWith(salesOrderHeaderId: event.salesOrderHeaderId),
          )
          .toList();

      await repository.createSalesOrderDetailBatch(itemsToSave);

      emit(
        state.copyWith(
          status: SalesOrderDetailStatus.success,
          successMessage: 'Sales order details saved successfully',
          createItems: const [],
          selected: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: SalesOrderDetailStatus.failure,
          errorMessage: 'Failed to save sales order details: $e',
        ),
      );
    }
  }

  Future<void> _onSaveEditItems(
    SaveEditItems event,
    Emitter<SalesOrderDetailState> emit,
  ) async {
    emit(state.copyWith(status: SalesOrderDetailStatus.saving));

    try {
      for (final item in state.editItems) {
        if (item.id == null) {
          await repository.createSalesOrderDetail(item);
        } else {
          await repository.updateSalesOrderDetail(item);
        }
      }

      emit(
        state.copyWith(
          status: SalesOrderDetailStatus.success,
          successMessage: 'Sales order details saved successfully',
          editItems: const [],
        ),
      );

      add(RefreshSalesOrderDetails());
    } catch (e) {
      emit(
        state.copyWith(
          status: SalesOrderDetailStatus.failure,
          errorMessage: 'Failed to save sales order details: $e',
        ),
      );
    }
  }

  Future<void> _onSaveRow(
    SaveRow event,
    Emitter<SalesOrderDetailState> emit,
  ) async {
    emit(state.copyWith(status: SalesOrderDetailStatus.saving));

    try {
      for (final item in state.editItems) {
        if (item.id == null) {
          await repository.createSalesOrderDetail(item);
        } else {
          await repository.updateSalesOrderDetail(item);
        }
      }

      emit(
        state.copyWith(
          status: SalesOrderDetailStatus.success,
          successMessage: 'Row saved successfully',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: SalesOrderDetailStatus.failure,
          errorMessage: 'Failed to save row: $e',
        ),
      );
    }
  }

  // Utility Methods
  Future<void> _onRefreshSalesOrderDetails(
    RefreshSalesOrderDetails event,
    Emitter<SalesOrderDetailState> emit,
  ) async {
    if (state.companyId != null) {
      add(LoadSalesOrderDetails(companyId: state.companyId!));
    }
  }

  void _onSetFirst(SetFirst event, Emitter<SalesOrderDetailState> emit) {
    emit(state.copyWith(first: event.first));
  }

  void _onSetAvailablitySelections(
    SetAvailablitySelections event,
    Emitter<SalesOrderDetailState> emit,
  ) {
    emit(state.copyWith(availablitySelections: event.availablitySelections));
  }

  void _onResetSalesOrderDetails(
    ResetSalesOrderDetails event,
    Emitter<SalesOrderDetailState> emit,
  ) {
    emit(const SalesOrderDetailState());
  }

  // Helper Methods
  int _getNextTempId(List<SalesOrderDetail> items) {
    if (items.isEmpty) return 1;
    final maxTempId = items
        .map((e) => e.tempId ?? 0)
        .reduce((a, b) => a > b ? a : b);
    return maxTempId + 1;
  }

  // 🎯 CRITICAL: Stock Validation (Equivalent to Java's availableValidatorMethod)
  Future<void> _onValidateStockForOrder(
    ValidateStockForOrder event,
    Emitter<SalesOrderHeaderState> emit,
  ) async {
    emit(state.copyWith(status: SalesOrderHeaderStatus.validatingItemInBranch));
    try {
      // Build item branch map for validation
      final itemBranchMap = <int, ItemInBranchModel>{};
      for (final item in state.createItems) {
        if (item.salesOrderDetail!.itemInBranch != null) {
          final itemBranch = await itemInBranchRepository.findById(
            item.salesOrderDetail!.itemInBranch!,
            state.companyId!,
          );
          if (itemBranch != null) {
            itemBranchMap[item.salesOrderDetail!.itemInBranch!] = itemBranch;
          }
        }
      }

      final validationResult = await itemInBranchRepository.validateSalesOrder(
        items: state.createItems,
        customer: event.customer,
        itemBranchMap: itemBranchMap,
        currentAvailableValidator: state.v,
        systemConstants: state.systemConstants!,
      );

      emit(
        state.copyWith(
          status: SalesOrderDetailStatus.loaded,
          validationErrors: validationResult.errors,
          validationWarnings: validationResult.warnings,
          availableValidator: validationResult.availableQuantities,
          isSalesOrderValid: validationResult.isValid,
          validationMessage: validationResult.isValid
              ? 'Sales order validation passed'
              : validationResult.combinedErrorMessage,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: SalesOrderDetailStatus.failure,
          errorMessage: 'Validation failed: $e',
        ),
      );
    }
  }

  // 🎯 CRITICAL: Lot Availability Check (Equivalent to Java's lot validation)
  Future<void> _onCheckLotAvailability(
    CheckLotAvailability event,
    Emitter<SalesOrderHeaderState> emit,
  ) async {
    emit(state.copyWith(status: SalesOrderHeaderStatus.validatingLot));
    final systemConstants =
        systemConstantBloc.systemConstantService.currentSystemConstant;
    final applyLotMgm = systemConstants?.applyLotMgm == 'Y';

    try {
      final itemBranch = await itemInBranchRepository.findById(
        event.branchId,
        state.companyId!,
      );

      if (itemBranch == null) return;

      if (applyLotMgm) {
        final lotValidation = await lotMasterRepository.validateLotForSale(
          itemId: event.itemId,
          branchId: itemBranch.branch,
          companyId: state.companyId!,
          requestedQuantity: event.quantity,
          systemConstants: systemConstants!,
          selectedLot: event.selectedLot,
        );

        if (lotValidation.isValid) {
          // Update item with recommended lot
          final updatedItem = event.orderDetail
              .firstWhere((item) => item.id == event.orderDetail.first.id)
              .copyWith(
                lotNumber: lotValidation.recommendedLot?.id,
                lot: lotValidation.recommendedLot,
              );

          // Update in sales order details
          final currentDetails = state.salesOrderDetail ?? [];
          final itemIndex = currentDetails.indexWhere(
            (item) =>
                item.tempId == event.orderDetail.first.tempId ||
                item.id == event.orderDetail.first.id,
          );

          if (itemIndex != -1) {
            final updatedDetails = List<SalesOrderDetail>.from(currentDetails);
            updatedDetails[itemIndex] = updatedItem;

            emit(
              state.copyWith(
                status: SalesOrderHeaderStatus.loaded,
                salesOrderDetail: updatedDetails,
                successmessage: 'Lot validation successful',
              ),
            );
          }
        } else {
          emit(
            state.copyWith(
              status: SalesOrderHeaderStatus.failure,
              error: lotValidation.message,
            ),
          );
        }
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: SalesOrderHeaderStatus.failure,
          error: 'Lot validation error: $e',
        ),
      );
    }
  }

  Future<void> _onCalculateUomConversion(
    CalculateUomConversion event,
    Emitter<SalesOrderHeaderState> emit,
  ) async {
    try {
      // 🎯 Use ItemUomConversionsBloc to get conversion factor
      final conversionFactor = await itemUomConversionsRepository
          .getConversionFactor(
            event.itemId,
            event.fromUomId,
            event.toUomId,
            event.companyId,
          );

      final convertedQuantity = event.quantity * conversionFactor;

      emit(
        state.copyWith(
          uomConversionResult: UOMConversionResult(
            convertedQuantity: convertedQuantity,
            conversionFactor: conversionFactor,
            fromUOM: event.fromUomId,
            toUOM: event.toUomId,
            isSuccess: true,
          ),
        ),
      );
    } catch (e) {
      emit(state.errorState('Failed to calculate UOM conversion: $e'));
    }
  }

  Future<void> _reverseStockQuantities(
    int salesOrderId,
    bool applyLotMgm,
  ) async {
    // Implement stock reversal logic when voiding sales order
    final orderDetails = await repository.getSalesOrderDetailsByHeaderId(
      salesOrderId,
    );

    for (final detail in orderDetails) {
      if (detail.itemInBranch != null && detail.quantity != null) {
        if (!applyLotMgm && detail.lotNumber != null) {
          await lotMasterRepository.restoreLotQuantity(
            detail.itemInBranch!,
            detail.quantity!,
            detail.company!,
          );
        } else {
          await itemInBranchRepository.updateQuantity(
            detail.itemInBranch!,
            detail.quantity!,
            detail.company!,
          );
        }
        await itemTransactionRepository.stockCardCreation(
          ib: detail.itemBranch!,
          loc: null,
          lm: null,
          transactionType: 'SO',
          trNo: null,
          remark: null,
          qty: detail.quantity!,
          por: null,
          soD: detail,
        );
      }
    }
  }

  // Stock Integration Methods (from Java controller)
  Future<void> updateStockAfterSalesOrder(SalesOrderHeader header) async {
    try {
      // Get sales order details
      final orderDetails = await repository.getSalesOrderDetailsByHeaderId(
        header.id!,
      );

      // Update stock quantities for each item
      for (final detail in orderDetails) {
        if (detail.itemInBranch != null && detail.quantity != null) {
          // Reduce available quantity in stock
          await itemInBranchRepository.updateStockQuantity(
            detail.itemInBranch!,
            -detail.quantity!, // Negative to reduce stock
          );

          // Create item transaction record
          await itemTransactionRepository.createTransaction(
            itemInBranchId: detail.itemInBranch!,
            quantity: detail.quantity!,
            transactionType: 'SO', // Sales Order
            referenceId: header.id!,
            orderDate: header.orderDate!,
          );
        }
      }
    } catch (e) {
      print('Error updating stock after sales order: $e');
      rethrow;
    }
  }

  // Integration with ItemInBranchBloc for stock validation
  Future<bool> validateStockAvailability(List<dynamic> orderDetails) async {
    try {
      for (final detail in orderDetails) {
        if (detail.itemInBranch != null && detail.quantity != null) {
          final availableStock = await repository.getAvailableStock(
            detail.itemInBranch!,
          );
          if (availableStock < detail.quantity!) {
            return false; // Insufficient stock
          }
        }
      }
      return true; // All items have sufficient stock
    } catch (e) {
      print('Error validating stock availability: $e');
      return false;
    }
  }

  // Integration with LotMasterBloc for lot tracking
  Future<void> assignLotsToSalesOrder(SalesOrderHeader header) async {
    try {
      final orderDetails = await repository.getSalesOrderDetailsByHeaderId(
        header.id!,
      );

      for (final detail in orderDetails) {
        if (detail.itemInBranch != null && detail.quantity != null) {
          // Get available lots for the item
          final availableLots = await repository.getAvailableLotsForItem(
            detail.itemInBranch!,
          );

          // Assign lots based on FIFO or other logic
          await repository.assignLotsToSalesOrderDetail(
            salesOrderDetailId: detail.id!,
            lots: availableLots,
            requiredQuantity: detail.quantity!,
          );
        }
      }
    } catch (e) {
      print('Error assigning lots to sales order: $e');
      rethrow;
    }
  }

  // Integration with ItemLocationsBloc for location tracking
  Future<void> updateItemLocations(SalesOrderHeader header) async {
    try {
      final orderDetails = await repository.getSalesOrderDetailsByHeaderId(
        header.id!,
      );

      for (final detail in orderDetails) {
        if (detail.itemInBranch != null && detail.quantity != null) {
          // Update item location quantities
          await repository.updateItemLocationQuantity(
            itemInBranchId: detail.itemInBranch!,
            quantity: detail.quantity!,
            locationType: 'SALES', // Sales location
          );
        }
      }
    } catch (e) {
      print('Error updating item locations: $e');
      rethrow;
    }
  }

  // Business logic methods from Java controller
  Future<void> processHeaderBusinessLogic(SalesOrderHeader header) async {
    try {
      // Validate stock availability
      final orderDetails = await repository.getSalesOrderDetailsByHeaderId(
        header.id!,
      );
      final hasStock = await validateStockAvailability(orderDetails);

      if (!hasStock) {
        throw Exception('Insufficient stock for some items');
      }

      // Update stock quantities
      await updateStockAfterSalesOrder(header);

      // Assign lots if lot tracking is enabled
      final systemConstants =
          systemConstantBloc.systemConstantService.currentSystemConstant;
      if (systemConstants?.lotType != null && systemConstants!.lotType! > 0) {
        await assignLotsToSalesOrder(header);
      }

      // Update item locations
      await updateItemLocations(header);

      // Generate FS number if not already set
      if (header.fsNumber == null || header.fsNumber!.isEmpty) {
        final fsNumber = await repository.generateNextFsNumber(
          header.company!,
          1, // Default branch - should come from user context
        );

        // Update header with FS number
        final updatedHeader = header.copyWith(fsNumber: fsNumber);
        await repository.updateSalesOrderHeader(updatedHeader);
      }
    } catch (e) {
      print('Error processing header business logic: $e');
      rethrow;
    }
  }
}
