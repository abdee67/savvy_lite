/*// features/sales/services/proforma_conversion_service.dart
import 'package:savvy_stock/features/sales/sales_order_header/model/sales_order_header.dart';
import 'package:savvy_stock/features/sales/sales_order_detail/model/sales_order_detail.dart';

class ProformaConversionResult {
  final bool success;
  final SalesOrderHeader salesOrderHeader;
  final List<SalesOrderDetail> salesOrderDetails;
  final String message;
  final String convertedQuoteNumber;

  const ProformaConversionResult({
    required this.success,
    required this.salesOrderHeader,
    required this.salesOrderDetails,
    required this.message,
    required this.convertedQuoteNumber,
  });
}

class ProformaConversionService {
  final QuoteOrderHeaderRepository quoteOrderHeaderRepository;

  ProformaConversionService({required this.quoteOrderHeaderRepository});

  Future<ProformaConversionResult> convertProformaToSalesOrder({
    required String proformaReference,
    required int companyId,
    required DateTime conversionDate,
  }) async {
    try {
      // Get the proforma quote
      final proformaQuote = await quoteOrderHeaderRepository
          .getQuoteOrderHeaderByFsNumber(proformaReference, companyId);

      if (proformaQuote == null) {
        throw Exception('Proforma quote not found: $proformaReference');
      }

      // Check if already converted
      if (proformaQuote.conversionStatus == 'Converted') {
        throw Exception('Proforma quote already converted');
      }

      // Create sales order header from proforma
      final salesOrderHeader = _createSalesOrderFromProforma(
        proformaQuote,
        conversionDate,
      );

      // Create sales order details from proforma details
      final salesOrderDetails = await _createSalesDetailsFromProforma(
        proformaQuote.id!,
        salesOrderHeader.id!,
        companyId,
      );

      // Update proforma status
      await _updateProformaStatus(proformaQuote, salesOrderHeader.fsNumber!);

      return ProformaConversionResult(
        success: true,
        salesOrderHeader: salesOrderHeader,
        salesOrderDetails: salesOrderDetails,
        message: 'Proforma quote successfully converted to sales order',
        convertedQuoteNumber: proformaReference,
      );
    } catch (e) {
      return ProformaConversionResult(
        success: false,
        salesOrderHeader: SalesOrderHeader(),
        salesOrderDetails: [],
        message: 'Failed to convert proforma: $e',
        convertedQuoteNumber: proformaReference,
      );
    }
  }

  SalesOrderHeader _createSalesOrderFromProforma(
    QuoteOrderHeader proforma,
    DateTime conversionDate,
  ) {
    return SalesOrderHeader(
      orderDate: conversionDate,
      requiredDate: conversionDate.add(const Duration(days: 30)),
      salesType: 'Credit', // Default to credit for converted quotes
      customerBillTo: proforma.customerBillTo,
      customerTableId: proforma.customerTableId,
      amountTotal: proforma.amountTotal,
      tax: proforma.tax,
      discountAmount: proforma.discountAmount,
      //proformaReference: proforma.fsNumber,
      company: proforma.company,
      employeesId: proforma.employeesId,
      orderType: proforma.orderType,
      // Add other necessary fields...
    );
  }

  Future<List<SalesOrderDetail>> _createSalesDetailsFromProforma(
    int quoteId,
    int salesOrderHeaderId,
    int companyId,
  ) async {
    final quoteDetails = await quoteOrderHeaderRepository
        .getQuoteDetailsByHeaderId(quoteId, companyId);

    return quoteDetails
        .map(
          (quoteDetail) => SalesOrderDetail(
            salesOrderHeaderId: salesOrderHeaderId,
            itemsTableId: quoteDetail.itemsTableId,
            quantity: quoteDetail.quantity,
            unitPrice: quoteDetail.unitPrice,
            extendedPrice: quoteDetail.extendedPrice,
            unitOfMeasure: quoteDetail.unitOfMeasure,
            company: companyId,
            // Copy other relevant fields...
          ),
        )
        .toList();
  }

  Future<void> _updateProformaStatus(
    QuoteOrderHeader proforma,
    String salesOrderFsNumber,
  ) async {
    final updatedProforma = proforma.copyWith(
      conversionStatus: 'Converted',
      referenceNote3: salesOrderFsNumber,
      conversionDate: DateTime.now(),
    );

    await quoteOrderHeaderRepository.updateQuoteOrderHeader(updatedProforma);
  }

  // Check if proforma can be converted
  Future<bool> canConvertProforma(
    String proformaReference,
    int companyId,
  ) async {
    try {
      final proforma = await quoteOrderHeaderRepository
          .getQuoteOrderHeaderByFsNumber(proformaReference, companyId);

      return proforma != null &&
          proforma.conversionStatus != 'Converted' &&
          proforma.quoteStatus == 'Approved';
    } catch (e) {
      return false;
    }
  }
}
*/
