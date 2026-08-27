import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../ captain_pin_login/captain_login_screen.dart';
import '../../../utils/validators.dart';
import '../../../constants/color_constants.dart';
import 'merchant_login_bloc/merchant_login_bloc.dart';
import 'merchant_login_bloc/merchant_login_event.dart';
import 'merchant_login_bloc/merchant_login_state.dart';

class MerchantLoginScreen extends StatefulWidget {
  const MerchantLoginScreen({Key? key}) : super(key: key);

  @override
  State<MerchantLoginScreen> createState() => _MerchantLoginScreenState();
}

class _MerchantLoginScreenState extends State<MerchantLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _storeIdController = TextEditingController();
  final _deviceIdController = TextEditingController();
  String _shift = '';

  bool _obscurePassword = true;
  bool get _isFilled =>
      _usernameController.text.trim().isNotEmpty &&
          _passwordController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _usernameController.addListener(_onFieldChanged);
    _passwordController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _usernameController.removeListener(_onFieldChanged);
    _passwordController.removeListener(_onFieldChanged);
    _usernameController.dispose();
    _passwordController.dispose();
    _storeIdController.dispose();
    _deviceIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final horizontalPadding = size.width * 0.07;


    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    final topContentOffset =
    keyboardOpen ? size.height * 0.08 : size.height * 0.24;
    final bottomContentGap =
    keyboardOpen ? size.height * 0.03 : size.height * 0.16;

    return Scaffold(
      // FIX: false instead of true — stops the body from being resized
      // (and thus overflowing) when the keyboard appears. The keyboard
      // now overlays the screen instead of squeezing the Column.
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      body: BlocConsumer<MerchantLoginBloc, MerchantLoginState>(
        listener: (context, state) {
          if (state is MerchantLoginSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Welcome ${state.entity.storeName ?? ''}'),
                backgroundColor: ColorConstants.successColor,
              ),
            );
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => CaptainLoginScreen (
                  // storeName: state.entity.storeName,
                ),
              ),
            );
          } else if (state is MerchantLoginFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error),
                backgroundColor: ColorConstants.errorColor,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is MerchantLoginLoading;
          return Stack(
            children: [
              // ---------- Top orange curved band ----------
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _TopCurveBand(
                  height: size.height,
                  width: size.width,
                ),
              ),

              // ---------- Bottom orange curved band ----------
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _BottomCurveBand(
                  height: size.height,
                  width: size.width,
                ),
              ),

              // ---------- Foreground form (no SafeArea / ScrollView) ----------
              Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: size.height * 0.150),
                    Center(
                      child: Text(
                        'Sign In',
                        style: TextStyle(
                          fontSize: size.width * 0.075,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    SizedBox(height: size.height * 0.008),
                    Center(
                      child: Text(
                        'Login into your Account',
                        style: TextStyle(
                          fontSize: size.width * 0.038,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                    SizedBox(height: size.height * 0.035),
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _fieldLabel('Email Address:', size),
                          _buildStyledField(
                            controller: _usernameController,
                            hint: 'Email',
                            validator: Validators.validateUsername,
                            size: size,
                          ),
                          SizedBox(height: size.height * 0.02),
                          _fieldLabel('Password:', size),
                          _buildStyledField(
                            controller: _passwordController,
                            hint: 'Password',
                            obscureText: _obscurePassword,
                            validator: Validators.validatePassword,
                            size: size,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.black45,
                                size: size.width * 0.05,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          SizedBox(height: size.height * 0.02),
                          _fieldLabel('Store ID (optional):', size),
                          _buildStyledField(
                            controller: _storeIdController,
                            hint: 'Store ID',
                            validator: null,
                            size: size,
                          ),
                          SizedBox(height: size.height * 0.02),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Padding(
                              padding: EdgeInsets.only(
                                top: size.height * 0.012,
                              ),
                              child: GestureDetector(
                                onTap: () {
                                  // TODO: forgot password flow
                                },
                                child: Text(
                                  'Forgot Password?',
                                  style: TextStyle(
                                    color: ColorConstants.errorColor,
                                    fontSize: size.width * 0.035,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: size.height * 0.03),
                          _buildSignInButton(size, isLoading),
                          SizedBox(height: bottomContentGap),
                        ],
                      ),
                    ),
                  ],
                ),
              ),


              // ---------- Foreground form ----------
              // Padding(
              //   padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              //   child: SingleChildScrollView(
              //     // Optional: smoother feel
              //     physics: const BouncingScrollPhysics(),
              //     child: Column(
              //       crossAxisAlignment: CrossAxisAlignment.start,
              //       children: [
              //         SizedBox(height: topContentOffset),
              //         Center(
              //           child: Text(
              //             'Sign In',
              //             style: TextStyle(
              //               fontSize: size.width * 0.075,
              //               fontWeight: FontWeight.bold,
              //               color: Colors.black87,
              //             ),
              //           ),
              //         ),
              //         SizedBox(height: size.height * 0.008),
              //         Center(
              //           child: Text(
              //             'Login into your Account',
              //             style: TextStyle(
              //               fontSize: size.width * 0.038,
              //               color: Colors.black54,
              //             ),
              //           ),
              //         ),
              //         SizedBox(height: size.height * 0.035),
              //         Form(
              //           key: _formKey,
              //           child: Column(
              //             crossAxisAlignment: CrossAxisAlignment.start,
              //             children: [
              //               _fieldLabel('Email Address:', size),
              //               _buildStyledField(
              //                 controller: _usernameController,
              //                 hint: 'Email',
              //                 validator: Validators.validateUsername,
              //                 size: size,
              //               ),
              //               SizedBox(height: size.height * 0.02),
              //               _fieldLabel('Password:', size),
              //               _buildStyledField(
              //                 controller: _passwordController,
              //                 hint: 'Password',
              //                 obscureText: _obscurePassword,
              //                 validator: Validators.validatePassword,
              //                 size: size,
              //                 suffixIcon: IconButton(
              //                   icon: Icon(
              //                     _obscurePassword
              //                         ? Icons.visibility_off
              //                         : Icons.visibility,
              //                     color: Colors.black45,
              //                     size: size.width * 0.05,
              //                   ),
              //                   onPressed: () {
              //                     setState(() {
              //                       _obscurePassword = !_obscurePassword;
              //                     });
              //                   },
              //                 ),
              //               ),
              //               SizedBox(height: size.height * 0.02),
              //               _fieldLabel('Store ID:', size),
              //               _buildStyledField(
              //                 controller: _storeIdController,
              //                 hint: 'Store ID',
              //                 validator: null,
              //                 size: size,
              //               ),
              //               SizedBox(height: size.height * 0.02),
              //               Align(
              //                 alignment: Alignment.centerRight,
              //                 child: Padding(
              //                   padding: EdgeInsets.only(
              //                     top: size.height * 0.012,
              //                   ),
              //                   child: GestureDetector(
              //                     onTap: () {
              //                       // TODO: forgot password flow
              //                     },
              //                     child: Text(
              //                       'Forgot Password?',
              //                       style: TextStyle(
              //                         color: ColorConstants.errorColor,
              //                         fontSize: size.width * 0.035,
              //                         fontWeight: FontWeight.w500,
              //                       ),
              //                     ),
              //                   ),
              //                 ),
              //               ),
              //               SizedBox(height: size.height * 0.03),
              //               _buildSignInButton(size, isLoading),
              //
              //               // Extra space so last field is not covered by keyboard
              //               SizedBox(
              //                 height: keyboardOpen
              //                     ? MediaQuery.of(context).viewInsets.bottom + 24
              //                     : bottomContentGap,
              //               ),
              //             ],
              //           ),
              //         ),
              //       ],
              //     ),
              //   ),
              // ),

            ],
          );
        },
      ),
    );
  }

  Widget _fieldLabel(String text, Size size) {
    return Padding(
      padding: EdgeInsets.only(bottom: size.height * 0.006),
      child: Text(
        text,
        style: TextStyle(
          fontSize: size.width * 0.036,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildStyledField({
    required TextEditingController? controller,
    required String hint,
    required String? Function(String?)? validator,
    required Size size,
    bool obscureText = false,
    Widget? suffixIcon,
    void Function(String)? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(size.width * 0.025),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        onChanged: onChanged,
        validator: validator,
        style: TextStyle(fontSize: size.width * 0.038),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.black38,
            fontSize: size.width * 0.038,
          ),
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(size.width * 0.025),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: const Color(0xFFF2F2F2),
          contentPadding: EdgeInsets.symmetric(
            horizontal: size.width * 0.04,
            vertical: size.height * 0.018,
          ),
        ),
      ),
    );
  }

  Widget _buildSignInButton(Size size, bool isLoading) {
    final Color buttonColor =
    _isFilled ? ColorConstants.primaryColor : Colors.grey;

    return SizedBox(
      width: double.infinity,
      height: size.height * 0.065,
      child: ElevatedButton(
        onPressed: isLoading ? null : _onLoginPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: buttonColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(size.width * 0.03),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? SizedBox(
          width: size.width * 0.06,
          height: size.width * 0.06,
          child: const CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2.5,
          ),
        )
            : Text(
          'Sign In',
          style: TextStyle(
            fontSize: size.width * 0.045,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _onLoginPressed() {
    if (_formKey.currentState!.validate()) {
      final bloc = context.read<MerchantLoginBloc>();
      bloc.add(
        LoginButtonPressed(
          username: _usernameController.text.trim(),
          password: _passwordController.text.trim(),
          storeId: _storeIdController.text.trim(),
          deviceId: _deviceIdController.text.trim(),
          shift: _shift.trim(),
        ),
      );
    }
  }
}


class _TopCurveBand extends StatelessWidget {
  final double height;
  final double width;

  const _TopCurveBand({required this.height, required this.width});

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _TopArchClipper(),
      child: Container(
        height: height,
        width: width,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFF8A50),
              Color(0xFFE8600C),
              Color(0xFFC1440E),
            ],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: CustomPaint(
          painter: DiagonalSheenPainter(),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _BottomCurveBand extends StatelessWidget {
  final double height;
  final double width;

  const _BottomCurveBand({required this.height, required this.width});

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: BottomArchClipper(),
      child: Container(
        height: height,
        width: width,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE8600C),
              Color(0xFFC1440E),
              Color(0xFF8E2A0B),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: CustomPaint(
          painter: DiagonalSheenPainter(),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _TopArchClipper extends CustomClipper<Path> {
  static const double _leftFraction = 0.17;
  static const double _rightFraction = 0.10;
  static const double _archFraction = 0.045;

  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height * _leftFraction);
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height * _archFraction,
      size.width,
      size.height * _rightFraction,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

/// Made public (renamed, no leading underscore) so pin_login_screen.dart
/// can reuse the exact same bottom curve shape.
class BottomArchClipper extends CustomClipper<Path> {
  static const double _leftFraction = 0.10;
  static const double _rightFraction = 0.15; // 👈 was 0.25 — lower value = shorter band on the right
  static const double _archFraction = 0.045;

  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, size.height * (1 - _leftFraction));
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height * (1 - _archFraction),
      size.width,
      size.height * (1 - _rightFraction),
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

/// Made public so pin_login_screen.dart can reuse it too.
class DiagonalSheenPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.10)
      ..strokeWidth = size.width * 0.035
      ..strokeCap = StrokeCap.round;

    final gap = size.width * 0.16;
    for (double x = -size.height; x < size.width + size.height; x += gap) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}



