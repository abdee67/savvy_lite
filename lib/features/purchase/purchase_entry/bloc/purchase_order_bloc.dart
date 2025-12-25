// features/purchase_order/bloc/purchase_order_bloc.dart
import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:savvy_stock/core/repositories/udc_repository.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/next_number/repo/next_number_repo.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/bloc/purchase_order_event.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/bloc/purchase_order_state.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/models/credit_payment_model.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/models/purchase_order_detail_model.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/models/purchase_order_header_model.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/models/purchase_order_receiver_model.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/models/purchase_report_filter_model.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/models/purchase_transaction_totals_model.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/repos/purchase_order_report_repo.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/repos/purchase_order_repository.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/services/purchase_order_stock_service.dart';
import 'package:savvy_stock/features/purchase/supplier_entry/repo/supplier_repo.dart';
import 'package:savvy_stock/features/stock/item_cost/repo/item_cost_repository.dart';
import 'package:savvy_stock/features/stock/item_entry/data/item_repository.dart';
import 'package:savvy_stock/features/system_constant/bloc/system_constant_bloc.dart';
import 'package:savvy_stock/features/system_constant/bloc/system_constant_state.dart';

class PurchaseOrderBloc extends Bloc<PurchaseOrderEvent, PurchaseOrderState> {
  final PurchaseOrderRepository repository;
  final AuthBloc authBloc;
  final SystemConstantBloc systemConstantBloc;
  final SupplierRepository supplierRepository;
  final StockItemsEntryRepository itemsTableRepository;
  final ItemCostRepository itemCostsRepository;
  final UdcRepository udcRepository;
  final NextNumberRepository nextNumberRepository;
  final PurchaseOrderStockService stockService;
  final PurchaseOrderReportRepository purchaseOrderReportRepository;

  StreamSubscription? _authSubscription;
  StreamSubscription? _systemConstantSubscription;

  PurchaseOrderBloc({
    required this.repository,
    required this.authBloc,
    required this.systemConstantBloc,
    required this.supplierRepository,
    required this.itemsTableRepository,
    required this.itemCostsRepository,
    required this.udcRepository,
    required this.nextNumberRepository,
    required this.stockService,
    required this.purchaseOrderReportRepository,
  }) : super(const PurchaseOrderState()) {
    _authSubscription = authBloc.stream.listen((authState) {
      if (authState.isAuthenticated && authState.companyId != null) {
        add(
          PurchaseOrderInitialized(
            companyId: authState.companyId!,
            userId: authState.userId?.id,
          ),
        );
      }
    });

    _systemConstantSubscription = systemConstantBloc.stream.listen((
      systemState,
    ) {
      if (systemState.status == SystemConstantStatus.success) {
        add(
          SystemConstantsUpdated(
            systemConstants: systemState.systemConstants.first,
          ),
        );
      }
    });

    // ============ EVENT HANDLERS ============

    // Initialization
    on<PurchaseOrderInitialized>(_onInitialized);
    on<SystemConstantsUpdated>(_onSystemConstantsUpdated);

    // Header operations
    on<LoadPurchaseOrders>(_onLoadPurchaseOrders);
    on<LoadPurchaseOrderCredit>(_onLoadPurchaseOrderCredit);
    on<PrepareCreatePurchaseOrder>(_onPrepareCreate);
    on<PrepareEditPurchaseOrder>(_onPrepareEdit);
    on<CreatePurchaseOrderHeader>(_onCreateHeader);
    on<UpdatePurchaseOrderHeader>(_onUpdateHeader);
    on<DeletePurchaseOrderHeader>(_onDeleteHeader);
    on<SavePurchaseOrder>(_onSavePurchaseOrder);
    on<SavePurchaseOrderAndContinue>(_onSaveAndContinue);
    on<SavePurchaseOrderAndAddNew>(_onSaveAndAddNew);
    on<CancelPurchaseOrderUpdate>(_onCancelUpdate);
    on<CancelPurchaseOrderCreate>(_onCancelCreate);
    on<DiscardPurchaseOrderChanges>(_onDiscardChanges);
    on<SelectPurchaseOrder>(_onSelectPurchaseOrder);
    on<SelectMultiplePurchaseOrders>(_onSelectMultiplePurchaseOrders);
    on<ClearPurchaseOrderSelection>(_onClearSelection);

    // Detail operations
    on<LoadPurchaseOrderDetails>(_onLoadDetails);
    on<AddPurchaseOrderDetail>(_onAddDetail);
    on<UpdatePurchaseOrderDetail>(_onUpdateDetail);
    on<RemovePurchaseOrderDetail>(_onRemoveDetail);
    on<RemovePurchaseOrderDetailInCreate>(_onRemoveDetailInCreate);
    on<RemovePurchaseOrderDetailInEdit>(_onRemoveDetailInEdit);
    on<SavePurchaseOrderRow>(_onSaveRow);
    on<SavePurchaseOrderRow1>(_onSaveRow1);
    on<CalculateExtendedCost>(_onCalculateExtendedCost);
    on<SetDefaultUomForDetail>(_onSetDefaultUom);
    on<SetDefaultSettingForAuto>(_onSetDefaultSettingForAuto);
    on<PrepareCopyPurchaseOrderDetail>(_onPrepareCopyDetail);

    // Receiver operations
    on<LoadPurchaseOrderReceivers>(_onLoadReceivers);
    on<PreparePurchaseOrderReceipt>(_onPrepareReceipt);
    on<PrepareAutoReceipt>(_onPrepareAutoReceipt);
    on<PreparePurchaseOrderReceiptForDetail>(_onPrepareReceiptForDetail);
    on<AddPurchaseOrderReceiver>(_onAddReceiver);
    on<UpdatePurchaseOrderReceiver>(_onUpdateReceiver);
    on<SavePurchaseOrderReceipt>(_onSaveReceiptWithStockUpdate);
    on<SavePurchaseOrderReceiptInEdit>(_onSaveReceiptInEdit);
    on<ValidateReceiptQuantity>(_onValidateReceiptQuantity);
    on<CheckReceiptValidity>(_onCheckReceiptValidity);

    // Filter operations
    on<FilterPurchaseOrders>(_onFilterPurchaseOrders);
    on<FilterPurchaseOrderDetails>(_onFilterPurchaseOrderDetails);
    on<SearchPurchaseOrders>(_onSearchPurchaseOrders);
    on<ClearPurchaseOrderFilters>(_onClearFilters);

    // Financial operations
    on<CalculatePurchaseOrderTotals>(_onCalculateTotals);
    on<UpdateCreditDueDate>(_onUpdateCreditDueDate);
    on<CalculateTaxesAndFees>(_onCalculateTaxesAndFees);
    on<UpdatePurchaseOrderAmounts>(_onUpdateAmounts);

    // Utility operations
    on<GenerateNextOrderNumber>(_onGenerateNextOrderNumber);
    on<RefreshPurchaseOrders>(_onRefreshPurchaseOrders);
    on<RefreshPurchaseOrderList>(_onRefreshList);
    on<GetPurchaseOrderStatistics>(_onGetStatistics);
    on<GetPurchaseOrderAgingReport>(_onGetAgingReport);
    on<GetSupplierPurchaseSummary>(_onGetSupplierSummary);

    // Batch operations
    on<DeleteMultiplePurchaseOrders>(_onDeleteMultipleOrders);
    on<SaveMultiplePurchaseOrders>(_onSaveMultipleOrders);
    on<RemovePurchaseOrderRecord>(_onRemoveRecord);
    on<RemovePurchaseOrderList>(_onRemoveList);

    // Copy operations
    on<PrepareCopyPurchaseOrder>(_onPrepareCopy);
    on<PrepareCreateInCreate>(_onPrepareCreateInCreate);
    on<PrepareCreateInEdit>(_onPrepareCreateInEdit);
    on<ResetPurchaseOrderSettings>(_onReset);
    on<SetPurchaseOrderAutoReceipt>(_onSetPurchaseOrderAutoReceipt);

    //credit payment
    on<LoadCreditPayments>(_onLoadCreditPayments);
    on<PrepareCreditPayment>(_onPrepareCreditPayment);
    on<UpdateCreditPayment>(_onUpdateCreditPayment);
    on<SaveCreditPayment>(_onSaveCreditPayment);
    on<DeleteCreditPayment>(_onDeleteCreditPayment);
    on<SelectCreditPayment>(_onSelectCreditPayment);
    on<FilterCreditPayments>(_onFilterCreditPayments);

    //Purchase Transaction Report
    on<LoadPurchaseTransactionReport>(_onLoadPurchaseTransactionReport);
    on<LoadMorePurchaseTransactionReport>(_onLoadMorePurchaseTransactionReport);
    on<UpdatePurchaseTransactionReportFilters>(
      _onUpdatePurchaseTransactionFilters,
    );
    on<ClearPurchaseTransactionReportFilters>(
      _onClearPurchaseTransactionFilters,
    );
    on<ExportPurchaseTransactionReportToExcel>(
      _onExportPurchaseTransactionToExcel,
    );
    on<ExportPurchaseTransactionReportToPDF>(_onExportPurchaseTransactionToPDF);
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    _systemConstantSubscription?.cancel();
    return super.close();
  }

  // ============ INITIALIZATION ============

  Future<void> _onInitialized(
    PurchaseOrderInitialized event,
    Emitter<PurchaseOrderState> emit,
  ) async {
    emit(state.loadingState('initialize_purchase_order'));

    try {
      // Load system constants
      await systemConstantBloc.systemConstantService.ensureLoaded();

      // Load initial data
      add(LoadPurchaseOrders(companyId: event.companyId));
      add(LoadPurchaseOrderCredit(companyId: event.companyId));
      add(GenerateNextOrderNumber(companyId: event.companyId));

      emit(
        state.copyWith(
          companyId: event.companyId,
          userId: event.userId,
          status: PurchaseOrderStatus.loaded,
        ),
      );
    } catch (e) {
      emit(state.errorState('Failed to initialize purchase order system: $e'));
    }
  }

  Future<void> _onSystemConstantsUpdated(
    SystemConstantsUpdated event,
    Emitter<PurchaseOrderState> emit,
  ) async {
    emit(state.copyWith(systemConstants: event.systemConstants));
  }

  // ============ HEADER OPERATIONS WITH COMPLEX LOGIC ============

  Future<void> _onLoadPurchaseOrders(
    LoadPurchaseOrders event,
    Emitter<PurchaseOrderState> emit,
  ) async {
    emit(state.loadingState('load_purchase_orders'));

    try {
      final headers = await repository.getPurchaseOrderHeaders(
        companyId: event.companyId,
        isCredit: event.isCredit,
        startDate: event.startDate ?? state.startdateForPO,
        endDate: event.endDate ?? state.thrudateForPO,
        purchaseType: event.purchaseType,
      );
      final List<PurchaseOrderDetail> details = [];
      for (final header in headers) {
        if (header.id != null && header.company != null) {
          final headerDetails = await repository.getDetailsByHeaderId(
            header.id!,
            header.company!,
          );
          details.addAll(headerDetails);
        }
      }

      emit(
        state.copyWith(
          status: PurchaseOrderStatus.loaded,
          headers: headers,
          filteredHeaders: headers,
          filteredDetails: details,
          error: null,
          startdateForPO: event.startDate,
          thrudateForPO: event.endDate,
          purchaseType: event.purchaseType,
        ),
      );
    } catch (e) {
      emit(state.errorState('Failed to load purchase orders: $e'));
    }
  }

