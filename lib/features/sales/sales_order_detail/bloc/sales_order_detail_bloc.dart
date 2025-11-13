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
import 'package:savvy_stock/features/stock/item_locations/repo/item_location_repo.dart';
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
  final ItemLocationsRepository itemLocationRepository;
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
    required this.itemLocationRepository,
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
        add(SystemConstantUpdate(systemConstant: state.systemConstants.first));
      }
    });

    // Event handlers
    on<SalesOrderDetailsInitialized>(_onInitialized);
    on<SystemConstantUpdate>(_onSystemConstantUpdate);
    on<LoadSalesOrderDetails>(_onLoadSalesOrderDetails);
    on<LoadSalesOrderDetailsByHeader>(_onLoadSalesOrderDetailsByHeader);
    on<CreateSalesOrderDetails>(_onCreateSalesOrderDetails);
    on<UpdateSalesOrderDetails>(_onUpdateSalesOrderDetails);
    on<DeleteSalesOrderDetails>(_onDeleteSalesOrderDetails);
    on<DeleteSalesOrderDetailsBatch>(_onDeleteSalesOrderDetailsBatch);

    // ✅ DETAIL-ONLY: Stock Validation & Business Logic
    on<ValidateStockAvailability>(_onValidateStockAvailability);
    on<ValidateAllStockAvailability>(_onValidateAllStockAvailability);

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

    // Calculations
    on<CalculateExtendedPrice>(_onCalculateExtendedPrice);
    on<CalculateAllExtendedPrices>(_onCalculateAllExtendedPrices);
    on<UpdateUnitPriceWithUom>(_onUpdateUnitPriceWithUom);

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
    on<UpdateStockForSalesOrder>(_onUpdateStockForSalesOrder);
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
    _systemConstantSubscription?.cancel();
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

  Future<void> _onSystemConstantUpdate(
    SystemConstantUpdate event,
    Emitter<SalesOrderDetailState> emit,
  ) async {
    emit(state.copyWith(systemConstant: event.systemConstant));
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
              unitOfMeasure: itemInBranch.unitOfMeasure,
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
              unitOfMeasure: itemInBranch.unitOfMeasure,
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
          // 🎯 Update unit price and validate stock
          add(
            UpdateUnitPriceWithUom(
              salesOrderDetail: newItem,
              itemsInBranch: itemInBranch,
            ),
          );

          // Validate stock availability
          add(ValidateStockAvailability(salesOrderDetail: newItem));
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
    emit(state.copyWith(status: SalesOrderDetailStatus.validatingStock));

    final soD = event.salesOrderDetail;
    if (soD.itemInBranch == null || soD.itemsTableId == null) return;
    try {
      // Get system configuration
      final systemConstant = systemConstantBloc.state.selected;
      final applyLocationMgmt =
          systemConstant?.applyLocationMgmBoolean ?? false;
      final applyLotMgmt = systemConstant?.applyLotMgmBoolean ?? false;

      // Get all create items using the same item in branch
      final sameBranchItems = state.createItems
          .where((item) => item.itemInBranch == soD.itemInBranch)
          .toList();

      double totalRequestedQuantity = 0.0;

      // 🎯 Calculate total requested quantity with UOM conversions
      for (final item in sameBranchItems) {
        if (item.quantity != null && item.unitOfMeasure != null) {
          final conversionFactor = await itemUOMConversionsRepository
              .fromOtherToPrimary(
                item.itemsTableId!,
                item.unitOfMeasure!,
                authBloc.state.companyId!,
              );
          totalRequestedQuantity += item.quantity! * conversionFactor;
        }
      }
      double availableQuantity = 0.0;
      String validationMessage = '';
      bool isValid = false;
      // Check availability based on system configuration
      if (applyLocationMgmt && applyLotMgmt) {
        // Case 1: Both location and lot management
        final lotAvailability = await lotMasterRepository
            .validateLotLevelAvailability(soD, state.companyId!);
        availableQuantity = lotAvailability.availableQty;
        validationMessage = lotAvailability.message;
        isValid = lotAvailability.isValid;
      } else if (applyLocationMgmt && !applyLotMgmt) {
        // 🎯 Get actual available quantity from ItemsInBranch
        final locationAvailability = await itemLocationRepository
            .validateLocationLevelAvailability(soD, state.companyId!);
        availableQuantity = locationAvailability.availableQty;
        validationMessage = locationAvailability.message;
        isValid = locationAvailability.isValid;
      } else {
        final branchAvailability = await itemsInBranchRepository
            .validateBranchLevelAvailability(soD, state.companyId!);
        availableQuantity = branchAvailability.availableQty;
        validationMessage = branchAvailability.message;
        isValid = branchAvailability.isValid;
      }

      final beyondQuantity = totalRequestedQuantity - availableQuantity;

      // 🎯 Update available validator map
      final updatedAvailableValidator = Map<int, double>.from(
        state.availableValidator,
      );
      updatedAvailableValidator[soD.itemInBranch!] = beyondQuantity;

      emit(
        state.copyWith(
          status: SalesOrderDetailStatus.loaded,
          availableValidator: updatedAvailableValidator,
          stockValidationResults: {
            ...state.stockValidationResults,
            soD.itemInBranch!: StockValidationResult(
              isValid: beyondQuantity <= 0,
              availableQuantity: availableQuantity,
              requestedQuantity: totalRequestedQuantity,
              beyondQuantity: beyondQuantity,
              message: beyondQuantity > 0
                  ? 'Quantity Beyond Available (Beyond Quantity is ${beyondQuantity.abs()})!'
                  : 'Stock is sufficient',
            ),
          },
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: SalesOrderDetailStatus.failure,
          errorMessage: 'Failed to validate stock: ${e.toString()}',
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
      bool allValid = true;

      for (final item in state.createItems) {
        if (item.itemInBranch != null) {
          await _onValidateStockAvailability(
            ValidateStockAvailability(salesOrderDetail: item),
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

  Future<void> _onUpdateUnitPriceWithUom(
    UpdateUnitPriceWithUom event,
    Emitter<SalesOrderDetailState> emit,
  ) async {
    try {
      if (event.itemsInBranch == null) return;

      // 🎯 Get UOM conversion factor (like Java's fromOtherToAnother)
      final conversionFactor = await itemUOMConversionsRepository
          .fromOtherToPrimary(
            event.itemsInBranch!.itemNumber,
            event.salesOrderDetail.unitOfMeasure!,
            event.itemsInBranch!.unitOfMeasure!,
          );

      final convertedQuantity =
          event.salesOrderDetail.quantity! * conversionFactor;

      // 🎯 Check if converted quantity is available
      if (convertedQuantity <= event.itemsInBranch!.quantityAvailable!) {
        // 🎯 Apply converted unit price (like Java's factor * unitPrice)
        final convertedUnitPrice = event.itemsInBranch!.unitPrice != null
            ? (conversionFactor * event.itemsInBranch!.unitPrice!)
            : 0.0;

        final updatedDetail = event.salesOrderDetail.copyWith(
          unitPrice: convertedUnitPrice,
          extendedPrice: event.salesOrderDetail.quantity! * convertedUnitPrice,
          itemInBranch: event.itemsInBranch!.id,
        );

        // Update in create items
        final itemIndex = state.createItems.indexWhere(
          (item) => item.tempId == event.salesOrderDetail.tempId,
        );

        if (itemIndex != -1) {
          add(UpdateInCreateItems(item: updatedDetail, index: itemIndex));
        }

        // 🎯 Validate stock availability
        add(ValidateStockAvailability(salesOrderDetail: updatedDetail));
      } else {
        // 🎯 Insufficient stock - disable item (like Java's logic)
        final disabledDetail = event.salesOrderDetail.copyWith(
          unitPrice: 0.0,
          extendedPrice: 0.0,
          itemInBranch: null,
        );

        final itemIndex = state.createItems.indexWhere(
          (item) => item.tempId == event.salesOrderDetail.tempId,
        );

        if (itemIndex != -1) {
          add(UpdateInCreateItems(item: disabledDetail, index: itemIndex));
        }
      }
    } catch (e) {
      emit(
        state.copyWith(
          errorMessage: 'Failed to update unit price with UOM: $e',
        ),
      );
    }
  }

  Future<void> _onCalculateItemCost(
    CalculateItemCost event,
    Emitter<SalesOrderDetailState> emit,
  ) async {
    try {
      if (event.salesOrderDetail.itemsTableId == null) return;

      // 🎯 Get item cost from ItemCostTableBloc
      final itemCost = await itemCostRepository.calculateItemCost(
        item: event.salesOrderDetail,
        companyId: state.companyId!,
      );

      final unitCost = itemCost;
      final amountCost = unitCost * (event.salesOrderDetail.quantity ?? 0.0);

      final updatedDetail = event.salesOrderDetail.copyWith(
        unitCost: unitCost,
        amountCost: amountCost,
      );

      // Update in create items
      final itemIndex = state.createItems.indexWhere(
        (item) => item.tempId == event.salesOrderDetail.tempId,
      );

      if (itemIndex != -1) {
        add(UpdateInCreateItems(item: updatedDetail, index: itemIndex));
      }
    } catch (e) {
      print('Failed to calculate item cost: $e');
    }
  }

  Future<void> _onCalculateAllItemCosts(
    CalculateAllItemCosts event,
    Emitter<SalesOrderDetailState> emit,
  ) async {
    for (final item in event.salesOrderDetail) {
      add(CalculateItemCost(salesOrderDetail: item));
    }
  }

  Future<void> _onReverseStockOnVoid(
    ReverseStockOnVoid event,
    Emitter<SalesOrderDetailState> emit,
  ) async {
    try {
      emit(state.copyWith(status: SalesOrderDetailStatus.processing));

      // Get all order details for this header
      final orderDetails = await repository.getSalesOrderDetailsByHeaderId(
        event.salesOrderId,
        state.companyId!,
      );

      for (final detail in orderDetails) {
        if (detail.itemInBranch != null && detail.quantity != null) {
          // If lot management is enabled, use LotMasterBloc
          if (event.applyLotMgm && detail.lotNumber != null) {
            // Reverse lot quantity
            lotMasterRepository.restoreLotQuantitiesForVoid(
              voidedItems: orderDetails,
              companyId: state.companyId!,
            );
          } else {
            // Reverse ItemsInBranch quantity
            itemsInBranchRepository.restoreStockQuantitiesForVoid(
              voidedItems: orderDetails,
              companyId: state.companyId!,
            );
          }
        }
      }

      emit(
        state.copyWith(
          status: SalesOrderDetailStatus.success,
          successMessage: 'Stock quantities reversed successfully',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: SalesOrderDetailStatus.failure,
          errorMessage: 'Failed to reverse stock: $e',
        ),
      );
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

  Future<void> _onUpdateStockForSalesOrder(
    UpdateStockForSalesOrder event,
    Emitter<SalesOrderDetailState> emit,
  ) async {
    try {
      final salesOrderDetail = event.salesOrderDetail;

      // Validate input like Java version
      if (salesOrderDetail.itemsTableId != null &&
          salesOrderDetail.quantity != null &&
          salesOrderDetail.quantity != 0.0 &&
          salesOrderDetail.itemInBranch != null) {
        // Get conversion factor
        final factor = await itemUOMConversionsRepository.fromOtherToPrimary(
          salesOrderDetail.itemsTableId!,
          salesOrderDetail.unitOfMeasure ??
              salesOrderDetail.itemBranch!.unitOfMeasure!,
          authBloc.state.companyId!,
        );

        // Get system constants
        final systemConstant = systemConstantBloc.state.selected;
        final applyLocationMgmt =
            systemConstant?.applyLocationMgmBoolean ?? false;
        final applyLotMgmt = systemConstant?.applyLotMgmBoolean ?? false;

        if (!applyLocationMgmt && !applyLotMgmt) {
          // Case 1: No location or lot management
          await itemsInBranchRepository.handleSimpleStockUpdate(
            salesOrderDetail,
            factor,
            authBloc.state.companyId!,
          );
        } else if (applyLocationMgmt && !applyLotMgmt) {
          // Case 2: Location management only
          await itemLocationRepository.handleLocationStockUpdate(
            salesOrderDetail,
            factor,
            authBloc.state.companyId!,
          );
        } else if (applyLocationMgmt && applyLotMgmt) {
          // Case 3: Both location and lot management
          await lotMasterRepository.handleLotStockUpdate(
            salesOrderDetail,
            factor,
            authBloc.state.companyId!,
          );
        }

        emit(
          state.copyWith(
            status: SalesOrderDetailStatus.success,
            successMessage: 'Stock updated for sales order',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: SalesOrderDetailStatus.failure,
          errorMessage: 'Failed to update stock for sales order: $e',
        ),
      );
    }
  }

  // Batch Operations
  Future<void> _onSaveCreateItems(
    SaveCreateItems event,
    Emitter<SalesOrderDetailState> emit,
  ) async {
    try {
      emit(state.copyWith(status: SalesOrderDetailStatus.saving));

      // 🎯 Validate all stock first
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
      // 🎯 Calculate all costs before saving
      add(
        CalculateAllItemCosts(
          salesOrderDetail: state.createItems,
          companyId: state.companyId!,
        ),
      );

      // 🎯 Prepare items for saving with header ID
      final itemsToSave = state.createItems
          .map(
            (item) => item.copyWith(
              salesOrderHeaderId: event.salesOrderHeaderId,
              company: state.companyId,
            ),
          )
          .toList();

      // 🎯 Save to repository
      await repository.createSalesOrderDetailBatch(itemsToSave);

      // 🎯 Update stock quantities (like Java's updatingStockItemAvailablitySo)
      for (final item in itemsToSave) {
        if (item.itemInBranch != null && item.quantity != null) {
          add(UpdateStockForSalesOrder(salesOrderDetail: item));
        }
      }

      emit(
        state.copyWith(
          status: SalesOrderDetailStatus.success,
          successMessage: 'Sales order details saved successfully',
          createItems: const [],
          selected: null,
        ),
      );

      // 🎯 Refresh the list
      add(RefreshSalesOrderDetails());
    } catch (e) {
      emit(
        state.copyWith(errorMessage: 'Failed to save sales order details: $e'),
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
}
