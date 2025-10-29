// bloc/sales_order_details/sales_order_details_bloc.dart
import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:savvy_stock/core/repositories/udc_repository.dart';
import 'package:savvy_stock/features/next_number/bloc/next_number_bloc.dart';
import 'package:savvy_stock/features/sales/customer/blocs/customer_bloc.dart';
import 'package:savvy_stock/features/stock/UOM_entry/blocs/UOM_entry_bloc.dart';
import 'package:savvy_stock/features/stock/item_UoM_conversions/blocs/item_UoM_conversions_bloc.dart';
import 'package:savvy_stock/features/stock/item_cost/repo/item_cost_repository.dart';
import 'package:savvy_stock/features/stock/item_in_branch/blocs/item_in_branch_bloc.dart';
import 'package:savvy_stock/features/stock/lot_coloring/bloc/lot_coloring_bloc.dart';
import 'package:savvy_stock/features/stock/lot_master/blocs/lot_master_bloc.dart';
import 'package:savvy_stock/features/stock/sales_order_detail/bloc/sales_order_detail_event.dart';
import 'package:savvy_stock/features/stock/sales_order_detail/bloc/sales_order_detail_state.dart';
import 'package:savvy_stock/features/stock/sales_order_detail/model/sales_order_detail.dart';
import 'package:savvy_stock/features/stock/sales_order_detail/sales_order_detail_repo.dart';
import 'package:savvy_stock/features/stock/sales_order_header/repo/sales_order_header_repo.dart';


class SalesOrderDetailBloc extends Bloc<SalesOrderDetailEvent, SalesOrderDetailState> {
  final SalesOrderDetailRepository repository;
  final SalesOrderHeaderRepository headerRepository;
  final StockItemInBranchBloc itemBranchRepository;
  final LotMasterBloc lotMasterRepository;
  final UdcRepository udcDetailsRepository;
  //final FsTableRepository fsTableRepository;
  final NextNumberBloc nextNumberRepository;
  final CustomerBloc customerTableRepository;
  final InvoiceBloc invoiceHeaderRepository;
  //final InvoiceHistoryDetailRepository invoiceDetailRepository;
  final ItemCostRepository itemCostTableRepository;
  final ItemUomConversionBloc itemUomConversionsRepository;
  final LotExpirationColorsBloc lotExpirationColorsRepository;

  SalesOrderDetailBloc({
    required this.repository,
    required this.headerRepository,
    required this.itemBranchRepository,
    required this.lotMasterRepository,
    required this.udcDetailsRepository,
    //required this.fsTableRepository,
    required this.nextNumberRepository,
    required this.customerTableRepository,
    required this.invoiceHeaderRepository,
  //  required this.invoiceDetailRepository,
    required this.itemCostTableRepository,
    required this.itemUomConversionsRepository,
    required this.lotExpirationColorsRepository,
  }) : super(SalesOrderDetailInitial()) {
    on<SalesOrderDetailLoadEvent>(_onLoad);
    on<SalesOrderDetailPrepareCreateEvent>(_onPrepareCreate);
    on<SalesOrderDetailPrepareCreateAfterCreateEvent>(_onPrepareCreateAfterCreate);
    on<SalesOrderDetailCreateEvent>(_onCreate);
    on<SalesOrderDetailUpdateEvent>(_onUpdate);
    on<SalesOrderDetailDeleteEvent>(_onDelete);
    on<SalesOrderDetailDeleteCollectionEvent>(_onDeleteCollection);
    on<SalesOrderDetailMultiSelectEvent>(_onMultiSelect);
    on<SalesOrderDetailPrepareEditEvent>(_onPrepareEdit);
    on<SalesOrderDetailSetBarcodeEvent>(_onSetBarcode);
   // on<SalesOrderDetailValidateAvailabilityEvent>(_onValidateAvailability);
   // on<SalesOrderDetailSaveEvent>(_onSave);
   // on<SalesOrderDetailSaveRowEvent>(_onSaveRow);
  //  on<SalesOrderDetailReportGenerateEvent>(_onReportGenerate);
  //  on<SalesOrderDetailPrepareInvoiceReviewEvent>(_onPrepareInvoiceReview);
    on<SalesOrderDetailDiscardEvent>(_onDiscard);
  }

