import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:savvy_stock/core/blocs/system_constant/system_constant_bloc.dart';
import 'package:savvy_stock/core/blocs/system_constant/system_constant_event.dart';
import 'package:savvy_stock/core/config/app_config.dart';
import 'package:savvy_stock/core/constants/app_routes.dart';
import 'package:savvy_stock/core/di/injection_container.dart';
import 'package:savvy_stock/core/routes/app_router.dart';
import 'package:savvy_stock/core/services/conectitvity_service.dart';
import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:savvy_stock/core/services/system_constant/system_constant_service.dart';
import 'package:savvy_stock/features/admin/employees/blocs/employee_bloc.dart';
import 'package:savvy_stock/features/admin/privilege/blocs/privilege_bloc.dart';
import 'package:savvy_stock/features/admin/role/blocs/role_bloc.dart';
import 'package:savvy_stock/features/admin/users/blocs/user_bloc.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/auth/blocs/auth_state.dart';
import 'package:savvy_stock/features/branch_list/blocs/branch_list_bloc.dart';
import 'package:savvy_stock/features/sales/customer/blocs/customer_bloc.dart';
import 'package:savvy_stock/features/sales/invoice/blocs/invoice_bloc.dart';
import 'package:savvy_stock/features/sales/payment/blocs/payment_bloc.dart';
import 'package:savvy_stock/features/sales/sales_item_entry/blocs/sales_item_entry_bloc.dart';
import 'package:savvy_stock/features/stock/item_UoM_conversions/blocs/item_UoM_conversions_bloc.dart';
import 'package:savvy_stock/features/stock/item_entry/blocs/item_entry_bloc.dart';
import 'package:savvy_stock/features/stock/item_in_branch/blocs/item_in_branch_bloc.dart';
import 'package:savvy_stock/features/stock/location_entry/blocs/location_master_bloc.dart';
import 'package:savvy_stock/features/udc_detail/blocs/udc_detail_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/repositories/system_constant_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _initializeAndRunApp();
  //  clearAllSharedPreferences();
}

// Add error handling wrapper
Future<void> _initializeAndRunApp() async {
  try {
    await ConnectivityService().initConnectivity();
    initDependencies();
    //await LocalDatabaseService().resetDatabase();
    // await LocalDatabaseService().debugTable('branch_table');

    if (AppConfig.isTestMode) {
      developer.log('🚀 APP RUNNING IN TEST MODE');
      developer.log('📱 API calls bypassed');
      developer.log('💾 Using local database only');
    }
    // Debug database tables (optional - remove in production)
    await LocalDatabaseService().debugTable('location_master');
  } catch (error, stackTrace) {
    developer.log('Initialization error: $error');
    developer.log('Stack trace: $stackTrace');
  }
  runApp(const SavvyStock());
}

Future<void> clearAllSharedPreferences() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();
}

class SavvyStock extends StatefulWidget {
  const SavvyStock({super.key});
  @override
  State<SavvyStock> createState() => _SavvyStockState();
}

class _SavvyStockState extends State<SavvyStock> {
  bool showOnboarding = true;
  bool isLoading = true;
  bool hasError = false;
  String? errorMessage;
  late GoRouter _router;
  late AuthBloc _authBloc;
  late UserBloc _userBloc;

