import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/connection_setup_screen.dart';
import '../services/login_respository.dart';
import 'pin_input.dart';
import 'number_pad.dart';

class EmployeeLoginScreen extends StatefulWidget {
  final Function(KdsConfig) onLoginSuccess;
  final String storeBaseUrl;
  final String storeName;
  final String storeId;

  const EmployeeLoginScreen({
    super.key,
    required this.onLoginSuccess,
    required this.storeBaseUrl,
    required this.storeName,
    required this.storeId,
  });

  @override
  State<EmployeeLoginScreen> createState() => _EmployeeLoginScreenState();
}

class _EmployeeLoginScreenState extends State<EmployeeLoginScreen> {
  final EmployeePinLoginRepository _repository = EmployeePinLoginRepository();

  String enteredPin = "";
  bool isLoading = false;
  int _currentIndex = 0;

  final List<String> _images = [
    'assets/login_bg.png',
    'assets/login_bg.png',
    'assets/login_bg.png',
    'assets/login_bg.png',
  ];

  final List<String> _captions = [
    '"Designed for speed and efficiency — PINAKA KDS helps you track orders in seconds with an intuitive and user-friendly interface."',
    '"Track preparation times, manage queues, and handle order status — all from one sleek display built for real-time kitchen efficiency."',
    '"Reliable and secure — our KDS keeps your kitchen running smoothly every day with 24/7 synchronization and instant POS notifications."',
    '"Designed for speed and efficiency — PINAKA KDS helps you track orders in seconds with an intuitive and user-friendly interface."',
  ];

  late PageController _pageController;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    _timer = Timer.periodic(const Duration(seconds: 2), (Timer timer) {
      if (!mounted) return;

      if (_currentIndex < _images.length - 1) {
        _currentIndex++;
        _pageController.animateToPage(
          _currentIndex,
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeInOut,
        );
      } else {
        Future.delayed(const Duration(milliseconds: 710), () {
          if (mounted) {
            _pageController.jumpToPage(0);
            _currentIndex = 0;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (enteredPin.length != 6) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please enter 6 digit PIN")));
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await _repository.loginWithPin(empLoginPin: enteredPin);

      if (!mounted) return;

      // Save token
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("token", response.data.token);
      await prefs.setInt("restaurant_id", response.data.restaurantId);
      await prefs.setInt("emp_login_pin", int.tryParse(enteredPin) ?? 0);
      await prefs.setString("emp_login_pin_str", enteredPin);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));

      final config = KdsConfig(
        brokerHost: KdsConfig.defaultBrokerHost,
        brokerPort: KdsConfig.defaultBrokerPort,
        restaurantId: response.data.restaurantId.toString(),
        apiToken: response.data.token,
      );

      widget.onLoginSuccess(config);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });
  }

  void _onKeyPressed(String value) {
    setState(() {
      if (value == "C") {
        enteredPin = "";
      } else if (value == "⌫" && enteredPin.isNotEmpty) {
        enteredPin = enteredPin.substring(0, enteredPin.length - 1);
      } else if (enteredPin.length < 6 && value != "C" && value != "⌫") {
        enteredPin += value;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SizedBox(
          width: screenWidth,
          height: screenHeight,
          child: Row(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _images.length,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(_images[index], fit: BoxFit.cover),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 700),
                          transitionBuilder: (Widget child, Animation<double> animation) {
                            final offsetAnimation = Tween<Offset>(
                              begin: const Offset(-1.0, 0.0),
                              end: Offset.zero,
                            ).animate(animation);
                            return SlideTransition(
                              position: offsetAnimation,
                              child: child,
                            );
                          },
                          child: Container(
                            key: ValueKey<int>(index),
                            padding: const EdgeInsets.symmetric(horizontal: 150),
                            alignment: Alignment.bottomCenter,
                            margin: const EdgeInsets.only(bottom: 40),
                            child: Text(
                              _captions[index],
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                color: Colors.white,
                                fontSize: 18,
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
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/pinaka.png',
                          height: screenHeight * 0.1,
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Employee Login',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 23,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                            height: 0.9,
                          ),
                        ),
                        const SizedBox(height: 22),
                        const Text(
                          'Please Input your PIN to Validate yourself',
                          style: TextStyle(
                            color: Color(0xFF4C5F7D),
                            fontSize: 18,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                            height: 0.92,
                          ),
                        ),
                        const SizedBox(height: 22),
                        SizedBox(
                          width: screenWidth * 0.3,
                          child: Column(
                            children: [
                              PinInput(pin: enteredPin),
                              const SizedBox(height: 20),
                              NumberPad(onKeyPressed: _onKeyPressed),
                              const SizedBox(height: 25),
                              ElevatedButton(
                                onPressed: isLoading
                                    ? null
                                    : () {
                                  if (enteredPin.length == 6) {
                                    _login();
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('PIN must be exactly 6 digits'),
                                        duration: Duration(seconds: 1),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                },
                                style: ButtonStyle(
                                  backgroundColor: WidgetStateProperty.resolveWith<Color>(
                                        (Set<WidgetState> states) {
                                      if (states.contains(WidgetState.disabled)) {
                                        return Colors.red;
                                      }
                                      return Colors.red;
                                    },
                                  ),
                                  foregroundColor: WidgetStateProperty.all<Color>(Colors.white),
                                  padding: WidgetStateProperty.all<EdgeInsets>(
                                    const EdgeInsets.symmetric(vertical: 13),
                                  ),
                                  shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                                    RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  minimumSize: WidgetStateProperty.all<Size>(Size(screenWidth * 0.29, 25)),
                                ),
                                child: isLoading
                                    ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                    backgroundColor: Colors.transparent,
                                  ),
                                )
                                    : const Text(
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