  Future<void> _onLoad(
    SalesOrderDetailLoadEvent event,
    Emitter<SalesOrderDetailState> emit,
  ) async {
    emit(SalesOrderDetailLoading());
    try {
      final items = await repository.getAll(event.companyId);
      emit(SalesOrderDetailLoadSuccess(
        items: items,
        createItems: const [],
        editItems: const [],
        multiSelectionItems: const [],
        filteredValues: const [],
        selected2: SalesOrderDetail(
          salesOrderHeaderId: 0,
          itemsTableId: 0,
          quantity: 1.0,
        ),
        availableValidator: {},
        enablePreview: false,
        enableFinishingProcess: false,
        useBarcode: false,
      ));
    } catch (e) {
      emit(SalesOrderDetailError('Failed to load sales order details: $e'));
    }
  }

  Future<void> _onPrepareCreate(
    SalesOrderDetailPrepareCreateEvent event,
    Emitter<SalesOrderDetailState> emit,
  ) async {
    try {
      // Get default customer
    /*  final defaultCustomers = await customerTableRepository.getDefaultCustomers(event.companyId);
      Customer? defaultCustomer;
      if (defaultCustomers.isNotEmpty) {
        defaultCustomer = defaultCustomers.first;
      } */

      // Get next order number
      final orderNumber = await nextNumberRepository.generateFormattedNumber('SO');
      
      // Get order type
      final orderType = await udcDetailsRepository.getLocalUdcDetailsByCode('OT', 'S');

      final newDetails = SalesOrderDetail(
        tempId: 1,
        quantity: 1.0,
        company: event.companyId,
      );

      final createItems = [newDetails];

      emit(SalesOrderDetailLoadSuccess(
        items: state is SalesOrderDetailLoadSuccess ? (state as SalesOrderDetailLoadSuccess).items : [],
        createItems: createItems,
        editItems: const [],
        multiSelectionItems: const [],
        filteredValues: const [],
        selected: newDetails,
        selected1: null,
        selected2: SalesOrderDetail(
          salesOrderHeaderId: 0,
          itemsTableId: 0,
          quantity: 1.0,
        ),
        availableValidator: {},
        enablePreview: false,
        enableFinishingProcess: false,
        useBarcode: false,
      ));

      // Emit event for header creation
      // This would typically be handled by a separate SalesOrderHeaderBloc
    } catch (e) {
      emit(SalesOrderDetailError('Failed to prepare create: $e'));
    }
  }

  Future<void> _onPrepareCreateAfterCreate(
    SalesOrderDetailPrepareCreateAfterCreateEvent event,
    Emitter<SalesOrderDetailState> emit,
  ) async {
    try {
      final newDetails = SalesOrderDetail(
        tempId: 1,
        quantity: 1.0,
        company: event.companyId,
      );

      final createItems = [newDetails];

      if (state is SalesOrderDetailLoadSuccess) {
        final currentState = state as SalesOrderDetailLoadSuccess;
        emit(currentState.copyWith(
          createItems: createItems,
          selected: newDetails,
          selected1: null,
          availableValidator: {},
        ));
      }
    } catch (e) {
      emit(SalesOrderDetailError('Failed to prepare create after create: $e'));
    }
  }

  Future<void> _onCreate(
    SalesOrderDetailCreateEvent event,
    Emitter<SalesOrderDetailState> emit,
  ) async {
    try {
      await repository.create(event.details);
      final items = await repository.getAll(event.details.company!);
      
      emit(SalesOrderDetailOperationSuccess(
        message: 'Successfully created',
        items: items,
        createItems: const [],
      ));
    } catch (e) {
      emit(SalesOrderDetailError('Failed to create: $e'));
    }
  }

