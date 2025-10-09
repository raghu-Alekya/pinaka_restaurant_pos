import 'package:flutter/material.dart';
import 'package:pinaka_restaurant_pos/App%20flow/ui/tables_screen.dart';
import '../../local database/table_dao.dart';
import '../../models/UserPermissions.dart';
import '../widgets/NavigationHelper.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/top_bar.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  final String pin;
  final String token;
  final String restaurantId;
  final String restaurantName;
  final UserPermissions? userPermissions;

  const DashboardScreen({
    Key? key,
    required this.pin,
    required this.token,
    required this.restaurantId,
    required this.restaurantName,
    required this.userPermissions,
  }) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  UserPermissions? _userPermissions;

  @override
  void initState() {
    super.initState();
    _userPermissions = widget.userPermissions;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkDashboardPermission();
    });
  }

  void _checkDashboardPermission() async {
    if (_userPermissions != null && !_userPermissions!.canAccessDashboard) {
      final tableDao = TableDao();
      final tables = await tableDao.getTablesByManagerPin(widget.pin);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (_) => TablesScreen(
                loadedTables: tables,
                pin: widget.pin,
                token: widget.token,
                restaurantId: widget.restaurantId,
                restaurantName: widget.restaurantName,
                // zoneId: widget.zoneId,
              ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDEDF9),
      appBar: TopBar(
        token: widget.token,
        pin: widget.pin,
        userPermissions: _userPermissions,
        onPermissionsReceived: (permissions) async {
          setState(() {
            _userPermissions = permissions;
          });
          if (_userPermissions != null &&
              !_userPermissions!.canAccessDashboard) {
            final tableDao = TableDao();
            final tables = await tableDao.getTablesByManagerPin(widget.pin);
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => TablesScreen(
                        loadedTables: tables,
                        pin: widget.pin,
                        token: widget.token,
                        restaurantId: widget.restaurantId,
                        restaurantName: widget.restaurantName,
                      ),
                ),
              );
            }
          }
        }, restaurantId: 'restaurentid',
      ),
      body: const DashboardContent(),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: 0,
        onItemTapped: (index) {
          NavigationHelper.handleNavigation(
            context,
            0,
            index,
            widget.pin,
            widget.token,
            widget.restaurantId,
            widget.restaurantName,
            _userPermissions as UserPermissions?,
            // widget.zoneId
          );
        },
        userPermissions: _userPermissions,
      ),
    );
  }
}

class DashboardContent extends StatelessWidget {
  const DashboardContent({super.key});