  Future<void> _onLoadPurchaseOrderCredit(
    LoadPurchaseOrderCredit event,
    Emitter<PurchaseOrderState> emit,
  ) async {
    emit(state.loadingState('load_purchase_order_credit'));

    try {
      final creditHeaders = await repository.getPurchaseOrderHeaders(
        companyId: event.companyId,
        isCredit: true,
      );
      final List<PurchaseOrderDetail> details = [];
      for (final header in creditHeaders) {
        if (header.id != null && header.company != null) {
          final headerDetails = await repository.getDetailsByHeaderId(
            header.id!,
            header.company!,
          );
          details.addAll(headerDetails);
        }
      }

      emit(
        state.copyWith(
          status: PurchaseOrderStatus.loaded,
          creditHeaders: creditHeaders,
          filteredHeaders: creditHeaders,
          error: null,
        ),
      );
    } catch (e) {
      emit(state.errorState('Failed to load credit purchase orders: $e'));
    }
  }

  Future<void> _onPrepareCreate(
    PrepareCreatePurchaseOrder event,
    Emitter<PurchaseOrderState> emit,
  ) async {
    emit(state.loadingState('prepare_create_purchase_order'));

    try {
      // Get next order number
      final nextOrderNumber = await nextNumberRepository.generateNextNumber(
        'PO',
        event.companyId,
      );

      // Get default order type (P for Purchase)
      final defaultOrderType = await udcRepository.getUdcDetailsByCode(
        'PO',
        'OT',
      );

      // Get default purchase receive status (N for Not Received)
      final defaultReceiveStatus = await udcRepository.getUdcDetailsByCode(
        'N',
        'PR',
      );

      // Create new header
      final newHeader = PurchaseOrderHeader(
        orderNumber: nextOrderNumber,
        orderType: defaultOrderType.isNotEmpty
            ? defaultOrderType.first.id
            : null,
        poReceiveStatus: defaultReceiveStatus.isNotEmpty
            ? defaultReceiveStatus.first.id
            : null,
        company: event.companyId,
        tempId: _getNextHeaderTempId(state.createHeaders),
        dateTransaction: DateTime.now(),
        userId: state.userId,
        dateUpdated: DateTime.now(),
        //branchReceive: event.branchId,
      );

      emit(
        state.copyWith(
          status: PurchaseOrderStatus.loaded,
          createHeaders: [newHeader],
          selectedHeader: newHeader,
          createDetails: [],
          selectedDetail: null,
          editReceivers: [],
          selectedReceiver: null,
          totalAmount: 0.0,
          autoReceipt: false,
          receivingDates: DateTime.now(),
        ),
      );
    } catch (e) {
      emit(state.errorState('Failed to prepare create: $e'));
    }
  }

  Future<void> _onPrepareEdit(
    PrepareEditPurchaseOrder event,
    Emitter<PurchaseOrderState> emit,
  ) async {
    emit(state.loadingState('prepare_edit_purchase_order'));

    try {
      if (state.multiselectionHeaders.isEmpty) {
        emit(state.errorState('No purchase order selected for editing'));
        return;
      }

      final selectedHeader = state.multiselectionHeaders.first;

      // Load associated details
      final details = await repository.getDetailsByHeaderId(
        selectedHeader.id!,
        selectedHeader.company!,
      );

      // Load associated receivers
      final receivers = await repository.getReceiversByHeaderId(
        selectedHeader.id!,
        selectedHeader.company!,
      );

      emit(
        state.copyWith(
          editHeaders: [selectedHeader],
          selectedHeader: selectedHeader,
          selectedHeader1: selectedHeader,
          editDetails: details,
          createDetails: details,
          selectedDetail: details.isNotEmpty ? details.first : null,
          editReceivers: receivers,
          selectedReceiver: receivers.isNotEmpty ? receivers.first : null,
          totalAmount: selectedHeader.amountGrandTotalCost ?? 0.0,
          autoReceipt: false,
        ),
      );
    } catch (e) {
      emit(state.errorState('Failed to prepare edit: $e'));
    }
  }

  Future<void> _onPrepareCopy(
    PrepareCopyPurchaseOrder event,
    Emitter<PurchaseOrderState> emit,
  ) async {
    emit(state.loadingState('prepare_copy_purchase_order'));

    try {
      if (state.multiselectionHeaders.isEmpty) {
        emit(state.errorState('No purchase order selected for copying'));
        return;
      }

      final originalHeader = state.multiselectionHeaders.first;

      // Get next order number
      final nextOrderNumber = await nextNumberRepository.generateNextNumber(
        'PO',
        event.companyId,
      );

      // Create copy of header
      final copiedHeader = originalHeader.copyWith(
        id: null,
        orderNumber: nextOrderNumber,
        tempId: _getNextHeaderTempId(state.createHeaders),
        dateTransaction: DateTime.now(),
        dateUpdated: DateTime.now(),
        poReceiveStatus: await _getUdcDetailId('N', 'PR'),
        paymentStatus: originalHeader.paymentTerm != null
            ? await _getUdcDetailId('N', 'PS')
            : null,
        creditDueDate: _calculateCreditDueDate(
          originalHeader.paymentTerm,
          DateTime.now(),
        ),
      );

      // Load original details
      final originalDetails = await repository.getDetailsByHeaderId(
        originalHeader.id!,
        originalHeader.company!,
      );
      final poReceiveStatus = await _getUdcDetailId('N', 'PR');

      final copiedDetails = originalDetails.map((detail) {
        return detail.copyWith(
          id: null,
          poHeader: null,
          tempId: _getNextDetailTempId(state.createDetails),
          poReceiveStatus: poReceiveStatus,
          quantityOpen: detail.quantityTransaction,
          amountOpen: detail.amountExtendedCost,
          quantityRecieved: 0.0,
          amountReceived: 0.0,
          dateUpdated: DateTime.now(),
        );
      }).toList();

      emit(
        state.copyWith(
          status: PurchaseOrderStatus.loaded,
          createHeaders: [copiedHeader],
          selectedHeader: copiedHeader,
          createDetails: copiedDetails,
          selectedDetail: copiedDetails.isNotEmpty ? copiedDetails.first : null,
          totalAmount: originalHeader.amountGrandTotalCost ?? 0.0,
        ),
      );
    } catch (e) {
      emit(state.errorState('Failed to prepare copy: $e'));
    }
  }

  Future<void> _onCreateHeader(
    CreatePurchaseOrderHeader event,
    Emitter<PurchaseOrderState> emit,
  ) async {
    emit(state.loadingState('create_purchase_order_header'));

    try {
      // Validate supplier
      if (event.header.supplierId == null) {
        emit(state.errorState('Supplier must be selected'));
        return;
      }

      // Process header with all business logic
      final processedHeader = await _processHeaderBusinessLogic(event.header);

      final id = await repository.createPurchaseOrderHeader(processedHeader);
      final createdHeader = processedHeader.copyWith(id: id);

      // Update state
      final updatedHeaders = [createdHeader, ...state.headers];
      final updatedCreateHeaders = state.createHeaders
          .where((item) => item.tempId != createdHeader.tempId)
          .toList();

      emit(
        state.copyWith(
          status: PurchaseOrderStatus.success,
          headers: updatedHeaders,
          filteredHeaders: updatedHeaders,
          createHeaders: updatedCreateHeaders,
          selectedHeader: createdHeader,
          successMessage: 'Purchase order created successfully',
        ),
      );
    } catch (e) {
      emit(state.errorState('Failed to create purchase order: $e'));
    }
  }

  Future<PurchaseOrderHeader> _processHeaderBusinessLogic(
    PurchaseOrderHeader header,
  ) async {
    // Get default statuses
    final notReceivedStatus = await _getUdcDetailId('N', 'PR');
    final notPaidStatus = await _getUdcDetailId('N', 'PS');

    // Calculate credit due date if payment term exists
    DateTime? creditDueDate;
    if (header.paymentTerm != null && header.dateTransaction != null) {
      creditDueDate = header.dateTransaction!.add(
        Duration(days: header.paymentTerm!),
      );
    }

    // Calculate amounts if details exist
    double totalAmount = 0.0;
    if (state.createDetails.isNotEmpty) {
      totalAmount = state.createDetails
          .where((detail) => detail.amountExtendedCost != null)
          .map((detail) => detail.amountExtendedCost!)
          .fold(0.0, (sum, amount) => sum + amount);
    }

    final discount = header.amountDiscount ?? 0;
    final otherCosts = header.amountOtherCosts ?? 0;
    final grossAmount = totalAmount - discount;
    final grandTotal = grossAmount + otherCosts;

    return header.copyWith(
      poReceiveStatus: notReceivedStatus,
      paymentStatus: header.paymentTerm != null ? notPaidStatus : null,
      creditDueDate: creditDueDate,
      userId: state.userId,
      dateUpdated: DateTime.now(),
      amountGross: grossAmount,
      amountGrandTotalCost: grandTotal,
      amountOpenCredit: header.paymentTerm != null ? grandTotal : null,
    );
  }

  Future<void> _onUpdateHeader(
    UpdatePurchaseOrderHeader event,
    Emitter<PurchaseOrderState> emit,
  ) async {
    emit(state.loadingState('update_purchase_order_header'));

    try {
      if (event.header.id != null) {
        await repository.updatePurchaseOrderHeader(event.header);

        // Update in lists for existing headers
        final updatedHeaders = state.headers
            .map((h) => h.id == event.header.id ? event.header : h)
            .toList();
        final updatedEditHeaders = state.editHeaders
            .where((item) => item.id != event.header.id)
            .toList();

        emit(
          state.copyWith(
            status: PurchaseOrderStatus.success,
            headers: updatedHeaders,
            filteredHeaders: updatedHeaders,
            editHeaders: updatedEditHeaders,
            selectedHeader: event.header,
          ),
        );
      } else {
        // For new headers (id == null), just update the state
        // Find and update in createHeaders if it exists
        final updatedCreateHeaders = state.createHeaders.map((h) {
          // Match by tempId or reference
          if (h.tempId == event.header.tempId) {
            return event.header;
          }
          return h;
        }).toList();

        emit(
          state.copyWith(
            status: PurchaseOrderStatus.success,
            createHeaders: updatedCreateHeaders,
            selectedHeader: event.header,
          ),
        );
      }
    } catch (e) {
      emit(state.errorState('Failed to update purchase order: $e'));
    }
  }

  Future<void> _onDeleteHeader(
    DeletePurchaseOrderHeader event,
    Emitter<PurchaseOrderState> emit,
  ) async {
    emit(state.loadingState('delete_purchase_order_header'));

    try {
      await repository.deletePurchaseOrderHeader(event.id);

      final updatedHeaders = state.headers
          .where((h) => h.id != event.id)
          .toList();
      final updatedFilteredHeaders = state.filteredHeaders
          .where((h) => h.id != event.id)
          .toList();

      emit(
        state.copyWith(
          status: PurchaseOrderStatus.success,
          headers: updatedHeaders,
          filteredHeaders: updatedFilteredHeaders,
          selectedHeader: state.selectedHeader?.id == event.id
              ? null
              : state.selectedHeader,
          successMessage: 'Purchase order deleted successfully',
        ),
      );
    } catch (e) {
      emit(state.errorState('Failed to delete purchase order: $e'));
    }
  }

