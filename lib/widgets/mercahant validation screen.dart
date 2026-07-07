import 'package:flutter/material.dart';
// import 'package:pinaka_restaurant_pos/App%20flow/ui/splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

// import '../../constants/constants.dart';
// import '../../repositories/merchantvalidation_repository.dart';
import '../services/merchant validation_repository.dart';
import '../utils/AppConstant.dart';
import 'login_screen.dart';
// import 'employee_login_page.dart';

class MerchantOnboardingScreen extends StatefulWidget {
  final Function(dynamic) onLoginSuccess;

  const MerchantOnboardingScreen({
    super.key,
    required this.onLoginSuccess,
  });

  @override
  State<MerchantOnboardingScreen> createState() =>
      _MerchantOnboardingScreenState();
}

class _MerchantOnboardingScreenState
    extends State<MerchantOnboardingScreen> {

  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _storeIdController = TextEditingController();

  final MerchantLoginRepository _repository =
  MerchantLoginRepository();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _storeIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF2F2F2),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 800;
            final isShort = constraints.maxHeight < 700;

            return Padding(
              padding: EdgeInsets.all(isNarrow ? 12 : 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isNarrow) const SizedBox(height: 20),

                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(isNarrow ? 0 : 2),
                      ),
                      child: Row(
                        children: [
                          /// LEFT PANEL
                          if (!isNarrow)
                            Expanded(
                              flex: 2,
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
                                            image: AssetImage(
                                              "assets/pinaka_logo.png",
                                            ),
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                          /// RIGHT PANEL
                          Expanded(
                            flex: 2,
                            child: Center(
                              child: SingleChildScrollView(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isNarrow ? (isShort ? 16 : 24) : 70,
                                    vertical: isShort ? 16 : 24,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        "Sign-In",
                                        style: TextStyle(
                                          fontSize: isShort ? 32 : 46,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xff4A5F84),
                                        ),
                                      ),

                                      SizedBox(height: isShort ? 20 : 40),

                                      _buildLabel("User Name / E-Mail:"),

                                      const SizedBox(height: 8),

                                      _buildTextField(
                                        controller: _usernameController,
                                        hint: "User Name / E-Mail",
                                        height: isShort ? 44 : 52,
                                      ),

                                      SizedBox(height: isShort ? 10 : 18),

                                      _buildLabel("Password:"),

                                      const SizedBox(height: 8),

                                      _buildTextField(
                                        controller: _passwordController,
                                        hint: "Password",
                                        isPassword: true,
                                        height: isShort ? 44 : 52,
                                      ),

                                      SizedBox(height: isShort ? 10 : 18),

                                      _buildLabel("Store ID:"),

                                      const SizedBox(height: 8),

                                      _buildTextField(
                                        controller: _storeIdController,
                                        hint: "Store ID",
                                        height: isShort ? 44 : 52,
                                      ),

                                      SizedBox(height: isShort ? 25 : 45),

                                      SizedBox(
                                        width: double.infinity,
                                        height: isShort ? 44 : 50,
                                        child: ElevatedButton(
                                          onPressed: _isLoading
                                              ? null
                                              : () async {
                                            setState(() {
                                              _isLoading = true;
                                            });

                                            try {
                                              final response = await _repository.login(
                                                username: _usernameController.text.trim(),
                                                password: _passwordController.text.trim(),
                                                storeId: _storeIdController.text.trim(),
                                                deviceId: "42343432424234",
                                              );

                                              if (response.success) {
                                                AppConstants.updateBaseUrl(
                                                  response.storeBaseUrl,
                                                );

                                                final prefs =
                                                await SharedPreferences.getInstance();

                                                await prefs.setString(
                                                  'store_base_url',
                                                  response.storeBaseUrl,
                                                );
                                                await prefs.setString(
                                                  'store_name',
                                                  response.storeName,
                                                );

                                                await prefs.setString(
                                                  'store_address',
                                                  response.storeAddress,
                                                );

                                                await prefs.setString(
                                                  'store_phone',
                                                  response.storePhone,
                                                );

                                                await prefs.setString(
                                                  'store_logo',
                                                  response.storeLogo,
                                                );
                                                await prefs.setString('store_gstin', response.storeGstin);
                                                await prefs.setString('store_id', response.storeId);

                                                Navigator.pushReplacement(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) => EmployeeLoginScreen(
                                                      onLoginSuccess: widget.onLoginSuccess,
                                                      storeBaseUrl: response.storeBaseUrl,
                                                      storeName: response.storeName,
                                                      storeId: response.storeId,
                                                    ),
                                                  ),
                                                );
                                              } else {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text(response.message),
                                                    backgroundColor: Colors.red,
                                                    duration: const Duration(seconds: 1),
                                                  ),
                                                );
                                              }
                                            } catch (e) {
                                              final message = e.toString().replaceFirst("Exception: ", "");

                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(message),
                                                  backgroundColor: Colors.red,
                                                  behavior: SnackBarBehavior.floating,
                                                  duration: const Duration(seconds: 1),
                                                ),
                                              );
                                            } finally {
                                              if (mounted) {
                                                setState(() {
                                                  _isLoading = false;
                                                });
                                              }
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xffF96666),
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                          ),
                                          child: _isLoading
                                              ? const SizedBox(
                                            height: 22,
                                            width: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                              AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          )
                                              : const Text(
                                            "Login",
                                            style: TextStyle(
                                              fontSize: 24,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  static Widget _buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          color: Color(0xff555555),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    bool isPassword = false,
    double height = 52,
  }) {
    return SizedBox(
      height: height,
      child: TextField(
        controller: controller,
        obscureText: isPassword ? _obscurePassword : false,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: Color(0xffCFCFCF),
          ),
          suffixIcon: isPassword
              ? IconButton(
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_off
                  : Icons.visibility,
              color: Colors.grey,
            ),
            onPressed: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
          )
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 15,
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Colors.blueGrey.shade200,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(
              color: Color(0xff173F7A),
            ),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}