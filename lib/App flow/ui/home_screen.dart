import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pinaka_restaurant_pos/App%20flow/ui/reservation_list_screen.dart';
import 'package:pinaka_restaurant_pos/App%20flow/ui/tables_screen.dart';
import 'package:pinaka_restaurant_pos/App%20flow/ui/tip_screen.dart';
import 'package:pinaka_restaurant_pos/App%20flow/ui/vendor_payment_screen.dart';

import '../../blocs/Bloc Event/attendance_event.dart';
import '../../blocs/Bloc Logic/attendance_bloc.dart';
import '../../blocs/Bloc Logic/checkin_bloc.dart';
import '../../blocs/Bloc Logic/order_list_bloc.dart';
import '../../blocs/Bloc State/attendance_state.dart';
import '../../models/UserPermissions.dart';
import '../../models/tip_model.dart';
import '../../repositories/TIP_repository.dart';
import '../../repositories/checkin_repository.dart';
import '../../repositories/employee_repository.dart';
import '../../repositories/order_list_repository.dart';
import '../../repositories/table_status_count_repository.dart';
import '../../repositories/vendor_payment_repository.dart';
import '../../utils/SessionManager.dart';
import '../widgets/top_bar.dart';
import 'CheckinPopup.dart';
import 'DailyAttendanceScreen.dart';
import 'KitchenStatusScreen.dart';
import 'orderstatus_screen.dart';

class HomeScreen extends StatefulWidget {
  final String token;
  final String pin;
  final String restaurantId;
  final String restaurantName;
  // final List<Map<String, dynamic>> loadedTables;
  const HomeScreen({
    super.key,
    required this.token,
    required this.pin,
    required this.restaurantId,
    required this.restaurantName,
    // required this.loadedTables,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  UserPermissions? _userPermissions;
  Map<String, dynamic>? _selectedUser;
  String _currentTime = '';
  Timer? _clockTimer;
  int occupiedTables = 0;
  int availableTables = 0;
  bool isLoadingCounts = true;
  int upcomingReservations = 0;
  int totalReservations = 0;
  bool isLoading = true;
  int activeOrdersCount = 0;
  double totalTipAmount = 0.0;
  double vendorcount = 0;

  @override
  void initState() {
    super.initState();
    _loadSavedPermissions();
    _startClock();
    loadTableStatusCounts();
    loadReservationCounts();
    loadActiveOrdersCount();
    loadTotalTipAmount();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkShiftStatus();
    });
    _loadVendorCount();
  }
  void _startClock() {
    _updateTime();

    _clockTimer = Timer.periodic(
      const Duration(seconds: 1),
          (_) => _updateTime(),
    );
  }

  void _updateTime() {
    if (!mounted) return;

    setState(() {
      _currentTime = DateFormat('hh:mm:ss a').format(DateTime.now());
    });
  }
  final VendorPaymentRepository _repository = VendorPaymentRepository();

  Future<void> _loadVendorCount() async {
    try {
      final result = await _repository.getVendors(
        token: widget.token,
      );

      setState(() {
        vendorcount =
            (result["vendor_count"] as num).toDouble();
      });
    } catch (e) {
      print(e);
    }
  }

