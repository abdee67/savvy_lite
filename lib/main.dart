import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:savvy_stock/core/blocs/system_constant/system_constant_bloc.dart';
import 'package:savvy_stock/core/blocs/system_constant/system_constant_event.dart';
import 'package:savvy_stock/core/config/app_config.dart';
import 'package:savvy_stock/core/di/injection_container.dart';
import 'package:savvy_stock/core/routes/app_router.dart';
import 'package:savvy_stock/core/services/auth/auth_service.dart';
import 'package:savvy_stock/core/services/conectitvity_service.dart';
import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:savvy_stock/core/services/system_constant/system_constant_service.dart';
import 'package:savvy_stock/core/services/udc_service.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/auth/blocs/auth_state.dart';
import 'package:savvy_stock/features/sales/customer/blocs/customer_bloc.dart';
import 'package:savvy_stock/features/sales/invoice/blocs/invoice_bloc.dart';
import 'package:savvy_stock/features/sales/payment/blocs/payment_bloc.dart';
import 'package:savvy_stock/features/sales/sales_item_entry/blocs/sales_item_entry_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/repositories/system_constant_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _initializeAndRunApp();
}

// Add error handling wrapper
Future<void> _initializeAndRunApp() async {
  try {
    await ConnectivityService().initConnectivity();
    initDependencies();
    // await LocalDatabaseService().resetDatabase();

    if (AppConfig.isTestMode) {
      developer.log('🚀 APP RUNNING IN TEST MODE');
      developer.log('📱 API calls bypassed');
      developer.log('💾 Using local database only');
    }
    // Debug database tables (optional - remove in production)
    await LocalDatabaseService().debugTable('role_table');
  } catch (error, stackTrace) {
    developer.log('Initialization error: $error');
    developer.log('Stack trace: $stackTrace');
  }
  runApp(const SavvyStock());
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

  @override
  void initState() {
    super.initState();
    _authBloc = getIt<AuthBloc>();
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

    return MultiProvider(
      providers: [
        // Bloc providers
        // Provide the SAME instance used by AppRouter so redirects react to auth changes
        BlocProvider<AuthBloc>.value(value: _authBloc),
        BlocProvider<CustomerBloc>(create: (context) => CustomerBloc()),
        BlocProvider<ItemEntryBloc>(create: (context) => ItemEntryBloc()),
        BlocProvider<PaymentBloc>(
          create: (context) => PaymentBloc(getIt<SystemConstantsService>()),
        ),
        BlocProvider<InvoiceBloc>(create: (context) => InvoiceBloc()),
        BlocProvider<SystemConstantBloc>(
          create: (context) => SystemConstantBloc(
            systemConstantRepository: getIt<SystemConstantRepository>(),
            // authService: getIt<AuthService>(),
            // Use the same AuthBloc instance to avoid multiple instances
            authBloc: _authBloc,
            udcService: getIt<UdcService>(),
            systemConstantService: getIt<SystemConstantsService>(),
          )..add(LoadSystemConstants()),
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
    );
  }
}
