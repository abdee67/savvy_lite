import 'package:flutter/material.dart';
import 'package:savvy_stock/getStarted.dart';
import 'package:savvy_stock/login.dart';
import 'package:savvy_stock/screens/salesScreen.dart';
import 'package:savvy_stock/trial_page_refactored.dart';

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
        '/salesScreen': (context) => const SalesEntryScreen(),

        //'/register': (context) => const RegisterScreen(),
      },
    );
  }
}
