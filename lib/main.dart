import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:savvy_stock/core/blocs/system_constant/system_constant_bloc.dart';
import 'package:savvy_stock/core/blocs/system_constant/system_constant_event.dart';
import 'package:savvy_stock/core/di/injection_container.dart';
import 'package:savvy_stock/core/repositories/system_repository.dart';
import 'package:savvy_stock/core/routes/app_router.dart';
import 'package:savvy_stock/core/services/auth_services/auth_service.dart';
import 'package:savvy_stock/features/sales/customer/blocs/customer_bloc.dart';
import 'package:savvy_stock/features/sales/invoice/blocs/invoice_bloc.dart';
import 'package:savvy_stock/features/sales/payment/blocs/payment_bloc.dart';
import 'package:savvy_stock/features/sales/sales_item_entry/blocs/sales_item_entry_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/repositories/system_constant_repository.dart';
//import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await dotenv.load(fileName: ".env");

  await initDependencies();
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
  late GoRouter _router;

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;
      setState(() {
        showOnboarding = !hasSeenOnboarding;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        showOnboarding = true;
        isLoading = false;
      });
    }

    // Initialize router after onboarding status is determined
    _router = AppRouter(showOnboarding: showOnboarding).router;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }
    return MultiProvider(
      providers: [
        // Bloc providers
        BlocProvider<CustomerBloc>(create: (context) => CustomerBloc()),
        BlocProvider<ItemEntryBloc>(create: (context) => ItemEntryBloc()),
        BlocProvider<PaymentBloc>(create: (context) => PaymentBloc()),
        BlocProvider<InvoiceBloc>(create: (context) => InvoiceBloc()),
        BlocProvider<SystemConstantBloc>(
          create: (context) => SystemConstantBloc(
            systemConstantRepository: getIt<SystemConstantRepository>(),
            authService: getIt<AuthService>(),
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
          ),
          fontFamily: 'Montserrat',
        ),
      ),
    );
  }
}