  Future<void> _onSavePurchaseOrder(
    SavePurchaseOrder event,
    Emitter<PurchaseOrderState> emit,
  ) async {
    emit(state.loadingState('save_purchase_order'));

    try {
      // Validate supplier
      if (state.selectedHeader?.supplierId == null) {
        emit(state.errorState('Supplier must be filled!'));
        return;
      }

      // Validate details
      if (state.createDetails.isEmpty) {
        emit(state.errorState('No purchase order details to save'));
        return;
      }

      // Save header
      final header = state.selectedHeader!;
      final savedHeader = header.id == null
          ? await _createHeaderWithBusinessLogic(header)
          : await _updateHeaderWithBusinessLogic(header);

      // Save details
      await _savePurchaseOrderDetails(savedHeader.id!);

      // Calculate and update header amounts
      await repository.updateHeaderAmounts(savedHeader.id!);

      // Auto receipt if enabled
      if (state.autoReceipt == true) {
        // Reload details to get their IDs after saving
        final savedDetails = await repository.getDetailsByHeaderId(
          savedHeader.id!,
          savedHeader.company!,
        );

        final autoReceivers = savedDetails.map((savedDetail) {
          // Find the original detail that matches this saved detail (using tempId if possible, or item number)
          final originalDetail = state.createDetails.firstWhere(
            (d) =>
                d.tempId == savedDetail.tempId ||
                d.itemNumber == savedDetail.itemNumber,
            orElse: () => savedDetail,
          );

          // Use autoReceiptReceiver from original detail if available
          final autoData = originalDetail.autoReceiptReceiver;

          return PurchaseOrderReceiver(
            poDetail: savedDetail.id,
            itemNumber: savedDetail.itemNumber,
            quantityTransaction: savedDetail.quantityTransaction,
            unitCost: savedDetail.unitCost,
            amountExtendedCost: savedDetail.amountExtendedCost,
            quantityOpen: savedDetail.quantityTransaction,
            amountOpen: savedDetail.amountExtendedCost,
            quantityRecieved: savedDetail.quantityTransaction,
            company: savedHeader.company,
            dateReceived: state.receivingDates ?? DateTime.now(),
            userId: state.userId,
            dateUpdated: DateTime.now(),
            // Use data from original detail (form input)
            branchRecieved: autoData?.branchRecieved,
            location: autoData?.location,
            unitOfMeasure: savedDetail.unitOfMeasure,
            dateEffective: savedDetail.dateEffective,
            dateExpiration: savedDetail.dateExpiration,
            batchNumberSupplier: savedDetail.batchNumberSupplier,
            tempId: savedDetail.tempId,
          );
        }).toList();

        // Set editReceivers and trigger save receipt
        emit(state.copyWith(editReceivers: autoReceivers));

        // Wait a moment for state to update
        await Future.delayed(const Duration(milliseconds: 100));

        // ⭐⭐ USE THE EXACT SAME RECEIPT SAVE LOGIC ⭐⭐
        await _onSaveReceiptWithStockUpdate(SavePurchaseOrderReceipt(), emit);
      }

      emit(
        state.copyWith(
          status: PurchaseOrderStatus.success,
          selectedHeader: savedHeader,
          successMessage: 'Purchase order saved successfully',
        ),
      );

      // Refresh lists
      add(RefreshPurchaseOrders());
    } catch (e) {
      //emit(state.errorState('Failed to save purchase order: $e'));
      print('Failed to save purchase order: $e');
    }
  }

  Future<PurchaseOrderHeader> _createHeaderWithBusinessLogic(
    PurchaseOrderHeader header,
  ) async {
    final processedHeader = await _processHeaderBusinessLogic(header);
    final id = await repository.createPurchaseOrderHeader(processedHeader);
    return processedHeader.copyWith(id: id);
  }

  Future<PurchaseOrderHeader> _updateHeaderWithBusinessLogic(
    PurchaseOrderHeader header,
  ) async {
    final processedHeader = await _processHeaderBusinessLogic(header);
    await repository.updatePurchaseOrderHeader(processedHeader);
    return processedHeader;
  }

  Future<void> _savePurchaseOrderDetails(int headerId) async {
    for (final detail in state.createDetails) {
      final detailToSave = detail.copyWith(
        poHeader: headerId,
        company: state.selectedHeader!.company,
        dateUpdated: DateTime.now(),
        dateReceived: detail.dateReceived,
        userId: state.userId ?? authBloc.state.userId?.id,
        poReceiveStatus: await _getUdcDetailId('N', 'PR'),
        quantityOpen: detail.quantityTransaction,
        amountOpen: detail.amountExtendedCost,
        amountReceived: detail.amountReceived ?? 0,
        quantityRecieved: detail.quantityRecieved ?? 0,
        dateDelivery: state.selectedHeader!.dateDelivery,
      );

      if (detail.id == null) {
        await repository.createPurchaseOrderDetail(detailToSave);
      } else {
        await repository.updatePurchaseOrderDetail(detailToSave);
      }
    }
  }

  Future<void> _processAutoReceipt(int headerId) async {
    try {
      // Load details for auto-receipt
      final details = await repository.getDetailsByHeaderId(
        headerId,
        state.companyId!,
      );

      if (details.isEmpty) return;

      final receivers = <PurchaseOrderReceiver>[];
      for (final detail in details) {
        final receiver = PurchaseOrderReceiver(
          poDetail: detail.id,
          itemNumber: detail.itemNumber,
          quantityTransaction: detail.quantityTransaction,
          unitCost: detail.unitCost,
          amountExtendedCost: detail.amountExtendedCost,
          quantityOpen: detail.quantityOpen,
          amountOpen: detail.amountOpen,
          company: detail.company,
          dateReceived: state.receivingDates ?? DateTime.now(),
          quantityRecieved: detail.quantityTransaction,
          branchRecieved: authBloc.state.branchId,
          userId: state.userId,
          dateUpdated: DateTime.now(),
          tempId: _getNextReceiverTempId(receivers),
        );

        // Apply location if system setting enabled
        if (state.systemConstants?.applyLocationMgmBoolean == true) {
          // receiver = receiver.copyWith(location: detail.itemLocationsSelect);
        }

        receivers.add(receiver);
      }

      // Save receivers
      for (final receiver in receivers) {
        if (await repository.canCreateReceipt(receiver)) {
          await _saveReceiverWithBusinessLogic(receiver);
        }
      }
    } catch (e) {
      // Log error but don't fail the entire operation
      print('Auto receipt failed: $e');
    }
  }

  // ============ DETAIL OPERATIONS WITH COMPLEX LOGIC ============

  Future<void> _onLoadDetails(
    LoadPurchaseOrderDetails event,
    Emitter<PurchaseOrderState> emit,
  ) async {
    emit(state.loadingState('load_purchase_order_details'));

    try {
      final details = await repository.getDetailsByHeaderId(
        event.headerId,
        event.companyId,
      );

      emit(
        state.copyWith(
          status: PurchaseOrderStatus.loaded,
          details: details,
          createDetails: details,
          error: null,
        ),
      );
    } catch (e) {
      emit(state.errorState('Failed to load purchase order details: $e'));
    }
  }

  Future<void> _onAddDetail(
    AddPurchaseOrderDetail event,
    Emitter<PurchaseOrderState> emit,
  ) async {
    try {
      final newDetail = event.detail.copyWith(
        tempId: _getNextDetailTempId(state.createDetails),
        company: state.selectedHeader?.company,
        poHeader: state.selectedHeader?.id,
      );

      final updatedDetails = [...state.createDetails, newDetail];

      emit(
        state.copyWith(
          createDetails: updatedDetails,
          selectedDetail: newDetail,
          status: PurchaseOrderStatus.success,
          //  successMessage: 'Purchase order detail added',
        ),
      );

      // Calculate totals
      add(CalculatePurchaseOrderTotals());
    } catch (e) {
      emit(state.errorState('Failed to add detail: $e'));
    }
  }

  void _onUpdateDetail(
    UpdatePurchaseOrderDetail event,
    Emitter<PurchaseOrderState> emit,
  ) {
    final updatedDetails = List<PurchaseOrderDetail>.from(state.createDetails);
    if (event.index < updatedDetails.length) {
      updatedDetails[event.index] = event.detail;
    }

    emit(state.copyWith(createDetails: updatedDetails));

    // Calculate extended cost if needed
    if (event.detail.quantityTransaction != null &&
        event.detail.unitCost != null) {
      add(CalculateExtendedCost(detail: event.detail));
    }

    // Set default UOM if not set
    if (event.detail.unitOfMeasure == null && event.detail.itemNumber != null) {
      add(SetDefaultUomForDetail(detail: event.detail));
    }
  }

  void _onRemoveDetail(
    RemovePurchaseOrderDetail event,
    Emitter<PurchaseOrderState> emit,
  ) {
    try {
      final updatedDetails = state.createDetails.where((detail) {
        if (detail.id == null) {
          return detail.tempId != event.detail.tempId;
        } else {
          return detail.id != event.detail.id;
        }
      }).toList();

      emit(state.copyWith(createDetails: updatedDetails));

      // Recalculate totals
      add(CalculatePurchaseOrderTotals());
    } catch (e) {
      emit(state.errorState('Failed to remove detail: $e'));
    }
  }

  void _onRemoveDetailInCreate(
    RemovePurchaseOrderDetailInCreate event,
    Emitter<PurchaseOrderState> emit,
  ) {
    try {
      final updatedDetails = state.createDetails.where((detail) {
        if (detail.id == null) {
          return detail.tempId != event.detail.tempId;
        } else {
          return detail.id != event.detail.id;
        }
      }).toList();

      emit(state.copyWith(createDetails: updatedDetails));

      // If the detail has an ID, delete it from database
      if (event.detail.id != null) {
        add(RemovePurchaseOrderRecord(detail: event.detail));
      }
    } catch (e) {
      emit(state.errorState('Failed to remove detail in create: $e'));
    }
  }

  void _onRemoveDetailInEdit(
    RemovePurchaseOrderDetailInEdit event,
    Emitter<PurchaseOrderState> emit,
  ) {
    try {
      final updatedDetails = state.editDetails.where((detail) {
        if (detail.id == null) {
          return detail.tempId != event.detail.tempId;
        } else {
          return detail.id != event.detail.id;
        }
      }).toList();

      emit(state.copyWith(editDetails: updatedDetails));

      // If the detail has an ID, delete it from database
      if (event.detail.id != null) {
        add(RemovePurchaseOrderRecord(detail: event.detail));
      }
    } catch (e) {
      emit(state.errorState('Failed to remove detail in edit: $e'));
    }
  }

  Future<void> _onSaveRow(
    SavePurchaseOrderRow event,
    Emitter<PurchaseOrderState> emit,
  ) async {
    emit(state.loadingState('save_purchase_order_row'));

    try {
      if (state.selectedHeader == null) {
        throw Exception('No purchase order header selected');
      }

      for (final detail in state.createDetails) {
        final detailToSave = detail.copyWith(
          poHeader: state.selectedHeader!.id,
          company: state.selectedHeader!.company,
          dateUpdated: DateTime.now(),
          userId: state.userId,
          poReceiveStatus: await _getUdcDetailId('N', 'PR'),
          quantityOpen: detail.quantityTransaction,
          amountOpen: detail.amountExtendedCost,
          dateDelivery: state.selectedHeader!.dateDelivery,
        );

        if (detail.id == null) {
          await repository.createPurchaseOrderDetail(detailToSave);
        } else {
          await repository.updatePurchaseOrderDetail(detailToSave);
        }
      }

      emit(
        state.copyWith(
          status: PurchaseOrderStatus.success,
          successMessage: 'Purchase order details saved successfully',
        ),
      );
    } catch (e) {
      //emit(state.errorState('Failed to save row: $e'));
      print('Failed to save row: $e');
    }
  }

  Future<void> _onSaveRow1(
    SavePurchaseOrderRow1 event,
    Emitter<PurchaseOrderState> emit,
  ) async {
    emit(state.loadingState('save_purchase_order_row1'));

    try {
      if (event.detail.id == null) {
        emit(state.errorState('Detail ID is null'));
        return;
      }

      // Update the detail
      await repository.updatePurchaseOrderDetail(event.detail);

      // Check and update header status based on all details
      if (event.detail.poHeader != null) {
        await repository.updateHeaderReceiptStatus(event.detail.poHeader!);

        // Update item costs
        await repository.updateItemCostsForHeader(event.detail.poHeader!);
      }

      emit(
        state.copyWith(
          status: PurchaseOrderStatus.success,
          successMessage: 'Purchase order detail updated successfully',
        ),
      );
    } catch (e) {
      //emit(state.errorState('Failed to save row: $e'));
      print('Failed to save row: $e');
    }
  }