  Future<void> _onUpdate(
    SalesOrderDetailUpdateEvent event,
    Emitter<SalesOrderDetailState> emit,
  ) async {
    try {
      await repository.update(event.details);
      final items = await repository.getAll(event.details.company!);
      
      emit(SalesOrderDetailOperationSuccess(
        message: 'Successfully updated',
        items: items,
        createItems: const [],
      ));
    } catch (e) {
      emit(SalesOrderDetailError('Failed to update: $e'));
    }
  }

  Future<void> _onDelete(
    SalesOrderDetailDeleteEvent event,
    Emitter<SalesOrderDetailState> emit,
  ) async {
    try {
      await repository.delete(event.id);
      final currentState = state as SalesOrderDetailLoadSuccess;
      final items = await repository.getAll(currentState.items.first.company!);
      
      emit(currentState.copyWith(items: items));
    } catch (e) {
      emit(SalesOrderDetailError('Failed to delete: $e'));
    }
  }

  Future<void> _onDeleteCollection(
    SalesOrderDetailDeleteCollectionEvent event,
    Emitter<SalesOrderDetailState> emit,
  ) async {
    try {
      await repository.deleteCollection(event.items);
      final currentState = state as SalesOrderDetailLoadSuccess;
      final items = await repository.getAll(currentState.items.first.company!);
      
      emit(currentState.copyWith(items: items));
    } catch (e) {
      emit(SalesOrderDetailError('Failed to delete collection: $e'));
    }
  }

  Future<void> _onMultiSelect(
    SalesOrderDetailMultiSelectEvent event,
    Emitter<SalesOrderDetailState> emit,
  ) async {
    if (state is SalesOrderDetailLoadSuccess) {
      final currentState = state as SalesOrderDetailLoadSuccess;
      emit(currentState.copyWith(multiSelectionItems: event.selectedItems));
    }
  }

  Future<void> _onPrepareEdit(
    SalesOrderDetailPrepareEditEvent event,
    Emitter<SalesOrderDetailState> emit,
  ) async {
    if (state is SalesOrderDetailLoadSuccess) {
      final currentState = state as SalesOrderDetailLoadSuccess;
      emit(currentState.copyWith(
        editItems: event.selectedItems,
        selected: event.selectedItems.isNotEmpty ? event.selectedItems.first : null,
      ));
    }
  }
  Future<void> _onSetBarcode(
    SalesOrderDetailSetBarcodeEvent event,
    Emitter<SalesOrderDetailState> emit,
  ) async {
    try {
      final itemBranchList = await repository.getItemsByBarcode(
        event.barcode,
        event.branchId,
      );
      
      if (itemBranchList.isNotEmpty) {
        if (state is SalesOrderDetailLoadSuccess) {
          final currentState = state as SalesOrderDetailLoadSuccess;
          
          SalesOrderDetail itemToUpdate;
          List<SalesOrderDetail> updatedCreateItems;
          if (currentState.createItems.length == 1 && 
              currentState.createItems[0].itemsTableId == 0) {
            itemToUpdate = currentState.createItems[0].copyWith(
              itemBranch: itemBranchList[0],
              itemsTableId: itemBranchList[0].itemNumber,
              quantity: 1.0,
            );
            
            updatedCreateItems = [itemToUpdate];
            emit(currentState.copyWith(
              createItems: updatedCreateItems,
              selected: itemToUpdate,
              barcode: '',
            ));
          } else {
            itemToUpdate = SalesOrderDetail(
              tempId: _getNextTempId(currentState.createItems),
              itemBranch: itemBranchList[0],
              itemsTableId: itemBranchList[0].itemNumber,
              quantity: 1.0,
              company: event.companyId,
              salesOrderHeaderId: 0,
            );
            
            updatedCreateItems = [...currentState.createItems, itemToUpdate];
            emit(currentState.copyWith(
              createItems: updatedCreateItems,
              selected: itemToUpdate,
              barcode: '',
            ));
          }
          
          // Validate availability for the updated item
          add(SalesOrderDetailValidateAvailabilityEvent(
            item: itemToUpdate,
            createItems: updatedCreateItems,
            companyId: event.companyId,
          ));
        }
      } else {
        emit(SalesOrderDetailError('No items found for barcode: ${event.barcode}'));
      }
    } catch (e) {
      emit(SalesOrderDetailError('Error setting barcode: $e'));
    }
  }

