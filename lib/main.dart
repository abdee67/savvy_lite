import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:savvy_stock/features/onboarding/screens/welcome_screen.dart';
import 'package:savvy_stock/features/onboarding/widgets/getStarted.dart';
import 'package:savvy_stock/features/sales/customer/blocs/customer_bloc.dart';
import 'package:savvy_stock/features/sales/customer/blocs/customer_event.dart';
import 'package:savvy_stock/features/sales/payment/screens/paymentSummary.dart';
import 'package:savvy_stock/features/sales/presentation/screens/sales_dashboard.dart';
import 'package:savvy_stock/features/sales/sales_item_entry/blocs/sales_item_entry_bloc.dart';
import 'package:savvy_stock/features/sales/sales_item_entry/blocs/sales_item_entry_event.dart';
import 'package:savvy_stock/features/sales/sales_item_entry/screens/sales_item_entry.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    // Initialize BLoCs first
    final customerBloc = CustomerBloc()..add(LoadCustomers());
    final itemEntryBloc = ItemEntryBloc()..add(LoadItemsAndStores());

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: customerBloc),
        BlocProvider.value(value: itemEntryBloc),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'Savvy Stock',
        routerConfig: _buildRouter(itemEntryBloc, customerBloc),
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

  // Build router with access to BLoCs
  GoRouter _buildRouter(
    ItemEntryBloc itemEntryBloc,
    CustomerBloc customerBloc,
  ) {
    return GoRouter(
      initialLocation: showOnboarding ? '/welcome' : '/sales-dashboard',
      routes: [
        GoRoute(
          path: '/welcome',
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/sales-dashboard',
          builder: (context, state) => const SalesDashboard(),
        ),
        GoRoute(path: '/signup', builder: (context, state) => const GetStart()),
        GoRoute(
          path: '/sales-item-entry-screen',
          builder: (context, state) => const ItemEntryScreen(),
        ),
        // Your other routes...
        GoRoute(
          path: '/payment-screen',
          builder: (context, state) {
            final bloc = BlocProvider.of<ItemEntryBloc>(context);
            print(
              'Order confirmed- Items: ${bloc.state.confirmedItems.length}, Total Amount: ${bloc.state.totalAmount}, bloc state: ${bloc.state}',
            );

            return PaymentScreen(
              confirmedItems: bloc.state.confirmedItems,
              totalAmount: bloc.state.totalAmount,
            );
          },
        ),
        // Add other routes here
      ],
    );
  }
}
