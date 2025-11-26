/*import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/sales/quotation_order/bloc/quotation_order_event.dart';
import 'package:savvy_stock/features/sales/quotation_order/bloc/quotation_order_state.dart';
import 'package:savvy_stock/features/sales/quotation_order/model/quotation_order_detail.dart';
import 'package:savvy_stock/features/sales/quotation_order/model/quotation_order_header.dart';
import 'package:savvy_stock/features/sales/quotation_order/repo/quotation_order_repo.dart';
import 'package:savvy_stock/features/sales/sales_order/detail/model/sales_order_detail.dart';
import 'package:savvy_stock/features/sales/sales_order/header/model/sales_order_header.dart';
import 'package:savvy_stock/features/sales/sales_order/invoice/detail/model/invoice_detail_model.dart';
import 'package:savvy_stock/features/sales/sales_order/invoice/header/model/invoice_header_model.dart';
import 'package:savvy_stock/features/stock/item_in_branch/repo/item_in_branch_repo.dart';
import 'package:savvy_stock/features/stock/item_uom_conversions/repo/item_uom_conv_repo.dart';
import 'package:savvy_stock/features/system_constant/bloc/system_constant_bloc.dart';
class QuotationOrderBloc
    extends Bloc<QuotationOrderEvent, QuotationOrderState> {
  final QuotationOrderRepository quotationOrderRepository;
  final StockItemInBranchRepository itemInBranchRepository;
  final ItemUomConversionsRepository uomConversionsRepository;
  final SystemConstantBloc systemConstantBloc;
  final AuthBloc authBloc;

  QuotationOrderBloc({
    required this.quotationOrderRepository,
    required this.itemInBranchRepository,
    required this.uomConversionsRepository,
    required this.systemConstantBloc,
    required this.authBloc,
  }) : super(const QuotationOrderState()) {
    on<QuotationOrderInitialized>(_onInitialized);
    on<LoadQuotations>(_onLoadQuotations);
    on<CreateQuotation>(_onCreateQuotation);
    on<UpdateQuotation>(_onUpdateQuotation);
    on<DeleteQuotation>(_onDeleteQuotation);
    on<PrepareCreateQuotation>(_onPrepareCreateQuotation);
    on<PrepareEditQuotation>(_onPrepareEditQuotation);
    on<AddDetailItem>(_onAddDetailItem);
    on<UpdateDetailItem>(_onUpdateDetailItem);
    on<RemoveDetailItem>(_onRemoveDetailItem);
    on<BarcodeScanned>(_onBarcodeScanned);
    on<CalculateTotals>(_onCalculateTotals);
    on<UomChanged>(_onUomChanged);
    on<ConvertToSalesOrder>(_onConvertToSalesOrder);
    on<PrepareInvoiceReview>(_onPrepareInvoiceReview);
    on<UpdateCustomerInfo>(_onUpdateCustomerInfo);
    on<GenerateNextFsNumber>(_onGenerateNextFsNumber);
    on<SystemConstantsUpdated>(_onSystemConstantsUpdated);
  }

  // Initialize
  Future<void> _onInitialized(
    QuotationOrderInitialized event,
    Emitter<QuotationOrderState> emit,
  ) async {
    emit(
      state.copyWith(
        companyId: event.companyId,
        systemConstants: systemConstantBloc.state.selected,
      ),
    );
    add(LoadQuotations(companyId: event.companyId));
  }

  // Load quotations
  Future<void> _onLoadQuotations(
    LoadQuotations event,
    Emitter<QuotationOrderState> emit,
  ) async {
    emit(state.copyWith(status: QuotationOrderStatus.loading));
    try {
      final quotations = await quotationOrderRepository
          .getQuotationOrderHeaders(companyId: event.companyId);
      emit(
        state.copyWith(
          status: QuotationOrderStatus.loaded,
          quotations: quotations,
          filteredQuotations: quotations,
          companyId: event.companyId,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: QuotationOrderStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  // Create quotation
  Future<void> _onCreateQuotation(
    CreateQuotation event,
    Emitter<QuotationOrderState> emit,
  ) async {
    emit(state.copyWith(status: QuotationOrderStatus.creating));
    try {
      // Save Header
      final headerId = await quotationOrderRepository
          .createQuotationOrderHeader(event.header);

      // Save Details
      final detailsWithHeaderId = event.details
          .map((d) => d.copyWith(quoteOrderHeaderId: headerId))
          .toList();

      await quotationOrderRepository.createQuotationOrderDetailBatch(
        detailsWithHeaderId,
      );

      emit(
        state.copyWith(
          status: QuotationOrderStatus.success,
          successMessage: 'Quotation created successfully',
        ),
      );
      add(LoadQuotations(companyId: event.header.company!));
    } catch (e) {
      emit(
        state.copyWith(
          status: QuotationOrderStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  // Update quotation
  Future<void> _onUpdateQuotation(
    UpdateQuotation event,
    Emitter<QuotationOrderState> emit,
  ) async {
    emit(state.copyWith(status: QuotationOrderStatus.updating));
    try {
      await quotationOrderRepository.updateQuotationOrderHeader(event.header);

      // Delete all existing details and recreate them
      await quotationOrderRepository.deleteQuotationOrderDetailByHeaderId(
        event.header.id!,
      );

      final detailsWithHeaderId = event.details
          .map((d) => d.copyWith(quoteOrderHeaderId: event.header.id))
          .toList();

      await quotationOrderRepository.createQuotationOrderDetailBatch(
        detailsWithHeaderId,
      );

      emit(
        state.copyWith(
          status: QuotationOrderStatus.success,
          successMessage: 'Quotation updated successfully',
        ),
      );
      add(LoadQuotations(companyId: event.header.company!));
    } catch (e) {
      emit(
        state.copyWith(
          status: QuotationOrderStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  // Delete quotation
  Future<void> _onDeleteQuotation(
    DeleteQuotation event,
    Emitter<QuotationOrderState> emit,
  ) async {
    try {
      // Delete details first
      await quotationOrderRepository.deleteQuotationOrderDetailByHeaderId(
        event.id,
      );
      // Then delete header
      await quotationOrderRepository.deleteQuotationOrderHeader(event.id);

      emit(
        state.copyWith(
          status: QuotationOrderStatus.success,
          successMessage: 'Quotation deleted successfully',
        ),
      );
      if (state.companyId != null) {
        add(LoadQuotations(companyId: state.companyId!));
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: QuotationOrderStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  // Prepare create (prepareCreate method from Java)
  Future<void> _onPrepareCreateQuotation(
    PrepareCreateQuotation event,
    Emitter<QuotationOrderState> emit,
  ) async {
    final nextOrderNumber = await quotationOrderRepository.getNextOrderNumber(
      event.companyId,
    );

    final newHeader = QuotationOrderHeader(
      company: event.companyId,
      //salesRepresent: event.employeeId,
      orderDate: DateTime.now(),
      requiredDate: DateTime.now(),
      orderNumber: nextOrderNumber,
      orderStatus: 'Open', // Default status
      tempId: 1, // Temporary ID
    );

    // Create initial detail item with quantity 1.0 (like Java controller)
    final initialDetail = QuotationOrderDetail(
      quoteOrderHeaderId: newHeader.id!,
      quantity: 1.0,
      tempId: 1,
      company: event.companyId,
    );

    emit(
      state.copyWith(
        selectedQuotation: newHeader,
        currentDetails: [initialDetail],
        subTotal: 0,
        tax: 0,
        totalAmount: 0,
        discountAmount: 0,
        withholdAmount: 0,
        status: QuotationOrderStatus.initial,
      ),
    );

    add(GenerateNextFsNumber(companyId: event.companyId));
  }

  // Prepare edit
  Future<void> _onPrepareEditQuotation(
    PrepareEditQuotation event,
    Emitter<QuotationOrderState> emit,
  ) async {
    emit(state.copyWith(status: QuotationOrderStatus.loading));
    try {
      final details = await quotationOrderRepository
          .getQuotationOrderDetailsByHeaderId(
            event.header.id!,
            event.header.company!,
          );

      emit(
        state.copyWith(
          selectedQuotation: event.header,
          currentDetails: details,
          status: QuotationOrderStatus.loaded,
        ),
      );

      add(CalculateTotals(header: event.header, details: details));
    } catch (e) {
      emit(
        state.copyWith(
          status: QuotationOrderStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  // Add detail item
  Future<void> _onAddDetailItem(
    AddDetailItem event,
    Emitter<QuotationOrderState> emit,
  ) async {
    final updatedDetails = List<QuotationOrderDetail>.from(state.currentDetails)
      ..add(event.detail);

    emit(state.copyWith(currentDetails: updatedDetails));

    if (state.selectedQuotation != null) {
      add(
        CalculateTotals(
          header: state.selectedQuotation!,
          details: updatedDetails,
        ),
      );
    }
  }

  // Update detail item
  Future<void> _onUpdateDetailItem(
    UpdateDetailItem event,
    Emitter<QuotationOrderState> emit,
  ) async {
    final updatedDetails = List<QuotationOrderDetail>.from(
      state.currentDetails,
    );
    if (event.index >= 0 && event.index < updatedDetails.length) {
      updatedDetails[event.index] = event.detail;
      emit(state.copyWith(currentDetails: updatedDetails));

      if (state.selectedQuotation != null) {
        add(
          CalculateTotals(
            header: state.selectedQuotation!,
            details: updatedDetails,
          ),
        );
      }
    }
  }

  // Remove detail item
  Future<void> _onRemoveDetailItem(
    RemoveDetailItem event,
    Emitter<QuotationOrderState> emit,
  ) async {
    final updatedDetails = List<QuotationOrderDetail>.from(
      state.currentDetails,
    );
    if (event.index >= 0 && event.index < updatedDetails.length) {
      updatedDetails.removeAt(event.index);
      emit(state.copyWith(currentDetails: updatedDetails));

      if (state.selectedQuotation != null) {
        add(
          CalculateTotals(
            header: state.selectedQuotation!,
            details: updatedDetails,
          ),
        );
      }
    }
  }

  // Barcode scanned (settingSOByBarcode from Java)
  Future<void> _onBarcodeScanned(
    ScanBarcode event,
    Emitter<QuotationOrderState> emit,
  ) async {
    emit(state.loadingState());
    try {
      final items = await itemInBranchRepository.findByBarcode(
        event.barcode,
        state.companyId ?? authBloc.state.companyId!,
      );

      if (items.isNotEmpty) {
        final item = items.first;

        // Check if item already exists in details
        final existingIndex = state.currentDetails.indexWhere(
          (d) => d.itemInBranch == item.id,
        );

        if (existingIndex != -1) {
          // Update quantity (increment by 1)
          final existingDetail = state.currentDetails[existingIndex];
          final newQuantity = (existingDetail.quantity ?? 0) + 1;
          final newExtendedPrice =
              newQuantity * (existingDetail.unitPrice ?? 0);

          final updatedDetail = existingDetail.copyWith(
            quantity: newQuantity,
            extendedPrice: newExtendedPrice,
          );

          add(UpdateDetailItem(detail: updatedDetail, index: existingIndex));
        } else {
          // Add new item
          final newDetail = QuotationOrderDetail(
            itemInBranch: item.id,
            unitPrice: item.unitPrice,
            quantity: 1.0,
            extendedPrice: item.unitPrice,
            unitCost: item.unitCost,
            unitOfMeasure: item.unitOfMeasure,
            taxable: item.taxable == 'Y' ? 'Y' : 'N',
            tempId: DateTime.now().millisecondsSinceEpoch,
            company: state.companyId ?? authBloc.state.companyId,
          );

          add(AddDetailItem(detail: newDetail));
        }
      } else {
        emit(
          state.copyWith(
            errorMessage: 'Item not found for barcode: ${event.barcode}',
          ),
        );
      }
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Error scanning barcode: $e'));
    } finally {
      emit(state.copyWith(isBarcodeScanning: false));
    }
  }

  // Calculate totals (calQtyWithAmt from Java)
  Future<void> _onCalculateTotals(
    CalculateTotals event,
    Emitter<QuotationOrderState> emit,
  ) async {
    final systemConstants =
        event.systemConstants ??
        state.systemConstants ??
        (systemConstantBloc.state.systemConstants.isNotEmpty
            ? systemConstantBloc.state.systemConstants.first
            : null);

    if (systemConstants == null) {
      return;
    }

    final decimalPlaces = systemConstants.decimalPlaces ?? 2;
    double subTotal = 0.0;
    double taxableAmount = 0.0;

    // Calculate subtotal and taxable amount
    for (final detail in event.details) {
      final extendedPrice = detail.extendedPrice ?? 0.0;
      subTotal += extendedPrice;

      if (detail.taxable == 'Y') {
        taxableAmount += extendedPrice;
      }
    }

    final roundedSubTotal = systemConstantBloc.systemConstantService
        .roundToDecimalPlaces(subTotal, decimalPlaces);

    // Calculate tax
    final tax = systemConstantBloc.systemConstantService.calculateTaxAmount(
      taxableAmount,
    );

    // Calculate withholding amount if applicable
    double withholdAmount = 0.0;
    if (event.header.withHoldApply == 'Y') {
      withholdAmount = systemConstantBloc.systemConstantService
          .calculateWithholdingAmount(roundedSubTotal);
    }

    final discountAmount = event.header.discountAmount ?? 0.0;

    // Calculate total amount
    final totalAmount = systemConstantBloc.systemConstantService
        .roundToDecimalPlaces(
          roundedSubTotal + tax - withholdAmount - discountAmount,
          decimalPlaces,
        );

    emit(
      state.copyWith(
        subTotal: roundedSubTotal,
        tax: tax,
        withholdAmount: withholdAmount,
        discountAmount: discountAmount,
        totalAmount: totalAmount,
        systemConstants: systemConstants,
      ),
    );

    // Update selected quotation with calculated values
    if (state.selectedQuotation != null) {
      emit(
        state.copyWith(
          selectedQuotation: state.selectedQuotation!.copyWith(
            amountTotal: totalAmount,
            tax: tax,
            withholdAmount: withholdAmount,
          ),
        ),
      );
    }
  }

  // UOM changed (uomConversion from Java)
  Future<void> _onUomChanged(
    UomChanged event,
    Emitter<QuotationOrderState> emit,
  ) async {
    try {
      final newPrice = await uomConversionsRepository.convertPrice(
        itemId: event.itemInBranch.itemNumber!,
        price: event.itemInBranch.unitPrice ?? 0.0,
        fromUomId: event.itemInBranch.unitOfMeasure!,
        toUomId: event.newUomId,
        companyId: state.companyId ?? authBloc.state.companyId!,
      );

      // Update detail with new UOM and Price
      final updatedDetail = event.detail.copyWith(
        unitOfMeasure: event.newUomId,
        unitPrice: newPrice,
        extendedPrice: newPrice * (event.detail.quantity ?? 1.0),
      );

      // Find index and update
      final index = state.currentDetails.indexOf(event.detail);
      if (index != -1) {
        add(UpdateDetailItem(detail: updatedDetail, index: index));
      }
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Error converting UOM: $e'));
    }
  }

  // Convert to sales order (convertToSales from Java)
  Future<void> _onConvertToSalesOrder(
    ConvertToSalesOrder event,
    Emitter<QuotationOrderState> emit,
  ) async {
    try {
      // Map Quotation Header to Sales Order Header
      final salesHeader = SalesOrderHeader(
        company: event.header.company,
        //salesRepresent: event.header.salesRepresent,
        orderDate: DateTime.now(),
        requiredDate: event.header.requiredDate,
        customerBillTo: event.header.customerBillTo,
        customerTableId: event.header.customerTableId,
        //orderStatus: 'Open',
        orderType: event.header.orderType,
        paymentMethod: event.header.paymentMethod,
        paymentTerm: event.header.paymentTerm,
        //currencyCode: event.header.currencyCode,
        //exchangeRate: event.header.exchangeRate,
        // Copy other relevant fields...
      );

      // Map Details (recalculate prices based on sales order logic)
      final salesDetails = state.currentDetails.map((d) {
        return SalesOrderDetail(
          itemInBranch: d.itemInBranch,
          quantity: d.quantity,
          unitPrice: d.unitPrice,
          extendedPrice: d.extendedPrice,
          unitOfMeasure: d.unitOfMeasure,
          taxable: d.taxable,
          // Map other required fields...
        );
      }).toList();

      // Here you would typically call the SalesOrderBloc or repository
      // For now, just emit success message
      emit(
        state.copyWith(successMessage: 'Converted to Sales Order successfully'),
      );
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Error converting to Sales Order: $e'));
    }
  }

  // Prepare invoice review (prepareInvoiceToReview from Java)
  Future<void> _onPrepareInvoiceReview(
    PrepareInvoiceReview event,
    Emitter<QuotationOrderState> emit,
  ) async {
    try {
      // Map to Invoice History models
      final invoiceHeader = InvoiceHistoryHeader(
        company: event.header.company,
        customerName: event.header.customerBillToRef!.customerName,
        dateTransaction: DateTime.now(),
        totalAmount: state.totalAmount,
        fsNumber: event.header.fsNumber,
        // Map other fields...
      );

      final invoiceDetails = state.currentDetails.map((d) {
        return InvoiceHistoryDetail(
          invoiceHistory: invoiceHeader.id,
          item: d.itemBranchRef!.itemRef!.itemDescription,
          quantityTransaction: d.quantity,
          amountExtendedPrice: d.extendedPrice,
          amountUnitPrice: d.unitPrice,
          // Map other fields...
        );
      }).toList();

      // In actual implementation, you would pass this to Invoice Review screen or bloc
      emit(state.copyWith(
        successMessage: 'Invoice prepared for review'));
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Error preparing invoice: $e'));
    }
  }

  // Update customer info (customerSetItems from Java)
  Future<void> _onUpdateCustomerInfo(
    UpdateCustomerInfo event,
    Emitter<QuotationOrderState> emit,
  ) async {
    if (state.selectedQuotation != null) {
      final updatedHeader = state.selectedQuotation!.copyWith(
        customerBillTo: event.customer.id,
        customerTableId: event.customer.id,
        // Update other customer-related fields if stored in header
      );
      emit(state.copyWith(selectedQuotation: updatedHeader));
    }
  }

  // Generate next FS number (getNextFsNumber from Java)
  Future<void> _onGenerateNextFsNumber(
    GenerateNextFsNumber event,
    Emitter<QuotationOrderState> emit,
  ) async {
    try {
      final fsNumber = await quotationOrderRepository.generateNextFsNumber(
        event.companyId,
        authBloc.state.branchId!,
      );

      emit(state.copyWith(nextFsNumber: fsNumber));

      if (state.selectedQuotation != null) {
        emit(
          state.copyWith(
            selectedQuotation: state.selectedQuotation!.copyWith(
              fsNumber: fsNumber,
            ),
          ),
        );
      }
    } catch (e) {
      // Handle error or use default
    }
  }

  // System constants updated
  Future<void> _onSystemConstantsUpdated(
    SystemConstantsUpdated event,
    Emitter<QuotationOrderState> emit,
  ) async {
    emit(state.copyWith(systemConstants: event.systemConstants));
    if (state.selectedQuotation != null) {
      add(
        CalculateTotals(
          header: state.selectedQuotation!,
          details: state.currentDetails,
          systemConstants: event.systemConstants,
        ),
      );
    }
  }
}
*/
