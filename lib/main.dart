import 'dart:async';
import 'dart:developer' as developer;
import 'package:device_preview/device_preview.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:savvy_stock/features/FSNMR/blocs/FSNMR_bloc.dart';
import 'package:savvy_stock/features/auth/blocs/password_reset/password_reset_bloc.dart';

import 'package:savvy_stock/features/company/blocs/company_bloc.dart';
import 'package:savvy_stock/features/licensing/bloc/license_bloc.dart';
import 'package:savvy_stock/features/licensing/services/license_service.dart';
import 'package:savvy_stock/features/purchase/other_expenses/bloc/other_expenses_bloc.dart';
import 'package:savvy_stock/features/purchase/purchase_entry/bloc/purchase_order_bloc.dart';

import 'package:savvy_stock/features/purchase/supplier_entry/blocs/supplier_bloc.dart';

import 'package:savvy_stock/features/registration/blocs/registration_bloc.dart';

import 'package:savvy_stock/features/reports/cash_flow/bloc/cash_flow_bloc.dart';

import 'package:savvy_stock/features/sales/quotation_order/bloc/quotation_order_bloc.dart';

import 'package:savvy_stock/features/sales/sales_order/invoice/detail/bloc/invoice_detail_bloc.dart';

import 'package:savvy_stock/features/sales/sales_order/invoice/header/bloc/invoice_header_bloc.dart';

import 'package:savvy_stock/features/sales/sales_order/detail/bloc/sales_order_detail_bloc.dart';

import 'package:savvy_stock/features/sales/sales_order/integration/bloc/sales_order_coordinator_bloc.dart';

import 'package:savvy_stock/features/sales/sales_return/bloc/sales_return_bloc.dart';

import 'package:savvy_stock/features/system_constant/bloc/system_constant_bloc.dart';
import 'package:savvy_stock/features/system_constant/bloc/system_constant_event.dart';
import 'package:savvy_stock/core/config/app_config.dart';
import 'package:savvy_stock/core/constants/app_routes.dart';
import 'package:savvy_stock/core/di/injection_container.dart';

import 'package:savvy_stock/core/routes/app_router.dart';
import 'package:savvy_stock/core/services/conectitvity_service.dart';
import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:savvy_stock/core/services/supabase/supabase_service.dart';
import 'package:savvy_stock/features/admin/employees/blocs/employee_bloc.dart';
import 'package:savvy_stock/features/admin/privilege/blocs/privilege_bloc.dart';
import 'package:savvy_stock/features/admin/role/blocs/role_bloc.dart';
import 'package:savvy_stock/features/admin/users/blocs/user_bloc.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/auth/blocs/auth_state.dart';
import 'package:savvy_stock/features/branch_list/blocs/branch_list_bloc.dart';
import 'package:savvy_stock/features/next_number/bloc/next_number_bloc.dart';

import 'package:savvy_stock/features/sales/customer/blocs/customer_bloc.dart';
import 'package:savvy_stock/features/sales/sales_order/sales_item_entry/blocs/sales_item_entry_bloc.dart';
import 'package:savvy_stock/features/stock/item_uom_conversions/blocs/item_uom_conversions_bloc.dart';
import 'package:savvy_stock/features/stock/item_cost/blocs/item_cost_bloc.dart';

import 'package:savvy_stock/features/stock/item_entry/blocs/item_entry_bloc.dart';

import 'package:savvy_stock/features/stock/item_entry_workbench/blocs/item_master_bloc.dart';

import 'package:savvy_stock/features/stock/item_in_branch/blocs/item_in_branch_bloc.dart';

import 'package:savvy_stock/features/stock/item_locations/blocs/item_locations_bloc.dart';

import 'package:savvy_stock/features/stock/item_transactions/blocs/item_transaction_bloc.dart';

import 'package:savvy_stock/features/stock/location_entry/blocs/location_master_bloc.dart';

import 'package:savvy_stock/features/stock/lot_coloring/bloc/lot_coloring_bloc.dart';
import 'package:savvy_stock/features/stock/lot_master/blocs/lot_master_bloc.dart';

import 'package:savvy_stock/features/sales/sales_order/header/bloc/sales_order_header_bloc.dart';

import 'package:savvy_stock/features/udc_detail/blocs/udc_detail_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _initializeAndRunApp();
  //clearAllSharedPreferences();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
}

