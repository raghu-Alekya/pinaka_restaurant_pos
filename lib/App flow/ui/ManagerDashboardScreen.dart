import 'package:flutter/material.dart';
import 'package:pinaka_restaurant_pos/App%20flow/ui/tables_screen.dart';
import '../../local database/table_dao.dart';
import '../widgets/NavigationHelper.dart';
import '../widgets/bottom_nav_bar.dart';

class ManagerDashboardScreen extends StatefulWidget {
  final String pin;
  final String token;
  final String restaurantId;
  final String restaurantName;

  const ManagerDashboardScreen({
    Key? key,
    required this.pin,
    required this.token,
    required this.restaurantId,
    required this.restaurantName,
  }) : super(key: key);

  @override
  State<ManagerDashboardScreen> createState() => _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState extends State<ManagerDashboardScreen> {
  int _selectedIndex = 0;
  final tableDao= TableDao();

  void _onNavItemTapped(int index) {
    NavigationHelper.handleNavigation(context, _selectedIndex, index,
        widget.pin,
        widget.token,
        widget.restaurantId,
      widget.restaurantName);
    setState(() {
      _selectedIndex = index;
    });
  }


  void _navigateToTables() async {
    final tables = await tableDao.getTablesByManagerPin(widget.pin);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TablesScreen(
          loadedTables: tables,
          pin: widget.pin,
          token:widget.token,
          restaurantId:widget.restaurantId,
          restaurantName:widget.restaurantName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF6F7FB),
      appBar: AppBar(
        title: Text('Manager Dashboard'),
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 70,
      ),
      body: Stack(
        children: [
          Center(
            child: ElevatedButton(
              onPressed: _navigateToTables,
              child: const Text('Create New Order'),
            ),
          ),
          BottomNavBar(
            selectedIndex: _selectedIndex,
            onItemTapped: _onNavItemTapped,
          ),
        ],
      ),
    );
  }
}
