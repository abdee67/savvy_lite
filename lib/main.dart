import 'package:flutter/material.dart';
import 'package:savvy_stock/dayTrial.dart';
import 'package:savvy_stock/getStarted.dart';
import 'package:savvy_stock/login.dart';

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
        '/forgot-password': (context) => const TrialPage(),

        //'/register': (context) => const RegisterScreen(),
      },
    );
  }
}
