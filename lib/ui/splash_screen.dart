import 'dart:async';
import 'package:flutter/material.dart';
import 'employee_login_page.dart';

/// SplashScreen widget that displays an animated logo and text before navigating to the login page.
/// It utilizes various Flutter animations such as `AnimatedAlign`, `AnimatedOpacity`, `AnimatedScale`, and `AnimatedRotation`
/// to create a smooth transition effect.

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

/// State class for SplashScreen that handles animations and automatic navigation to the next screen.
class _SplashScreenState extends State<SplashScreen> {
  // Initial positions for animations
  Alignment topPartAlignment = const Alignment(-1.2, -1.2);
  Alignment middlePartAlignment = Alignment.center;
  Alignment bottomPartAlignment = const Alignment(1.2, 1.2);

  // Initial opacities for fade-in effect
  double topOpacity = 0.0;
  double middleOpacity = 0.0;
  double bottomOpacity = 0.0;

  // Scaling and rotation variables
  double middleScale = 0.2;
  double bottomScale = 0.1;
  double middleRotation = 0.0;

  /// Called when the state is initialized. Triggers animations and navigation.
  @override
  void initState() {
    super.initState();

    // Delayed animation start
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        // Updating alignments for animation
        topPartAlignment = const Alignment(0.0, -0.15);
        bottomPartAlignment = const Alignment(0.0, 0.1);
        middlePartAlignment = Alignment.center;

        // Making images fully visible
        topOpacity = 1.0;
        middleOpacity = 1.0;
        bottomOpacity = 1.0;

        // Scaling and rotating elements
        middleScale = 1.0;
        bottomScale = 1.0;
        middleRotation = 360;
      });
    });

    // Timer to navigate to the next screen after 4 seconds
    Timer(const Duration(seconds: 4), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const EmployeeLoginPage()),
      );
    });
  }

  /// Builds the UI for the splash screen with animated elements.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Top part (Arrow animation)
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

          // Middle part (Rotating and scaling red arc)
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

          // Bottom part (Scaling text "PINAKA")
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