  void _onCalculateExtendedCost(
    CalculateExtendedCost event,
    Emitter<PurchaseOrderState> emit,
  ) {
    final detail = event.detail;
    if (detail.quantityTransaction != null && detail.unitCost != null) {
      final extendedCost = detail.quantityTransaction! * detail.unitCost!;
      final updatedDetail = detail.copyWith(amountExtendedCost: extendedCost);

      // Update in create details
      final index = state.createDetails.indexWhere(
        (d) =>
            d.tempId == detail.tempId ||
            (detail.id != null && d.id == detail.id),
      );

      if (index != -1) {
        final updatedDetails = List<PurchaseOrderDetail>.from(
          state.createDetails,
        );
        updatedDetails[index] = updatedDetail;
        emit(state.copyWith(createDetails: updatedDetails));
      }

      // Update in edit details if exists
      final editIndex = state.editDetails.indexWhere(
        (d) =>
            d.tempId == detail.tempId ||
            (detail.id != null && d.id == detail.id),
      );

      if (editIndex != -1) {
        final updatedEditDetails = List<PurchaseOrderDetail>.from(
          state.editDetails,
        );
        updatedEditDetails[editIndex] = updatedDetail;
        emit(state.copyWith(editDetails: updatedEditDetails));
      }
    }
  }

  Future<void> _onSetDefaultUom(
    SetDefaultUomForDetail event,
    Emitter<PurchaseOrderState> emit,
  ) async {
    try {
      if (event.detail.itemNumber != null) {
        final item = await itemsTableRepository.findById(
          event.detail.itemNumber!,
          event.detail.company!,
        );
        if (item != null && event.detail.unitOfMeasure == null) {
          // Get UDC id for the unit of measure
          final uomUdc = await udcRepository.getUdcDetailsByCode(
            item.unitOfMeasure!,
            'UM',
          );
          if (uomUdc.isNotEmpty) {
            final updatedDetail = event.detail.copyWith(
              unitOfMeasure: uomUdc.first.id,
            );

            // Update in state
            final index = state.createDetails.indexWhere(
              (d) =>
                  d.tempId == event.detail.tempId ||
                  (event.detail.id != null && d.id == event.detail.id),
            );

            if (index != -1) {
              final updatedDetails = List<PurchaseOrderDetail>.from(
                state.createDetails,
              );
              updatedDetails[index] = updatedDetail;
              emit(state.copyWith(createDetails: updatedDetails));
            }
          }
        }
      }
    } catch (e) {
      // Silently fail, just don't set UOM
      print('Default uom not setted: $e');
    }
  }

  void _onSetDefaultSettingForAuto(
    SetDefaultSettingForAuto event,
    Emitter<PurchaseOrderState> emit,
  ) {
    emit(state.copyWith(selectedOpApply: event.detail));
  }

  Future<void> _onPrepareCopyDetail(
    PrepareCopyPurchaseOrderDetail event,
    Emitter<PurchaseOrderState> emit,
  ) async {
    if (state.multiselectionDetails.isEmpty) return;

    final originalDetail = state.multiselectionDetails.first;

    final copiedDetail = originalDetail.copyWith(
      id: null,
      tempId: _getNextDetailTempId(state.createDetails),
      poHeader: state.selectedHeader?.id,
      poReceiveStatus: await _getUdcDetailId('N', 'PR'),
      quantityOpen: originalDetail.quantityTransaction,
      amountOpen: originalDetail.amountExtendedCost,
      quantityRecieved: 0.0,
      amountReceived: 0.0,
      dateUpdated: DateTime.now(),
    );

    emit(
      state.copyWith(
        createDetails: [...state.createDetails, copiedDetail],
        selectedDetail: copiedDetail,
      ),
    );
  }

  // ============ RECEIVER OPERATIONS WITH COMPLEX LOGIC ============

  Future<void> _onLoadReceivers(
    LoadPurchaseOrderReceivers event,
    Emitter<PurchaseOrderState> emit,
  ) async {
    emit(state.loadingState('load_purchase_order_receivers'));

    try {
      final receivers = await repository.getReceiversByHeaderId(
        event.headerId,
        event.companyId,
      );

      emit(
        state.copyWith(
          status: PurchaseOrderStatus.loaded,
          receivers: receivers,
          error: null,
        ),
      );
    } catch (e) {
      emit(state.errorState('Failed to load purchase order receivers: $e'));
    }
  }

  Future<void> _onPrepareReceipt(
    PreparePurchaseOrderReceipt event,
    Emitter<PurchaseOrderState> emit,
  ) async {
    emit(state.loadingState('prepare_purchase_order_receipt'));

    try {
      if (event.detail == null && state.selectedDetail == null) {
        emit(state.errorState('No purchase order detail selected'));
        return;
      }

      final detail = event.detail ?? state.selectedDetail!;

      // Ensure we have the correct header selected for this detail so that
      // stock updates can use a valid orderNumber
      PurchaseOrderHeader? header = state.selectedHeader;
      if (header == null && detail.poHeader != null) {
        header = await repository.getHeaderById(detail.poHeader!);
      }

      // Check for existing receivers
      final existingReceivers = await repository.getReceiversByDetailId(
        detail.id!,
        detail.company!,
      );

      PurchaseOrderReceiver receiver;
      if (existingReceivers.isNotEmpty) {
        final existing = existingReceivers.first;
        receiver = existing.copyWith(
          quantityOpen: detail.quantityOpen,
          amountOpen: detail.amountOpen,
          tempId: _getNextReceiverTempId(state.editReceivers),
          unitOfMeasure: existing.unitOfMeasure ?? detail.unitOfMeasure,
        );
      } else {
        receiver = PurchaseOrderReceiver(
          poDetail: detail.id,
          itemNumber: detail.itemNumber,
          quantityTransaction: detail.quantityTransaction,
          unitCost: detail.unitCost,
          amountExtendedCost: detail.amountExtendedCost,
          quantityOpen: detail.quantityOpen,
          amountOpen: detail.amountOpen,
          company: detail.company,
          dateReceived: DateTime.now(),
          userId: state.userId,
          dateUpdated: DateTime.now(),
          amountReceived: detail.amountReceived,
          quantityRecieved: detail.quantityRecieved,
          unitOfMeasure: detail.unitOfMeasure,
          location: detail.autoReceiptReceiver?.location,
          branchRecieved: detail.autoReceiptReceiver?.branchRecieved,
          dateExpiration: detail.dateExpiration,
          dateEffective: detail.dateEffective,
          batchNumberSupplier: detail.batchNumberSupplier,
          tempId: _getNextReceiverTempId(state.editReceivers),
        );
      }

      receiver = receiver.copyWith(
        quantityRecieved: null,
        location: null,
        // branchRecieved: state.selectedHeader?.branchReceive,
      );

      emit(
        state.copyWith(
          status: PurchaseOrderStatus.loaded,
          editReceivers: [receiver],
          selectedReceiver: receiver,
          selectedReceiver2: receiver,
          selectedHeader: header ?? state.selectedHeader,
          selectedHeader1: header ?? state.selectedHeader1,
          lastOperation: 'receive_items',
        ),
      );
    } catch (e) {
      emit(state.errorState('Failed to prepare receipt: $e'));
    }
  }

  Future<void> _onPrepareAutoReceipt(
    PrepareAutoReceipt event,
    Emitter<PurchaseOrderState> emit,
  ) async {
    emit(state.loadingState('prepare_auto_receipt'));

    try {
      final details = event.details;
      final receivers = <PurchaseOrderReceiver>[];

      for (final detail in details) {
        // Use branch and location from detail if provided (from form selection)
        final receiver = PurchaseOrderReceiver(
          poDetail: detail.id,
          itemNumber: detail.itemNumber,
          quantityTransaction: detail.quantityTransaction,
          unitCost: detail.unitCost,
          amountExtendedCost: detail.amountExtendedCost,
          quantityOpen: detail.quantityOpen,
          amountOpen: detail.amountOpen,
          company: detail.company,
          dateReceived: state.receivingDates ?? DateTime.now(),
          quantityRecieved: detail.quantityTransaction,
          unitOfMeasure: detail.unitOfMeasure,
          branchRecieved:
              detail.autoReceiptReceiver?.branchRecieved ??
              await _getUserBranchId(state.userId!),
          location: detail.autoReceiptReceiver?.location,
          dateEffective: detail.dateEffective,
          dateExpiration: detail.dateExpiration,
          batchNumberSupplier: detail.batchNumberSupplier,
          userId: state.userId,
          dateUpdated: DateTime.now(),
          tempId: _getNextReceiverTempId(receivers),
        );

        receivers.add(receiver);
      }

      emit(state.copyWith(editReceivers: receivers, autoReceipt: true));
    } catch (e) {
      emit(state.errorState('Failed to prepare auto receipt: $e'));
    }
  }

  Future<void> _onPrepareReceiptForDetail(
    PreparePurchaseOrderReceiptForDetail event,
    Emitter<PurchaseOrderState> emit,
  ) async {
    emit(state.loadingState('prepare_receipt_for_detail'));

    try {
      final detail = event.detail;

      // Check for existing receivers
      final existingReceivers = await repository.getReceiversByDetailId(
        detail.id!,
        detail.company!,
      );

      PurchaseOrderReceiver receiver;
      if (existingReceivers.isNotEmpty) {
        receiver = existingReceivers.first.copyWith(
          quantityOpen: detail.quantityOpen,
          amountOpen: detail.amountOpen,
          tempId: _getNextReceiverTempId(state.editReceivers),
        );
      } else {
        receiver = PurchaseOrderReceiver(
          poDetail: detail.id,
          itemNumber: detail.itemNumber,
          quantityTransaction: detail.quantityTransaction,
          unitCost: detail.unitCost,
          amountExtendedCost: detail.amountExtendedCost,
          quantityOpen: detail.quantityOpen,
          amountOpen: detail.amountOpen,
          company: detail.company,
          dateReceived: DateTime.now(),
          userId: state.userId,
          dateUpdated: DateTime.now(),
          tempId: _getNextReceiverTempId(state.editReceivers),
        );
      }

      receiver = receiver.copyWith(
        quantityRecieved: detail.quantityTransaction,
        //branchRecieved: state.selectedHeader?.branchReceive,
      );

      // Apply location if system setting enabled
      if (state.systemConstants?.applyLocationMgmBoolean == true) {
        // receiver = receiver.copyWith(location: detail.itemLocationsSelect);
      }

      emit(
        state.copyWith(
          editReceivers: [receiver],
          selectedReceiver: receiver,
          selectedReceiver2: receiver,
        ),
      );
    } catch (e) {
      emit(state.errorState('Failed to prepare receipt for detail: $e'));
    }
  }

  Future<void> _onAddReceiver(
    AddPurchaseOrderReceiver event,
    Emitter<PurchaseOrderState> emit,
  ) async {
    try {
      final newReceiver = event.receiver.copyWith(
        tempId: _getNextReceiverTempId(state.editReceivers),
      );

      final updatedReceivers = [...state.editReceivers, newReceiver];

      emit(
        state.copyWith(
          editReceivers: updatedReceivers,
          selectedReceiver: newReceiver,
        ),
      );
    } catch (e) {
      emit(state.errorState('Failed to add receiver: $e'));
    }
  }

  void _onUpdateReceiver(
    UpdatePurchaseOrderReceiver event,
    Emitter<PurchaseOrderState> emit,
  ) {
    final updatedReceivers = List<PurchaseOrderReceiver>.from(
      state.editReceivers,
    );
    if (event.index < updatedReceivers.length) {
      updatedReceivers[event.index] = event.receiver;
    }

    emit(state.copyWith(editReceivers: updatedReceivers));

    // Validate receipt quantity
    add(ValidateReceiptQuantity(receiver: event.receiver));
  }