  @override
  void initState() {
    super.initState();
    _authBloc = getIt<AuthBloc>();
    _userBloc = getIt<UserBloc>();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

      setState(() {
        showOnboarding = !hasSeenOnboarding;
        isLoading = false;
      });

      // Initialize router after onboarding status is determined
      _router = AppRouter(
        showOnboarding: showOnboarding,
        authBloc: _authBloc,
        userBloc: _userBloc,
      ).router;
    } catch (e) {
      setState(() {
        hasError = true;
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Initializing Savvy Stock...'),
              ],
            ),
          ),
        ),
      );
    }

    if (hasError) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    'Initialization Error',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    errorMessage ?? 'Unknown error occurred',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _initializeApp,
                    child: Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return _AppWrapper(
      authBloc: _authBloc,
      router: _router,
      child: MultiBlocProvider(
        providers: [
          // Bloc providers
          BlocProvider<AuthBloc>.value(value: _authBloc),
          BlocProvider<EmployeeBloc>(
            create: (context) =>
                EmployeeBloc(databaseService: getIt(), authBloc: _authBloc),
          ),
          BlocProvider<UserBloc>(
            create: (context) =>
                UserBloc(databaseService: getIt(), authBloc: _authBloc),
          ),
          BlocProvider<PrivilegeBloc>(
            create: (context) =>
                PrivilegeBloc(databaseService: getIt(), authBloc: _authBloc),
          ),
          BlocProvider<RoleBloc>(
            create: (context) =>
                RoleBloc(databaseService: getIt(), authBloc: _authBloc),
          ),
          BlocProvider<CustomerBloc>(
            create: (context) =>
                CustomerBloc(authBloc: _authBloc, databaseService: getIt()),
          ),
          BlocProvider<ItemEntryBloc>(create: (context) => ItemEntryBloc()),
          BlocProvider<PaymentBloc>(
            create: (context) => PaymentBloc(getIt<SystemConstantsService>()),
          ),
          BlocProvider<InvoiceBloc>(create: (context) => InvoiceBloc()),
          BlocProvider<SystemConstantBloc>(
            create: (context) => SystemConstantBloc(
              systemConstantRepository: getIt<SystemConstantRepository>(),
              authBloc: _authBloc,
              systemConstantService: getIt<SystemConstantsService>(),
            )..add(LoadSystemConstants(_authBloc.state.companyId!)),
          ),
          BlocProvider<BranchBloc>(
            create: (context) =>
                BranchBloc(databaseService: getIt(), authBloc: _authBloc),
          ),
          BlocProvider<StockItemEntryBloc>(
            create: (context) => StockItemEntryBloc(
              databaseService: getIt(),
              authBloc: _authBloc,
            ),
          ),
          BlocProvider<StockItemInBranchBloc>(
            create: (context) => StockItemInBranchBloc(
              databaseService: getIt(),
              authBloc: _authBloc,
            ),
          ),
          BlocProvider<ItemUomConversionBloc>(
            create: (context) => ItemUomConversionBloc(
              databaseService: getIt(),
              authBloc: _authBloc,
            ),
          ),
          BlocProvider<UdcDetailsBloc>(
            create: (context) =>
                UdcDetailsBloc(databaseService: getIt(), authBloc: _authBloc),
          ),
          BlocProvider<LocationMasterBloc>(
            create: (context) => LocationMasterBloc(
              databaseService: getIt(),
              authBloc: _authBloc,
            ),
          ),
        ],
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: 'Savvy Stock',
          routerConfig: _router,
          theme: ThemeData(
            primarySwatch: Colors.deepPurple,
            appBarTheme: AppBarTheme(
              backgroundColor: Color(0xFF155888),
              foregroundColor: Colors.white,
              elevation: 0,
              iconTheme: IconThemeData(color: Colors.white),
            ),
            fontFamily: 'Montserrat',
            scaffoldBackgroundColor: Colors.grey[50],
            inputDecorationTheme: InputDecorationTheme(
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF155888),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Wrapper widget to handle auth state changes safely
class _AppWrapper extends StatefulWidget {
  final AuthBloc authBloc;
  final GoRouter router;
  final Widget child;

  const _AppWrapper({
    required this.authBloc,
    required this.router,
    required this.child,
  });

  @override
  State<_AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<_AppWrapper> {
  @override
  void initState() {
    super.initState();

    // Listen for logout events and handle navigation safely
    widget.authBloc.stream.listen((state) {
      if (state.status == AuthStatus.unauthenticated &&
          state.message?.contains('logout') == true) {
        // Use a post-frame callback to ensure safe navigation
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // Navigate to login screen safely
          if (mounted) {
            widget.router.push(AppRoutes.login);
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
