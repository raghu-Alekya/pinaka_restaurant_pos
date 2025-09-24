import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pinaka_restaurant_pos/App%20flow/ui/tables_screen.dart';
import '../../local database/table_dao.dart';
import '../../models/UserPermissions.dart';
import '../../repositories/dashboard_repository.dart';
import '../widgets/NavigationHelper.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/top_bar.dart';
import 'package:fl_chart/fl_chart.dart';
import 'EmployeeListScreen.dart';

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

class DashboardStats {
  final String revenue;
  final String orders;
  final String activeOrders;
  final String runningTables;
  final double revenueChange;
  final double ordersChange;

  DashboardStats({
    required this.revenue,
    required this.orders,
    required this.activeOrders,
    required this.runningTables,
    this.revenueChange = 0,
    this.ordersChange = 0,
  });
}

class _DashboardScreenState extends State<DashboardScreen> {
  UserPermissions? _userPermissions;

  // Filters
  String _selectedPeriod = "Daily";
  Map<String, dynamic>? _selectedZone;

  // Data
  List<String> periods = ["Daily", "Weekly", "Monthly"];
  List<Map<String, dynamic>> zones = [];
  String totalRevenue = "0";
  String revenueTrend = "";
  String totalOrders = "0";
  String ordersTrend = "";
  String activeOrders = "0";
  String runningTables = "0";
  bool isLoading = true;
  double revenueChange = 0;
  double ordersChange = 0;

  String get currentDate => DateFormat("dd-MMM-yyyy").format(DateTime.now());

  String get currentTime => DateFormat("hh:mma").format(DateTime.now());
  late DashboardRepository _repository;
  List<Map<String, dynamic>> employees = [];
  bool isEmployeeLoading = true;
  List<Map<String, dynamic>> inventoryAlerts = [];
  bool isInventoryLoading = true;
  List<Map<String, dynamic>> completedOrders = [];
  bool isCompletedOrdersLoading = true;
  List<Map<String, dynamic>> topProducts = [];
  bool isTopProductsLoading = true;
  List<Map<String, dynamic>> topCategories = [];
  bool isTopCategoriesLoading = true;

