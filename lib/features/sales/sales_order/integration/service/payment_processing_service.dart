// features/sales/services/payment_processing_service.dart
import 'package:savvy_stock/core/repositories/udc_repository.dart';
import 'package:savvy_stock/features/sales/sales_order/header/model/sales_order_header.dart';

class PaymentProcessingResult {
  final bool success;
  final DateTime dueDate;
  final double openAmount;
  final int? paymentStatus;
  final String transactionId;
  final String message;

  const PaymentProcessingResult({
    required this.success,
    required this.dueDate,
    required this.openAmount,
    required this.paymentStatus,
    required this.transactionId,
    required this.message,
  });
}

class PaymentProcessingService {
  final UdcRepository udcRepository;

  PaymentProcessingService({required this.udcRepository});

  Future<PaymentProcessingResult> processPayment({
    required SalesOrderHeader salesOrder,
    required String paymentType,
    required String paymentTermCode,
    required double amountPaid,
    required int companyId,
  }) async {
    try {
      // Calculate due date based on payment term
      final dueDate = _calculateDueDate(salesOrder.orderDate!, paymentTermCode);

      // Calculate open amount
      final openAmount = _calculateOpenAmount(
        salesOrder.amountTotal ?? 0,
        salesOrder.discountAmount ?? 0,
        amountPaid,
      );

      // Determine payment status
      final paymentStatus = await _determinePaymentStatus(
        openAmount,
        paymentType,
      );

      // Generate transaction ID
      final transactionId = _generateTransactionId();

      // Process payment based on type
      await _processPaymentByType(
        paymentType,
        amountPaid,
        transactionId,
        companyId,
      );

      return PaymentProcessingResult(
        success: true,
        dueDate: dueDate,
        openAmount: openAmount,
        paymentStatus: paymentStatus,
        transactionId: transactionId,
        message: 'Payment processed successfully',
      );
    } catch (e) {
      final paymentStatus = await udcRepository.getUdcDetailIdByHeaderCode('N');

      return PaymentProcessingResult(
        success: false,
        dueDate: DateTime.now(),
        openAmount: salesOrder.amountTotal ?? 0,
        paymentStatus: paymentStatus, // Not paid
        transactionId: '',
        message: 'Payment processing failed: $e',
      );
    }
  }

  DateTime _calculateDueDate(DateTime orderDate, String paymentTermCode) {
    switch (paymentTermCode) {
      case 'NET15':
        return orderDate.add(const Duration(days: 15));
      case 'NET30':
        return orderDate.add(const Duration(days: 30));
      case 'NET60':
        return orderDate.add(const Duration(days: 60));
      case 'DUE_ON_RECEIPT':
        return orderDate;
      default:
        return orderDate.add(const Duration(days: 30)); // Default to NET30
    }
  }

  double _calculateOpenAmount(
    double totalAmount,
    double discountAmount,
    double amountPaid,
  ) {
    final netAmount = totalAmount - discountAmount;
    return netAmount - amountPaid;
  }

  Future<int?> _determinePaymentStatus(double openAmount, String paymentType) {
    if (openAmount <= 0) {
      return udcRepository.getUdcDetailIdByHeaderCode('P'); // Paid
    } else if (paymentType == 'Cash' && openAmount > 0) {
      return udcRepository.getUdcDetailIdByHeaderCode(
        'P',
      ); // Consider cash as paid
    } else {
      return udcRepository.getUdcDetailIdByHeaderCode('N'); // Not paid
    }
  }

  String _generateTransactionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecond;
    return 'TXN${timestamp}_$random';
  }

  Future<void> _processPaymentByType(
    String paymentType,
    double amount,
    String transactionId,
    int companyId,
  ) async {
    switch (paymentType) {
      case 'Cash':
        await _processCashPayment(amount, transactionId, companyId);
        break;
      case 'Credit':
        await _processCreditPayment(amount, transactionId, companyId);
        break;
      case 'Card':
        await _processCardPayment(amount, transactionId, companyId);
        break;
      case 'Bank Transfer':
        await _processBankTransfer(amount, transactionId, companyId);
        break;
      default:
        throw Exception('Unsupported payment type: $paymentType');
    }
  }

  Future<void> _processCashPayment(
    double amount,
    String transactionId,
    int companyId,
  ) async {
    // Record cash receipt in accounting system
    // Update cash account balance
    // Create accounting entry
  }

  Future<void> _processCreditPayment(
    double amount,
    String transactionId,
    int companyId,
  ) async {
    // Update accounts receivable
    // Create credit transaction
    // Notify credit department if needed
  }

  Future<void> _processCardPayment(
    double amount,
    String transactionId,
    int companyId,
  ) async {
    // Integrate with payment gateway
    // Process card transaction
    // Record bank deposit
  }

  Future<void> _processBankTransfer(
    double amount,
    String transactionId,
    int companyId,
  ) async {
    // Record bank transfer
    // Update bank account balance
    // Create bank reconciliation entry
  }

  // Calculate credit limit utilization
  Future<double> calculateCreditUtilization(
    int customerId,
    int companyId,
  ) async {
    // Get customer credit limit
    // Calculate total outstanding invoices
    // Return utilization percentage
    return 0.0; // Implement based on your accounting system
  }
}