  /*Future<void> _onValidateAvailability(
    SalesOrderDetailValidateAvailabilityEvent event,
    Emitter<SalesOrderDetailState> emit,
  ) async {
    try {
      if (event.item.itemBranch != null) {
        // Calculate total quantity for this item in branch across all create items
        double qtyTotal = 0.0;
        for (final sd in event.createItems) {
          if (sd.itemBranch != null && 
              sd.itemBranch!.id == event.item.itemBranch!.id) {
            final factor = await itemUomConversionsRepository.getConversionFactor(
              sd.itemsTableId,
              sd.unitOfMeasure,
              sd.itemBranch!.unitOfMeasure,
            );
            qtyTotal += factor * (sd.quantity ?? 0.0);
          }
        }

        // Get actual available quantity
        final itemBranchList = await itemBranchRepository.getItemsAvailableByItemAndBranch(
          event.item.itemBranch!.itemNumber,
          event.item.itemBranch!.branch,
        );
        
        double qtyTotalActual = itemBranchList
            .where((k) => k.quantityAvailable != null)
            .map((i) => i.quantityAvailable!)
            .fold(0.0, (sum, element) => sum + element);

        double qExpired = 0.0;

        // Handle lot management if enabled
        // This would require additional system constant checks
        final lotMasters = await repository.getLotMastersForItem(
          event.item.itemBranch!.itemNumber,
          event.item.itemBranch!.branch,
          event.companyId,
        );

        qExpired = lotMasters
            .where((e) => e.quantityAvailable != null)
            .map((e) => e.quantityAvailable!)
            .fold(0.0, (sum, element) => sum + element);

        final available = qtyTotalActual - qtyTotal - qExpired;

        if (state is SalesOrderDetailLoadSuccess) {
          final currentState = state as SalesOrderDetailLoadSuccess;
          final updatedValidator = Map<ItemInBranchModel, double>.from(currentState.availableValidator);
          updatedValidator[event.item.itemBranch!] = available;
          
          emit(currentState.copyWith(availableValidator: updatedValidator));
        }
      }
    } catch (e) {
      emit(SalesOrderDetailError('Error validating availability: $e'));
    }
  }

  Future<void> _onSave(
    SalesOrderDetailSaveEvent event,
    Emitter<SalesOrderDetailState> emit,
  ) async {
    try {
      // Validate quantities and lot management
      bool validationPassed = true;
      double beyondQuantity = 0.0;

      for (final item in event.createItems) {
        final available = event.createItems
            .where((i) => i.itemBranch?.id == item.itemBranch?.id)
            .map((i) => i.quantity ?? 0.0)
            .fold(0.0, (sum, element) => sum + element);

        final actualAvailable = await _getActualAvailableQuantity(item);
        
        if (available > actualAvailable ||
            item.quantity == null ||
            item.quantity! < 0.0 ||
            (event.systemConstant.applyLotMgmBoolean &&
                !event.systemConstant.lotQtyAutoForSalesBoolean &&
                (item.lotNumber == null))) {
          validationPassed = false;
          beyondQuantity = available - actualAvailable;
          break;
        }
      }

      if (!validationPassed) {
        if (state is SalesOrderDetailLoadSuccess) {
          final currentState = state as SalesOrderDetailLoadSuccess;
          emit(SalesOrderDetailValidationError(
            error: 'Quantity Beyond Available (Beyond Quantity is ${beyondQuantity.abs()})!',
            createItems: currentState.createItems,
            availableValidator: currentState.availableValidator,
          ));
        }
        return;
      }

      // Prepare and save sales order header
      final savedHeader = await _saveSalesOrderHeader(
        event.salesOrderHeader,
        event.companyId,
        event.branchId,
        event.fsReference,
      );

      // Save sales order details
      double totalCost = 0.0;
      for (final item in event.createItems) {
        final itemCost = await itemCostTableRepository.findById(item.itemsTableId!);
        final unitCost = itemCost?.amountUnitCost ?? 0.0;
        final amountCost = unitCost * (item.quantity ?? 0.0);
        totalCost += amountCost;

        final itemToSave = item.copyWith(
          salesOrderHeaderId: savedHeader.id!,
          unitCost: unitCost,
          amountCost: amountCost,
          company: event.companyId,
        );

        if (item.id == null) {
          await repository.create(itemToSave);
        } else {
          await repository.update(itemToSave);
        }

        // Update stock availability
       // await itemBranchRepository.updateStockAvailability(itemToSave);
      }

      // Update header with total cost
      final updatedHeader = savedHeader.copyWith(amountCost: totalCost);
      await headerRepository.updateSalesOrderHeader(updatedHeader);

      // Handle proforma conversion if applicable
      if (updatedHeader.proformaFlag == 'Y' && updatedHeader.proformaReference != null) {
        await _convertProformaToSalesOrder(updatedHeader, event.companyId);
      }

      // Prepare for next creation
      add(SalesOrderDetailPrepareCreateAfterCreateEvent(
        companyId: event.companyId,
        userId: event.userId,
        branchId: event.branchId,
      ));

      emit(SalesOrderDetailOperationSuccess(
        message: 'Successfully saved',
        items: await repository.getAll(event.companyId),
        createItems: const [],
      ));

    } catch (e) {
      emit(SalesOrderDetailError('Failed to save: $e'));
    }
  }

  Future<void> _onSaveRow(
    SalesOrderDetailSaveRowEvent event,
    Emitter<SalesOrderDetailState> emit,
  ) async {
    try {
      for (final item in event.editItems) {
        if (item.id == null) {
          await repository.create(item);
        } else {
          await repository.update(item);
        }
      }

      emit(SalesOrderDetailOperationSuccess(
        message: 'Saved',
        items: const [],
        createItems: const [],
      ));
    } catch (e) {
      emit(SalesOrderDetailError('Failed to save row: $e'));
    }
  }

  Future<void> _onReportGenerate(
    SalesOrderDetailReportGenerateEvent event,
    Emitter<SalesOrderDetailState> emit,
  ) async {
    try {
      final invoiceHeaders = await invoiceHeaderRepository.getBySalesNumber(
        event.salesHeader.id!,
        event.companyId,
      );

      if (invoiceHeaders.isNotEmpty) {
        final invoiceDetails = await invoiceDetailRepository.getByInvoiceHistory(
          invoiceHeaders.first.id!,
          event.companyId,
        );

        emit(SalesOrderDetailReportGenerated(
          invoiceHeader: invoiceHeaders.first,
          invoiceDetails: invoiceDetails,
        ));
      } else {
        emit(SalesOrderDetailReportGenerated(
          invoiceHeader: null,
          invoiceDetails: const [],
        ));
      }
    } catch (e) {
      emit(SalesOrderDetailError('Failed to generate report: $e'));
    }
  }
*/
/*  Future<void> _onPrepareInvoiceReview(
    SalesOrderDetailPrepareInvoiceReviewEvent event,
    Emitter<SalesOrderDetailState> emit,
  ) async {
    try {
      // Validate lot management
      bool lotValidationPassed = true;
      if (event.systemConstant.applyLotMgmBoolean &&
          !event.systemConstant.lotQtyAutoForSalesBoolean) {
        for (final soD in event.createItems) {
          if (soD.lotNumber == null ||
              soD.quantity == null ||
              (soD.lot?.quantityAvailable ?? 0) < soD.quantity!) {
            lotValidationPassed = false;
            break;
          }
        }
      }

      if (!lotValidationPassed) {
        emit(SalesOrderDetailError('Lot/Batch Quantity is Not Correct!'));
        return;
      }

      // Prepare invoice header
      final invoiceHeader = await _prepareInvoiceHeader(
        event.salesOrderHeader,
        event.companyId,
        event.branchId,
        event.cityDesc,
        event.countryDesc,
        event.phoneNumbers,
        event.regionDesc,
        event.tinNumber,
        event.totalAmount,
        event.subTotal,
        event.fsReference,
      );

      // Prepare invoice details
      final invoiceDetails = await _prepareInvoiceDetails(
        event.createItems,
        event.companyId,
      );

      emit(SalesOrderDetailInvoicePrepared(
        invoiceHeader: invoiceHeader,
        invoiceDetails: invoiceDetails,
        enableFinishingProcess: false,
      ));

    } catch (e) {
      emit(SalesOrderDetailError('Failed to prepare invoice review: $e'));
    }
  }
*/


