

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pinaka_restaurant_pos/App%20flow/widgets/pin_input.dart';

import 'number_pad.dart';

class PinConfirmationPopup extends StatefulWidget {
final String expectedPin;

// Dynamic texts
final String title;
final String message;
final String cancelText;
final String proceedText;

// Optional callbacks
final VoidCallback? onCancel;
final VoidCallback? onProceed;

// Button colors
final Color cancelColor;
final Color proceedColor;

const PinConfirmationPopup({
super.key,
required this.expectedPin,

this.title = 'Confirm Login',
this.message = 'Please enter your PIN to edit this order.',
this.cancelText = 'Cancel',
this.proceedText = 'Proceed',

this.onCancel,
this.onProceed,

this.cancelColor = const Color(0xFFFE6464),
this.proceedColor = const Color(0xFFFE6464),
});

/// Reusable static method
static Future<bool> show({
required BuildContext context,
required String expectedPin,

String title = 'Confirm Login',
String message = 'Please enter your PIN to edit this order.',
String cancelText = 'Cancel',
String proceedText = 'Proceed',

VoidCallback? onCancel,
VoidCallback? onProceed,

Color cancelColor = const Color(0xFFFE6464),
Color proceedColor = const Color(0xFFFE6464),
}) async {
final bool? result = await showDialog<bool>(
context: context,
barrierDismissible: false,
builder: (dialogContext) {
return PinConfirmationPopup(
expectedPin: expectedPin,

title: title,
message: message,
cancelText: cancelText,
proceedText: proceedText,

cancelColor: cancelColor,
proceedColor: proceedColor,

onCancel: onCancel,
onProceed: onProceed,
);
},
);

return result ?? false;
}

@override
State<PinConfirmationPopup> createState() =>
_PinConfirmationPopupState();
}

class _PinConfirmationPopupState
extends State<PinConfirmationPopup> {
String _pin = '';
bool _isChecking = false;

void _onKeyPressed(String value) {
if (_isChecking) return;

setState(() {
if (value == 'C') {
_pin = '';
} else if (value == '⌫') {
if (_pin.isNotEmpty) {
_pin = _pin.substring(0, _pin.length - 1);
}
} else if (_pin.length < 6) {
_pin += value;
}
});
}

Future<void> _onProceed() async {
if (_pin.length != 6) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('PIN must be exactly 6 digits'),
duration: Duration(seconds: 1),
backgroundColor: Colors.red,
behavior: SnackBarBehavior.floating,
),
);

return;
}

setState(() {
_isChecking = true;
});

final String enteredPin = _pin.trim();
final String expectedPin = widget.expectedPin.trim();

// -----------------------------------------
// VERIFY PIN
// -----------------------------------------
if (enteredPin != expectedPin) {
if (!mounted) return;

setState(() {
_isChecking = false;
_pin = '';
});

ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text(
'PIN does not match the logged-in user',
),
duration: Duration(seconds: 2),
backgroundColor: Colors.red,
behavior: SnackBarBehavior.floating,
),
);

return;
}

// -----------------------------------------
// PIN MATCHED
// -----------------------------------------

if (!mounted) return;

// Execute optional callback
widget.onProceed?.call();

// Close popup and return success
Navigator.of(context).pop(true);
}

void _onCancel() {
if (_isChecking) return;

// Execute optional callback
widget.onCancel?.call();

// Close popup and return false
Navigator.of(context).pop(false);
}

@override
Widget build(BuildContext context) {
final theme = Theme.of(context);
final bool isDark =
theme.brightness == Brightness.dark;

return Dialog(
backgroundColor: Colors.transparent,
insetPadding:
const EdgeInsets.symmetric(horizontal: 30),

child: Container(
width: 430,

padding:
const EdgeInsets.fromLTRB(30, 28, 30, 25),

decoration: BoxDecoration(
color:
isDark
? const Color(0xFF202433)
    : Colors.white,

borderRadius:
BorderRadius.circular(16),

boxShadow: [
BoxShadow(
color:
Colors.black.withOpacity(0.18),
blurRadius: 25,
spreadRadius: 2,
offset:
const Offset(0, 10),
),
],
),

child: Column(
mainAxisSize: MainAxisSize.min,

children: [
// -----------------------------------------
// LOGO
// -----------------------------------------
Image.asset(
isDark
? 'assets/pinaka_dark.png'
    : 'assets/pinaka.png',
height: 55,
),

const SizedBox(height: 18),

// -----------------------------------------
// DYNAMIC TITLE
// -----------------------------------------
Text(
widget.title,
textAlign: TextAlign.center,
style:
theme.textTheme.titleLarge?.copyWith(
fontWeight:
FontWeight.w600,
color:
isDark
? Colors.white
    : const Color(0xFF26344D),
),
),

const SizedBox(height: 10),

// -----------------------------------------
// DYNAMIC MESSAGE
// -----------------------------------------
Text(
widget.message,
textAlign: TextAlign.center,
style:
theme.textTheme.bodyMedium?.copyWith(
color:
isDark
? Colors.white70
    : const Color(0xFF4C5F7D),
),
),

const SizedBox(height: 22),

// -----------------------------------------
// PIN INPUT
// -----------------------------------------
PinInput(pin: _pin),

const SizedBox(height: 18),

// -----------------------------------------
// NUMBER PAD
// -----------------------------------------
NumberPad(
onKeyPressed: _onKeyPressed,
),

const SizedBox(height: 24),

// -----------------------------------------
// BUTTONS
// -----------------------------------------
Row(
children: [
// -------------------------------------
// DYNAMIC CANCEL BUTTON
// -------------------------------------
Expanded(
child: OutlinedButton(
onPressed:
_isChecking
? null
    : _onCancel,

style:
OutlinedButton.styleFrom(
minimumSize:
const Size(
double.infinity,
48,
),

side: BorderSide(
color:
widget.cancelColor,
width: 1.2,
),

shape:
RoundedRectangleBorder(
borderRadius:
BorderRadius.circular(
8,
),
),
),

child: Text(
widget.cancelText,
style: TextStyle(
color:
widget.cancelColor,
fontSize: 15,
fontWeight:
FontWeight.w600,
),
),
),
),

const SizedBox(width: 14),

// -------------------------------------
// DYNAMIC PROCEED BUTTON
// -------------------------------------
Expanded(
child: ElevatedButton(
onPressed:
_isChecking
? null
    : _onProceed,

style:
ElevatedButton.styleFrom(
backgroundColor:
widget.proceedColor,

foregroundColor:
Colors.white,

elevation: 0,

minimumSize:
const Size(
double.infinity,
48,
),

shape:
RoundedRectangleBorder(
borderRadius:
BorderRadius.circular(
8,
),
),
),

child:
_isChecking
? const SizedBox(
width: 22,
height: 22,
child:
CircularProgressIndicator(
color:
Colors.white,
strokeWidth:
2,
),
)
    : Text(
widget.proceedText,
style:
const TextStyle(
color:
Colors.white,
fontSize: 15,
fontWeight:
FontWeight.w600,
),
),
),
),
],
),
],
),
),
);
}
}

