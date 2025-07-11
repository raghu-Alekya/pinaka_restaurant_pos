import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pinkapos_restar/screens/dashboard%20screen.dart';
import 'package:pinkapos_restar/bloc/menu_bloc.dart';
import 'package:pinkapos_restar/bloc/order_bloc.dart';
 import 'package:pinkapos_restar/bloc/category_bloc.dart'; // Make sure this path is correct
import 'models/theme/theme_model.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.themeNotifier,
      builder: (_, currentMode, __) {
        return MultiBlocProvider(
          providers: [
            BlocProvider<MenuBloc>(
              create: (_) => MenuBloc(),
            ),
            BlocProvider<OrderBloc>(
              create: (_) => OrderBloc(),
            ),
            BlocProvider<CategoryBloc>(
              create: (_) => CategoryBloc(),
            ),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Pinaka POS',
            theme: ThemeData(
              brightness: Brightness.light,
              primarySwatch: Colors.deepOrange,
              scaffoldBackgroundColor: Colors.white,
              fontFamily: 'Poppins',
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.white,
                elevation: 0,
              ),
            ),
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              scaffoldBackgroundColor: const Color(0xFF1C1C1E),
              fontFamily: 'Poppins',
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFF2C2C2E),
                elevation: 0,
              ),
            ),
            themeMode: currentMode,
            home: const DashboardScreen(),
          ),
        );
      },
    );
  }
}
