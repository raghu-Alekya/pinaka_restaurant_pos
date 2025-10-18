import 'package:flutter/material.dart';
import '../../utils/SessionManager.dart';
import '../widgets/payment_sidebar_widget.dart';
import '../widgets/paymentnum_pad.dart';
import '../widgets/top_bar.dart';
// import '../utils/session_manager.dart'; // make sure this import is correct

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  dynamic _userPermissions;
  Map<String, dynamic>? _selectedUser;

  @override
  void initState() {
    super.initState();
    _loadPermissions();
  }

  Future<void> _loadPermissions() async {
    try {
      final savedPermissions = await SessionManager.loadPermissions();
      if (savedPermissions != null) {
        setState(() {
          _userPermissions = savedPermissions;
          _selectedUser = {
            "id": savedPermissions.userId,
            "name": savedPermissions.displayName,
            "role": savedPermissions.role,
          };
        });
      }
    } catch (e) {
      debugPrint("❌ Error loading permissions: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: TopBar(
          userPermissions: _userPermissions,
          selectedUser: _selectedUser, token: '', pin: '',
        ),
      ),
      body: Row(
        children: [
          // Left Sidebar
          Expanded(
            flex: 25,
            child: Sidebarwidgets(
              userPermissions: _userPermissions,
              selectedUser: _selectedUser,
            ),
          ),

          // Middle Number Pad Section
          const Expanded(
            flex: 50,
            child: Numberpad(),
          ),
        ],
      ),
    );
  }
}