  // Updated save receipt method with stock update
  Future<void> _onSaveReceiptWithStockUpdate(
    SavePurchaseOrderReceipt event,
    Emitter<PurchaseOrderState> emit,
  ) async {
    emit(state.loadingState('save_purchase_order_receipt'));

    try {
      bool hasErrors = false;
      bool hasSuccess = false;
      final updatedReceivers = <PurchaseOrderReceiver>[];

      for (final receiver in state.editReceivers) {
        if (!_validateReceipt(receiver)) {
          hasErrors = true;
          final invalidReceiver = receiver.copyWith(validCell: false);
          updatedReceivers.add(invalidReceiver);
          continue;
        }

        // Calculate amounts
        final quantityRecieved = receiver.quantityRecieved ?? 0;
        final amountReceived = (receiver.unitCost ?? 0) * quantityRecieved;
        final quantityOpen = (receiver.quantityOpen ?? 0) - quantityRecieved;
        final amountOpen = (receiver.unitCost ?? 0) * quantityOpen;

        final receiverToSave = receiver.copyWith(
          amountReceived: amountReceived,
          quantityOpen: quantityOpen,
          amountOpen: amountOpen,
          dateUpdated: DateTime.now(),
          userId: state.userId,
          validCell: true,
        );

        int id;
        if (receiver.id == null) {
          print('💾 Creating receiver with:');
          print('  poDetail: ${receiverToSave.poDetail}');
          print('  itemNumber: ${receiverToSave.itemNumber}');
          print('  company: ${receiverToSave.company}');
          print('  branchRecieved: ${receiverToSave.branchRecieved}');
          print('  location: ${receiverToSave.location}');
          print('  unitOfMeasure: ${receiverToSave.unitOfMeasure}');

          id = await repository.createPurchaseOrderReceiver(receiverToSave);
          final savedReceiver = receiverToSave.copyWith(id: id);
          updatedReceivers.add(savedReceiver);

          // Determine orderNumber and companyId for stock update
          int? orderNumber = state.selectedHeader?.orderNumber;
          int? companyId = state.companyId ?? authBloc.state.companyId;

          if (orderNumber == null && receiver.poDetail != null) {
            // Fallback: load detail and derive order number from its header
            final detail = await repository.getDetailById(receiver.poDetail!);
            orderNumber ??= detail?.poHeaderRef?.orderNumber;
            companyId ??= detail?.company;
          }

          print(
            '🔎 Stock update check - headerId: ${state.selectedHeader?.id}, '
            'orderNumber: $orderNumber, companyId: $companyId',
          );

          // 🎯 ENRICH RECEIVER WITH DETAIL (ENSURE SUPPLIER/ORDERTYPE)
          var enrichedReceiver = savedReceiver;
          if (enrichedReceiver.poDetail != null) {
            try {
              final detail = await repository.getDetailById(
                enrichedReceiver.poDetail!,
              );
              if (detail != null) {
                enrichedReceiver = enrichedReceiver.copyWith(
                  poDetailRef: detail,
                );
              }
            } catch (e) {
              print(
                'WARNING: Could not enrich PurchaseOrderReceiver with detail: $e',
              );
            }
          }

          if (orderNumber != null && companyId != null) {
            await stockService.updateStockItemAvailabilityPor(
              receiver: enrichedReceiver,
              companyId: companyId,
              orderNumber: orderNumber,
            );
          } else {
            print('⚠️ Skipping stock update: missing orderNumber or companyId');
          }

          hasSuccess = true;
        } else {
          id = receiver.id!;
          await repository.updatePurchaseOrderReceiver(receiverToSave);
          updatedReceivers.add(receiverToSave);
        }

        // Update detail and header status
        await _updateDetailAndHeaderAfterReceipt(
          detailId: receiver.poDetail,
          quantityRecieved: quantityRecieved,
          amountReceived: amountReceived,
          quantityOpen: quantityOpen,
          amountOpen: amountOpen,
        );
      }

      if (hasErrors && !hasSuccess) {
        emit(
          state.copyWith(
            status: PurchaseOrderStatus.failure,
            editReceivers: updatedReceivers,
            error: 'All receipts have invalid quantities',
          ),
        );
      } else if (hasErrors) {
        emit(
          state.copyWith(
            status: PurchaseOrderStatus.partialError,
            editReceivers: updatedReceivers,
            error: 'Some receipts have invalid quantities',
            successMessage:
                'Valid receipts saved and stock updated successfully',
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: PurchaseOrderStatus.success,
            editReceivers: updatedReceivers,
            successMessage: 'All receipts saved and stock updated successfully',
          ),
        );

        // Refresh data
        if (state.selectedHeader != null) {
          add(
            LoadPurchaseOrderDetails(
              headerId: state.selectedHeader!.id!,
              companyId:
                  state.selectedHeader!.company ?? authBloc.state.companyId!,
            ),
          );
        }
      }
    } catch (e) {
      //emit(state.errorState('Failed to save receipt and update stock: $e'));
      print('Failed to save receipt and update stock: $e');
    }
  }

  Future<void> _updateDetailAndHeaderAfterReceipt({
    required int? detailId,
    required double quantityRecieved,
    required double amountReceived,
    required double quantityOpen,
    required double amountOpen,
  }) async {
    if (detailId == null) return;

    final detail = await repository.getDetailById(detailId);
    if (detail == null) return;

    final detailQuantityReceived =
        (detail.quantityRecieved ?? 0) + quantityRecieved;
    final detailAmountReceived = (detail.amountReceived ?? 0) + amountReceived;

    final updatedDetail = detail.copyWith(
      quantityOpen: quantityOpen,
      amountOpen: amountOpen,
      quantityRecieved: detailQuantityReceived,
      amountReceived: detailAmountReceived,
      poReceiveStatus: quantityOpen == 0
          ? await _getUdcDetailId('C', 'PR')
          : await _getUdcDetailId('P', 'PR'),
      dateUpdated: DateTime.now(),
      userId: state.userId,
    );

    await repository.updatePurchaseOrderDetail(updatedDetail);

    // Only update header if poHeader is not null
    if (updatedDetail.poHeader != null) {
      await repository.updateHeaderReceiptStatus(updatedDetail.poHeader!);
      await repository.updateItemCostsForHeader(updatedDetail.poHeader!);
    } else {
      print('⚠️ poHeader is null, skipping header status update');
    }
  }

  bool _validateReceipt(PurchaseOrderReceiver receiver) {
    final quantityRecieved = receiver.quantityRecieved ?? 0;
    final quantityOpen = receiver.quantityOpen ?? 0;
    final effectiveDate = receiver.dateEffective;
    final expirationDate = receiver.dateExpiration;

    print('🔍 Validating receiver:');
    print('  itemNumber: ${receiver.itemNumber}');
    print('  unitOfMeasure: ${receiver.unitOfMeasure}');
    print('  quantityRecieved: $quantityRecieved');
    print('  quantityOpen: $quantityOpen');
    print('  effectiveDate: $effectiveDate');
    print('  expirationDate: $expirationDate');
    print('  branchRecieved: ${receiver.branchRecieved}');
    print('  location: ${receiver.location}');

    // Basic quantity validation
    if (quantityRecieved <= 0 || quantityRecieved > quantityOpen) {
      print(
        '❌ Quantity validation failed: recieved=$quantityRecieved, open=$quantityOpen',
      );
      return false;
    }

    // Date validation (same as Java)
    if (effectiveDate != null && expirationDate != null) {
      if (effectiveDate.isAfter(expirationDate)) {
        print(
          '❌ Date validation failed: effective=$effectiveDate > expiration=$expirationDate',
        );
        return false;
      }
    }

    print('✅ Receiver validation passed');
    return true;
  }

  Future<PurchaseOrderReceiver> _saveReceiverWithBusinessLogic(
    PurchaseOrderReceiver receiver,
  ) async {
    // Calculate received amounts
    final quantityRecieved = receiver.quantityRecieved ?? 0;
    final amountReceived = (receiver.unitCost ?? 0) * quantityRecieved;
    final quantityOpen = (receiver.quantityOpen ?? 0) - quantityRecieved;
    final amountOpen = (receiver.unitCost ?? 0) * quantityOpen;

    final receiverToSave = receiver.copyWith(
      amountReceived: amountReceived,
      quantityOpen: quantityOpen,
      amountOpen: amountOpen,
      dateUpdated: DateTime.now(),
      userId: state.userId,
      validCell: true,
    );

    int id;
    if (receiver.id == null) {
      id = await repository.createPurchaseOrderReceiver(receiverToSave);
      // Update stock availability
      await repository.updateStockItemAvailability(
        receiverToSave.copyWith(id: id),
      );
    } else {
      id = receiver.id!;
      await repository.updatePurchaseOrderReceiver(receiverToSave);
    }

    final savedReceiver = receiverToSave.copyWith(id: id);

    // Update purchase order detail
    final detail = await repository.getDetailById(receiver.poDetail!);
    if (detail != null) {
      final detailQuantityReceived =
          (detail.quantityRecieved ?? 0) + quantityRecieved;
      final detailAmountReceived =
          (detail.amountReceived ?? 0) + amountReceived;

      final updatedDetail = detail.copyWith(
        quantityOpen: quantityOpen,
        amountOpen: amountOpen,
        quantityRecieved: detailQuantityReceived,
        amountReceived: detailAmountReceived,
        poReceiveStatus: quantityOpen == 0
            ? await _getUdcDetailId('C', 'PR')
            : await _getUdcDetailId('P', 'PR'),
        dateUpdated: DateTime.now(),
        userId: state.userId,
      );

      await repository.updatePurchaseOrderDetail(updatedDetail);

      // Update header status if needed
      await repository.updateHeaderReceiptStatus(updatedDetail.poHeader!);

      // Update item costs
      await repository.updateItemCostsForHeader(updatedDetail.poHeader!);

      // Update item cost table
      //  await _updateItemCostTable(savedReceiver);//aman said ''comment ketederege tewew
    }

    return savedReceiver;
  }

  /*Future<void> _updateItemCostTable(PurchaseOrderReceiver receiver) async {
    try {
      if (receiver.itemNumber != null && receiver.unitCost != null) {
        await itemCostsRepository.updateItemCostFromPurchase(
          itemId: receiver.itemNumber!,
          unitCost: receiver.unitCost!,
          quantity: receiver.quantityRecieved ?? 0,
          purchaseDate: receiver.dateReceived ?? DateTime.now(),
        );
      }
    } catch (e) {
      // Log but don't fail
      print('Failed to update item cost table: $e');
    }
  }*/

  Future<void> _onSaveReceiptInEdit(
    SavePurchaseOrderReceiptInEdit event,
    Emitter<PurchaseOrderState> emit,
  ) async {
    emit(state.loadingState('save_purchase_order_receipt_in_edit'));

    try {
      for (final receiver in state.editReceivers) {
        if (receiver.id != null) {
          await repository.updatePurchaseOrderReceiver(receiver);
        }
      }

      emit(
        state.copyWith(
          status: PurchaseOrderStatus.success,
          successMessage: 'Receipts updated successfully',
        ),
      );
    } catch (e) {
      //emit(state.errorState('Failed to save receipt in edit: $e'));
      print('Failed to save receipt in edit: $e');
    }
  }

  void _onValidateReceiptQuantity(
    ValidateReceiptQuantity event,
    Emitter<PurchaseOrderState> emit,
  ) {
    final quantityRecieved = event.receiver.quantityRecieved ?? 0;
    final quantityOpen = event.receiver.quantityOpen ?? 0;

    final isValid = quantityRecieved > 0 && quantityRecieved <= quantityOpen;
    final updatedReceiver = event.receiver.copyWith(validCell: isValid);

    final index = state.editReceivers.indexWhere(
      (r) => r.tempId == event.receiver.tempId || r.id == event.receiver.id,
    );

    if (index != -1) {
      final updatedReceivers = List<PurchaseOrderReceiver>.from(
        state.editReceivers,
      );
      updatedReceivers[index] = updatedReceiver;
      emit(state.copyWith(editReceivers: updatedReceivers));
    }
  }

