import 'package:flutter/material.dart';

import 'package:pinaka_restaurant_pos/ui/employee_login_page.dart';
import 'package:pinaka_restaurant_pos/ui/tables_screen.dart';
import 'ui/splash_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Employee Login',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: TablesScreen(),
     //home:  const SplashScreen(),
    );
  }
}