  Future<void> _onDiscard(
    SalesOrderDetailDiscardEvent event,
    Emitter<SalesOrderDetailState> emit,
  ) async {
    if (state is SalesOrderDetailLoadSuccess) {
      final currentState = state as SalesOrderDetailLoadSuccess;
      
      // Remove items that have IDs from database
      final itemsWithIds = currentState.createItems.where((item) => item.id != null).toList();
      if (itemsWithIds.isNotEmpty) {
        await repository.deleteCollection(itemsWithIds);
      }
      
      emit(currentState.copyWith(
        createItems: const [],
        selected: null,
      ));
    }
  }



  // Helper methods
  int _getNextTempId(List<SalesOrderDetail> items) {
    int maxTempId = 0;
    for (final item in items) {
      if (item.tempId != null && item.tempId! > maxTempId) {
        maxTempId = item.tempId!;
      }
    }
    return maxTempId + 1;
  }

 /* Future<double> _getActualAvailableQuantity(SalesOrderDetail item) async {
    if (item.itemBranch == null) return 0.0;
    
    final items = await itemBranchRepository.getItemsAvailableByItemAndBranch(
      item.itemBranch!.itemNumber!.id!,
      item.itemBranch!.branch!.id!,
    );
    
    return items
        .where((k) => k.quantityAvailable != null)
        .map((i) => i.quantityAvailable!)
        .fold(0.0, (sum, element) => sum + element);
  }

  Future<SalesOrderHeader> _saveSalesOrderHeader(
    SalesOrderHeader header,
    int companyId,
    int branchId,
    String? fsReference,
  ) async {
    // Set FS number if not provided
    if (fsReference == null || fsReference.isEmpty) {
      final fsTables = await fsTableRepository.getByBranch(branchId, companyId);
      if (fsTables.isNotEmpty) {
        header = header.copyWith(
          fsNumber: fsTables.first.fsNumber?.toString().padLeft(8, '0'),
          referenceNote1: fsTables.first.mrcNumber ?? fsTables.first.branch?.description,
        );
        
        // Increment FS number
        final updatedFs = fsTables.first.copyWith(
          fsNumber: (fsTables.first.fsNumber ?? 0) + 1,
        );
        await fsTableRepository.update(updatedFs);
      }
    } else {
      header = header.copyWith(
        fsNumber: fsReference,
        referenceNote1: fsReference,
      );
    }

    header = header.copyWith(
      salesType: header.salesType ?? 'Cash',
      requiredDate: DateTime.now(),
      company: companyId,
    );

    if (header.id == null) {
      return await headerRepository.createSalesOrderHeader(header);
    } else {
      await headerRepository.update(header);
      return header;
    }
  }

  Future<void> _convertProformaToSalesOrder(
    SalesOrderHeader salesHeader,
    int companyId,
  ) async {
    final quoteHeaders = await headerRepository.getByFsNumber(
      salesHeader.proformaReference!,
      companyId,
    );

    for (final quoteHeader in quoteHeaders) {
      final updatedQuote = quoteHeader.copyWith(
        conversionStatus: 'Converted',
        referenceNote3: salesHeader.fsNumber,
        conversionDate: salesHeader.orderDate,
      );
      await headerRepository.update(updatedQuote);
    }
  }

  Future<InvoiceHistoryHeader> _prepareInvoiceHeader(
    SalesOrderHeader salesHeader,
    int companyId,
    int branchId,
    String? cityDesc,
    String? countryDesc,
    String? phoneNumbers,
    String? regionDesc,
    String? tinNumber,
    double? totalAmount,
    double? subTotal,
    String? fsReference,
  ) async {
    String fsNumber;
    String mrcNumber;

    if (fsReference == null || fsReference.isEmpty) {
      final fsTables = await fsTableRepository.getByBranch(branchId, companyId);
      if (fsTables.isNotEmpty) {
        fsNumber = (fsTables.first.fsNumber ?? 0).toString().padLeft(8, '0');
        mrcNumber = fsTables.first.mrcNumber ?? fsTables.first.branch?.description ?? '';
      } else {
        fsNumber = '00000000';
        mrcNumber = '';
      }
    } else {
      fsNumber = fsReference;
      mrcNumber = fsReference;
    }

    return InvoiceHistoryHeader(
      fsNumber: fsNumber,
      mrcNumber: mrcNumber,
      customerName: salesHeader.customerBillTo?.customerName,
      dateTransaction: salesHeader.orderDate,
      city: cityDesc,
      country: countryDesc,
      phoneNumber: phoneNumbers,
      region: regionDesc,
      tinNumber: tinNumber ?? salesHeader.customerBillTo?.tinNumber,
      taxAmount: salesHeader.tax,
      totalAmount: totalAmount,
      withholdAmount: salesHeader.withholdAmount,
      amountBeforeTax: subTotal,
      discountAmount: salesHeader.discountAmount,
      salesPerson: '${salesHeader.employeesIdObj?.nameFirst} ${salesHeader.employeesIdObj?.nameMiddle} ${salesHeader.employeesIdObj?.nameLast}',
      company: companyId,
    );
  }

  Future<List<InvoiceHistoryDetail>> _prepareInvoiceDetails(
    List<SalesOrderDetail> createItems,
    int companyId,
  ) async {
    final Map<String, InvoiceHistoryDetail> itemMap = {};

    for (final sD in createItems) {
      final itemDescription = sD.itemsTableIdObj?.itemDescritpion;
      final unitPrice = sD.unitPrice;

      if (itemDescription == null || unitPrice == null) continue;

      final key = '$itemDescription-$unitPrice';

      if (itemMap.containsKey(key)) {
        final existing = itemMap[key]!;
        itemMap[key] = existing.copyWith(
          quantityTransaction: existing.quantityTransaction + (sD.quantity ?? 0.0),
          amountExtendedPrice: existing.amountExtendedPrice + (sD.extendedPrice ?? 0.0),
        );
      } else {
        itemMap[key] = InvoiceHistoryDetail(
          item: itemDescription,
          quantityTransaction: sD.quantity ?? 0.0,
          amountUnitPrice: unitPrice,
          amountExtendedPrice: sD.extendedPrice ?? 0.0,
          unitOfMeasure: sD.unitOfMeasureObj?.description1 ?? '',
          company: companyId,
        );
      }
    }

    return itemMap.values.toList();
  }
  */
}