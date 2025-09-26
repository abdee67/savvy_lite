import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:savvy_stock/core/constants/privilege_constants.dart';
import 'package:savvy_stock/core/widgets/route_guard.dart';
import 'package:savvy_stock/features/admin/employees/screens/employee_dashboard.dart';
import 'package:savvy_stock/features/admin/privilege/screens/privilege_dahsboard.dart';
import 'package:savvy_stock/features/admin/role/screens/role_dashboard.dart';
import 'package:savvy_stock/features/admin/users/screens/user_dashboard.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/auth/blocs/auth_state.dart';
import 'package:savvy_stock/features/auth/screens/login_screen.dart';
import 'package:savvy_stock/features/dashboards/screens/home_page.dart';
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
      GoRoute(path: '/signup', builder: (context, state) => const GetStart()),

      // Dynamically select dashboard based on privileges
      GoRoute(
        path: '/homePage',
        builder: (context, state) => const HomePage(),
        redirect: (context, state) => _protectedRouteRedirect(context, state),
      ),

      // SALES ROUTES
      GoRoute(
        path: PrivilegeConstants.salesCustomerInfo,
        builder: (context, state) => PrivilegeRouteGuard(
          requiredPrivilege: PrivilegeConstants.salesCustomerInfo,
          parentPrivilege: PrivilegeConstants.salesEntry,
          child: const CustomerInfoScreen(),
        ),
        redirect: _protectedRouteRedirect,
      ),
      GoRoute(
        path: PrivilegeConstants.salesItemEntry,
        builder: (context, state) => PrivilegeRouteGuard(
          requiredPrivilege: PrivilegeConstants.salesItemEntry,
          parentPrivilege: PrivilegeConstants.salesEntry,
          child: ItemEntryScreen(),
        ),
        redirect: _protectedRouteRedirect,
      ),
      GoRoute(
        path: PrivilegeConstants.paymentSummary,
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>?;

          if (args == null ||
              args['confirmedItems'] == null ||
              args['totalAmount'] == null ||
              args['customer'] == null) {
            return Scaffold(
              body: Center(child: Text('Missing payment arguments')),
            );
          }

          return PrivilegeRouteGuard(
            requiredPrivilege: PrivilegeConstants.paymentSummary,
            parentPrivilege: PrivilegeConstants.salesEntry,
            child: PaymentScreen(
              confirmedItems: args['confirmedItems'] as List<ConfirmedItem>,
              totalAmount: args['totalAmount'] as double,
              customer: args['customer'] as Customer,
            ),
          );
        },
        redirect: _protectedRouteRedirect,
      ),
      GoRoute(
        path: PrivilegeConstants.salesInvoice,
        builder: (context, state) => PrivilegeRouteGuard(
          requiredPrivilege: PrivilegeConstants.salesInvoice,
          parentPrivilege: PrivilegeConstants.salesEntry,
          child: InvoiceReviewScreen(),
        ),
        redirect: _protectedRouteRedirect,
      ),
      GoRoute(
        path: PrivilegeConstants.customerEntry,
        builder: (context, state) => PrivilegeRouteGuard(
          requiredPrivilege: PrivilegeConstants.customerEntry,
          parentPrivilege: PrivilegeConstants.salesEntry,
          child: const CustomerListPage(),
        ),
        redirect: _protectedRouteRedirect,
      ),

      // ADMIN ROUTES
      GoRoute(
        path: PrivilegeConstants.roleManagement,
        builder: (context, state) => PrivilegeRouteGuard(
          requiredPrivilege: PrivilegeConstants.roleManagement,
          parentPrivilege: PrivilegeConstants.adminDashboard,
          child: RoleCreationScreen(authBloc: context.read<AuthBloc>()),
        ),
        redirect: _protectedRouteRedirect,
      ),
      GoRoute(
        path: PrivilegeConstants.privilegeManagement,
        builder: (context, state) => PrivilegeRouteGuard(
          requiredPrivilege: PrivilegeConstants.privilegeManagement,
          parentPrivilege: PrivilegeConstants.adminDashboard,
          child: PrivilegeManagementScreen(authBloc: context.read<AuthBloc>()),
        ),
        redirect: _protectedRouteRedirect,
      ),
      GoRoute(
        path: PrivilegeConstants.userManagement,
        builder: (context, state) => PrivilegeRouteGuard(
          requiredPrivilege: PrivilegeConstants.userManagement,
          parentPrivilege: PrivilegeConstants.adminDashboard,
          child: const UserCreationScreen(),
        ),
        redirect: _protectedRouteRedirect,
      ),
      GoRoute(
        path: PrivilegeConstants.employeeManagement,
        builder: (context, state) => PrivilegeRouteGuard(
          requiredPrivilege: PrivilegeConstants.employeeManagement,
          parentPrivilege: PrivilegeConstants.adminDashboard,
          child: EmployeeListPage(authBloc: context.read<AuthBloc>()),
        ),
        redirect: _protectedRouteRedirect,
      ),

      // SYSTEM CONSTANT
      GoRoute(
        path: '/system_constant',
        builder: (context, state) => const SystemConstantsScreen(),
      ),

      // UNAUTHORIZED
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
                  onPressed: () => context.go('/homePage'),
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
              onPressed: () => context.go('/homePage'),
              child: const Text('Go to Dashboard'),
            ),
          ],
        ),
      ),
    ),
  );

  // Redirect logic
  String? _authRedirect(BuildContext context, GoRouterState state) {
    final authState = authBloc.state;

    if (authState.status == AuthStatus.loading) return null;

    if (authState.status == AuthStatus.authenticated) {
      final intended = state.uri.queryParameters['redirect'];
      return intended ?? '/homePage';
    }
    return '/login';
  }

  String? _loginRedirect(BuildContext context, GoRouterState state) {
    if (authBloc.state.status == AuthStatus.authenticated) {
      return '/homePage';
    }
    return null;
  }

  String? _protectedRouteRedirect(BuildContext context, GoRouterState state) {
    final authState = authBloc.state;

    if (authState.status == AuthStatus.loading) return '/auth-check';

    if (authState.status != AuthStatus.authenticated) {
      return '/login?redirect=${Uri.encodeComponent(state.uri.toString())}';
    }

    return null;
  }
}

// Utility to refresh routes when auth state changes
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((dynamic state) {
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