  @override
  void initState() {
    super.initState();
    _userPermissions = widget.userPermissions;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkDashboardPermission();
      _repository = DashboardRepository(
        token: widget.token,
        restaurantId: widget.restaurantId,
      );
      fetchDashboard();
      fetchEmployees();
      fetchInventoryAlerts();
      fetchCompletedOrders();
      fetchTopProducts();
      fetchTopCategories();
    });
  }

  Future<void> fetchTopProducts() async {
    setState(() => isTopProductsLoading = true);
    try {
      final products = await _repository.fetchTopProducts(
        zoneId: _selectedZone?['id']?.toString(),
      );
      setState(() {
        topProducts = products;
        isTopProductsLoading = false;
      });
    } catch (e) {
      print("Error fetching top products: $e");
      setState(() => isTopProductsLoading = false);
    }
  }

  Future<void> fetchTopCategories() async {
    setState(() => isTopCategoriesLoading = true);
    try {
      final categories = await _repository.fetchTopCategories(
        zoneId: _selectedZone?['id']?.toString(),
      );
      setState(() {
        topCategories = categories;
        isTopCategoriesLoading = false;
      });
    } catch (e) {
      print("Error fetching top categories: $e");
      setState(() => isTopCategoriesLoading = false);
    }
  }

  Future<void> fetchInventoryAlerts() async {
    setState(() => isInventoryLoading = true);
    try {
      final alerts = await _repository.fetchInventoryAlerts();
      setState(() {
        inventoryAlerts = alerts;
        isInventoryLoading = false;
      });
    } catch (e) {
      print("Error fetching inventory alerts: $e");
      setState(() => isInventoryLoading = false);
    }
  }
  Future<void> fetchCompletedOrders() async {
    setState(() => isCompletedOrdersLoading = true);
    try {
      final orders = await _repository.fetchCompletedOrders();
      setState(() {
        completedOrders = orders;
        isCompletedOrdersLoading = false;
      });
    } catch (e) {
      print("Error fetching completed orders: $e");
      setState(() => isCompletedOrdersLoading = false);
    }
  }

  Future<void> fetchEmployees() async {
    setState(() => isEmployeeLoading = true);

    try {
      final repo = _repository;
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final nowTime = DateFormat('hh:mm a').format(DateTime.now());

      final empList = await repo.fetchCurrentShiftEmployees(date: today, time: nowTime);
      setState(() {
        employees = empList;
        isEmployeeLoading = false;
      });
    } catch (e) {
      print("Error fetching employees: $e");
      setState(() => isEmployeeLoading = false);
    }
  }

  Future<void> fetchDashboard() async {
    setState(() => isLoading = true);

    try {
      final result = await _repository.fetchDashboardData(
        selectedPeriod: _selectedPeriod,
        selectedZone: _selectedZone,
      );

      setState(() {
        zones = result['zones'];
        _selectedZone = result['selectedZone'];
        totalRevenue = result['totalRevenue'];
        totalOrders = result['totalOrders'];
        revenueTrend = result['revenueTrend'];
        ordersTrend = result['ordersTrend'];
        activeOrders = result['activeOrders'];
        runningTables = result['runningTables'];
        isLoading = false;
      });
    } catch (e) {
      print(e);
      setState(() => isLoading = false);
    }
  }

  void _checkDashboardPermission() async {
    if (_userPermissions != null && !_userPermissions!.canAccessDashboard) {
      final tableDao = TableDao();
      final tables = await tableDao.getTablesByManagerPin(widget.pin);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (_) =>
              TablesScreen(
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

  final Map<String, Map<String, Map<String, double>>> revenueData = {
    "Week": {
      "Week 1": {"Dine In": 70, "Takeaway": 42},
      "Week 2": {"Dine In": 60, "Takeaway": 35},
      "Week 3": {"Dine In": 80, "Takeaway": 50},
      "Week 4": {"Dine In": 55, "Takeaway": 30},
      "Week 5": {"Dine In": 65, "Takeaway": 38},
      "Week 6": {"Dine In": 70, "Takeaway": 42},
      "Week 7": {"Dine In": 60, "Takeaway": 35},
      "Week 8": {"Dine In": 80, "Takeaway": 50},
      "Week 9": {"Dine In": 55, "Takeaway": 30},
      "Week 10": {"Dine In": 65, "Takeaway": 38},
    },
    "Month": {
      "Jan": {"Dine In": 40, "Takeaway": 42},
      "Feb": {"Dine In": 52, "Takeaway": 40},
      "Mar": {"Dine In": 75, "Takeaway": 46},
      "Apr": {"Dine In": 68, "Takeaway": 42},
      "May": {"Dine In": 80, "Takeaway": 50},
      "Jun": {"Dine In": 75, "Takeaway": 52},
      "Jul": {"Dine In": 90, "Takeaway": 58},
      "Aug": {"Dine In": 60, "Takeaway": 56},
      "Sep": {"Dine In": 82, "Takeaway": 54},
      "Oct": {"Dine In": 80, "Takeaway": 50},
      "Nov": {"Dine In": 78, "Takeaway": 47},
      "Dec": {"Dine In": 82, "Takeaway": 51},
    },
  };

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
                      (_) =>
                      TablesScreen(
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
        },
      ),
      body:
      isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(25, 15, 0, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// Greeting + Date + Time + Filters
            Row(
              children: [
                Text(
                  "Good Morning ${widget.userPermissions?.displayName ??
                      "User Name"} !",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),

                /// Date
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16),
                    const SizedBox(width: 6),
                    Text(currentDate),
                  ],
                ),
                const SizedBox(width: 10),

                /// Time
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16),
                    const SizedBox(width: 6),
                    Text(currentTime),
                  ],
                ),
                const SizedBox(width: 20),
                if (periods.isNotEmpty)
                  DropdownButtonHideUnderline(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade300),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: DropdownButton<String>(
                        value: _selectedPeriod,
                        items:
                        periods.map((p) {
                          return DropdownMenuItem(
                            value: p,
                            child: Text(
                              p,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() => _selectedPeriod = val!);
                          fetchDashboard();
                        },
                      ),
                    ),
                  ),
                const SizedBox(width: 8),

                /// Zone Filter
                if (zones.isNotEmpty)
                  DropdownButtonHideUnderline(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade300),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: DropdownButton<Map<String, dynamic>>(
                        value: _selectedZone,
                        items:
                        zones.map((z) {
                          return DropdownMenuItem(
                            value: z,
                            child: Text(
                              z['name'] ?? '',
                              style: const TextStyle(fontSize: 15),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() => _selectedZone = val);
                          fetchDashboard();
                        },
                      ),
                    ),
                  ),
                const SizedBox(width: 25),
              ],
            ),
            const SizedBox(height: 20),

            /// Metric Cards
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _metricCard(
                    icon: Icons.attach_money,
                    iconBg: Colors.green,
                    title: "Total Revenue",
                    value: totalRevenue,
                    cardColor: Colors.green.shade50,
                    trend: revenueTrend,
                  ),
                  const SizedBox(width: 20),
                  _metricCard(
                    icon: Icons.shopping_bag,
                    iconBg: Colors.orange,
                    title: "Total Orders",
                    value: totalOrders,
                    cardColor: Colors.orange.shade50,
                    trend: ordersTrend,
                  ),
                  const SizedBox(width: 20),
                  _metricCard(
                    icon: Icons.pending_actions,
                    iconBg: Colors.pink,
                    title: "Active Orders",
                    value: activeOrders,
                    cardColor: Colors.pink.shade50,
                  ),
                  const SizedBox(width: 20),
                  _metricCard(
                    icon: Icons.table_bar,
                    iconBg: Colors.purple,
                    title: "Running Tables",
                    value: runningTables,
                    cardColor: Colors.purple.shade50,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            /// Other Cards (horizontal scroll)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  topProductsCard(),
                  const SizedBox(width: 25),
                  topCategoriesCard(),
                  const SizedBox(width: 25),
                  StocksCard(),
                ],
              ),
            ),

            const SizedBox(height: 30),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  revenueBreakdownCard(),
                  const SizedBox(width: 25),
                  paymentModesCard(),
                ],
              ),
            ),

            const SizedBox(height: 25),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  recentTransactionsCard(),
                  const SizedBox(width: 25),
                  employeeListCard(),
                ],
              ),
            ),
          ],
        ),
      ),
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
            _userPermissions,
          );
        },
        userPermissions: _userPermissions,
      ),
    );
  }

  Widget revenueBreakdownCard() {
    String _selectedRevenuePeriod = "Week";
    final List<String> periods = ["Week", "Month"];

    return StatefulBuilder(
      builder: (context, setState) {
        final data = revenueData[_selectedRevenuePeriod] ?? {};

        return Container(
          width: 872,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              /// Title + Dropdown
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Total Revenue",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedRevenuePeriod,
                      items:
                      periods.map((p) {
                        return DropdownMenuItem(
                          value: p,
                          child: Text(
                            p,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedRevenuePeriod = val!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              /// Bar Chart
              SizedBox(
                height: 280,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 100,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final label = data.keys.elementAt(group.x.toInt());
                          final category =
                          rodIndex == 0 ? "Dine In" : "Takeaway";
                          return BarTooltipItem(
                            "$label\n$category: ${rod.toY.toStringAsFixed(0)}",
                            const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              backgroundColor: Colors.black87,
                            ),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final label = data.keys.elementAt(value.toInt());
                            return Text(
                              label,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 20,
                          reservedSize: 30,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              value.toInt().toString(),
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black,
                              ),
                            );
                          },
                        ),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 20,
                      getDrawingHorizontalLine:
                          (value) =>
                          FlLine(
                            color: Colors.grey.withOpacity(0.2),
                            strokeWidth: 1,
                          ),
                    ),
                    barGroups: List.generate(data.length, (index) {
                      final label = data.keys.elementAt(index);
                      final dineIn = data[label]!["Dine In"]!;
                      final takeaway = data[label]!["Takeaway"]!;
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: dineIn,
                            width: 14,
                            borderRadius: BorderRadius.circular(4),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.blue.shade700,
                                Colors.blue.shade300,
                              ],
                            ),
                          ),
                          BarChartRodData(
                            toY: takeaway,
                            width: 14,
                            borderRadius: BorderRadius.circular(4),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.green.shade700,
                                Colors.green.shade300,
                              ],
                            ),
                          ),
                        ],
                        barsSpace: 6,
                      );
                    }),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.circle, size: 10, color: Colors.blue),
                  SizedBox(width: 4),
                  Text("Dine In"),
                  SizedBox(width: 16),
                  Icon(Icons.circle, size: 10, color: Colors.green),
                  SizedBox(width: 4),
                  Text("Takeaway"),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget paymentModesCard() {
    final Map<String, Map<String, Map<String, double>>> paymentData = {
      "Week": {
        "Dine In": {"Cards": 5000, "Cash": 3000, "UPI": 2000},
        "Takeaway": {"Cards": 4000, "Cash": 2000, "UPI": 1000},
      },
      "Month": {
        "Dine In": {"Cards": 20000, "Cash": 12000, "UPI": 8000},
        "Takeaway": {"Cards": 15000, "Cash": 9000, "UPI": 5000},
      },
    };

    final List<String> periods = ["Week", "Month"];
    final List<String> orderTypes = ["Dine In", "Takeaway"];

    String selectedPeriod = "Week";
    String selectedOrderType = "Dine In";

    final colors = {
      "Cards": Colors.blue,
      "Cash": Colors.green,
      "UPI": Colors.redAccent,
    };

    return StatefulBuilder(
      builder: (context, setState) {
        final paymentModes =
            paymentData[selectedPeriod]?[selectedOrderType] ?? {};
        final total =
        paymentModes.values.isNotEmpty
            ? paymentModes.values.reduce((a, b) => a + b)
            : 1.0;

        return Container(
          width: 427,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              /// Header + Filters
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Payment Modes",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),
                  Row(
                    children: [

                      /// Order Type Dropdown
                      DropdownButton<String>(
                        value: selectedOrderType,
                        underline: const SizedBox(),
                        items:
                        orderTypes
                            .map(
                              (e) =>
                              DropdownMenuItem(
                                value: e,
                                child: Text(e),
                              ),
                        )
                            .toList(),
                        onChanged: (val) {
                          setState(() {
                            selectedOrderType = val!;
                          });
                        },
                      ),

                      /// Period Dropdown
                      DropdownButton<String>(
                        value: selectedPeriod,
                        underline: const SizedBox(),
                        items:
                        periods
                            .map(
                              (p) =>
                              DropdownMenuItem(
                                value: p,
                                child: Text(p),
                              ),
                        )
                            .toList(),
                        onChanged: (val) {
                          setState(() {
                            selectedPeriod = val!;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              /// Pie Chart
              SizedBox(
                height: 265,
                child: PieChart(
                  PieChartData(
                    centerSpaceRadius: 55,
                    sectionsSpace: 2,
                    borderData: FlBorderData(show: false),
                    sections:
                    paymentModes.entries.map((e) {
                      final percentage = (e.value / total) * 100;
                      return PieChartSectionData(
                        value: e.value,
                        color: colors[e.key],
                        radius: 40,
                        showTitle: true,
                        title: "${percentage.toStringAsFixed(0)}%",
                        titleStyle: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: colors[e.key],
                        ),
                        titlePositionPercentageOffset: 1.6,
                      );
                    }).toList(),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              /// Legends
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children:
                paymentModes.keys.map((key) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        Icon(Icons.circle, size: 10, color: colors[key]),
                        const SizedBox(width: 4),
                        Text(
                          key,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget topProductsCard() {
    return Container(
      width: 425,
      height: 255,
      decoration: BoxDecoration(
        color: Colors.white,
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Top Products - Items Sold",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),

          if (isTopProductsLoading)
            const Center(child: CircularProgressIndicator())
          else if (topProducts.isEmpty)
            const Center(child: Text("No products found"))
          else
            Expanded(
              child: Column(
                children: [
                  /// Header row
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: const [
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text("Name", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text("Items Sold", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text("Net Sales", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),

                  /// Data rows
                  Expanded(
                    child: ListView.builder(
                      itemCount: topProducts.length,
                      itemBuilder: (context, index) {
                        final product = topProducts[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  product['name'] ?? '',
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  "${product['items_sold']}",
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  "₹${product['net_sales']}",
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget topCategoriesCard() {
    return Container(
      width: 425,
      height: 255,
      decoration: BoxDecoration(
        color: Colors.white,
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Top Categories - Items Sold",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),

          if (isTopCategoriesLoading)
            const Center(child: CircularProgressIndicator())
          else if (topCategories.isEmpty)
            const Center(child: Text("No categories found"))
          else
            Expanded(
              child: Column(
                children: [
                  /// Header row
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: const [
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text("Name", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text("Items Sold", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text("Net Sales", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),

                  /// Data rows
                  Expanded(
                    child: ListView.builder(
                      itemCount: topCategories.length,
                      itemBuilder: (context, index) {
                        final category = topCategories[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  category['name'] ?? '',
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  "${category['items_sold']}",
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  "₹${category['net_sales']}",
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget recentTransactionsCard() {
    return Container(
      width: 650,
      height: 245,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            offset: const Offset(-2, 2),
            blurRadius: 6,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            offset: const Offset(2, 2),
            blurRadius: 6,
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 🔹 Title + View All
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                "Recent Transactions",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                "View All →",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.blue,
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          Expanded(
            child: Column(
              children: [
                /// 🔹 Header Row
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: const [
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            "Order Id",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            "Order Type",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            "Payment Type",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            "Total",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 4),

                /// 🔹 Transaction Rows
                isCompletedOrdersLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Expanded(
                  child: ListView.builder(
                    itemCount: completedOrders.length,
                    itemBuilder: (context, index) {
                      final tx = completedOrders[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                tx["order_id"].toString(),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                tx["order_type"].toString(),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                tx["payment_type"].toString(),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                "₹${tx["total"]}",
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget employeeListCard() {
    return Container(
      width: 645,
      height: 245,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            offset: const Offset(-2, 2),
            blurRadius: 6,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            offset: const Offset(2, 2),
            blurRadius: 6,
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 🔹 Title + View All
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Employee list",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EmployeeListScreen(
                        pin: widget.pin,
                        token: widget.token,
                        restaurantId: widget.restaurantId,
                        restaurantName: widget.restaurantName,
                        userPermissions: widget.userPermissions,
                      ),
                    ),
                  );
                },
                child: const Text(
                  "View All →",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.blue,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Expanded(
            child: Column(
              children: [
                /// 🔹 Header Row
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: const [
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            "Employee ID",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            "Name",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            "Designation",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            "Status",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 4),

                /// 🔹 Employee Rows
                Expanded(
                  child: isEmployeeLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                    itemCount: employees.length,
                    itemBuilder: (context, index) {
                      final emp = employees[index];

                      String userId = (emp["user_id"]?.toString().trim().isEmpty ?? true)
                          ? "-"
                          : emp["user_id"].toString();

                      String name = (emp["name"]?.toString().trim().isEmpty ?? true)
                          ? "-"
                          : emp["name"].toString();

                      String designation = (emp["designation"]?.toString().trim().isEmpty ?? true)
                          ? "-"
                          : emp["designation"].toString();

                      String status = (emp["attendance_status"]?.toString().trim().isEmpty ?? true)
                          ? "-"
                          : emp["attendance_status"].toString();

                      final isPresent = status == "Present";

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                userId,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                name,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                designation,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                status,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: status == "-"
                                      ? Colors.grey
                                      : (isPresent
                                      ? Colors.green.shade800
                                      : Colors.red.shade800),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget StocksCard() {
    return Container(
      width: 425,
      height: 255,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            offset: const Offset(-2, 2),
            blurRadius: 6,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            offset: const Offset(2, 2),
            blurRadius: 6,
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Stock Alerts - Low Quantity Stock",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: isInventoryLoading
                ? const Center(child: CircularProgressIndicator())
                : inventoryAlerts.isEmpty
                ? const Center(child: Text("No low stock items"))
                : Column(
              children: [
                /// Curved header row
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: const [
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            "Name",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            "Alerts",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),

                /// Inventory rows
                ...inventoryAlerts.map(
                      (item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item['name'] ?? item['in_name'] ?? '',
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            "Reorder",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFFAA3028),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricCard({
    required IconData icon,
    required Color iconBg,
    required String title,
    required String value,
    required Color cardColor,
    String? trend,
  }) {
    bool isPositive = true;
    String trendText = "";
    if (trend != null && trend
        .trim()
        .isNotEmpty) {
      trend = trend.trim();
      isPositive = trend.startsWith("↑");
      trendText = trend.substring(1).trim();
    } else {
      trend = null;
    }
    return Container(
      width: 310,
      height: 160,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            offset: const Offset(-2, 2),
            blurRadius: 6,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            offset: const Offset(2, 2),
            blurRadius: 6,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(width: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                mainAxisAlignment: trend != null
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (trend != null) const SizedBox(height: 45),
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  if (trend != null) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          isPositive ? Icons.arrow_upward : Icons
                              .arrow_downward,
                          size: 16,
                          color: isPositive ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            trendText,
                            style: TextStyle(
                              fontSize: 14,
                              color: isPositive ? Colors.green : Colors.red,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