  Future<void> _checkShiftStatus() async {
    final savedPermissions =
    await SessionManager.loadPermissions();

    try {
      final currentShift =
      await EmployeeRepository()
          .getCurrentShift(widget.token);

      final shiftStatus =
      currentShift?['shift_status']
          ?.toString()
          .toLowerCase();

      if (shiftStatus == 'closed') {
        context.read<AttendanceBloc>().add(
          InitializeAttendanceFlow(
            token: widget.token,
            pin: widget.pin,
          ),
        );
      } else if (shiftStatus == 'open' &&
          savedPermissions == null) {
        _showCheckInPopupDirectly();
      }
    } catch (e) {
      debugPrint("Shift check failed: $e");
    }
  }
  void _showCheckInPopupDirectly() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider(
        create: (_) => CheckInBloc(CheckInRepository()),
        // child: Checkinpopup(
        //   token: widget.token,
        //   onCheckIn: () {
        //     Navigator.of(context).pop();
        //   },
        //   onCancel: () {
        //     Navigator.of(context).pop();
        //   },
        //   onPermissionsReceived: (permissions) {
        //     setState(() {
        //       _userPermissions = permissions;
        //     });
        //   },
        // ),
      ),
    );
  }


  Future<void> _loadSavedPermissions() async {
    final permissions = await SessionManager.loadPermissions();
    print("Loaded User: ${permissions?.displayName}");
    print("Loaded Role: ${permissions?.role}");

    if (permissions != null && mounted) {
      setState(() {
        _userPermissions = permissions;
        _selectedUser = {
          "id": permissions.userId,
          "name": permissions.displayName,
          "role": permissions.role,
        };
      });
    }
  }
  Future<void> loadTableStatusCounts() async {
    try {
      final repository = TableStatusCountRepository(
        token: widget.token,
      );

      final counts = await repository.fetchTableStatusCounts(
        restaurantId: int.tryParse(widget.restaurantId) ?? 0,
      );

      setState(() {
        occupiedTables = counts.dineinTables;
        availableTables = counts.availableTables;
        isLoadingCounts = false;
      });
    } catch (e) {
      debugPrint('Error loading table counts: $e');

      setState(() {
        isLoadingCounts = false;
      });
    }
  }
  Future<void> loadReservationCounts() async {
    try {
      final repository = ReservationStatusCountRepository(
        token: widget.token,
      );

      final counts = await repository.fetchReservationStatusCounts(
        restaurantId: int.parse(widget.restaurantId),
      );

      setState(() {
        upcomingReservations = counts.upcoming;
        totalReservations = counts.totalReservations;
        isLoading = false; // ✅ Important
      });
    } catch (e) {
      debugPrint('Reservation Count Error: $e');

      setState(() {
        isLoading = false; // ✅ Important
      });
    }
  }
  Future<void> loadActiveOrdersCount() async {
    try {
      final repository = ActiveOrdersCountRepository(
        token: widget.token,
      );

      final result = await repository.fetchActiveOrdersCount(
        restaurantId: int.parse(widget.restaurantId),
      );

      setState(() {
        activeOrdersCount = result.activeOrdersCount;
      });

      debugPrint(
        'Active Orders Count: ${result.activeOrdersCount}',
      );
    } catch (e) {
      debugPrint('Active Orders Count Error: $e');
    }
  }
  Future<void> loadTotalTipAmount() async {
    try {
      final repo = TipssummaryRepository();

      final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      final TipsScreenModel? response = await repo.getTips(
        token: widget.token,
        tipDate: today,
      );

      if (!mounted) return;

      setState(() {
        totalTipAmount = response?.totalTipAmt ?? 0.0;
      });
    } catch (e) {
      debugPrint("Error loading tips: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AttendanceBloc, AttendanceState>(
        listener: (context, state) async {
          if (state is AttendancePopupReady) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => AttendancePopup(
                employees: state.employees,
                token: widget.token,
                onComplete: (String extractedStartTime) async {
                  _showCheckInPopupDirectly();
                },
              ),
            );
          }
        },
        child: Scaffold(
      backgroundColor: const Color(0xffF5F6FA),

      appBar: TopBar(
        token: widget.token,
        pin: widget.pin,
        restaurantId: widget.restaurantId,
        restaurantName: widget.restaurantName,
        userPermissions: _userPermissions,
        isHomeScreen: true,
        onPermissionsReceived: (permissions) async {
          setState(() {
            _userPermissions = permissions;
            _selectedUser = {
              "id": permissions.userId,
              "name": permissions.displayName,
              "role": permissions.role,
            };
          });
        },
      ),


            body: Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                height: MediaQuery.of(context).size.height,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _greetingSection(),
            const SizedBox(height: 10),

            /// Stats Row
            Row(
              children: [
                Expanded(
                  child: _summaryCard(
                    "Occupied Tables",
                    occupiedTables.toString(),
                    Icons.table_restaurant,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _summaryCard(
                    "Available Tables",
                    availableTables.toString(),
                    Icons.event_seat,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _summaryCard(
                    "Active Orders",
                    activeOrdersCount.toString(),
                    Icons.receipt_long,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _summaryCard(
                    "Online Orders",
                    "0",
                    Icons.language,
                    Colors.purple,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _summaryCard(
                    "Reservations",
                     upcomingReservations.toString(),
                    Icons.calendar_today,
                    Colors.cyan,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: Divider(
                    color: Colors.grey.shade300,
                    thickness: 1,
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    "QUICK ACCESS",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                      fontSize: 16,
                      letterSpacing: 1,
                    ),
                  ),
                ),

                Expanded(
                  child: Divider(
                    color: Colors.grey.shade300,
                    thickness: 1,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            /// Quick Access
            Row(
              children: [
                Expanded(
                  child: _moduleCard(
                    title: "Tables",
                    subtitle: "Floor Plan",
                    count: occupiedTables.toString(),
                    countLabel: "occupied",
                    isCurrent: true,
                    color: const Color(0xffF5A25D),
                    icon: Icons.grid_view_rounded,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TablesScreen(
                            pin: widget.pin,
                            token: widget.token,
                            restaurantId: widget.restaurantId,
                            restaurantName: widget.restaurantName, loadedTables: [],
                            // loadedTables: widget.loadedTables,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _moduleCard(
                    title: "Take Aways",
                    subtitle: "Walk-in Orders",
                    count: "0",
                    countLabel: "active",
                    color: const Color(0xff5FCB89),
                    icon: Icons.inventory_2_outlined,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _moduleCard(
                    title: "Online Orders",
                    subtitle: "Delivery",
                    count: "0",
                    countLabel: "pending",
                    color: const Color(0xff9B7AE7),
                    icon: Icons.language,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            _sectionTitle("Kitchen & Orders"),

            const SizedBox(height: 15),

            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _whiteModuleCard(
                    title: "KOT Status",
                    count: "8",
                    countLabel: "in kitchen",
                    icon: Icons.restaurant_menu,
                    iconColor: Colors.red,
                    description:
                    "Monitor live kitchen order tickets and prep times",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => KitchenStatusScreen(
                            pin: widget.pin,
                            associatedManagerPin: widget.pin,
                            token: widget.token,
                            restaurantId: widget.restaurantId,
                            restaurantName: widget.restaurantName,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(width: 16),

                Expanded(
                  flex: 2,
                  child: _whiteModuleCard(
                    title: "Orders",
                    count: activeOrdersCount.toString(),
                    countLabel: "total",
                    icon: Icons.receipt_long,
                    iconColor: Colors.blue,
                    description:
                    "View, modify and settle all active orders",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BlocProvider(
                            create: (context) => OrderstatusBloc(
                              OrderstatusRepository(),
                            ),
                            child: OrdersListTable(
                              token: widget.token,
                              pin: widget.pin,
                              restaurantId: widget.restaurantId,
                              restaurantName: widget.restaurantName,
                              userPermissions: _userPermissions,
                              orders: const [],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),

                if (_userPermissions?.role.toLowerCase() == 'manager')
                  Expanded(
                    flex: 2,
                    child: _whiteModuleCard(
                      title: "Tips",
                      count: totalTipAmount.toStringAsFixed(2),
                      countLabel: "Tips",
                      icon: Icons.account_balance_wallet_outlined,
                      iconColor: Colors.orange,
                      description: "Manage and view tips",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TipsScreen(
                              token: widget.token,
                              pin: widget.pin,
                              userPermissions: _userPermissions,
                              restaurantId: widget.restaurantId,
                              restaurantName: widget.restaurantName,
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                const Spacer(flex: 2),
              ],
            ),

            const SizedBox(height: 10),

            _sectionTitle("Customer Management"),

            const SizedBox(height: 15),

            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _whiteModuleCard(
                    title: "Reservation",
                    count: upcomingReservations.toString(),
                    countLabel: "upcoming",
                    icon: Icons.calendar_today,
                    iconColor: Colors.blue,
                    description:
                    "Accept, confirm and seat table reservations",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReservationListScreen(
                            pin: widget.pin,
                            token: widget.token,
                            restaurantId: widget.restaurantId,
                            restaurantName: widget.restaurantName,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(width: 16),

                Expanded(
                  flex: 2,
                  child: _whiteModuleCard(
                    title: "Customers",
                    count: "248",
                    countLabel: "profiles",
                    icon: Icons.people_outline,
                    iconColor: Colors.purple,
                    description:
                    "Profiles, loyalty history and preferences",
                  ),
                ),

                if (_userPermissions?.role.toLowerCase() == 'manager') ...[
                  const SizedBox(width: 16),

                  Expanded(
                    flex: 2,
                    child: _whiteModuleCard(
                      title: "Vendors",
                      count: vendorcount.toInt().toString(),
                      countLabel: "vendors",
                      icon: Icons.local_shipping_outlined,
                      iconColor: Colors.orange,
                      description:
                      "Manage supplier profiles, orders and deliveries",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => Vendorpaymentsscreen(
                              token: widget.token,
                              pin: widget.pin,
                              restaurantId: widget.restaurantId,
                              restaurantName: widget.restaurantName,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],

                const Spacer(flex: 2),
              ],
            ),
          ],
        ),
              )),
    ));
  }

  Widget _greetingSection() {
    final userName = _selectedUser?['name'] ?? 'User';
    final userRole = _selectedUser?['role'] ?? '';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Welcome, $userName 👋",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              userRole,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              _currentTime.toLowerCase(),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
                height: 1,
              ),
            ),

            const SizedBox(height: 4),

            Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(
                  Icons.circle,
                  color: Colors.green,
                  size: 8,
                ),
                SizedBox(width: 4),
                Text(
                  "System Online",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        )
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _summaryCard(
      String title,
      String value,
      IconData icon,
      Color color,
      ) {
    return Container(
      height: 79,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
          )
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(.1),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(title),
            ],
          ),
        ],
      ),
    );
  }

  Widget _moduleCard({
    required String title,
    required String subtitle,
    required String count,
    required Color color,
    required IconData icon,
    String countLabel = "",
    bool isCurrent = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 135,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(.25),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            /// TOP CONTENT
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Container(
                      width: 55,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            count,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            countLabel,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                if (isCurrent)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      "CURRENT",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                const Spacer(),

                const Text(
                  "Open module →",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),

            /// BOTTOM RIGHT ICON
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _whiteModuleCard({
    required String title,
    required String count,
    required IconData icon,
    required Color iconColor,
    String description = "",
    String countLabel = "",
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 138,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 18,
                  ),
                ),

                const Spacer(),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      count,
                      style: TextStyle(
                        color: iconColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    Text(
                      countLabel,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 3),

            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF23263A),
              ),
            ),

            const SizedBox(height: 2),

            Expanded(
              child: Text(
                description,
                style: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              "Open module →",
              style: TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          const FlutterLogo(size: 40),
          const SizedBox(width: 20),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search item or shortcut...",
                filled: true,
                fillColor: Colors.grey.shade100,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
          const CircleAvatar(
            radius: 18,
            child: Icon(Icons.person),
          ),
        ],
      ),
    );
  }
}