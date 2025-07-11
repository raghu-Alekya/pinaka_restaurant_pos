import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'employee_login_page.dart';
import 'tables_screen.dart';
import '../../local database/table_dao.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Alignment topPartAlignment = const Alignment(-1.2, -1.2);
  Alignment middlePartAlignment = Alignment.center;
  Alignment bottomPartAlignment = const Alignment(1.2, 1.2);

  double topOpacity = 0.0;
  double middleOpacity = 0.0;
  double bottomOpacity = 0.0;

  double middleScale = 0.2;
  double bottomScale = 0.1;
  double middleRotation = 0.0;

  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        topPartAlignment = const Alignment(0.0, -0.15);
        bottomPartAlignment = const Alignment(0.0, 0.1);
        middlePartAlignment = Alignment.center;
        topOpacity = 1.0;
        middleOpacity = 1.0;
        bottomOpacity = 1.0;
        middleScale = 1.0;
        bottomScale = 1.0;
        middleRotation = 360;
      });
    });
    Timer(const Duration(seconds: 4), _checkLoginStatus);
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();

    final pin = prefs.getString('pin');
    final token = prefs.getString('token');
    final restaurantId = prefs.getString('restaurantId');
    final restaurantName = prefs.getString('restaurantName');

    if (pin != null && token != null && restaurantId != null && restaurantName != null) {
      final tableDao = TableDao();
      final tables = await tableDao.getTablesByManagerPin(pin);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => TablesScreen(
            pin: pin,
            token: token,
            restaurantId: restaurantId,
            restaurantName: restaurantName,
            loadedTables: tables,
          ),
        ),
      );
    } else {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const EmployeeLoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedAlign(
            duration: const Duration(seconds: 3),
            curve: Curves.easeOut,
            alignment: topPartAlignment,
            child: AnimatedOpacity(
              duration: const Duration(seconds: 3),
              opacity: topOpacity,
              child: Image.asset('assets/top.jpg', width: 20),
            ),
          ),
          AnimatedAlign(
            duration: const Duration(seconds: 3),
            curve: Curves.easeOut,
            alignment: middlePartAlignment,
            child: AnimatedOpacity(
              duration: const Duration(seconds: 3),
              opacity: middleOpacity,
              child: AnimatedRotation(
                duration: const Duration(seconds: 3),
                turns: middleRotation / 360,
                curve: Curves.easeOut,
                child: AnimatedScale(
                  duration: const Duration(seconds: 3),
                  scale: middleScale,
                  curve: Curves.easeOut,
                  child: Image.asset('assets/rr.jpg', width: 180),
                ),
              ),
            ),
          ),
          AnimatedAlign(
            duration: const Duration(seconds: 3),
            curve: Curves.easeOut,
            alignment: bottomPartAlignment,
            child: AnimatedOpacity(
              duration: const Duration(seconds: 3),
              opacity: bottomOpacity,
              child: AnimatedScale(
                duration: const Duration(seconds: 3),
                scale: bottomScale,
                curve: Curves.easeOut,
                child: Image.asset('assets/lp.jpg', width: 130),
              ),
            ),
          ),
        ],
      ),
    );
  }
}