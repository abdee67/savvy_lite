// features/sales/invoice/widgets/invoice_third_part.dart
import 'package:flutter/material.dart';

class InvoiceThirdPart extends StatelessWidget {
  final double subtotal;
  final double discountAmount;
  final double taxAmount;
  final double withholdingAmount;
  final double totalAmount;
  final String? paymentType;
  final String? paymentInstrument;

  const InvoiceThirdPart({
    super.key,
    required this.subtotal,
    required this.discountAmount,
    required this.taxAmount,
    required this.withholdingAmount,
    required this.totalAmount,
    this.paymentType,
    this.paymentInstrument,
  });

  @override
  Widget build(BuildContext context) {
    final hasDiscount = discountAmount > 0;
    final hasWithholding = withholdingAmount > 0;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.payment, color: Color(0xFF155888)),
                const SizedBox(width: 8),
                const Text(
                  'PAYMENT SUMMARY',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF155888),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Two-column layout
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left column - Amount in words
                Expanded(flex: 1, child: _buildAmountInWords(totalAmount)),

                const SizedBox(width: 24),

                // Right column - Amount breakdown
                Expanded(
                  flex: 1,
                  child: _buildAmountBreakdown(
                    hasDiscount: hasDiscount,
                    hasWithholding: hasWithholding,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Payment Method
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.credit_card, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  const Text(
                    'Payment Method:',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$paymentType - $paymentInstrument',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountInWords(double amount) {
    final words = _convertAmountToWords(amount);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Amount in Words:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF155888),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(words, style: const TextStyle(fontSize: 13, height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildAmountBreakdown({
    required bool hasDiscount,
    required bool hasWithholding,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _buildAmountRow('Subtotal', subtotal),
          if (hasDiscount)
            _buildAmountRow('Discount', -discountAmount, isDiscount: true),
          if (hasWithholding) _buildAmountRow('Withholding', withholdingAmount),
          _buildAmountRow('Tax', taxAmount),
          const Divider(height: 16),
          _buildAmountRow('TOTAL', totalAmount, isTotal: true),
        ],
      ),
    );
  }

  Widget _buildAmountRow(
    String label,
    double amount, {
    bool isTotal = false,
    bool isDiscount = false,
  }) {
    final textColor = isDiscount
        ? Colors.red
        : (isTotal ? const Color(0xFF155888) : Colors.black);
    final fontWeight = isTotal ? FontWeight.bold : FontWeight.normal;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: fontWeight,
              color: textColor,
            ),
          ),
          Text(
            _formatCurrency(amount),
            style: TextStyle(
              fontSize: 12,
              fontWeight: fontWeight,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    final isNegative = amount < 0;
    final displayAmount = isNegative ? -amount : amount;
    return 'ETB ${isNegative ? '-' : ''}${displayAmount.toStringAsFixed(2)}';
  }

  String _convertAmountToWords(double amount) {
    final wholePart = amount.floor();
    final decimalPart = ((amount - wholePart) * 100).round();

    final wholeWords = _convertNumberToWords(wholePart);
    final decimalWords = _convertNumberToWords(decimalPart);

    return '${wholeWords.isEmpty ? 'Zero' : wholeWords} Birr${decimalPart > 0 ? ' and $decimalWords Cents' : ''} Only';
  }

  String _convertNumberToWords(int number) {
    // This is a simplified version - you might want to use a more robust solution
    final wholePart = number.floor();
    final decimalPart = ((number - wholePart) * 100).round();

    final wholeWords = _convertNumberToWordsHelper(wholePart);
    final decimalWords = _convertNumberToWordsHelper(decimalPart);

    return '${wholeWords.isEmpty ? 'Zero' : wholeWords} Birr${decimalPart > 0 ? ' and $decimalWords Cents' : ''}';
  }

  String _convertNumberToWordsHelper(int number) {
    if (number == 0) return '';

    final units = [
      '',
      'One',
      'Two',
      'Three',
      'Four',
      'Five',
      'Six',
      'Seven',
      'Eight',
      'Nine',
    ];
    final teens = [
      'Ten',
      'Eleven',
      'Twelve',
      'Thirteen',
      'Fourteen',
      'Fifteen',
      'Sixteen',
      'Seventeen',
      'Eighteen',
      'Nineteen',
    ];
    final tens = [
      '',
      'Ten',
      'Twenty',
      'Thirty',
      'Forty',
      'Fifty',
      'Sixty',
      'Seventy',
      'Eighty',
      'Ninety',
    ];

    if (number < 10) return units[number];
    if (number < 20) return teens[number - 10];
    if (number < 100) {
      return '${tens[number ~/ 10]} ${units[number % 10]}'.trim();
    }
    if (number < 1000) {
      return '${units[number ~/ 100]} Hundred ${_convertNumberToWordsHelper(number % 100)}'
          .trim();
    }
    if (number < 1000000) {
      return '${_convertNumberToWordsHelper(number ~/ 1000)} Thousand ${_convertNumberToWordsHelper(number % 1000)}'
          .trim();
    }
    if (number < 1000000000) {
      return '${_convertNumberToWordsHelper(number ~/ 1000000)} Million ${_convertNumberToWordsHelper(number % 1000000)}'
          .trim();
    }
    if (number < 1000000000000) {
      return '  ${_convertNumberToWordsHelper(number ~/ 1000000000)} Billion ${_convertNumberToWordsHelper(number % 1000000000)}'
          .trim();
    }

    return 'Large Amount'; // Simplified for very large numbers
  }
}
