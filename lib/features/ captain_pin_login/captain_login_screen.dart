// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:provider/provider.dart';
// import '../ merchant_login/merchant_login_data_layer/merchant_local_storage.dart';
// import '../ merchant_login/merchant_login_screen.dart';
// import '../../../constants/color_constants.dart';
// import '../home_screen/TableManagement_Screen.dart';
// import 'captain_login_bloc/captain_login_bloc.dart';
// import 'captain_login_bloc/captain_login_event.dart';
// import 'captain_login_bloc/captain_login_state.dart';
//
// class CaptainLoginScreen extends StatefulWidget {
//   const CaptainLoginScreen({Key? key}) : super(key: key);
//
//   @override
//   State<CaptainLoginScreen> createState() => _CaptainLoginScreenState();
// }
//
// class _CaptainLoginScreenState extends State<CaptainLoginScreen> {
//   static const int _pinLength = 6;
//   String _pin = '';
//
//   bool get _isComplete => _pin.length == _pinLength;
//
//   void _onKeyTap(String digit) {
//     if (_pin.length >= _pinLength) return;
//     setState(() => _pin += digit);
//   }
//
//   void _onClear() {
//     setState(() => _pin = '');
//   }
//
//   void _onBackspace() {
//     if (_pin.isEmpty) return;
//     setState(() => _pin = _pin.substring(0, _pin.length - 1));
//   }
//
//   void _onLoginPressed() {
//     if (!_isComplete) return;
//     final bloc = context.read<CaptainLoginBloc>();
//     bloc.add(
//       CaptainLoginButtonPressed(
//         pin: _pin.trim(),
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final size = MediaQuery.of(context).size;
//     final horizontalPadding = size.width * 0.07;
//
//     return Scaffold(
//       resizeToAvoidBottomInset: true,
//       backgroundColor: Colors.white,
//       body: BlocConsumer<CaptainLoginBloc, CaptainLoginState>(
//         listener: (context, state) {
//           if (state is CaptainLoginSuccess) {
//             // Debug log
//             print('CaptainLoginSuccess received! Navigating to TableManagementScreen.');
//
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(
//                 content: Text('Welcome ${state.entity.data?.displayName ?? ''}'),
//                 backgroundColor: ColorConstants.successColor,
//               ),
//             );
//
//             // Schedule navigation after the current frame to avoid context issues
//             WidgetsBinding.instance.addPostFrameCallback((_) {
//               if (mounted) {
//                 Navigator.of(context).pushReplacement(
//                   MaterialPageRoute(
//                     builder: (_) => TableManagementScreen(
//                       captainName: state.entity.data?.displayName,
//                       captainRole: 'Captain',
//                     ),
//                   ),
//                 );
//               }
//             });
//           } else if (state is CaptainLoginFailure) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(
//                 content: Text(state.error),
//                 backgroundColor: ColorConstants.errorColor,
//               ),
//             );
//             setState(() => _pin = '');
//           }
//         },
//         builder: (context, state) {
//           final isLoading = state is CaptainLoginLoading;
//
//           return Stack(
//             children: [
//               // ---------- Bottom orange curved band ----------
//               Positioned(
//                 left: 0,
//                 right: 0,
//                 bottom: 0,
//                 child: ClipPath(
//                   clipper: BottomArchClipper(),
//                   child: Container(
//                     height: size.height,
//                     width: size.width,
//                     decoration: const BoxDecoration(
//                       gradient: LinearGradient(
//                         begin: Alignment.topLeft,
//                         end: Alignment.bottomRight,
//                         colors: [
//                           Color(0xFFE8600C),
//                           Color(0xFFC1440E),
//                           Color(0xFF8E2A0B),
//                         ],
//                         stops: [0.0, 0.5, 1.0],
//                       ),
//                     ),
//                     child: CustomPaint(
//                       painter: DiagonalSheenPainter(),
//                       child: const SizedBox.expand(),
//                     ),
//                   ),
//                 ),
//               ),
//
//               // ---------- Foreground content ----------
//               SafeArea(
//                 child: LayoutBuilder(
//                   builder: (context, constraints) {
//                     return SingleChildScrollView(
//                       padding: EdgeInsets.symmetric(
//                         horizontal: horizontalPadding,
//                       ),
//                       child: ConstrainedBox(
//                         constraints: BoxConstraints(
//                           minHeight: constraints.maxHeight,
//                         ),
//                         child: IntrinsicHeight(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               SizedBox(height: size.height * 0.06),
//                               Center(
//                                 child: Text(
//                                   'Captain Login',
//                                   style: TextStyle(
//                                     fontSize: size.width * 0.065,
//                                     fontWeight: FontWeight.bold,
//                                     color: Colors.black87,
//                                   ),
//                                 ),
//                               ),
//                               SizedBox(height: size.height * 0.008),
//                               Center(
//                                 child: Text(
//                                   'Login to manage orders operations',
//                                   textAlign: TextAlign.center,
//                                   style: TextStyle(
//                                     fontSize: size.width * 0.036,
//                                     color: Colors.black54,
//                                   ),
//                                 ),
//                               ),
//                               SizedBox(height: size.height * 0.03),
//                               Text(
//                                 'Please enter your user PIN',
//                                 style: TextStyle(
//                                   fontSize: size.width * 0.042,
//                                   color: Colors.black87,
//                                 ),
//                               ),
//                               SizedBox(height: size.height * 0.016),
//                               _buildPinBoxes(size),
//                               SizedBox(height: size.height * 0.025),
//                               _buildKeypad(size, isLoading),
//                               SizedBox(height: size.height * 0.02),
//                               _buildLoginButton(size, isLoading),
//
//                               // ========== NEW: Bottom navigation to Merchant Login ==========
//                               const Spacer(),
//                               Row(
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 children: [
//                                   TextButton(
//                                     onPressed: () async {
//                                       // Clear stored merchant data
//                                       final merchantStorage = context.read<MerchantLocalStorage>();
//                                       await merchantStorage.clearMerchantData();
//                                       print('Merchant data cleared. Navigating to MerchantLoginScreen.');
//
//                                       // Navigate to merchant login
//                                       Navigator.pushReplacement(
//                                         context,
//                                         MaterialPageRoute(builder: (_) => const MerchantLoginScreen()),
//                                       );
//                                     },
//                                     child: Text(
//                                       'Login as Merchant?',
//                                       style: TextStyle(
//                                         color: Colors.black,
//                                         fontSize: size.width * 0.04,
//                                         fontWeight: FontWeight.w500,
//                                       ),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                               SizedBox(height: size.height * 0.12),
//                               // ==============================================================
//                             ],
//                           ),
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//               ),
//             ],
//           );
//         },
//       ),
//     );
//   }
//
//   Widget _buildPinBoxes(Size size) {
//     final boxSize = size.width * 0.115;
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: List.generate(_pinLength, (index) {
//         final filled = index < _pin.length;
//         return Container(
//           width: boxSize,
//           height: boxSize,
//           alignment: Alignment.center,
//           decoration: BoxDecoration(
//             color: const Color(0xFFF2F2F2),
//             borderRadius: BorderRadius.circular(size.width * 0.02),
//           ),
//           child: filled
//               ? Container(
//             width: boxSize * 0.24,
//             height: boxSize * 0.24,
//             decoration: const BoxDecoration(
//               color: Colors.black87,
//               shape: BoxShape.circle,
//             ),
//           )
//               : null,
//         );
//       }),
//     );
//   }
//
//   Widget _buildKeypad(Size size, bool isLoading) {
//     final rows = <List<_KeyData>>[
//       [_KeyData('1'), _KeyData('2'), _KeyData('3')],
//       [_KeyData('4'), _KeyData('5'), _KeyData('6')],
//       [_KeyData('7'), _KeyData('8'), _KeyData('9')],
//       [
//         _KeyData('C', isClear: true),
//         _KeyData('0'),
//         _KeyData('', isBackspace: true),
//       ],
//     ];
//
//     return Column(
//       children: rows
//           .map(
//             (row) => Padding(
//           padding: EdgeInsets.only(bottom: size.height * 0.012),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children:
//             row.map((key) => _buildKey(key, size, isLoading)).toList(),
//           ),
//         ),
//       )
//           .toList(),
//     );
//   }
//
//   Widget _buildKey(_KeyData key, Size size, bool isLoading) {
//     final keySize = (size.width * 0.19).clamp(48.0, size.height * 0.09);
//
//     Widget child;
//     if (key.isBackspace) {
//       child = Icon(
//         Icons.backspace_outlined,
//         size: size.width * 0.05,
//         color: Colors.black54,
//       );
//     } else {
//       child = Text(
//         key.label,
//         style: TextStyle(
//           fontSize: size.width * 0.05,
//           fontWeight: FontWeight.w600,
//           color: Colors.black87,
//         ),
//       );
//     }
//
//     return Material(
//       color: const Color(0xFFF2F2F2),
//       borderRadius: BorderRadius.circular(size.width * 0.03),
//       child: InkWell(
//         borderRadius: BorderRadius.circular(size.width * 0.03),
//         onTap: isLoading
//             ? null
//             : () {
//           if (key.isClear) {
//             _onClear();
//           } else if (key.isBackspace) {
//             _onBackspace();
//           } else {
//             _onKeyTap(key.label);
//           }
//         },
//         child: SizedBox(
//           width: keySize,
//           height: keySize,
//           child: Center(child: child),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildLoginButton(Size size, bool isLoading) {
//     final Color buttonColor =
//     _isComplete ? ColorConstants.primaryColor : Colors.grey;
//
//     return SizedBox(
//       width: double.infinity,
//       height: size.height * 0.065,
//       child: ElevatedButton(
//         onPressed: (_isComplete && !isLoading) ? _onLoginPressed : null,
//         style: ElevatedButton.styleFrom(
//           backgroundColor: buttonColor,
//           foregroundColor: Colors.white,
//           disabledBackgroundColor: buttonColor,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(size.width * 0.03),
//           ),
//           elevation: 0,
//         ),
//         child: isLoading
//             ? SizedBox(
//           width: size.width * 0.06,
//           height: size.width * 0.06,
//           child: const CircularProgressIndicator(
//             color: Colors.white,
//             strokeWidth: 2.5,
//           ),
//         )
//             : Text(
//           'Login',
//           style: TextStyle(
//             fontSize: size.width * 0.045,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// class _KeyData {
//   final String label;
//   final bool isClear;
//   final bool isBackspace;
//
//   _KeyData(this.label, {this.isClear = false, this.isBackspace = false});
// }
//



import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../ merchant_login/merchant_login_data_layer/merchant_local_storage.dart';
import '../ merchant_login/merchant_login_screen.dart';
import '../../../constants/color_constants.dart';
import '../home_screen/TableManagement_Screen.dart';
import 'captain_login_bloc/captain_login_bloc.dart';
import 'captain_login_bloc/captain_login_event.dart';
import 'captain_login_bloc/captain_login_state.dart';

class CaptainLoginScreen extends StatefulWidget {
  const CaptainLoginScreen({Key? key}) : super(key: key);

  @override
  State<CaptainLoginScreen> createState() => _CaptainLoginScreenState();
}

class _CaptainLoginScreenState extends State<CaptainLoginScreen> {
  static const int _pinLength = 6;
  String _pin = '';

  // Colors tuned to match the reference image: cooler grey for the PIN
  // boxes, warmer beige for the keypad keys.
  static const Color _pinBoxColor = Color(0xFFF1F1F1);
  static const Color _keyColor = Color(0xFFF6EFE3);

  bool get _isComplete => _pin.length == _pinLength;

  void _onKeyTap(String digit) {
    if (_pin.length >= _pinLength) return;
    setState(() => _pin += digit);
  }

  void _onClear() {
    setState(() => _pin = '');
  }

  void _onBackspace() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  void _onLoginPressed() {
    if (!_isComplete) return;
    final bloc = context.read<CaptainLoginBloc>();
    bloc.add(
      CaptainLoginButtonPressed(
        pin: _pin.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final horizontalPadding = size.width * 0.07;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      body: BlocConsumer<CaptainLoginBloc, CaptainLoginState>(
        listener: (context, state) {
          if (state is CaptainLoginSuccess) {
            print('CaptainLoginSuccess received! Navigating to TableManagementScreen.');

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Welcome ${state.entity.data?.displayName ?? ''}'),
                backgroundColor: ColorConstants.successColor,
              ),
            );

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => TableManagementScreen(
                      captainName: state.entity.data?.displayName,
                      captainRole: 'Captain',
                    ),
                  ),
                );
              }
            });
          } else if (state is CaptainLoginFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error),
                backgroundColor: ColorConstants.errorColor,
              ),
            );
            setState(() => _pin = '');
          }
        },
        builder: (context, state) {
          final isLoading = state is CaptainLoginLoading;

          return Stack(
            children: [
              // ---------- TOP orange curved band ----------
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: ClipPath(
                  clipper: _TopArchClipper(),
                  child: Container(
                    height: size.height,
                    width: size.width,
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
                ),
              ),

              // ---------- Bottom orange curved band ----------
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: ClipPath(
                  clipper: BottomArchClipper(),
                  child: Container(
                    height: size.height,
                    width: size.width,
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
                ),
              ),

              // ---------- Foreground content ----------
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: constraints.maxHeight),
                        child: IntrinsicHeight(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: size.height * 0.075),
                              Center(
                                child: Text(
                                  'Employee Login',
                                  style: TextStyle(
                                    fontSize: size.width * 0.065,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              SizedBox(height: size.height * 0.01),
                              Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: size.width * 0.06),
                                  child: Text(
                                    'Login to manage orders operations',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: size.width * 0.036,
                                      color: Colors.black54,
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: size.height * 0.035),
                              Center(
                                child: Text(
                                  'Please enter your user PIN',
                                  style: TextStyle(
                                    fontSize: size.width * 0.045,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              SizedBox(height: size.height * 0.02),
                              _buildPinBoxes(size),
                              SizedBox(height: size.height * 0.035),
                              _buildKeypad(size, isLoading),
                              SizedBox(height: size.height * 0.025),
                              _buildLoginButton(size, isLoading),

                              const Spacer(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  TextButton(
                                    onPressed: () async {
                                      final merchantStorage = context.read<MerchantLocalStorage>();
                                      await merchantStorage.clearMerchantData();
                                      print('Merchant data cleared. Navigating to MerchantLoginScreen.');

                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(builder: (_) => const MerchantLoginScreen()),
                                      );
                                    },
                                    child: Text(
                                      'Login  Here ?',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: size.width * 0.04,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: size.height * 0.12),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPinBoxes(Size size) {
    final boxSize = size.width * 0.100;
    final gap = size.width * 0.02; // tight gap between PIN boxes

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_pinLength, (index) {
        final filled = index < _pin.length;
        return Padding(
          padding: EdgeInsets.only(right: index == _pinLength - 1 ? 0 : gap),
          child: Container(
            width: boxSize,
            height: boxSize,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _pinBoxColor,
              borderRadius: BorderRadius.circular(size.width * 0.025),
            ),
            child: filled
                ? Container(
              width: boxSize * 0.24,
              height: boxSize * 0.24,
              decoration: const BoxDecoration(
                color: Colors.black87,
                shape: BoxShape.circle,
              ),
            )
                : null,
          ),
        );
      }),
    );
  }

  Widget _buildKeypad(Size size, bool isLoading) {
    final rows = <List<_KeyData>>[
      [_KeyData('1'), _KeyData('2'), _KeyData('3')],
      [_KeyData('4'), _KeyData('5'), _KeyData('6')],
      [_KeyData('7'), _KeyData('8'), _KeyData('9')],
      [
        _KeyData('C', isClear: true),
        _KeyData('0'),
        _KeyData('', isBackspace: true),
      ],
    ];

    final gap = size.width * 0.035; // tight gap between keys, same idea as PIN boxes

    return Column(
      children: rows
          .map(
            (row) => Padding(
          padding: EdgeInsets.only(bottom: size.height * 0.012),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int i = 0; i < row.length; i++) ...[
                if (i != 0) SizedBox(width: gap),
                _buildKey(row[i], size, isLoading),
              ],
            ],
          ),
        ),
      )
          .toList(),
    );
  }


  Widget _buildKey(_KeyData key, Size size, bool isLoading) {
    final keySize = (size.width * 0.2).clamp(50.0, size.height * 0.095);

    Widget child;
    if (key.isBackspace) {
      child = Icon(
        Icons.backspace_outlined,
        size: size.width * 0.05,
        color: Colors.black54,
      );
    } else {
      child = Text(
        key.label,
        style: TextStyle(
          fontSize: size.width * 0.05,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      );
    }

    return Material(
      color: _keyColor,
      borderRadius: BorderRadius.circular(size.width * 0.035),
      child: InkWell(
        borderRadius: BorderRadius.circular(size.width * 0.035),
        onTap: isLoading
            ? null
            : () {
          if (key.isClear) {
            _onClear();
          } else if (key.isBackspace) {
            _onBackspace();
          } else {
            _onKeyTap(key.label);
          }
        },
        child: SizedBox(
          width: keySize,
          height: keySize,
          child: Center(child: child),
        ),
      ),
    );
  }

  Widget _buildLoginButton(Size size, bool isLoading) {
    final Color buttonColor = _isComplete ? ColorConstants.primaryColor : Colors.grey.shade400;

    return SizedBox(
      width: double.infinity,
      height: size.height * 0.065,
      child: ElevatedButton(
        onPressed: (_isComplete && !isLoading) ? _onLoginPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: buttonColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(size.width * 0.035),
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
          'Login',
          style: TextStyle(
            fontSize: size.width * 0.045,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _KeyData {
  final String label;
  final bool isClear;
  final bool isBackspace;

  _KeyData(this.label, {this.isClear = false, this.isBackspace = false});
}

class _TopArchClipper extends CustomClipper<Path> {
  static const double _leftFraction = 0.15;   // was 0.25
  static const double _rightFraction = 0.06;  // was 0.10
  static const double _archFraction = 0.025;  // was 0.045

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