  Future<void> _onCheckReceiptValidity(
    CheckReceiptValidity event,
    Emitter<PurchaseOrderState> emit,
  ) async {
    try {
      bool allValid = true;
      final updatedReceivers = <PurchaseOrderReceiver>[];

      for (final receiver in state.editReceivers) {
        final isValid = await repository.canCreateReceipt(receiver);
        final updatedReceiver = receiver.copyWith(validCell: isValid);
        updatedReceivers.add(updatedReceiver);

        if (!isValid) {
          allValid = false;
        }
      }

      emit(
        state.copyWith(
          editReceivers: updatedReceivers,
          isValidReceipt: allValid,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          error: 'Failed to check receipt validity: $e',
          isValidReceipt: false,
        ),
      );
    }
  }

  // ============ FILTER OPERATIONS ============

  Future<void> _onFilterPurchaseOrders(
    FilterPurchaseOrders event,
    Emitter<PurchaseOrderState> emit,
  ) async {
    emit(state.loadingState('filter_purchase_orders'));

    try {
      final filteredHeaders = await repository.filterPurchaseOrders(
        companyId: state.companyId ?? authBloc.state.companyId!,
        supplierId: event.supplierId,
        invoiceNumber: event.invoiceNumber,
        startDate: event.startDate,
        endDate: event.endDate,
        purchaseType: event.purchaseType,
      );

      emit(
        state.copyWith(
          status: PurchaseOrderStatus.loaded,
          filteredHeaders: filteredHeaders,
          startdateForPO: event.startDate,
          thrudateForPO: event.endDate,
          purchaseType: event.purchaseType,
        ),
      );
    } catch (e) {
      emit(state.errorState('Failed to filter purchase orders: $e'));
    }
  }

  Future<void> _onFilterPurchaseOrderDetails(
    FilterPurchaseOrderDetails event,
    Emitter<PurchaseOrderState> emit,
  ) async {
    emit(state.loadingState('filter_purchase_order_details'));

    try {
      final filteredDetails = await repository.filterPurchaseOrderDetails(
        companyId: state.companyId ?? authBloc.state.companyId!,
        orderNumber: event.orderNumber,
        supplierId: event.supplierId,
        itemNumber: event.itemNumber,
        invoiceNumber: event.invoiceNumber,
        startDate: event.startDate,
        endDate: event.endDate,
      );

      emit(
        state.copyWith(
          status: PurchaseOrderStatus.loaded,
          filteredDetails: filteredDetails,
          dateOrderStart: event.startDate,
          dateOrderEnd: event.endDate,
        ),
      );
    } catch (e) {
      emit(state.errorState('Failed to filter purchase order details: $e'));
    }
  }

  Future<void> _onSearchPurchaseOrders(
    SearchPurchaseOrders event,
    Emitter<PurchaseOrderState> emit,
  ) async {
    if (event.query.isEmpty) {
      emit(state.copyWith(searchQuery: null, filteredHeaders: state.headers));
      return;
    }

    emit(state.loadingState('search_purchase_orders'));

    try {
      final query = event.query.toLowerCase();
      final filtered = state.headers.where((header) {
        return header.invoiceNumber?.toLowerCase().contains(query) == true ||
            header.orderNumber.toString().contains(query) ||
            (header.supplierRef?.supplierName?.toLowerCase().contains(query) ==
                true);
      }).toList();

      emit(
        state.copyWith(
          status: PurchaseOrderStatus.loaded,
          searchQuery: event.query,
          filteredHeaders: filtered,
        ),
      );
    } catch (e) {
      emit(state.errorState('Failed to search purchase orders: $e'));
    }
  }

  void _onClearFilters(
    ClearPurchaseOrderFilters event,
    Emitter<PurchaseOrderState> emit,
  ) {
    emit(
      state.copyWith(
        filteredHeaders: state.headers,
        filteredDetails: state.details,
        dateOrderStart: null,
        dateOrderEnd: null,
        startdateForPO: null,
        thrudateForPO: null,
        purchaseType: null,
        searchQuery: null,
      ),
    );
  }

  // ============ FINANCIAL OPERATIONS ============

  void _onCalculateTotals(
    CalculatePurchaseOrderTotals event,
    Emitter<PurchaseOrderState> emit,
  ) {
    final totalAmount = state.createDetails
        .where((detail) => detail.amountExtendedCost != null)
        .map((detail) => detail.amountExtendedCost!)
        .fold(0.0, (sum, amount) => sum + amount);

    emit(state.copyWith(totalAmount: totalAmount));
  }

  void _onUpdateCreditDueDate(
    UpdateCreditDueDate event,
    Emitter<PurchaseOrderState> emit,
  ) {
    if (event.paymentTerm != null && event.transactionDate != null) {
      final dueDate = event.transactionDate!.add(
        Duration(days: event.paymentTerm!),
      );
      emit(state.copyWith(creditDueDate: dueDate));
    }
  }

  Future<void> _onCalculateTaxesAndFees(
    CalculateTaxesAndFees event,
    Emitter<PurchaseOrderState> emit,
  ) async {
    try {
      final subtotal = state.totalAmount ?? 0.0;

      final discount = state.selectedHeader?.amountDiscount ?? 0.0;
      final otherCosts = state.selectedHeader?.amountOtherCosts ?? 0.0;
      final grossAmount = subtotal - discount;
      final grandTotal = grossAmount + otherCosts;

      emit(
        state.copyWith(
          totalAmount: subtotal,
          amountGross: grossAmount,
          amountGrandTotalCost: grandTotal,
        ),
      );
    } catch (e) {
      emit(state.errorState('Failed to calculate fees: $e'));
    }
  }

  Future<void> _onUpdateAmounts(
    UpdatePurchaseOrderAmounts event,
    Emitter<PurchaseOrderState> emit,
  ) async {
    try {
      if (state.selectedHeader?.id != null) {
        await repository.updateHeaderAmounts(state.selectedHeader!.id!);

        // Reload header
        final updatedHeader = await repository.getHeaderById(
          state.selectedHeader!.id!,
        );
        if (updatedHeader != null) {
          emit(state.copyWith(selectedHeader: updatedHeader));
        }
      }
    } catch (e) {
      emit(state.errorState('Failed to update purchase order amounts: $e'));
    }
  }

  // ============ SELECTION MANAGEMENT ============

  void _onSelectPurchaseOrder(
    SelectPurchaseOrder event,
    Emitter<PurchaseOrderState> emit,
  ) {
    emit(
      state.copyWith(
        selectedHeader: event.header,
        selectedHeader1: event.header,
      ),
    );
  }

  void _onSelectMultiplePurchaseOrders(
    SelectMultiplePurchaseOrders event,
    Emitter<PurchaseOrderState> emit,
  ) {
    emit(state.copyWith(multiselectionHeaders: event.headers));
  }

  void _onClearSelection(
    ClearPurchaseOrderSelection event,
    Emitter<PurchaseOrderState> emit,
  ) {
    emit(
      state.copyWith(
        multiselectionHeaders: const [],
        multiselectionDetails: const [],
        multiselectionReceivers: const [],
      ),
    );
  }

  // ============ UI STATE MANAGEMENT ============

  void _onCancelUpdate(
    CancelPurchaseOrderUpdate event,
    Emitter<PurchaseOrderState> emit,
  ) {
    emit(
      state.copyWith(
        selectedHeader1: null,
        editHeaders: const [],
        editDetails: const [],
        editReceivers: const [],
      ),
    );
  }

  void _onCancelCreate(
    CancelPurchaseOrderCreate event,
    Emitter<PurchaseOrderState> emit,
  ) {
    emit(
      state.copyWith(
        selectedHeader: null,
        createHeaders: const [],
        createDetails: const [],
        selectedDetail: null,
        editReceivers: const [],
        selectedReceiver: null,
      ),
    );
  }

  void _onDiscardChanges(
    DiscardPurchaseOrderChanges event,
    Emitter<PurchaseOrderState> emit,
  ) {
    final unsavedHeaders = state.createHeaders
        .where((item) => item.id == null)
        .toList();

    if (unsavedHeaders.isNotEmpty) {
      final updatedCreateHeaders = state.createHeaders
          .where((item) => item.id != null)
          .toList();

      emit(
        state.copyWith(
          createHeaders: updatedCreateHeaders,
          selectedHeader: updatedCreateHeaders.isNotEmpty
              ? updatedCreateHeaders.first
              : null,
          createDetails: const [],
          editReceivers: const [],
          successMessage: 'All unsaved records are removed',
        ),
      );
    } else {
      emit(state.copyWith(successMessage: 'No unsaved records to remove'));
    }
  }

  Future<void> _onSaveAndContinue(
    SavePurchaseOrderAndContinue event,
    Emitter<PurchaseOrderState> emit,
  ) async {
    await _onSavePurchaseOrder(SavePurchaseOrder(), emit);

    // Continue with the same header
    emit(state.copyWith(createDetails: const [], editReceivers: const []));
  }

  Future<void> _onSaveAndAddNew(
    SavePurchaseOrderAndAddNew event,
    Emitter<PurchaseOrderState> emit,
  ) async {
    await _onSavePurchaseOrder(SavePurchaseOrder(), emit);

    // Prepare new purchase order
    if (state.companyId != null) {
      add(
        PrepareCreatePurchaseOrder(
          companyId: state.companyId ?? authBloc.state.companyId!,
        ),
      );
    }
  }

  void _onPrepareCreateInCreate(
    PrepareCreateInCreate event,
    Emitter<PurchaseOrderState> emit,
  ) {
    final newHeader = PurchaseOrderHeader(
      tempId: _getNextHeaderTempId(state.createHeaders),
      company: state.companyId,
      dateTransaction: DateTime.now(),
      userId: state.userId,
      dateUpdated: DateTime.now(),
    );

    emit(
      state.copyWith(
        createHeaders: [...state.createHeaders, newHeader],
        selectedHeader: newHeader,
        selectedHeader1: newHeader,
      ),
    );
  }

  void _onPrepareCreateInEdit(
    PrepareCreateInEdit event,
    Emitter<PurchaseOrderState> emit,
  ) {
    final newHeader = PurchaseOrderHeader(
      tempId: _getNextHeaderTempId(state.editHeaders),
      company: state.companyId,
      dateTransaction: DateTime.now(),
      userId: state.userId,
      dateUpdated: DateTime.now(),
    );

    emit(
      state.copyWith(
        editHeaders: [...state.editHeaders, newHeader],
        selectedHeader: newHeader,
        selectedHeader1: newHeader,
      ),
    );
  }

  void _onReset(
    ResetPurchaseOrderSettings event,
    Emitter<PurchaseOrderState> emit,
  ) {
    emit(
      state.copyWith(
        status: PurchaseOrderStatus.loaded,
        selectedReceiver: null,
        selectedDetail: null,
        selectedHeader: null,
        selectedHeader1: null,
      ),
    );
  }

  // ============ UTILITY OPERATIONS ============

  Future<void> _onGenerateNextOrderNumber(
    GenerateNextOrderNumber event,
    Emitter<PurchaseOrderState> emit,
  ) async {
    try {
      final nextNumber = await repository.getNextOrderNumber(event.companyId);
      emit(state.copyWith(nextOrderNumber: nextNumber));
    } catch (e) {
      // Silently fail, default to 1
      emit(state.copyWith(nextOrderNumber: 1));
      print('Failed to generate next order number: $e');
    }
  }

