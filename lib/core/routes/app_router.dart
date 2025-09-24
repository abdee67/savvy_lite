import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:savvy_stock/core/widgets/route_guard.dart';
import 'package:savvy_stock/features/admin/employees/screens/employee_dashboard.dart';
import 'package:savvy_stock/features/admin/privilege/screens/privilege_dahsboard.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/auth/blocs/auth_state.dart';
import 'package:savvy_stock/features/auth/screens/login_screen.dart';
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

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class AppRouter {
  final AuthBloc authBloc;
  final bool showOnboarding;
  AppRouter({required this.showOnboarding, required this.authBloc});

  late final GoRouter router = GoRouter(
    navigatorKey: navigatorKey,
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    initialLocation: showOnboarding ? '/welcome' : '/auth-check',
    routes: [
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const OnboardingScreen(),
      ),

      GoRoute(
        path: '/auth-check',
        builder: (context, state) =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        redirect: (context, state) => _authRedirect(context, state),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
        redirect: (context, state) => _loginRedirect(context, state),
      ),
      GoRoute(
        path: '/sales-dashboard',
        builder: (context, state) => PrivilegeRouteGuard(
          requiredPrivilege: '/item-entry-dashboard', //Basic dashboard
          child: SalesDashboard(),
        ),
        redirect: (context, state) => _protectedRouteRedirect(context, state),
      ),
      GoRoute(path: '/signup', builder: (context, state) => const GetStart()),
      GoRoute(
        path: '/item-entry-dashboard',
        builder: (context, state) => PrivilegeRouteGuard(
          requiredPrivilege: '/item-entry-dashboard',
          child: ItemEntryScreen(),
        ),
        redirect: (context, state) => _protectedRouteRedirect(context, state),
      ),
      GoRoute(
        path: '/payment-dashboard',
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>;
          return PrivilegeRouteGuard(
            requiredPrivilege: '/payment-dashboard',
            child: PaymentScreen(
              confirmedItems: args['confirmedItems'] as List<ConfirmedItem>,
              totalAmount: args['totalAmount'] as double,
              customer: args['customer'] as Customer, // Pass customer to screen
            ),
          );
        },
        redirect: (context, state) => _protectedRouteRedirect(context, state),
      ),
      GoRoute(
        path: '/invoice-dashboard',
        builder: (context, state) {
          return PrivilegeRouteGuard(
            requiredPrivilege: '/invoice-dashboard',
            child: InvoiceReviewScreen(),
          );
        },
        redirect: (context, state) => _protectedRouteRedirect(context, state),
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
        path: '/customer-entry-dashboard',
        builder: (context, state) => PrivilegeRouteGuard(
          requiredPrivilege: '/customer-entry-dashboard',
          child: const CustomerScreen(),
        ),
        redirect: (context, state) => _protectedRouteRedirect(context, state),
      ),
      GoRoute(
        path: '/customer-list-dashboard',
        builder: (context, state) => PrivilegeRouteGuard(
          requiredPrivilege: '/customer-list-dashboard',
          child: CustomerListPage(),
        ),
        redirect: (context, state) => _protectedRouteRedirect(context, state),
      ),
      GoRoute(
        path: '/invoice-dashboard',
        builder: (context, state) => const PrivilegeRouteGuard(
          requiredPrivilege: '/invoice-dashboard',
          child: InvoiceReviewScreen(),
        ),
        redirect: (context, state) => _protectedRouteRedirect(context, state),
      ),

      // Admin Features
      GoRoute(
        path: '/role-create-dashboard',
        builder: (context, state) => const PrivilegeRouteGuard(
          requiredPrivilege: '/role-create-dashboard',
          child: RoleManagementScreen(),
        ),
        redirect: (context, state) => _protectedRouteRedirect(context, state),
      ),

      GoRoute(
        path: '/privilege-create-dashboard',
        builder: (context, state) => const PrivilegeRouteGuard(
          requiredPrivilege: '/privilege-create-dashboard',
          child: PrivilegeManagementScreen(),
        ),
        redirect: (context, state) => _protectedRouteRedirect(context, state),
      ),

      GoRoute(
        path: '/user-create-dashboard',
        builder: (context, state) => const PrivilegeRouteGuard(
          requiredPrivilege: '/user-create-dashboard',
          child: UserManagementScreen(),
        ),
        redirect: (context, state) => _protectedRouteRedirect(context, state),
      ),

      GoRoute(
        path: '/employee-management',
        builder: (context, state) => const PrivilegeRouteGuard(
          requiredPrivilege:
              '/user-create-dashboard', // Only admins can manage employees
          child: EmployeeListScreen(),
        ),
        redirect: (context, state) => _protectedRouteRedirect(context, state),
      ),
      // Unauthorized route
      GoRoute(
        path: '/unauthorized',
        name: 'unauthorized',
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text('Access Denied')),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('You do not have permission to access this page.'),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => context.go('/dashboard'),
                  child: const Text('Go to Dashboard'),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Page not found: ${state.uri}'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.go('/dashboard'),
              child: const Text('Go to Dashboard'),
            ),
          ],
        ),
      ),
    ),
  );
  // core/routes/app_router.dart
  String? _authRedirect(BuildContext context, GoRouterState state) {
    final authState = authBloc.state;

    developer.log('🔄 Router redirect check: ${authState.status}');
    developer.log('🔄 Current path: ${state.uri}');

    if (authState.status == AuthStatus.loading) {
      developer.log('⏳ Router: Still loading...');
      return null; // Stay on current page while loading
    }

    if (authState.status == AuthStatus.authenticated) {
      final intendedLocation = state.uri.queryParameters['redirect'];
      return intendedLocation ?? '/dashboard';
    }
    return '/login'; // Stay on current page if it's a protected route
  }

  String? _loginRedirect(BuildContext context, GoRouterState state) {
    final authState = authBloc.state;

    if (authState.status == AuthStatus.authenticated) {
      developer.log(
        '✅ Login page redirect: Already authenticated, going to dashboard',
      );
      return '/sales-dashboard';
    }

    return null; // Stay on login page
  }

  String? _protectedRouteRedirect(BuildContext context, GoRouterState state) {
    final authState = authBloc.state;

    if (authState.status == AuthStatus.loading) {
      return '/auth-check'; // Still loading auth status
    }

    if (authState.status != AuthStatus.authenticated) {
      // Not authenticated, redirect to login with return url
      return '/login?redirect=${Uri.encodeComponent(state.uri.toString())}';
    }

    return null; // Access granted
  }
}

// GoRouter refresh stream
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((dynamic state) {
      developer.log('GoRouterRefreshStream: $state');
      notifyListeners();
    });
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
