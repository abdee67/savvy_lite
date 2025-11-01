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
import 'package:savvy_stock/core/repositories/udc_repository.dart';
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
import 'package:savvy_stock/features/next_number/bloc/next_number_bloc.dart';
import 'package:savvy_stock/features/sales/customer/blocs/customer_bloc.dart';
import 'package:savvy_stock/features/sales/invoice/blocs/invoice_bloc.dart';
import 'package:savvy_stock/features/sales/payment/blocs/payment_bloc.dart';
import 'package:savvy_stock/features/sales/sales_item_entry/blocs/sales_item_entry_bloc.dart';
import 'package:savvy_stock/features/stock/item_UoM_conversions/blocs/item_UoM_conversions_bloc.dart';
import 'package:savvy_stock/features/stock/item_UoM_conversions/item_uom_conv_repo.dart';
import 'package:savvy_stock/features/stock/item_cost/blocs/item_cost_bloc.dart';
import 'package:savvy_stock/features/stock/item_cost/repo/item_cost_repository.dart';
import 'package:savvy_stock/features/stock/item_entry/blocs/item_entry_bloc.dart';
import 'package:savvy_stock/features/stock/item_entry/data/item_repository.dart';
import 'package:savvy_stock/features/stock/item_entry_workbench.dart/blocs/item_master_bloc.dart';
import 'package:savvy_stock/features/stock/item_entry_workbench.dart/repo/item_master_repo.dart';
import 'package:savvy_stock/features/stock/item_in_branch/blocs/item_in_branch_bloc.dart';
import 'package:savvy_stock/features/stock/item_in_branch/repo/item_in_branch_repo.dart';
import 'package:savvy_stock/features/stock/item_locations/blocs/item_locations_bloc.dart';
import 'package:savvy_stock/features/stock/item_locations/repo/item_location_repo.dart';
import 'package:savvy_stock/features/stock/item_transactions/blocs/item_transaction_bloc.dart';
import 'package:savvy_stock/features/stock/item_transactions/repo/item_transaction_repo.dart';
import 'package:savvy_stock/features/stock/location_entry/blocs/location_master_bloc.dart';
import 'package:savvy_stock/features/stock/lot_coloring/bloc/lot_coloring_bloc.dart';
import 'package:savvy_stock/features/stock/lot_master/blocs/lot_master_bloc.dart';
import 'package:savvy_stock/features/stock/sales_order_detail/model/sales_order_detail.dart';
import 'package:savvy_stock/features/stock/sales_order_header/bloc/sales_order_header_bloc.dart';
import 'package:savvy_stock/features/stock/sales_order_header/repo/sales_order_header_repo.dart';
import 'package:savvy_stock/features/udc_detail/blocs/udc_detail_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    // await LocalDatabaseService().resetDatabase();
    // await LocalDatabaseService().debugTable('branch_table');

    if (AppConfig.isTestMode) {
      developer.log('🚀 APP RUNNING IN TEST MODE');
      developer.log('📱 API calls bypassed');
      developer.log('💾 Using local database only');
    }
    // Debug database tables (optional - remove in production)
    await LocalDatabaseService().debugTable('item_transactions');
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
  late NextNumberBloc _nextNumberBloc;
  late SystemConstantBloc _systemConstantBloc;
  late UdcDetailsBloc _udcDetailsBloc;
  late LotExpirationColorsBloc _lotExpirationColorsBloc;
  late StockItemInBranchRepository _stockItemInBranchRepository;
  late StockItemInBranchBloc _stockItemInBranchBloc;
  late ItemTransactionRepository _itemTransactionsRepository;
  late SalesOrderDetail _salesOrderDetail;
  late SalesOrderHeaderRepository _salesOrderHeaderRepository;
  late SalesOrderHeaderBloc _salesOrderHeaderBloc;
  late StockItemsEntryBloc _stockItemEntryBloc;
  late StockItemsEntryRepository _stockItemsEntryRepository;
  late ItemTransactionsBloc _itemTransactionsBloc;
  late LotMasterBloc _lotMasterBloc;
  late ItemUomConversionBloc _itemUomConversionsBloc;
  late StockItemLocationBloc _stockItemLocationBloc;
  late LocationMasterBloc _locationMasterBloc;
  // final NotificationTableBloc notificationTableBloc;
  late ItemCostBloc _itemCostBloc;
  late ItemCostRepository _itemCostRepository;
  late ItemUomConversionsRepository _itemUomConversionRepository;
  late ItemLocationsRepository _stockItemLocationRepository;
  late UdcRepository _udcRepository;
  late ItemMasterRepository _itemMasterRepository;

  @override
  void initState() {
    super.initState();
    _udcRepository = getIt<UdcRepository>();
    _authBloc = getIt<AuthBloc>();
    _userBloc = getIt<UserBloc>();
    _nextNumberBloc = getIt<NextNumberBloc>();
    _stockItemEntryBloc = getIt<StockItemsEntryBloc>();
    _systemConstantBloc = getIt<SystemConstantBloc>();
    _udcDetailsBloc = getIt<UdcDetailsBloc>();
    _lotExpirationColorsBloc = getIt<LotExpirationColorsBloc>();
    _stockItemInBranchBloc = getIt<StockItemInBranchBloc>();
    _stockItemInBranchRepository = getIt<StockItemInBranchRepository>();
    _stockItemLocationBloc = getIt<StockItemLocationBloc>();
    _stockItemLocationRepository = getIt<ItemLocationsRepository>();
    _salesOrderHeaderRepository = getIt<SalesOrderHeaderRepository>();
    _salesOrderHeaderBloc = getIt<SalesOrderHeaderBloc>();
    _itemTransactionsRepository = getIt<ItemTransactionRepository>();
    _stockItemsEntryRepository = getIt<StockItemsEntryRepository>();
    _itemTransactionsBloc = getIt<ItemTransactionsBloc>();
    _lotMasterBloc = getIt<LotMasterBloc>();
    _locationMasterBloc = getIt<LocationMasterBloc>();
    _itemUomConversionsBloc = getIt<ItemUomConversionBloc>();
    _itemUomConversionRepository = getIt<ItemUomConversionsRepository>();
    _itemCostRepository = getIt<ItemCostRepository>();
    _itemCostBloc = getIt<ItemCostBloc>();
    _itemMasterRepository = getIt<ItemMasterRepository>();

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
          // Use the singleton from the DI container so everyone shares the same
          // SystemConstantBloc instance (prevents multiple instances with
          // differing states which broke color calculation).
          BlocProvider<SystemConstantBloc>.value(
            value: getIt<SystemConstantBloc>(),
          ),
          BlocProvider<BranchBloc>(
            create: (context) =>
                BranchBloc(databaseService: getIt(), authBloc: _authBloc),
          ),
          BlocProvider<StockItemsEntryBloc>(
            create: (context) => StockItemsEntryBloc(
              repository: _stockItemsEntryRepository,
              authBloc: _authBloc,
              systemConstantBloc: _systemConstantBloc,
              itemsInBranchBloc: _stockItemInBranchBloc,
            ),
          ),
          BlocProvider<StockItemInBranchBloc>(
            create: (context) => StockItemInBranchBloc(
              repository: _stockItemInBranchRepository,
              authBloc: _authBloc,
              systemConstantBloc: _systemConstantBloc,
              lotMasterBloc: _lotMasterBloc,
              //itemCostBloc: _itemCostBloc,
              itemTransactionsRepository: _itemTransactionsRepository,
              itemUomConversionsBloc: _itemUomConversionRepository,
            ),
          ),
          BlocProvider<ItemUomConversionBloc>(
            create: (context) => ItemUomConversionBloc(
              repository: _itemUomConversionRepository,
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
          BlocProvider<NextNumberBloc>(
            create: (context) =>
                NextNumberBloc(databaseService: getIt(), authBloc: _authBloc),
          ),
          BlocProvider<StockItemLocationBloc>(
            create: (context) => StockItemLocationBloc(
              repository: _stockItemLocationRepository,
              authBloc: _authBloc,
            ),
          ),
          BlocProvider<LotMasterBloc>(
            create: (context) => LotMasterBloc(
              repository: getIt(),
              udcRepository: _udcRepository,
              authBloc: _authBloc,
              systemConstantBloc: _systemConstantBloc,
              nextNumberBloc: _nextNumberBloc,
              lotExpirationColorsBloc: _lotExpirationColorsBloc,
            ),
          ),
          BlocProvider<LotExpirationColorsBloc>(
            create: (context) => LotExpirationColorsBloc(
              databaseService: getIt(),
              authBloc: _authBloc,
              systemConstantBloc: _systemConstantBloc,
            ),
          ),
          BlocProvider<ItemCostBloc>(
            create: (context) => ItemCostBloc(
              repository: _itemCostRepository,
              authBloc: _authBloc,
              itemUomConversionsController: _itemUomConversionRepository,
              itemsInBranchController: _stockItemInBranchBloc,
              systemConstantController: _systemConstantBloc,
            ),
          ),
          BlocProvider<ItemTransactionsBloc>(
            create: (context) => ItemTransactionsBloc(
              salesOrderHeaderController: _salesOrderHeaderBloc,
              itemsTableController: _stockItemEntryBloc,
              repository: _itemTransactionsRepository,
              authBloc: _authBloc,
              udcRepository: _udcRepository,
              systemConstantBloc: _systemConstantBloc,
              nextNumberBloc: _nextNumberBloc,
            ),
          ),
          BlocProvider<ItemMasterBloc>(
            create: (context) => ItemMasterBloc(
              repository: _itemMasterRepository,
              authBloc: _authBloc,
              locationMasterBloc: _locationMasterBloc,
              lotMasterBloc: _lotMasterBloc,
              itemCostBloc: _itemCostBloc,
              itemLocationsBloc: _stockItemLocationBloc,
              itemsEntryBloc: _stockItemEntryBloc,
              itemsInBranchBloc: _stockItemInBranchBloc,
              systemConstantBloc: _systemConstantBloc,
              udcDetailsBloc: _udcDetailsBloc,
              nextNumberBloc: _nextNumberBloc,
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
