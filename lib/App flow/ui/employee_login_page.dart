import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pinaka_restaurant_pos/App%20flow/ui/tables_screen.dart';
import '../../blocs/Bloc Logic/auth_bloc.dart';
import '../../constants/constants.dart';
import '../../local database/table_dao.dart';
import '../../models/UserPermissions.dart';
import '../../utils/SessionManager.dart';
import '../widgets/number_pad.dart';
import '../widgets/pin_input.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'home_screen.dart';

class EmployeeLoginPage extends StatefulWidget {
  final String storeBaseUrl;
  final String storeName;
  final String storeId;

  const EmployeeLoginPage({
    super.key,
    required this.storeBaseUrl,
    required this.storeName,
    required this.storeId,
  });

  @override
  State<EmployeeLoginPage> createState() => _EmployeeLoginPageState();
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
    print("CURRENT DOMAIN => ${AppConstants.baseDomain}");
    print("AUTH URL => ${AppConstants.authTokenEndpoint}");
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return BlocProvider(
      create: (_) => AuthBloc(RepositoryProvider.of(context)),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: BlocConsumer<AuthBloc, AuthState>(
            listener: (context, state) async {
              if (state is AuthFailure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 1),
                  ),
                );
              }
              // final tableDao = TableDao();
              // final tables = await tableDao.getTablesByManagerPin(state.pin);

              if (state is AuthSuccess) {
                _timer.cancel();

                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('pin', state.pin);
                await prefs.setString('token', state.token);
                await prefs.setString(
                  'restaurant_id',
                  state.restaurantId,
                );

                await prefs.setString(
                  'restaurant_name',
                  state.restaurantName,
                );

                print(
                  "✅ Saved Restaurant ID => ${state.restaurantId}",
                );

                final tableDao = TableDao();
                final tables = await tableDao.getTablesByManagerPin(state.pin);
                final permissions = UserPermissions.fromJson(state.permissions);

                await SessionManager.savePermissions(permissions);

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HomeScreen(
                      pin: state.pin,
                      token: state.token,
                      restaurantId: state.restaurantId,
                      restaurantName: state.restaurantName,
                      // loadedTables: tables,
                    ),
                  ),
                );
              }
            },

            builder: (context, state) {
              return SizedBox(
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
                                    PinInput(pin: pin),
                                    const SizedBox(height: 20),
                                    NumberPad(onKeyPressed: _onKeyPressed),
                                    const SizedBox(height: 25),
                                    ElevatedButton(
                                      onPressed: (state is AuthLoading)
                                          ? null
                                          : () {
                                        if (pin.length == 6) {
                                          BlocProvider.of<AuthBloc>(context).add(LoginEvent(pin.trim()));
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('PIN must be exactly 6 digits'),
                                              duration: Duration(seconds: 1),),
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
                                      child: (state is AuthLoading)
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
              );
            },
          ),
        ),
      ),
    );
  }
}