import 'package:flutter/material.dart';
import '../../helpers/CaptainNavigationHelper.dart';
import '../../local database/table_dao.dart';
import '../Widgets/CaptainBottomNavBar.dart';
import 'CaptainTablesScreen.dart';
class DashboardScreen extends StatefulWidget {
  final String pin;
  final String associatedManagerPin;

  const DashboardScreen({
    Key? key,
    required this.pin,
    required this.associatedManagerPin,
  }) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  final tableDao = TableDao();

  void _onItemTapped(int index) {
    CaptionNavigationHelper.handleNavigation(context, _selectedIndex, index, widget.pin,widget.associatedManagerPin);
    setState(() {
      _selectedIndex = index;
    });
  }

  void _navigateToTables() async {
    final tables = await tableDao.getTablesByManagerPin(widget.associatedManagerPin);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CaptionTablesScreen(
          loadedTables: tables,
          pin: widget.pin,
          associatedManagerPin: widget.associatedManagerPin,
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Center(
            child: ElevatedButton(
              onPressed: _navigateToTables,
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
