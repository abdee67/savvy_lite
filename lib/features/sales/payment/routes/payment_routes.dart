import 'package:go_router/go_router.dart';
import 'package:savvy_stock/features/sales/customer/models/customer_model.dart';
import 'package:savvy_stock/features/sales/payment/screens/paymentSummary.dart';
import 'package:savvy_stock/features/sales/payment/screens/successful_payment_screen.dart';
import 'package:savvy_stock/features/sales/sales_item_entry/models/confirmed_item.dart';

class PaymentRoutes {
  static GoRoute paymentScreen = GoRoute(
    path: '/payment',
    name: 'payment',
    builder: (context, state) {
      final extra = state.extra as Map<String, dynamic>? ?? {};
      final confirmedItems =
          extra['confirmedItems'] as List<ConfirmedItem>? ?? [];
      final totalAmount = extra['totalAmount'] as double? ?? 0.0;
      final customer =
          extra['customer'] as Customer? ??
          const Customer(id: '', name: '', tin: '', phone: '', country: '');

      return PaymentScreen(
        confirmedItems: confirmedItems,
        totalAmount: totalAmount,
        customer: customer,
      );
    },
  );

  static GoRoute paymentSuccess = GoRoute(
    path: '/payment/success',
    name: 'payment-success',
    builder: (context, state) {
      final extra = state.extra as Map<String, dynamic>? ?? {};
      final transactionId = extra['transactionId'] as String? ?? '';
      final amount = extra['amount'] as double? ?? 0.0;

      return PaymentSuccessScreen(transactionId: transactionId, amount: amount);
    },
  );
}
