import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:savvy_stock/features/auth/screens/login_screen.dart';
import 'package:savvy_stock/features/onboarding/screens/trial_screen.dart';
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
    initialLocation: showOnboarding ? '/welcome' : '/login',
    routes: [
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const SalesDashboard(),
      ),
      GoRoute(
        path: '/salesScreen',
        builder: (context, state) => const SalesDashboard(),
      ),
      GoRoute(path: '/signup', builder: (context, state) => const GetStart()),
      GoRoute(
        path: '/salesScreen',
        builder: (context, state) => const SalesDashboard(),
      ),
      GoRoute(
        path: '/customerScreen',
        builder: (context, state) => const CustomerScreen(),
      ),
      GoRoute(
        path: '/itemEntryScreen',
        builder: (context, state) => const ItemEntryScreen(),
      ),
      GoRoute(
        path: '/paymentScreen',
        builder: (context, state) =>
            const SummaryPaymentPage(confirmedItems: [], totalAmount: 0),
      ),

      GoRoute(
        path: '/forgot-password',
        builder: (_, __) => const Placeholder(),
      ),
      GoRoute(
        path: '/customerScreen',
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