  void _onRefreshPurchaseOrders(
    RefreshPurchaseOrders event,
    Emitter<PurchaseOrderState> emit,
  ) {
    if (state.companyId != null) {
      add(
        LoadPurchaseOrders(
          companyId: state.companyId ?? authBloc.state.companyId!,
        ),
      );
      add(
        LoadPurchaseOrderCredit(
          companyId: state.companyId ?? authBloc.state.companyId!,
        ),
      );
    }
  }

  void _onRefreshList(
    RefreshPurchaseOrderList event,
    Emitter<PurchaseOrderState> emit,
  ) {
    emit(
      state.copyWith(
        headers: const [],
        creditHeaders: const [],
        details: const [],
        receivers: const [],
        selectedHeader: null,
        selectedHeader2: null,
        dateOrderStart: null,
        dateOrderEnd: null,
        startdateForPO: null,
        thrudateForPO: null,
        supplierId: null,
        invoiceNumber: null,
      ),
    );
  }

  Future<void> _onGetStatistics(
    GetPurchaseOrderStatistics event,
    Emitter<PurchaseOrderState> emit,
  ) async {
    emit(state.loadingState('get_purchase_order_statistics'));

    try {
      final statistics = await repository.getPurchaseOrderStatistics(
        companyId: state.companyId!,
        startDate: event.startDate,
        endDate: event.endDate,
      );

      emit(
        state.copyWith(
          status: PurchaseOrderStatus.loaded,
          statistics: statistics,
        ),
      );
    } catch (e) {
      emit(state.errorState('Failed to get purchase order statistics: $e'));
    }
  }

  Future<void> _onGetAgingReport(
    GetPurchaseOrderAgingReport event,
    Emitter<PurchaseOrderState> emit,
  ) async {
    emit(state.loadingState('get_purchase_order_aging_report'));

    try {
      final agingReport = await repository.getPurchaseOrderAgingReport(
        companyId: state.companyId!,
        asOfDate: event.asOfDate,
      );

      emit(
        state.copyWith(
          status: PurchaseOrderStatus.loaded,
          agingReport: agingReport,
        ),
      );
    } catch (e) {
      emit(state.errorState('Failed to get purchase order aging report: $e'));
    }
  }

  Future<void> _onGetSupplierSummary(
    GetSupplierPurchaseSummary event,
    Emitter<PurchaseOrderState> emit,
  ) async {
    emit(state.loadingState('get_supplier_purchase_summary'));

    try {
      final supplierSummary = await repository.getSupplierPurchaseSummary(
        companyId: state.companyId!,
        startDate: event.startDate,
        endDate: event.endDate,
      );

      emit(
        state.copyWith(
          status: PurchaseOrderStatus.loaded,
          supplierSummary: supplierSummary,
        ),
      );
    } catch (e) {
      emit(state.errorState('Failed to get supplier purchase summary: $e'));
    }
  }

  // ============ BATCH OPERATIONS ============

  Future<void> _onDeleteMultipleOrders(
    DeleteMultiplePurchaseOrders event,
    Emitter<PurchaseOrderState> emit,
  ) async {
    emit(state.loadingState('delete_multiple_purchase_orders'));

    try {
      final idsToDelete = event.headers
          .map((h) => h.id)
          .whereType<int>()
          .toList();

      if (idsToDelete.isNotEmpty) {
        await repository.deletePurchaseOrderHeadersBatch(idsToDelete);
      }

      final updatedHeaders = state.headers
          .where((h) => !idsToDelete.contains(h.id))
          .toList();
      final updatedFilteredHeaders = state.filteredHeaders
          .where((h) => !idsToDelete.contains(h.id))
          .toList();

      emit(
        state.copyWith(
          status: PurchaseOrderStatus.success,
          headers: updatedHeaders,
          filteredHeaders: updatedFilteredHeaders,
          multiselectionHeaders: const [],
          successMessage:
              '${idsToDelete.length} purchase orders deleted successfully',
        ),
      );
    } catch (e) {
      emit(state.errorState('Failed to delete multiple purchase orders: $e'));
    }
  }

  Future<void> _onSaveMultipleOrders(
    SaveMultiplePurchaseOrders event,
    Emitter<PurchaseOrderState> emit,
  ) async {
    emit(state.loadingState('save_multiple_purchase_orders'));

    try {
      for (final header in event.headers) {
        if (header.id == null) {
          await repository.createPurchaseOrderHeader(header);
        } else {
          await repository.updatePurchaseOrderHeader(header);
        }
      }

      emit(
        state.copyWith(
          status: PurchaseOrderStatus.success,
          successMessage:
              '${event.headers.length} purchase orders saved successfully',
          editHeaders: const [],
        ),
      );

      add(RefreshPurchaseOrders());
    } catch (e) {
      //emit(state.errorState('Failed to save multiple purchase orders: $e'));
      print('Failed to save multiple purchase orders: $e');
    }
  }

  Future<void> _onRemoveRecord(
    RemovePurchaseOrderRecord event,
    Emitter<PurchaseOrderState> emit,
  ) async {
    try {
      if (event.detail?.id != null) {
        await repository.deletePurchaseOrderDetail(event.detail!.id!);
      } else if (event.receiver?.id != null) {
        await repository.deletePurchaseOrderReceiver(event.receiver!.id!);
      }

      emit(state.copyWith(successMessage: 'Record removed successfully'));
    } catch (e) {
      emit(state.errorState('Failed to remove record: $e'));
    }
  }

  Future<void> _onRemoveList(
    RemovePurchaseOrderList event,
    Emitter<PurchaseOrderState> emit,
  ) async {
    try {
      if (event.details!.isNotEmpty) {
        final ids = event.details!.map((d) => d.id).whereType<int>().toList();
        await repository.deletePurchaseOrderDetailBatch(ids);
      } else if (event.receivers!.isNotEmpty) {
        final ids = event.receivers!.map((r) => r.id).whereType<int>().toList();
        await repository.deletePurchaseOrderReceiverBatch(ids);
      }

      emit(state.copyWith(successMessage: 'Records removed successfully'));
    } catch (e) {
      emit(state.errorState('Failed to remove list: $e'));
    }
  }

  // ============ HELPER METHODS ============

  int _getNextHeaderTempId(List<PurchaseOrderHeader> items) {
    if (items.isEmpty) return 1;
    final maxTempId = items
        .map((e) => e.tempId ?? 0)
        .reduce((a, b) => a > b ? a : b);
    return maxTempId + 1;
  }

  int _getNextDetailTempId(List<PurchaseOrderDetail> items) {
    if (items.isEmpty) return 1;
    final maxTempId = items
        .map((e) => e.tempId ?? 0)
        .reduce((a, b) => a > b ? a : b);
    return maxTempId + 1;
  }

  int _getNextReceiverTempId(List<PurchaseOrderReceiver> items) {
    if (items.isEmpty) return 1;
    final maxTempId = items
        .map((e) => e.tempId ?? 0)
        .reduce((a, b) => a > b ? a : b);
    return maxTempId + 1;
  }

  Future<int?> _getUdcDetailId(String detailCode, String udcHeader) async {
    try {
      final udcDetails = await udcRepository.getUdcDetailsByCode(
        detailCode,
        udcHeader,
      );
      return udcDetails.isNotEmpty ? udcDetails.first.id : null;
    } catch (e) {
      return null;
    }
  }

  DateTime? _calculateCreditDueDate(
    int? paymentTerm,
    DateTime? transactionDate,
  ) {
    if (paymentTerm == null || transactionDate == null) return null;
    return transactionDate.add(Duration(days: paymentTerm));
  }

  Future<int?> _getUserBranchId(int userId) async {
    // This would fetch from user repository
    // For now, return null or a default branch
    return null;
  }

  Future<void> _onSetPurchaseOrderAutoReceipt(
    SetPurchaseOrderAutoReceipt event,
    Emitter<PurchaseOrderState> emit,
  ) async {
    emit(
      state.copyWith(
        autoReceipt: event.autoReceipt,
        receivingDates: event.autoReceipt ? DateTime.now() : null,
      ),
    );
  }
  // ============ CREDIT PAYMENT OPERATIONS ============

  Future<void> _onLoadCreditPayments(
    LoadCreditPayments event,
    Emitter<PurchaseOrderState> emit,
  ) async {
    emit(state.loadingState('load_credit_payments'));

    try {
      final payments = await repository.getCreditPayments(
        companyId: event.companyId,
        poHeaderId: event.poHeaderId,
        startDate: event.startDate,
        endDate: event.endDate,
      );

      emit(
        state.copyWith(
          status: PurchaseOrderStatus.loaded,
          creditPayments: payments,
          filteredCreditPayments: payments,
          error: null,
        ),
      );
    } catch (e) {
      emit(state.errorState('Failed to load credit payments: $e'));
    }
  }

  Future<void> _onPrepareCreditPayment(
    PrepareCreditPayment event,
    Emitter<PurchaseOrderState> emit,
  ) async {
    emit(state.loadingState('prepare_credit_payment'));

    try {
      // Get the purchase order header
      final header = await repository.getHeaderById(event.poHeaderId);
      if (header == null) {
        emit(state.errorState('Purchase order not found'));
        return;
      }

      // Check if there's open credit
      if (header.amountOpenCredit == null || header.amountOpenCredit! <= 0) {
        emit(state.errorState('No open credit available for payment'));
        return;
      }

      // Create new credit payment
      final newPayment = CreditPayment(
        poHeader: header.id,
        paymentAmount: 0.0, // Start with 0, user will enter amount
        datePayment: DateTime.now(),
        company: header.company,
        userId: state.userId,
        dateUpdated: DateTime.now(),
        tempId: _getNextCreditPaymentTempId(state.creditPayments),
      );

      emit(
        state.copyWith(
          selectedCreditPayment: newPayment,
          creditPaymentSuccess: null,
          creditPaymentError: null,
        ),
      );
    } catch (e) {
      emit(state.errorState('Failed to prepare credit payment: $e'));
    }
  }

  Future<void> _onUpdateCreditPayment(
    UpdateCreditPayment event,
    Emitter<PurchaseOrderState> emit,
  ) async {
    emit(state.copyWith(selectedCreditPayment: event.payment));
  }