// Add error handling wrapper
Future<void> _initializeAndRunApp() async {
  try {
    await ConnectivityService().initConnectivity();
    initDependencies();
    await SupabaseService.initialize();
    await getIt<LicenseService>().initialize();

    if (AppConfig.isTestMode) {
      developer.log('🚀 APP RUNNING IN TEST MODE');
      developer.log('📱 API calls bypassed');
      developer.log('💾 Using local database only');
    }
    if (kDebugMode) {
      //await LocalDatabaseService().resetDatabase();
      ///await getIt<LicenseService>().clearLicense();
      //  // await LocalDatabaseService().debugTable('branch_table');
      //await LocalDatabaseService().debugTable('items_in_branch');
      //await LocalDatabaseService().debugTable('item_cost');
      //await LocalDatabaseService().debugTable('item_location');
      //await LocalDatabaseService().debugTable('lot_master');
      //await LocalDatabaseService().debugTable('item_master');
      //await LocalDatabaseService().debugTable('items_table');
      // await LocalDatabaseService().debugTable('sales_order_header');
      //await LocalDatabaseService().debugTable('credit_receipt_table');
      //await LocalDatabaseService().debugTable('sales_order_details');
      //await LocalDatabaseService().debugTable('sales_return_header');
      //await LocalDatabaseService().debugTable('sales_return_details');
      //await LocalDatabaseService().debugTable('invoice_history_header');
      //await LocalDatabaseService().debugTable('fs_table');
      // await LocalDatabaseService().debugTable('invoice_history_detail');
      // await LocalDatabaseService().debugTable('item_transactions');
      // await LocalDatabaseService().debugTable('item_uom_conversions');
      // await LocalDatabaseService().debugTable('quote_order_header');
      //await LocalDatabaseService().debugTable('quote_order_details');
      // await LocalDatabaseService().debugTable('supplier_table');
      //await LocalDatabaseService().debugTable('purchase_order_header');
      // await LocalDatabaseService().debugTable('purchase_order_detail');
      //await LocalDatabaseService().debugTable('purchase_order_receiver');
      //await LocalDatabaseService().debugTable('credit_payment_table');
      //await LocalDatabaseService().debugTable('company_table');
      //await LocalDatabaseService().debugTable('udc_details');
      //await LocalDatabaseService().debugTable('user_table');
      //await LocalDatabaseService().debugTable('user_role');
      //await LocalDatabaseService().debugTable('role_privilege');
      //await LocalDatabaseService().debugTable('other_expense_table');
      await LocalDatabaseService().debugTable('next_number');
    }
  } catch (error, stackTrace) {
    if (kDebugMode) {
      developer.log('Initialization error: $error');
      developer.log('Stack trace: $stackTrace');
    }
  }
  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      builder: (context) => const SavvyStock(),
    ),
  );
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
  late SystemConstantBloc _systemConstantBloc;

  @override
  void initState() {
    super.initState();
    _authBloc = getIt<AuthBloc>();
    _userBloc = getIt<UserBloc>();
    _systemConstantBloc = getIt<SystemConstantBloc>();

    // Ensure system constants are loaded when companyId becomes available.
    final cid = _authBloc.state.companyId;
    if (cid != null) {
      _systemConstantBloc.add(LoadSystemConstants(cid));
    } else {
      // Listen once for the companyId and load constants when available.
      _authBloc.stream.listen((s) {
        if (s.companyId != null) {
          _systemConstantBloc.add(LoadSystemConstants(s.companyId!));
        }
      });
    }

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
        useInheritedMediaQuery: true,
        locale: DevicePreview.locale(context),
        builder: DevicePreview.appBuilder,
        home: Scaffold(
          body: SafeArea(
            child: Center(
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
        ),
      );
    }

    if (hasError) {
      return MaterialApp(
        home: Scaffold(
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red),
                    SizedBox(height: 16),
                    Text(
                      'Initialization Error',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
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
            create: (context) => getIt<EmployeeBloc>(),
          ),
          BlocProvider<UserBloc>(create: (context) => getIt<UserBloc>()),
          BlocProvider<PrivilegeBloc>(
            create: (context) => getIt<PrivilegeBloc>(),
          ),
          BlocProvider<RoleBloc>(create: (context) => getIt<RoleBloc>()),
          BlocProvider<CustomerBloc>(
            create: (context) => getIt<CustomerBloc>(),
          ),
          BlocProvider<ItemEntryBloc>(
            create: (context) => getIt<ItemEntryBloc>(),
          ),
          // Use the singleton from the DI container so everyone shares the same
          // SystemConstantBloc instance.
          BlocProvider<SystemConstantBloc>.value(value: _systemConstantBloc),
          BlocProvider<BranchBloc>(create: (context) => getIt<BranchBloc>()),
          BlocProvider<StockItemsEntryBloc>(
            create: (context) => getIt<StockItemsEntryBloc>(),
          ),
          BlocProvider<StockItemInBranchBloc>(
            create: (context) => getIt<StockItemInBranchBloc>(),
          ),
          BlocProvider<ItemUomConversionBloc>(
            create: (context) => getIt<ItemUomConversionBloc>(),
          ),
          BlocProvider<UdcDetailsBloc>(
            create: (context) => getIt<UdcDetailsBloc>(),
          ),
          BlocProvider<LocationMasterBloc>(
            create: (context) => getIt<LocationMasterBloc>(),
          ),
          BlocProvider<NextNumberBloc>(
            create: (context) => getIt<NextNumberBloc>(),
          ),
          BlocProvider<StockItemLocationBloc>(
            create: (context) => getIt<StockItemLocationBloc>(),
          ),
          BlocProvider<LotMasterBloc>(
            create: (context) => getIt<LotMasterBloc>(),
          ),
          BlocProvider<LotExpirationColorsBloc>(
            create: (context) => getIt<LotExpirationColorsBloc>(),
          ),
          BlocProvider<ItemCostBloc>(
            create: (context) => getIt<ItemCostBloc>(),
          ),
          BlocProvider<ItemTransactionsBloc>(
            create: (context) => getIt<ItemTransactionsBloc>(),
          ),
          BlocProvider<ItemMasterBloc>(
            create: (context) => getIt<ItemMasterBloc>(),
          ),
          BlocProvider<SalesOrderHeaderBloc>(
            create: (context) => getIt<SalesOrderHeaderBloc>(),
          ),
          BlocProvider<SalesOrderDetailBloc>(
            create: (context) => getIt<SalesOrderDetailBloc>(),
          ),
          BlocProvider<SalesOrderCoordinatorBloc>(
            create: (context) => getIt<SalesOrderCoordinatorBloc>(),
          ),
          BlocProvider<InvoiceHistoryHeaderBloc>(
            create: (context) => getIt<InvoiceHistoryHeaderBloc>(),
          ),
          BlocProvider<InvoiceHistoryDetailBloc>(
            create: (context) => getIt<InvoiceHistoryDetailBloc>(),
          ),
          BlocProvider<SalesReturnBloc>(
            create: (context) => getIt<SalesReturnBloc>(),
          ),
          BlocProvider<QuotationOrderBloc>(
            create: (context) => getIt<QuotationOrderBloc>(),
          ),
          // Purchase Blocs
          BlocProvider<SupplierBloc>(
            create: (context) => getIt<SupplierBloc>(),
          ),
          BlocProvider<PurchaseOrderBloc>(
            create: (context) => getIt<PurchaseOrderBloc>(),
          ),
          BlocProvider<CashFlowBloc>(
            create: (context) => getIt<CashFlowBloc>(),
          ),
          BlocProvider<CompanyBloc>(create: (context) => getIt<CompanyBloc>()),
          BlocProvider<FSNMRBloc>(create: (context) => getIt<FSNMRBloc>()),
          BlocProvider<RegistrationBloc>(
            create: (context) => getIt<RegistrationBloc>(),
          ),
          BlocProvider<LicenseBloc>(create: (context) => getIt<LicenseBloc>()),
          BlocProvider<OtherExpensesBloc>(
            create: (context) => getIt<OtherExpensesBloc>(),
          ),
          BlocProvider<PasswordResetBloc>(
            create: (context) => getIt<PasswordResetBloc>(),
          ),
        ],
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: 'Savvy Lite',
          routerConfig: _router,
          theme: ThemeData(
            appBarTheme: AppBarTheme(
              backgroundColor: Color.fromARGB(255, 8, 33, 102),
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
                backgroundColor: Color.fromARGB(255, 8, 33, 102),
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
