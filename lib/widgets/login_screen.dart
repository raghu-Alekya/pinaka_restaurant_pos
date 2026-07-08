import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/connection_setup_screen.dart';
import '../services/login_respository.dart';

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

    _timer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
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

  void addNumber(String value) {
    if (enteredPin.length >= 6) return;

    setState(() {
      enteredPin += value;
    });
  }

  void clearPin() {
    setState(() {
      enteredPin = "";
    });
  }

  void removeLast() {
    if (enteredPin.isEmpty) return;

    setState(() {
      enteredPin = enteredPin.substring(0, enteredPin.length - 1);
    });
  }

  Widget pinBox(int index, bool isShort) {
    bool filled = index < enteredPin.length;

    return Container(
      width: isShort ? 38 : 48,
      height: isShort ? 38 : 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 2,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: const Color(0xffF0F4F8), width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(
        filled ? "*" : "",
        style: TextStyle(
          fontSize: isShort ? 22 : 28,
          fontWeight: FontWeight.bold,
          color: const Color(0xff2F4376),
        ),
      ),
    );
  }

  Widget numberButton(
    String text, {
    VoidCallback? onTap,
    IconData? icon,
    Color color = Colors.white,
    bool isShort = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.09),
            blurRadius: 6,
            spreadRadius: 1,
            offset: const Offset(0, 2.5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Center(
            child:
                icon != null
                    ? Icon(
                      icon,
                      size: isShort ? 18 : 22,
                      color: const Color(0xff2F4376),
                    )
                    : Text(
                      text,
                      style: TextStyle(
                        fontSize: isShort ? 18 : 22,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xff2F4376),
                        fontFamily: "Inter",
                      ),
                    ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 800;
            final isShort = constraints.maxHeight < 700;

            return Center(
              child: SizedBox(
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                child: Row(
                  children: [
                    /// LEFT IMAGE SECTION with auto-sliding captions
                    if (!isNarrow)
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
                                // Dark overlay for text readability
                                Container(color: Colors.black.withOpacity(0.3)),
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
                                      horizontal: 48,
                                    ),
                                    alignment: Alignment.bottomCenter,
                                    margin: const EdgeInsets.only(bottom: 80),
                                    child: Text(
                                      _captions[index],
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        shadows: [
                                          Shadow(
                                            blurRadius: 4.0,
                                            color: Colors.black54,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
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

                    /// RIGHT LOGIN PANEL (PIN verification & numeric keypad)
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(
                                'assets/pinaka.png',
                                height: constraints.maxHeight * 0.1,
                              ),
                              const SizedBox(height: 10),
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
                              SizedBox(height: isShort ? 14 : 24),
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
                              SizedBox(height: isShort ? 14 : 24),
                              SizedBox(
                                width: isShort ? 310 : 370,
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        pinBox(0, isShort),
                                        pinBox(1, isShort),
                                        pinBox(2, isShort),
                                        pinBox(3, isShort),
                                        pinBox(4, isShort),
                                        pinBox(5, isShort),
                                      ],
                                    ),
                                    SizedBox(height: isShort ? 14 : 24),
                                    GridView.count(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      crossAxisCount: 3,
                                      crossAxisSpacing: isShort ? 10 : 16,
                                      mainAxisSpacing: isShort ? 12 : 20,
                                      childAspectRatio: isShort ? 2.2 : 1.95,
                                      children: [
                                        numberButton(
                                          "1",
                                          isShort: isShort,
                                          onTap: () => addNumber("1"),
                                        ),
                                        numberButton(
                                          "2",
                                          isShort: isShort,
                                          onTap: () => addNumber("2"),
                                        ),
                                        numberButton(
                                          "3",
                                          isShort: isShort,
                                          onTap: () => addNumber("3"),
                                        ),
                                        numberButton(
                                          "4",
                                          isShort: isShort,
                                          onTap: () => addNumber("4"),
                                        ),
                                        numberButton(
                                          "5",
                                          isShort: isShort,
                                          onTap: () => addNumber("5"),
                                        ),
                                        numberButton(
                                          "6",
                                          isShort: isShort,
                                          onTap: () => addNumber("6"),
                                        ),
                                        numberButton(
                                          "7",
                                          isShort: isShort,
                                          onTap: () => addNumber("7"),
                                        ),
                                        numberButton(
                                          "8",
                                          isShort: isShort,
                                          onTap: () => addNumber("8"),
                                        ),
                                        numberButton(
                                          "9",
                                          isShort: isShort,
                                          onTap: () => addNumber("9"),
                                        ),
                                        numberButton(
                                          "C",
                                          isShort: isShort,
                                          onTap: clearPin,
                                        ),
                                        numberButton(
                                          "0",
                                          isShort: isShort,
                                          onTap: () => addNumber("0"),
                                        ),
                                        numberButton(
                                          "",
                                          isShort: isShort,
                                          icon: Icons.backspace_outlined,
                                          onTap: removeLast,
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: isShort ? 26 : 30),
                                    SizedBox(
                                      width: double.infinity,
                                      height: isShort ? 44 : 52,
                                      child: ElevatedButton(
                                        onPressed:
                                            isLoading
                                                ? null
                                                : () {
                                                  if (enteredPin.length == 6) {
                                                    _login();
                                                  } else {
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                          "Please enter 6 digit PIN",
                                                        ),
                                                        duration: Duration(
                                                          seconds: 1,
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                },
                                        style: ButtonStyle(
                                          backgroundColor:
                                              WidgetStateProperty.all(
                                                const Color(0xffFA3633),
                                              ),
                                          foregroundColor:
                                              WidgetStateProperty.all(
                                                Colors.white,
                                              ),
                                          elevation: WidgetStateProperty.all(0),
                                          shape: WidgetStateProperty.all(
                                            RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                        ),
                                        child:
                                            (isLoading)
                                                ? const SizedBox(
                                                  width: 24,
                                                  height: 24,
                                                  child:
                                                      CircularProgressIndicator(
                                                        color: Colors.white,
                                                        strokeWidth: 2,
                                                        backgroundColor:
                                                            Colors.transparent,
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
            );
          },
        ),
      ),
    );
  }
}
