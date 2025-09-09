import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:savvy_stock/features/onboarding/screens/welcome_screen.dart';
import 'package:savvy_stock/features/onboarding/widgets/getStarted.dart';
import 'package:savvy_stock/features/sales/customer/blocs/customer_bloc.dart';
import 'package:savvy_stock/features/sales/customer/blocs/customer_event.dart';
import 'package:savvy_stock/features/sales/customer/screens/customer_screen.dart';
import 'package:savvy_stock/features/sales/payment/screens/paymentSummary.dart';
import 'package:savvy_stock/features/sales/presentation/screens/sales_dashboard.dart';
import 'package:savvy_stock/features/sales/sales_item_entry/screens/sales_item_entry.dart';

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
        builder: (context, state) => const ItemEntryScreen(),
      ),
      GoRoute(path: '/signup', builder: (context, state) => const GetStart()),
      GoRoute(
        path: '/sales-item-entry-screen',
        builder: (context, state) => const ItemEntryScreen(),
      ),
      GoRoute(
        path: '/payment-screen',
        builder: (context, state) =>
            const PaymentScreen(confirmedItems: [], totalAmount: 0),
      ),

      GoRoute(
        path: '/forgot-password',
        builder: (_, __) => const Placeholder(),
      ),
      GoRoute(
        path: '/customer-screen',
        builder: (_, __) => BlocProvider(
          create: (context) => CustomerBloc()..add(LoadCustomers()),
          child: const CustomerScreen(),
        ),
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
