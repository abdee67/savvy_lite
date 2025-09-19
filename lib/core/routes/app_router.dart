import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:savvy_stock/features/onboarding/screens/welcome_screen.dart';
import 'package:savvy_stock/features/onboarding/widgets/getStarted.dart';
import 'package:savvy_stock/features/sales/customer/models/customer_model.dart';
import 'package:savvy_stock/features/sales/customer/screens/customer_list.dart';
import 'package:savvy_stock/features/sales/customer/screens/customer_screen.dart';
import 'package:savvy_stock/features/sales/invoice/screens/invoice_review_screen.dart';
import 'package:savvy_stock/features/sales/payment/screens/payment_screen.dart';
import 'package:savvy_stock/features/sales/presentation/screens/sales_dashboard.dart';
import 'package:savvy_stock/features/sales/sales_item_entry/models/confirmed_item.dart';
import 'package:savvy_stock/features/sales/sales_item_entry/screens/sales_item_entry.dart';
import 'package:savvy_stock/features/system_constant/screen/system_constants_screen.dart';

class AppRouter {
  final bool showOnboarding;
  AppRouter({required this.showOnboarding});

  GoRouter get router => GoRouter(
    initialLocation: showOnboarding ? '/welcome' : '/sales-dashboard',
    routes: [
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/sales-dashboard',
        builder: (context, state) => const SalesDashboard(),
      ),
      GoRoute(path: '/signup', builder: (context, state) => const GetStart()),
      GoRoute(
        path: '/sales-item-entry-screen',
        pageBuilder: (context, state) => MaterialPage(child: ItemEntryScreen()),
      ),
      GoRoute(
        path: '/payment-screen',
        pageBuilder: (context, state) {
          final args = state.extra as Map<String, dynamic>;
          return MaterialPage(
            child: PaymentScreen(
              confirmedItems: args['confirmedItems'] as List<ConfirmedItem>,
              totalAmount: args['totalAmount'] as double,
              customer: args['customer'] as Customer, // Pass customer to screen
            ),
          );
        },
      ),
      GoRoute(
        path: '/invoice-review-screen',
        pageBuilder: (context, state) {
          return MaterialPage(child: InvoiceReviewScreen());
        },
      ),

      GoRoute(
        path: '/system_constant',
        builder: (context, state) => const SystemConstantsScreen(),
      ),

      GoRoute(
        path: '/forgot-password',
        builder: (_, __) => const Placeholder(),
      ),
      GoRoute(
        path: '/customer-screen',
        pageBuilder: (context, state) =>
            MaterialPage(child: const CustomerScreen()),
      ),
      GoRoute(
        path: '/customer-list',
        pageBuilder: (context, state) =>
            MaterialPage(child: const CustomerListPage()),
      ),
    ],
    errorBuilder: (context, state) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Text('Error: ${state.error}')),
      );
    },
  );
}
