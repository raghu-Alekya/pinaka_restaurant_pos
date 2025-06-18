import 'package:flutter/material.dart';
import 'package:pinaka_restaurant_pos/Manager%20flow/ui/tables_screen.dart';
import '../../helpers/DatabaseHelper.dart';
import '../widgets/NavigationHelper.dart';
import '../widgets/bottom_nav_bar.dart';

class ManagerDashboardScreen extends StatefulWidget {
  const ManagerDashboardScreen({Key? key}) : super(key: key);

  @override
  State<ManagerDashboardScreen> createState() => _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState extends State<ManagerDashboardScreen> {
  int _selectedIndex = 0;

  void _onNavItemTapped(int index) {
    NavigationHelper.handleNavigation(context, _selectedIndex, index);
    setState(() {
      _selectedIndex = index;
    });
  }
  void _navigateToTables() async {
    final dbHelper = DatabaseHelper();
    final tables = await dbHelper.getAllTables();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TablesScreen(loadedTables: tables),
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
