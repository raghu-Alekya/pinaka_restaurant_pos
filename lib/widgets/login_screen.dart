// import 'package:carousel_slider/carousel_slider.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// import '../repositories/employee_pin_login_repository.dart';
import '../kitchen_display_screen.dart';
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

  final String _pin = "";

  final List<String> images = [
    "assets/images/login1.png",
    "assets/images/login2.png",
    "assets/images/login3.png",
  ];

  int currentIndex = 0;
  String enteredPin = "";
  bool isLoading = false;

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

  Widget pinBox(int index) {
    bool filled = index < enteredPin.length;

    return Container(
      width: 42,
      height: 42,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xffD8D8D8)),
      ),
      alignment: Alignment.center,
      child: Text(
        filled ? "•" : "",
        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget numberButton(
    String text, {
    VoidCallback? onTap,
    IconData? icon,
    Color color = const Color(0xffF5F6FA),
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xffE5E7EB)),
        ),
        child: Center(
          child:
              icon != null
                  ? Icon(icon, size: 24)
                  : Text(
                    text,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      color: Color(0xff364152),
                    ),
                  ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF3F4F8),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: Container(
                width: constraints.maxWidth * 0.95,
                height: constraints.maxHeight * 0.95,
                constraints: const BoxConstraints(
                  maxWidth: 1400,
                  maxHeight: 900,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.08),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    /// LEFT IMAGE SECTION
                    Expanded(
                      // flex: 3,
                      child: Container(
                        color: const Color(0xff173F7A),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 200,
                                height: 120,
                                decoration: const BoxDecoration(
                                  image: DecorationImage(
                                    image: AssetImage("assets/pinaka_logo.png"),
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    /// RIGHT LOGIN PANEL
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset("assets/pinaka.png", height: 80),

                              const SizedBox(height: 20),

                              const Text(
                                "Employee Login",
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 23,
                                  fontFamily: "Inter",
                                  fontWeight: FontWeight.w600,
                                ),
                              ),

                              const SizedBox(height: 20),

                              const Text(
                                "Please Input your PIN to Validate yourself",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(0xff4C5F7D),
                                  fontSize: 18,
                                  fontFamily: "Inter",
                                  fontWeight: FontWeight.w500,
                                ),
                              ),

                              const SizedBox(height: 28),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                  6,
                                  (index) => pinBox(index),
                                ),
                              ),

                              const SizedBox(height: 28),

                              SizedBox(
                                width: 350,
                                child: GridView.count(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 1.55,
                                  children: [
                                    numberButton(
                                      "1",
                                      onTap: () => addNumber("1"),
                                    ),
                                    numberButton(
                                      "2",
                                      onTap: () => addNumber("2"),
                                    ),
                                    numberButton(
                                      "3",
                                      onTap: () => addNumber("3"),
                                    ),

                                    numberButton(
                                      "4",
                                      onTap: () => addNumber("4"),
                                    ),
                                    numberButton(
                                      "5",
                                      onTap: () => addNumber("5"),
                                    ),
                                    numberButton(
                                      "6",
                                      onTap: () => addNumber("6"),
                                    ),

                                    numberButton(
                                      "7",
                                      onTap: () => addNumber("7"),
                                    ),
                                    numberButton(
                                      "8",
                                      onTap: () => addNumber("8"),
                                    ),
                                    numberButton(
                                      "9",
                                      onTap: () => addNumber("9"),
                                    ),

                                    numberButton(
                                      "C",
                                      //color: const Color(0xffFFF4F4),
                                      onTap: clearPin,
                                    ),

                                    numberButton(
                                      "0",
                                      onTap: () => addNumber("0"),
                                    ),

                                    numberButton(
                                      "",
                                      icon: Icons.backspace_outlined,
                                      //color: const Color(0xffFFF4F4),
                                      onTap: removeLast,
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 30),

                              SizedBox(
                                width: 350,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: isLoading ? null : _login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child:
                                      isLoading
                                          ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                          : const Text(
                                            "Login",
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
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
