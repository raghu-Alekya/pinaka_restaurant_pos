import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// import '../repositories/employee_pin_login_repository.dart';
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
      width: 48,
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xffE2E8F0), width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(
        filled ? "*" : "",
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Color(0xff2F4376),
        ),
      ),
    );
  }

  Widget numberButton(
    String text, {
    VoidCallback? onTap,
    IconData? icon,
    Color color = const Color(0xffF4F5F7),
  }) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Center(
          child: icon != null
              ? Icon(
                  icon,
                  size: 22,
                  color: const Color(0xff2F4376),
                )
              : Text(
                  text,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Color(0xff2F4376),
                    fontFamily: "Inter",
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

            return Center(
              child: SizedBox(
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                child: Row(
                  children: [
                    /// LEFT IMAGE SECTION (NFC payment mockup match)
                    if (!isNarrow)
                      Expanded(
                        child: Container(
                          decoration: const BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage("assets/login_bg.png"),
                              fit: BoxFit.cover,
                            ),
                          ),
                          child: Stack(
                            children: [
                              Align(
                                alignment: Alignment.bottomCenter,
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 48, right: 48, bottom: 80),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        '"Designed for speed and efficiency—PINAKA POS helps you complete sales in seconds with an intuitive and user-friendly interface."',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: "Inter",
                                          height: 1.4,
                                          shadows: [
                                            Shadow(
                                              blurRadius: 4.0,
                                              color: Colors.black45,
                                              offset: Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.transparent,
                                              border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.5),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.transparent,
                                              border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.5),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    /// RIGHT LOGIN PANEL (PIN verification & numeric keypad)
                    Expanded(
                      child: Container(
                        color: Colors.white,
                        child: Center(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset("assets/pinaka.png", height: 80),
                                const SizedBox(height: 20),
                                const Text(
                                  "Employee Login",
                                  style: TextStyle(
                                    color: Color(0xffFF6C61),
                                    fontSize: 28,
                                    fontFamily: "Inter",
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  "Please Input your PIN to Validate your self",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Color(0xff4C5F7D),
                                    fontSize: 14,
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
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                    childAspectRatio: 1.55,
                                    children: [
                                      numberButton("1", onTap: () => addNumber("1")),
                                      numberButton("2", onTap: () => addNumber("2")),
                                      numberButton("3", onTap: () => addNumber("3")),
                                      numberButton("4", onTap: () => addNumber("4")),
                                      numberButton("5", onTap: () => addNumber("5")),
                                      numberButton("6", onTap: () => addNumber("6")),
                                      numberButton("7", onTap: () => addNumber("7")),
                                      numberButton("8", onTap: () => addNumber("8")),
                                      numberButton("9", onTap: () => addNumber("9")),
                                      numberButton("C", onTap: clearPin),
                                      numberButton("0", onTap: () => addNumber("0")),
                                      numberButton("", icon: Icons.backspace_outlined, onTap: removeLast),
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
                                      backgroundColor: const Color(0xffFF6C61),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: isLoading
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
                                              fontFamily: "Inter",
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
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
