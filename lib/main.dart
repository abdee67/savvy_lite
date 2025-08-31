import 'package:flutter/material.dart';
import 'package:savvy_stock/features/auth/screens/login_screen.dart';
import 'package:savvy_stock/features/onboarding/screens/trial_screen.dart';
import 'package:savvy_stock/features/onboarding/widgets/getStarted.dart';
import 'package:savvy_stock/features/sales/presentation/screens/sales_dashboard.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/getStarted': (context) => const GetStart(),
        // '/forgot-password': (context) => const TrialPageRefactored(),
        '/register': (context) => const TrialPageRefactored(),
        '/salesScreen': (context) => const SalesDashboard(),

        //'/register': (context) => const RegisterScreen(),
      },
    );
  }
}
