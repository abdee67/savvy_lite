import 'package:flutter/material.dart';
import 'package:savvy_stock/features/sales/invoice/models/invoice_model.dart';

class InvoiceThirdPart extends StatelessWidget {
  final PaymentInfo payment;

  const InvoiceThirdPart({super.key, required this.payment});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.payment, size: 20, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'PAYMENT INFORMATION',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Two-column layout
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left column: Amount in words
              Expanded(
                flex: 3,
                child: _buildAmountInWords(payment.totalAmount, context),
              ),

              const SizedBox(width: 16),

              // Right column: Payment details and amount breakdown
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Payment details in a column layout
                    // Amount breakdown
                    _buildAmountRow(context, 'Subtotal', payment.subtotal),
                    if (payment.discountAmount > 0) ...[
                      _buildAmountRow(
                        context,
                        'Discount',
                        -payment.discountAmount,
                        isDiscount: true,
                      ),
                    ],
                    if (payment.withholdingAmount > 0) ...[
                      _buildAmountRow(
                        context,
                        'Withholding',
                        payment.withholdingAmount,
                      ),
                    ],
                    _buildAmountRow(context, 'Tax', payment.taxAmount),
                    const Divider(height: 16),
                    _buildAmountRow(
                      context,
                      'TOTAL',
                      payment.totalAmount,
                      isTotal: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmountInWords(double amount, BuildContext context) {
    final words = _convertNumberToWords(amount);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Amount in Words:',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 6),
          Text(words, style: const TextStyle(fontSize: 14, height: 1.4)),
          const SizedBox(height: 4),
          Text(
            'Only',
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountRow(
    BuildContext context,
    String label,
    double amount, {
    bool isTotal = false,
    bool isDiscount = false,
  }) {
    final isNegative = amount < 0;
    final displayAmount = isNegative ? -amount : amount;
    final textColor = isDiscount
        ? Colors.red
        : (isTotal ? Theme.of(context).colorScheme.primary : Colors.black);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 14 : 13,
              color: textColor,
            ),
          ),
          Text(
            'Birr${isNegative ? '-' : ''} ${displayAmount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 14 : 13,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  String _convertNumberToWords(double number) {
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
