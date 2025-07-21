import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/Bloc Event/checkin_event.dart';
import '../../blocs/Bloc Logic/checkin_bloc.dart';
import '../../blocs/Bloc State/checkin_state.dart';

class Checkinpopup extends StatefulWidget {
  final VoidCallback? onCheckIn;
  final VoidCallback? onCancel;
  final String token;

  const Checkinpopup({
    super.key,
    this.onCheckIn,
    this.onCancel,
    required this.token,
  });

  @override
  State<Checkinpopup> createState() => _CheckinpopupState();
}

class _CheckinpopupState extends State<Checkinpopup> {
  List<String> pinDigits = ['', '', '', ''];
  bool showError = false;
  bool _isLoading = false;

  void _onNumberTap(String number) {
    for (int i = 0; i < pinDigits.length; i++) {
      if (pinDigits[i].isEmpty) {
        setState(() {
          pinDigits[i] = number;
        });
        break;
      }
    }
  }

  void _onClear() {
    setState(() {
      pinDigits = ['', '', '', ''];
      showError = false;
    });
  }

  void _onCheckIn() {
    final pin = pinDigits.join();
    if (pin.length < 4) {
      setState(() => showError = true);
      return;
    }
    context.read<CheckInBloc>().add(SubmitPinEvent(pin: pin, token: widget.token));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CheckInBloc, CheckInState>(
      listener: (context, state) {
        if (state is CheckInLoading) {
          setState(() {
            _isLoading = true;
            showError = false;
          });
        } else if (state is CheckInSuccess) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Check-In successful!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          widget.onCheckIn?.call();
        } else if (state is CheckInFailure) {
          setState(() {
            _isLoading = false;
            showError = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid PIN. Please try again.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
      child: _buildPopupContent(context),
    );
  }
  Widget _buildPopupContent(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 700,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xFFFAFFFE),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Captain Check-In',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Enter your 4-Digit PIN for Check-In',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF4C5F7D),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPinInputArea(),
                    const SizedBox(width: 10),
                    _buildNumberPad(),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPinInputArea() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PIN:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF4C5F7D),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(
              4,
                  (index) => Container(
                margin: const EdgeInsets.only(right: 12),
                width: 64,
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color: showError ? Colors.red : const Color(0xFF4C5F7D),
                    width: 1.8,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    pinDigits[index].isNotEmpty ? '*' : '',
                    style: const TextStyle(
                      fontSize: 30,
                      height: 1.0,
                      color: Color(0xFF4C5F7D),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          if (showError)
            const Text(
              'Please enter a valid PIN',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          const SizedBox(height: 25),
          Padding(
            padding: const EdgeInsets.only(left: 152),
            child: SizedBox(
              width: 140,
              height: 45,
              child: ElevatedButton(
                onPressed: () {
                  if (_isLoading) return;
                  _onCheckIn();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6C6C),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : const Text(
                  'Check-In',
                  style: TextStyle(fontSize: 17, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildNumberPad() {
    return Column(
      children: [
        _buildNumRow(['1', '2', '3']),
        _buildNumRow(['4', '5', '6']),
        _buildNumRow(['7', '8', '9']),
        _buildNumRow(['clear', '0']),
      ],
    );
  }

  Widget _buildNumRow(List<String> values) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: values.map((val) {
          return val == 'clear' ? _buildClearButton() : _buildKey(val);
        }).toList(),
      ),
    );
  }

  Widget _buildKey(String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: SizedBox(
        width: 84,
        height: 55,
        child: ElevatedButton(
          onPressed: () => _onNumberTap(value),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4C5F7D),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          child: Text(
            value,
            style: const TextStyle(fontSize: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildClearButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: SizedBox(
        width: 179,
        height: 55,
        child: ElevatedButton(
          onPressed: _onClear,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFFFF6C6C),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
              side: const BorderSide(color: Color(0xFFFF6C6C)),
            ),
          ),
          child: const Text(
            'Clear',
            style: TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }
}
