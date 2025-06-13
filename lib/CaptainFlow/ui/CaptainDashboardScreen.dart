import 'package:flutter/material.dart';
import '../../helpers/CaptainNavigationHelper.dart';
import '../../helpers/DatabaseHelper.dart';
import '../Widgets/CaptainBottomNavBar.dart';
import 'CaptainTablesScreen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    CaptionNavigationHelper.handleNavigation(context, _selectedIndex, index);
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Center(
            child: ElevatedButton(
              onPressed: () async {
                final dbHelper = DatabaseHelper();
                final tables = await dbHelper.getAllTables();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CaptionTablesScreen(loadedTables: tables),
                  ),
                );
              },
              child: const Text('Create New Order'),
            ),
          ),
          CaptionBottomNavBar(
            selectedIndex: _selectedIndex,
            onItemTapped: _onItemTapped,
          ),
        ],
      ),
    );
  }
}
