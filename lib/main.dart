import 'package:flutter/material.dart';
import 'Manager flow/ui/splash_screen.dart';

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
      //home: TablesScreen(),
     home:  const SplashScreen(),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:sqflite_common_ffi/sqflite_ffi.dart'; // Add this
// import 'Manager flow/ui/splash_screen.dart';
//
// void main() {
//   // Required to support sqflite on Windows
//   sqfliteFfiInit();
//   databaseFactory = databaseFactoryFfi;
//
//   runApp(const MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'Employee Login',
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//       ),
//       home: const SplashScreen(),
//     );
//   }
// }