  @override
  Widget build(BuildContext context) {
    final String currentDate = DateFormat("dd-MMM-yyyy").format(DateTime.now());
    final String currentTime = DateFormat("hh:mm a").format(DateTime.now());
    return SingleChildScrollView(
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Good Morning Ajay!",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          size: 18, color: Colors.black),
                      const SizedBox(width: 6),
                      Text(
                        currentDate,
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Row(
                    children: [
                      const Icon(Icons.access_time,
                          size: 18, color: Colors.black),
                      const SizedBox(width: 6),
                      Text(
                        currentTime,
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          /// Row: 4 metric cards + Employee List
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 4 metric cards
              Expanded(
                flex: 2,
                child: GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 2,
                  crossAxisSpacing: 25,
                  mainAxisSpacing: 25,
                  childAspectRatio: 2.4,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _metricCard(
                      icon: Icons.attach_money,
                      iconBg: Colors.green,
                      title: "Total Revenue",
                      value: "1800.49",
                      change: "+2.0%",
                      changeColor: Colors.green,
                      subtitle: "Revenue generated this month",
                      cardColor: Colors.green.shade50,
                    ),
                    _metricCard(
                      icon: Icons.shopping_bag,
                      iconBg: Colors.orange,
                      title: "Total Orders",
                      value: "25",
                      change: "+2.4%",
                      changeColor: Colors.green,
                      subtitle: "Orders placed till now",
                      cardColor: Colors.orange.shade50,
                    ),
                    _metricCard(
                      icon: Icons.pending_actions,
                      iconBg: Colors.purple,
                      title: "Pending Orders",
                      value: "7",
                      change: "-1.0%",
                      changeColor: Colors.red,
                      subtitle: "Delayed orders for today",
                      cardColor: Colors.purple.shade50,
                    ),
                    _metricCard(
                      icon: Icons.table_bar,
                      iconBg: Colors.pink,
                      title: "Active Tables",
                      value: "12",
                      change: "+3.6%",
                      changeColor: Colors.green,
                      subtitle: "Tables that are occupied till now",
                      cardColor: Colors.pink.shade50,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 20),

              /// Employee list on the right
              Expanded(flex: 1, child: _employeeCard()),
            ],
          ),

          const SizedBox(height: 20),

          /// Row: Graphs and Top Selling Items
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _graphCard("Revenue Breakdown", _buildBarChart()),
              ),
              const SizedBox(width: 16),
              Expanded(child: _graphCard("Payment Modes", _buildPieChart())),
              const SizedBox(width: 16),
              Expanded(
                child: _graphCard("Top Selling Items", _buildBubbleChart()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _metricCard({
    required IconData icon,
    required Color iconBg,
    required String title,
    required String value,
    required String change,
    required Color changeColor,
    required String subtitle,
    required Color cardColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            offset: const Offset(-2, 2),
            blurRadius: 6,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            offset: const Offset(2, 2),
            blurRadius: 6,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Top Row: Icon + Percentage chip
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 18),
                ),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: changeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    change,
                    style: TextStyle(
                      color: changeColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            /// Title
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 6),

            /// Value
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),

            const Spacer(),

            /// Subtitle
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }


  static Widget _graphCard(String title, Widget child) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            SizedBox(height: 200, child: child),
          ],
        ),
      ),
    );
  }

  static Widget _employeeCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Employees List",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 303,
              child: ListView(
                children: [
                  _employeeTile("Noah Jones", "Manager", "Logged Out", Colors.grey),
                  _employeeTile("Emma Johnson", "Captain", "On Shift", Colors.green),
                  _employeeTile("Ethan Davis", "Chef", "On Shift", Colors.green),
                  _employeeTile("Mason Wilson", "Captain", "In Break", Colors.orange),
                  _employeeTile("James Anderson", "Manager", "On Break", Colors.red),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _employeeTile(
    String name,
    String role,
    String status,
    Color statusColor,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(name),
      subtitle: Text(role),
      trailing: Text(
        status,
        style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
      ),
    );
  }

  /// Chart builders
  static Widget _buildBarChart() {
    return BarChart(
      BarChartData(
        borderData: FlBorderData(show: false),
        barGroups: List.generate(
          7,
          (i) => BarChartGroupData(
            x: i,
            barRods: [BarChartRodData(toY: (10 + i * 3).toDouble(), width: 16)],
          ),
        ),
      ),
    );
  }

  static Widget _buildPieChart() {
    return PieChart(
      PieChartData(
        sections: [
          PieChartSectionData(value: 40, title: "UPI", color: const Color(0xFFFF9A9A)),
          PieChartSectionData(value: 30, title: "Cash",  color: const Color(0xFF6FD195)),
          PieChartSectionData(value: 20, title: "Card", color: const Color(0xFF7086FD)),
        ],
      ),
    );
  }

  static Widget _buildBubbleChart() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _bubble("Margherita", 45, Colors.blue),
        _bubble("Pepperoni", 30, Colors.green),
        _bubble("Lasagna", 25, Colors.orange),
        _bubble("Tiramisu", 20, Colors.purple),
        _bubble("Caesar", 15, Colors.teal),
      ],
    );
  }

  static Widget _bubble(String label, double percent, Color color) {
    return Column(
      children: [
        CircleAvatar(
          radius: percent / 2,
          backgroundColor: color.withValues(alpha: 0.7),
          child: Text("${percent.toInt()}%"),
        ),
        const SizedBox(height: 4),
        Text(label),
      ],
    );
  }
}
