import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:savvy_stock/core/constants/app_routes.dart';
import 'package:savvy_stock/core/errors/unauthorized_screen.dart';
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
import 'package:savvy_stock/features/sales/sales_item_entry/models/confirmed_item.dart';
import 'package:savvy_stock/features/sales/sales_item_entry/screens/sales_item_entry.dart';
import 'package:savvy_stock/features/system_constant/screen/system_constants_screen.dart';

// Import your screen files for missing routes
// import 'package:savvy_stock/features/sales/sales_entry/screens/sales_entry_screen.dart';
// import 'package:savvy_stock/features/sales/sales_dashboard/screens/sales_dashboard.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class AppRouter {
  final AuthBloc authBloc;
  final bool showOnboarding;
  AppRouter({required this.showOnboarding, required this.authBloc});

  late final GoRouter router = GoRouter(
    navigatorKey: navigatorKey,
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    initialLocation: showOnboarding ? AppRoutes.welcome : AppRoutes.authCheck,
    routes: [
      // Auth Routes
      GoRoute(
        path: AppRoutes.welcome,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.authCheck,
        builder: (context, state) =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        redirect: (context, state) => _authRedirect(context, state),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
        redirect: (context, state) => _loginRedirect(context, state),
      ),
      GoRoute(
        path: AppRoutes.signup,
        builder: (context, state) => const GetStart(),
      ),

      // Main Dashboard
      GoRoute(
        path: AppRoutes.homePage,
        builder: (context, state) => const HomePage(),
        redirect: (context, state) => _protectedRouteRedirect(context, state),
      ),

      // Sales Routes
      GoRoute(
        path: AppRoutes.customerEntry,
        builder: (context, state) => PrivilegeRouteGuard(
          requiredPrivilege: AppRoutes.customerEntry,
          parentPrivilege: AppRoutes.salesDashboard,
          child: const CustomerListPage(),
        ),
        redirect: _protectedRouteRedirect,
      ),
      GoRoute(
        path: AppRoutes.salesCustomerInfo,
        builder: (context, state) => PrivilegeRouteGuard(
          requiredPrivilege: AppRoutes.salesCustomerInfo,
          parentPrivilege: AppRoutes.salesDashboard,
          child: const CustomerInfoScreen(),
        ),
        redirect: _protectedRouteRedirect,
      ),
      GoRoute(
        path: AppRoutes.salesItemEntry,
        builder: (context, state) => PrivilegeRouteGuard(
          requiredPrivilege: AppRoutes.salesItemEntry,
          parentPrivilege: AppRoutes.salesCustomerInfo,
          child: ItemEntryScreen(),
        ),
        redirect: _protectedRouteRedirect,
      ),
      GoRoute(
        path: AppRoutes.paymentSummary,
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
            requiredPrivilege: AppRoutes.paymentSummary,
            parentPrivilege: AppRoutes.salesCustomerInfo,
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
        path: AppRoutes.salesInvoice,
        builder: (context, state) => PrivilegeRouteGuard(
          requiredPrivilege: AppRoutes.salesInvoice,
          parentPrivilege: AppRoutes.salesCustomerInfo,
          child: InvoiceReviewScreen(),
        ),
        redirect: _protectedRouteRedirect,
      ),

      // Admin Routes
      GoRoute(
        path: AppRoutes.roleManagement,
        builder: (context, state) => PrivilegeRouteGuard(
          requiredPrivilege: AppRoutes.roleManagement,
          parentPrivilege: AppRoutes.adminDashboard,
          child: RoleCreationScreen(authBloc: authBloc),
        ),
        redirect: _protectedRouteRedirect,
      ),
      GoRoute(
        path: AppRoutes.privilegeManagement,
        builder: (context, state) => PrivilegeRouteGuard(
          requiredPrivilege: AppRoutes.privilegeManagement,
          parentPrivilege: AppRoutes.adminDashboard,
          child: PrivilegeManagementScreen(authBloc: authBloc),
        ),
        redirect: _protectedRouteRedirect,
      ),
      GoRoute(
        path: AppRoutes.userManagement,
        builder: (context, state) => PrivilegeRouteGuard(
          requiredPrivilege: AppRoutes.userManagement,
          parentPrivilege: AppRoutes.adminDashboard,
          child: const UserCreationScreen(),
        ),
        redirect: _protectedRouteRedirect,
      ),
      GoRoute(
        path: AppRoutes.employeeManagement,
        builder: (context, state) => PrivilegeRouteGuard(
          requiredPrivilege: AppRoutes.employeeManagement,
          parentPrivilege: AppRoutes.adminDashboard,
          child: EmployeeListPage(authBloc: authBloc),
        ),
        redirect: _protectedRouteRedirect,
      ),

      // System Constants
      GoRoute(
        path: AppRoutes.systemConstants,
        builder: (context, state) => const SystemConstantsScreen(),
      ),

      // Unauthorized
      GoRoute(
        path: AppRoutes.unauthorized,
        builder: (context, state) => const UnauthorizedScreen(),
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
              onPressed: () => context.push(AppRoutes.homePage),
              child: const Text('Go to Dashboard'),
            ),
          ],
        ),
      ),
    ),
  );

  // Redirect logic (same as before)
  String? _authRedirect(BuildContext context, GoRouterState state) {
    final authState = authBloc.state;

    if (authState.status == AuthStatus.loading) return null;

    if (authState.status == AuthStatus.authenticated) {
      final intended = state.uri.queryParameters['redirect'];
      return intended ?? AppRoutes.homePage;
    }
    return AppRoutes.login;
  }

  String? _loginRedirect(BuildContext context, GoRouterState state) {
    if (authBloc.state.status == AuthStatus.authenticated) {
      return AppRoutes.homePage;
    }
    return null;
  }

  String? _protectedRouteRedirect(BuildContext context, GoRouterState state) {
    final authState = authBloc.state;

    if (authState.status == AuthStatus.loading) return AppRoutes.authCheck;

    if (authState.status != AuthStatus.authenticated) {
      return '${AppRoutes.login}?redirect=${Uri.encodeComponent(state.uri.toString())}';
    }

    return null;
  }
}

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
