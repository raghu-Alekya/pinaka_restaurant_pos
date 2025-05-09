import 'dart:async';
import 'package:pinaka_restaurant_pos/ui/tables_screen.dart';
import 'package:flutter/material.dart';
import '../widgets/number_pad.dart';
import '../widgets/pin_input.dart';

class EmployeeLoginPage extends StatefulWidget {
  const EmployeeLoginPage({super.key});

  @override
  _EmployeeLoginPageState createState() => _EmployeeLoginPageState();
}

class _EmployeeLoginPageState extends State<EmployeeLoginPage> {
  String pin = "";
  int _currentIndex = 0;

  final List<String> _images = [
    'assets/img_1.png',
    'assets/loginname.png',
    'assets/POS-systems.jpg',
    'assets/img_1.png',
  ];

  final List<String> _captions = [
    '"Designed for speed and efficiency — PINAKA POS helps you complete sales in seconds with an intuitive and user-friendly interface, reducing training time and increasing productivity."',
    '"Track sales, manage inventory, and handle staff permissions — all from one sleek dashboard that’s built for real-time data access and seamless integration with your business tools."',
    '"Reliable and secure — our POS keeps your business running smoothly every day with 24/7 uptime, cloud backups, and end-to-end encrypted transactions."',
    '"Designed for speed and efficiency — PINAKA POS helps you complete sales in seconds with an intuitive and user-friendly interface, reducing training time and increasing productivity."',
  ];

  late PageController _pageController;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    _timer = Timer.periodic(const Duration(seconds: 2), (Timer timer) {
      _currentIndex++;

      _pageController.animateToPage(
        _currentIndex,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOut,
      );

      if (_currentIndex == _images.length - 1) {
        Future.delayed(const Duration(milliseconds: 710), () {
          _pageController.jumpToPage(0);
          _currentIndex = 0;
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer.cancel();
    super.dispose();
  }

  void _onKeyPressed(String value) {
    setState(() {
      if (value == "C") {
        pin = "";
      } else if (value == "⌫" && pin.isNotEmpty) {
        pin = pin.substring(0, pin.length - 1);
      } else if (pin.length < 6 && value != "C" && value != "⌫") {
        pin += value;
      }
    });
  }

  Future<void> _login() async {
    if (pin == "999999") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => TablesScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid PIN")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SizedBox(
          width: 1920, height: 1080,
          child: Row(
            children: [
              // Left Side - Image + Caption
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _images.length,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          _images[index],
                          fit: BoxFit.cover,
                        ),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 700),
                          transitionBuilder: (Widget child, Animation<double> animation) {
                            final offsetAnimation = Tween<Offset>(
                              begin: const Offset(-1.0, 0.0),
                              end: Offset.zero,
                            ).animate(animation);
                            return SlideTransition(position: offsetAnimation, child: child);
                          },
                          child: Container(
                            key: ValueKey<int>(index),
                            padding: const EdgeInsets.symmetric(horizontal: 150),
                            alignment: Alignment.bottomCenter,
                            margin: const EdgeInsets.only(bottom: 70),
                            child: Text(
                              _captions[index],
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w400,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // Right Side - Login Form
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/pinaka.png',
                        height: 100,
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Employee Login',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 25,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          height: 0.9,
                        ),
                      ),
                      const SizedBox(height: 19),
                      const Text(
                        'Please Input your PIN to Validate your self',
                        style: TextStyle(
                          color: Color(0xFF4C5F7D),
                          fontSize: 18.5,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                          height: 0.92,
                        ),
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: 450,
                        child: Column(
                          children: [
                            PinInput(pin: pin),
                            const SizedBox(height: 20),
                            NumberPad(onKeyPressed: _onKeyPressed),
                            const SizedBox(height: 30),
                            ElevatedButton(
                              onPressed: _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                minimumSize: const Size(440, 40),
                              ),
                              child: const Text(
                                "Login",
                                style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}