  // MAIN CREDIT PAYMENT SAVE FUNCTION (Based on Java logic)
  Future<void> _onSaveCreditPayment(
    SaveCreditPayment event,
    Emitter<PurchaseOrderState> emit,
  ) async {
    emit(state.loadingState('save_credit_payment'));

    try {
      final payment = event.payment;

      // Validate payment amount (from Java logic)
      if (payment.paymentAmount! <= 0.0) {
        emit(
          state.copyWith(
            creditPaymentError: 'Payment amount must be greater than 0',
            creditPaymentSuccess: false,
          ),
        );
        return;
      }

      // Get the purchase order header
      final header = await repository.getHeaderById(payment.poHeader!);
      if (header == null) {
        emit(
          state.copyWith(
            creditPaymentError: 'Purchase order header not found',
            creditPaymentSuccess: false,
          ),
        );
        return;
      }

      // Calculate remaining amount (from Java logic)
      final amountRemain =
          (header.amountOpenCredit ?? 0.0) - payment.paymentAmount!;

      // Validate payment amount doesn't exceed open credit
      if (amountRemain < 0) {
        emit(
          state.copyWith(
            creditPaymentError: 'Payment amount exceeds open credit',
            creditPaymentSuccess: false,
          ),
        );
        return;
      }

      // If payment is new (id == null), create it
      if (payment.id == null) {
        // Create credit payment record
        final paymentId = await repository.createCreditPayment(payment);
        final savedPayment = payment.copyWith(id: paymentId);

        // Update purchase order header (from Java logic)
        final updatedHeader = header.copyWith(
          amountOpenCredit: amountRemain,
          paymentStatus: amountRemain == 0.0
              ? await _getUdcDetailId('P', 'PS') // Paid
              : await _getUdcDetailId('S', 'PS'), // Partially Paid
          dateUpdated: DateTime.now(),
        );

        // Save updated header
        await repository.updatePurchaseOrderHeader(updatedHeader);

        // Update state with new lists
        final updatedHeaders = state.headers
            .map((h) => h.id == updatedHeader.id ? updatedHeader : h)
            .toList();

        final updatedFilteredHeaders = state.filteredHeaders
            .map((h) => h.id == updatedHeader.id ? updatedHeader : h)
            .toList();

        final updatedCreditPayments = [...state.creditPayments, savedPayment];
        final updatedFilteredCreditPayments = [
          ...state.filteredCreditPayments,
          savedPayment,
        ];

        emit(
          state.copyWith(
            status: PurchaseOrderStatus.success,
            headers: updatedHeaders,
            filteredHeaders: updatedFilteredHeaders,
            selectedHeader: updatedHeader,
            selectedHeader1: updatedHeader,
            creditPayments: updatedCreditPayments,
            filteredCreditPayments: updatedFilteredCreditPayments,
            selectedCreditPayment: savedPayment,
            creditPaymentSuccess: true,
            creditPaymentError: null,
            successMessage: 'Credit payment saved successfully',
          ),
        );

        // Refresh credit payments list
        add(LoadCreditPayments(companyId: event.companyId));
      } else {
        // For existing payments, just update (though typically payments shouldn't be edited)
        await repository.updateCreditPayment(payment);

        emit(
          state.copyWith(
            creditPaymentSuccess: true,
            creditPaymentError: null,
            successMessage: 'Credit payment updated successfully',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          //creditPaymentError: 'Failed to save credit payment: $e',
          creditPaymentSuccess: false,
        ),
      );
      print('Failed to save credit payment: $e');
    }
  }

  Future<void> _onDeleteCreditPayment(
    DeleteCreditPayment event,
    Emitter<PurchaseOrderState> emit,
  ) async {
    emit(state.loadingState('delete_credit_payment'));

    try {
      // Get payment details first
      final payment = state.creditPayments.firstWhere(
        (p) => p.id == event.paymentId,
        orElse: () => throw Exception('Payment not found'),
      );

      // Get header to restore credit amount
      final header = await repository.getHeaderById(payment.poHeader!);
      if (header != null) {
        // Restore the payment amount to open credit
        final restoredAmount =
            (header.amountOpenCredit ?? 0.0) + payment.paymentAmount!;

        // Update payment status (may need to revert to partial or not paid)
        int? newPaymentStatus;
        if (restoredAmount == (header.amountGrandTotalCost ?? 0.0)) {
          // All credit restored, back to not paid
          newPaymentStatus = await _getUdcDetailId('N', 'PS');
        } else if (restoredAmount > 0) {
          // Partial credit restored, back to partially paid
          newPaymentStatus = await _getUdcDetailId('S', 'PS');
        }

        final updatedHeader = header.copyWith(
          amountOpenCredit: restoredAmount,
          paymentStatus: newPaymentStatus,
          dateUpdated: DateTime.now(),
        );

        await repository.updatePurchaseOrderHeader(updatedHeader);

        // Update state headers
        final updatedHeaders = state.headers
            .map((h) => h.id == updatedHeader.id ? updatedHeader : h)
            .toList();

        final updatedFilteredHeaders = state.filteredHeaders
            .map((h) => h.id == updatedHeader.id ? updatedHeader : h)
            .toList();

        emit(
          state.copyWith(
            headers: updatedHeaders,
            filteredHeaders: updatedFilteredHeaders,
            selectedHeader: state.selectedHeader?.id == updatedHeader.id
                ? updatedHeader
                : state.selectedHeader,
          ),
        );
      }

      // Delete the payment
      await repository.deleteCreditPayment(event.paymentId);

      // Update state
      final updatedPayments = state.creditPayments
          .where((p) => p.id != event.paymentId)
          .toList();

      final updatedFilteredPayments = state.filteredCreditPayments
          .where((p) => p.id != event.paymentId)
          .toList();

      emit(
        state.copyWith(
          status: PurchaseOrderStatus.success,
          creditPayments: updatedPayments,
          filteredCreditPayments: updatedFilteredPayments,
          selectedCreditPayment:
              state.selectedCreditPayment?.id == event.paymentId
              ? null
              : state.selectedCreditPayment,
          successMessage: 'Credit payment deleted successfully',
        ),
      );
    } catch (e) {
      emit(state.errorState('Failed to delete credit payment: $e'));
    }
  }

  void _onSelectCreditPayment(
    SelectCreditPayment event,
    Emitter<PurchaseOrderState> emit,
  ) {
    emit(state.copyWith(selectedCreditPayment: event.payment));
  }

  Future<void> _onFilterCreditPayments(
    FilterCreditPayments event,
    Emitter<PurchaseOrderState> emit,
  ) async {
    emit(state.loadingState('filter_credit_payments'));

    try {
      final filteredPayments = await repository.filterCreditPayments(
        companyId: event.companyId,
        supplierId: event.supplierId,
        startDate: event.startDate,
        endDate: event.endDate,
        referenceNumber: event.referenceNumber,
      );

      emit(
        state.copyWith(
          status: PurchaseOrderStatus.loaded,
          filteredCreditPayments: filteredPayments,
        ),
      );
    } catch (e) {
      emit(state.errorState('Failed to filter credit payments: $e'));
    }
  }

  // ============================================================================
  // PURCHASE TRANSACTION REPORT EVENT HANDLERS
  // ============================================================================

  Future<void> _onLoadPurchaseTransactionReport(
    LoadPurchaseTransactionReport event,
    Emitter<PurchaseOrderState> emit,
  ) async {
    try {
      emit(state.copyWith(status: PurchaseOrderStatus.loading));

      // Fetch paginated data based on filter view type
      final result = await purchaseOrderReportRepository
          .getPurchaseTransactionReport(
            companyId: event.companyId,
            page: event.page,
            pageSize: event.pageSize,
            supplierId: event.filters.supplierId,
            startDate: event.filters.dateFrom,
            endDate: event.filters.dateTo,
            purchaseType: event.filters.purchaseType,
          );

      // Calculate totals
      final totalsResult = await purchaseOrderReportRepository
          .calculatePurchaseOrderTransactionTotals(
            companyId: event.companyId,
            supplierId: event.filters.supplierId,
            startDate: event.filters.dateFrom,
            endDate: event.filters.dateTo,
            purchaseType: event.filters.purchaseType,
          );

      final totals = PurchaseTransactionTotals(
        totalAmountGross: totalsResult['totalAmountGross'] as double,
        totalGrandAmountGross: totalsResult['totalGrandAmountGross'] as double,
        totalCount: totalsResult['totalCount'] as int,
        currentPage: result['currentPage'] as int,
        totalPages: result['totalPages'] as int,
      );

      emit(
        state.copyWith(
          status: PurchaseOrderStatus.loaded,
          purchaseTransactionReports:
              result['headers'] as List<PurchaseOrderHeader>,
          purchaseTransactionFilters: event.filters,
          purchaseTransactionTotals: totals,
          purchaseTransactionPage: result['currentPage'] as int,
          purchaseTransactionPageSize: event.pageSize,
          purchaseTransactionTotalCount: result['totalCount'] as int,
          purchaseTransactionTotalPages: result['totalPages'] as int,
          hasMorePurchaseTransaction:
              (result['currentPage'] as int) < (result['totalPages'] as int),
        ),
      );
    } catch (e) {
      emit(state.errorState('Failed to load sales transaction report: $e'));
    }
  }

  Future<void> _onLoadMorePurchaseTransactionReport(
    LoadMorePurchaseTransactionReport event,
    Emitter<PurchaseOrderState> emit,
  ) async {
    if (!state.hasMorePurchaseTransaction) return;

    try {
      emit(
        state.copyWith(
          status: PurchaseOrderStatus.loadingMorePurchaseTransactionReport,
        ),
      );
      final nextPage = state.purchaseTransactionPage + 1;
      final filters = state.purchaseTransactionFilters;

      // Fetch next page
      final result = await purchaseOrderReportRepository
          .getPurchaseTransactionReport(
            companyId: state.companyId ?? authBloc.state.companyId!,
            page: nextPage,
            pageSize: state.purchaseTransactionPageSize,
            supplierId: filters.supplierId,
            startDate: filters.dateFrom,
            endDate: filters.dateTo,
            purchaseType: filters.purchaseType,
          );

      emit(
        state.copyWith(
          status: PurchaseOrderStatus.loaded,
          purchaseTransactionReports: [
            ...state.purchaseTransactionReports,
            ...(result['headers'] as List<PurchaseOrderHeader>),
          ],
          purchaseTransactionPage: result['currentPage'] as int,
          hasMorePurchaseTransaction:
              (result['currentPage'] as int) < (result['totalPages'] as int),
        ),
      );
    } catch (e) {
      emit(state.errorState('Failed to load more transactions: $e'));
    }
  }

  Future<void> _onUpdatePurchaseTransactionFilters(
    UpdatePurchaseTransactionReportFilters event,
    Emitter<PurchaseOrderState> emit,
  ) async {
    // Reload data with new filters
    add(
      LoadPurchaseTransactionReport(
        companyId: state.companyId ?? authBloc.state.companyId!,
        page: 1,
        pageSize: state.purchaseTransactionPageSize,
        filters: event.filters,
      ),
    );
  }

  void _onClearPurchaseTransactionFilters(
    ClearPurchaseTransactionReportFilters event,
    Emitter<PurchaseOrderState> emit,
  ) {
    // Reload with empty filters
    add(
      LoadPurchaseTransactionReport(
        companyId: state.companyId ?? authBloc.state.companyId!,
        page: 1,
        pageSize: state.purchaseTransactionPageSize,
        filters: const PurchaseReportFilters(),
      ),
    );
  }

  Future<void> _onExportPurchaseTransactionToExcel(
    ExportPurchaseTransactionReportToExcel event,
    Emitter<PurchaseOrderState> emit,
  ) async {
    try {
      emit(
        state.copyWith(
          status: PurchaseOrderStatus.exportingPurchaseTransactionReport,
        ),
      );

      // TODO: Implement Excel export logic
      // This will be similar to _onExportTransactions but for the report data
      // You'll need to fetch all data (not paginated) and create Excel file

      emit(
        state.copyWith(
          status: PurchaseOrderStatus.loadedPurchaseTransactionReport,
          exportPurchaseTransactionMessage:
              'Excel export functionality coming soon',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: PurchaseOrderStatus.loadedPurchaseTransactionReport,
          exportPurchaseTransactionMessage: 'Failed to export to Excel: $e',
        ),
      );
    }
  }

  Future<void> _onExportPurchaseTransactionToPDF(
    ExportPurchaseTransactionReportToPDF event,
    Emitter<PurchaseOrderState> emit,
  ) async {
    try {
      emit(
        state.copyWith(
          status: PurchaseOrderStatus.exportingPurchaseTransactionReport,
        ),
      );

      // TODO: Implement PDF export logic
      // This will be similar to Excel export but generate PDF

      emit(
        state.copyWith(
          status: PurchaseOrderStatus.loadedPurchaseTransactionReport,
          exportPurchaseTransactionMessage:
              'PDF export functionality coming soon',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: PurchaseOrderStatus.loadedPurchaseTransactionReport,
          exportPurchaseTransactionMessage: 'Failed to export to PDF: $e',
        ),
      );
    }
  }

  // Helper method for temp IDs
  int _getNextCreditPaymentTempId(List<CreditPayment> items) {
    if (items.isEmpty) return 1;
    final maxTempId = items
        .map((e) => e.tempId ?? 0)
        .reduce((a, b) => a > b ? a : b);
    return maxTempId + 1;
  }
}
