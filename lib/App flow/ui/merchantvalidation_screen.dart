import 'package:flutter/material.dart';
import 'package:pinaka_restaurant_pos/App%20flow/ui/splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../constants/constants.dart';
import '../../repositories/merchantvalidation_repository.dart';
import 'employee_login_page.dart';

class MerchantOnboardingScreen extends StatefulWidget {
  const MerchantOnboardingScreen({super.key});

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
      body: Padding(
        padding: const EdgeInsets.all(0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // const Text(
            //   "Merchant Onboarding",
            //   style: TextStyle(
            //     fontSize: 24,
            //     color: Colors.grey,
            //     fontWeight: FontWeight.w500,
            //   ),
            // ),
            // const SizedBox(height: 20),

            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Row(
                  children: [
                    /// LEFT PANEL
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
                                      "assets/icon/pinaka_logo.png",
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 70,
                            ),
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.center,
                              children: [
                                const Text(
                                  "Sign-In",
                                  style: TextStyle(
                                    fontSize: 46,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xff4A5F84),
                                  ),
                                ),

                                const SizedBox(height: 40),

                                _buildLabel(
                                    "User Name / E-Mail:"),

                                const SizedBox(height: 8),

                                _buildTextField(
                                  controller: _usernameController,
                                  hint: "User Name / E-Mail",
                                ),

                                const SizedBox(height: 18),

                                _buildLabel("Password:"),

                                const SizedBox(height: 8),

                                _buildTextField(
                                  controller: _passwordController,
                                  hint: "Password",
                                  isPassword: true,
                                ),

                                const SizedBox(height: 18),

                                _buildLabel("Store ID:"),

                                const SizedBox(height: 8),

                                _buildTextField(
                                  controller: _storeIdController,
                                  hint: "Store ID",
                                ),

                                const SizedBox(height: 45),

                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
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

                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => EmployeeLoginPage(
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
                                              backgroundColor: Colors.red,duration: Duration(seconds: 1),
                                            ),
                                          );
                                        }
                                      }catch (e) {
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
  }) {
    return SizedBox(
      height: 52,
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