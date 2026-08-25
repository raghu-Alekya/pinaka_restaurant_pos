import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/connection_setup_screen.dart';
import '../services/login_respository.dart';
import '../utils/sessionmanger.dart';
import 'mercahant validation screen.dart';
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
    // ======================================================
    // VALIDATE PIN
    // ======================================================

    if (enteredPin.length != 6) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter 6 digit PIN"),
        ),
      );

      return;
    }

    // ======================================================
    // START LOADING
    // ======================================================

    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      // ======================================================
      // GET CURRENT STORE INFORMATION
      // ======================================================

      final prefs =
      await SharedPreferences.getInstance();

      final savedBaseUrl =
          prefs.getString('store_base_url') ?? '';

      final savedStoreId =
          prefs.getString('store_id') ?? '';

      debugPrint(
        '==========================================',
      );

      debugPrint(
        'EMPLOYEE LOGIN',
      );

      debugPrint(
        'PIN            : $enteredPin',
      );

      debugPrint(
        'PIN LENGTH     : ${enteredPin.length}',
      );

      debugPrint(
        'WIDGET URL     : ${widget.storeBaseUrl}',
      );

      debugPrint(
        'WIDGET STORE ID: ${widget.storeId}',
      );

      debugPrint(
        'SAVED URL      : $savedBaseUrl',
      );

      debugPrint(
        'SAVED STORE ID : $savedStoreId',
      );

      debugPrint(
        '==========================================',
      );

      // ======================================================
      // LOGIN API
      // ======================================================

      final response =
      await _repository.loginWithPin(
        empLoginPin: enteredPin,
      );

      debugPrint(
        '==========================================',
      );

      debugPrint(
        'EMPLOYEE LOGIN API SUCCESS',
      );

      debugPrint(
        'RESTAURANT ID : '
            '${response.data.restaurantId}',
      );

      debugPrint(
        'RESTAURANT    : '
            '${response.data.restaurantName}',
      );

      debugPrint(
        'ROLE          : '
            '${response.data.role}',
      );

      debugPrint(
        '==========================================',
      );

      if (!mounted) return;

      // ======================================================
      // SAVE EMPLOYEE LOGIN DETAILS
      // ======================================================

      await prefs.setString(
        'token',
        response.data.token,
      );

      await prefs.setInt(
        'restaurant_id',
        response.data.restaurantId,
      );

      await prefs.setInt(
        'emp_login_pin',
        int.tryParse(enteredPin) ?? 0,
      );

      await prefs.setString(
        'emp_login_pin_str',
        enteredPin,
      );

      await prefs.setString(
        'display_name',
        response.data.restaurantName,
      );

      await prefs.setString(
        'role',
        response.data.role,
      );

      // ======================================================
      // GET STORE ID FROM MERCHANT LOGIN
      // ======================================================

      final storeId =
      await SessionManager.getStoreId();

      debugPrint(
        '==========================================',
      );

      debugPrint(
        'Employee Login Success',
      );

      debugPrint(
        'Restaurant ID : '
            '${response.data.restaurantId}',
      );

      debugPrint(
        'Store ID      : $storeId',
      );

      debugPrint(
        'Token         : '
            '${response.data.token}',
      );

      debugPrint(
        '==========================================',
      );

      // ======================================================
      // STORE ID VALIDATION
      // ======================================================

      if (storeId.isEmpty) {
        if (!mounted) return;

        debugPrint(
          '❌ Store ID not found in merchant session',
        );

        setState(() {
          isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Store ID not found. Please login again.',
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );

        return;
      }

      // ======================================================
      // CREATE KDS CONFIG
      // ======================================================

      final config = KdsConfig(
        brokerHost:
        KdsConfig.defaultBrokerHost,

        brokerPort:
        KdsConfig.defaultBrokerPort,

        // Employee login provides restaurant ID
        restaurantId:
        response.data.restaurantId.toString(),

        // Merchant login provides store ID
        storeId:
        storeId,

        // Employee login provides token
        apiToken:
        response.data.token,
      );

      debugPrint(
        '==========================================',
      );

      debugPrint(
        '✅ KDS CONFIG CREATED',
      );

      debugPrint(
        'Restaurant ID: ${config.restaurantId}',
      );

      debugPrint(
        'Store ID      : ${config.storeId}',
      );

      debugPrint(
        '==========================================',
      );

      // ======================================================
      // STOP LOADING BEFORE NAVIGATION
      // ======================================================

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }

      // ======================================================
      // NAVIGATE / CONTINUE
      // ======================================================

      // IMPORTANT:
      // This callback navigates away from this screen.
      // Do not use context after this call.
      widget.onLoginSuccess(config);

      return;
    } catch (e, stackTrace) {
      // ======================================================
      // LOGIN FAILED
      // ======================================================

      debugPrint(
        '==========================================',
      );

      debugPrint(
        '❌ EMPLOYEE LOGIN FAILED',
      );

      debugPrint(
        'ERROR: $e',
      );

      debugPrint(
        'STACK TRACE:',
      );

      debugPrint(
        '$stackTrace',
      );

      debugPrint(
        '==========================================',
      );

      // The screen may already have been removed.
      if (!mounted) return;

      final errorStr =
      e.toString().toLowerCase();

      String errorMessage;

      if (errorStr.contains('socketexception') ||
          errorStr.contains('host lookup failed')) {
        errorMessage =
        'Network error. Please check your internet connection.';
      } else if (errorStr.contains('401') ||
          errorStr.contains('unauthorized') ||
          errorStr.contains('invalid pin') ||
          errorStr.contains('invalid credential')) {
        errorMessage =
        'Invalid PIN. Please enter a valid PIN.';
      } else {
        errorMessage =
        'Employee login failed. Please try again.';
      }

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor:
          Colors.red.shade800,
          behavior:
          SnackBarBehavior.floating,
        ),
      );

      return;
    }
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
                          transitionBuilder: (
                            Widget child,
                            Animation<double> animation,
                          ) {
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 150,
                            ),
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

                              NumberPad(
                                onKeyPressed: _onKeyPressed,
                              ),

                              const SizedBox(height: 25),

                              // ============================
                              // LOGIN BUTTON
                              // ============================
                              SizedBox(
                                width: screenWidth * 0.29,
                                child: ElevatedButton(
                                  onPressed: isLoading
                                      ? null
                                      : () {
                                    if (enteredPin.length == 6) {
                                      _login();
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'PIN must be exactly 6 digits',
                                          ),
                                          duration: Duration(seconds: 1),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  },
                                  style: ButtonStyle(
                                    backgroundColor:
                                    WidgetStateProperty.all<Color>(
                                      Colors.red,
                                    ),
                                    foregroundColor:
                                    WidgetStateProperty.all<Color>(
                                      Colors.white,
                                    ),
                                    padding:
                                    WidgetStateProperty.all<EdgeInsets>(
                                      const EdgeInsets.symmetric(
                                        vertical: 13,
                                      ),
                                    ),
                                    shape:
                                    WidgetStateProperty.all<
                                        RoundedRectangleBorder>(
                                      RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    minimumSize:
                                    WidgetStateProperty.all<Size>(
                                      Size(
                                        screenWidth * 0.29,
                                        25,
                                      ),
                                    ),
                                  ),
                                  child: isLoading
                                      ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                      backgroundColor:
                                      Colors.transparent,
                                    ),
                                  )
                                      : const Text(
                                    'Login',
                                    style: TextStyle(
                                      fontSize: 20,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 12),

                              // ============================
                              // SWITCH STORE / MERCHANT LOGIN
                              // ============================
                              TextButton(
                                onPressed: () {
                                  if (!mounted) return;

                                  Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(
                                      builder: (_) => MerchantOnboardingScreen(
                                        onLoginSuccess: (config) {
                                          // Pass the newly created config
                                          // back to the application entry point.
                                          widget.onLoginSuccess(config);
                                        },
                                      ),
                                    ),
                                        (route) => false,
                                  );
                                },
                                child: Text(
                                  'Switch Store / Merchant Login',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? Colors.lightBlueAccent
                                        : Colors.blue,
                                    fontWeight: FontWeight.w500,
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
