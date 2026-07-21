import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pinaka_restaurant_pos/App%20flow/ui/reservation_list_screen.dart';
import 'package:pinaka_restaurant_pos/App%20flow/ui/tables_screen.dart';
import 'package:pinaka_restaurant_pos/App%20flow/ui/tip_screen.dart';
import 'package:pinaka_restaurant_pos/App%20flow/ui/vendor_payment_screen.dart';

import '../../blocs/Bloc Event/attendance_event.dart';
import '../../blocs/Bloc Event/order_event.dart';
import '../../blocs/Bloc Logic/attendance_bloc.dart';
import '../../blocs/Bloc Logic/checkin_bloc.dart';
import '../../blocs/Bloc Logic/order_bloc.dart';
import '../../blocs/Bloc Logic/order_list_bloc.dart';
import '../../blocs/Bloc State/attendance_state.dart';
import '../../blocs/Bloc State/order_state.dart';
import '../../constants/constants.dart';
import '../../models/UserPermissions.dart';
import '../../models/tip_model.dart';
import '../../repositories/TIP_repository.dart';
import '../../repositories/checkin_repository.dart';
import '../../repositories/employee_repository.dart';
import '../../repositories/kot_order_count_repository.dart';
import '../../repositories/kot_status_count_repository.dart';
import '../../repositories/order_list_repository.dart';
import '../../repositories/table_status_count_repository.dart';
import '../../repositories/vendor_payment_repository.dart';
import '../../utils/SessionManager.dart';
import '../widgets/top_bar.dart';
import 'CheckinPopup.dart';
import 'DailyAttendanceScreen.dart';
import 'KitchenStatusScreen.dart';
import 'dashboard screen.dart';
import 'orderstatus_screen.dart';

class HomeScreen extends StatefulWidget {
  final String token;
  final String pin;
  final String restaurantId;
  final String restaurantName;
  final UserPermissions? userPermissions;

  const HomeScreen({
    super.key,
    required this.token,
    required this.pin,
    required this.restaurantId,
    required this.restaurantName,
    this.userPermissions,
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
  String _currency = "₹";
  int kotStatusCount = 0;
  int kotCustomerCount = 0;
  int totalTables = 0;
  int totalKotOrders = 0;
  int todayVendorPaymentsCount = 0;
  @override
  void initState() {
    super.initState();
    _loadSavedPermissions();
    loadKotOrderCount();
    _startClock();
    _loadCurrency();   // <-- Add this
    loadKotStatusCount();
    loadTableStatusCounts();
    loadReservationCounts();
    loadActiveOrdersCount();
    loadTotalTipAmount();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkShiftStatus();
    });
    _loadVendorCount();
    _loadTodayVendorPaymentsCount();
  }


  Future<void> _loadTodayVendorPaymentsCount() async {
    try {
      final response = await http.get(
        Uri.parse(
          "${AppConstants.baseApiPath}/vendor_payments/get-vendor-payments",
        ),
        headers: {
          "Authorization": "Bearer ${widget.token}",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          todayVendorPaymentsCount = data["today_payments_count"] ?? 0;
        });
      }
    } catch (e) {
      print("Today's Vendor Payments Count Error: $e");
    }
  }
  Future<void> loadKotOrderCount() async {
    try {
      debugPrint("Calling KOT Order Count API...");

      final repository = KotOrderCountRepository(
        token: widget.token,
      );

      final result = await repository.fetchKotOrderCount();

      debugPrint("API returned: ${result.totalOrderCount}");

      if (!mounted) return;

      setState(() {
        totalKotOrders = result.totalOrderCount;
      });

      debugPrint("Updated totalKotOrders: $totalKotOrders");
    } catch (e) {
      debugPrint("KOT Order Count Error: $e");
    }
  }
  Future<void> _loadCurrency() async {
    final currency = await SessionManager.getCurrencySymbol();

    if (mounted) {
      setState(() {
        _currency = currency ?? "₹";
      });
    }
  }
  Future<void> loadKotStatusCount() async {
    try {
      final repository = KotStatusCountRepository(
        token: widget.token,
      );

      final result = await repository.fetchKotStatusCount(
        restaurantId: int.parse(widget.restaurantId),
      );

      if (!mounted) return;

      setState(() {
        kotStatusCount = result.statusCount;
        kotCustomerCount = result.customerCount;
      });

      debugPrint("KOT Status Count: ${result.statusCount}");
      debugPrint("Customer Count: ${result.customerCount}");
    } catch (e) {
      debugPrint("KOT Status Count Error: $e");
    }
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
        vendorcount = (result["vendor_count"] as num).toDouble();
      });
    } catch (e) {
      print(e);
    }
  }

  Future<void> _checkShiftStatus() async {
    final savedPermissions = await SessionManager.loadPermissions();
    try {
      final currentShift = await EmployeeRepository().getCurrentShift(widget.token);
      final shiftStatus = currentShift?['shift_status']?.toString().toLowerCase();
      if (shiftStatus == 'closed') {
        context.read<AttendanceBloc>().add(
          InitializeAttendanceFlow(
            token: widget.token,
            pin: widget.pin,
          ),
        );
      }
    } catch (e) {
      debugPrint("Shift check failed: $e");
    }
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
        totalTables = counts.totalTables;
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
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Reservation Count Error: $e');
      setState(() {
        isLoading = false;
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
      debugPrint('Active Orders Count: ${result.activeOrdersCount}');
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
                // Handle completion
              },
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F1F5),
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
          child: SizedBox(child: SizedBox(
            height: MediaQuery.of(context).size.height,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

            /// LEFT SIDE
            Expanded(
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                _greetingSection(),

                const SizedBox(height: 8),
            // Row(
            //   children: [
            //     Expanded(
            //       child: _summaryCard(
            //         "Total Tables",
            //         totalTables.toString(),
            //         Icons.table_restaurant,
            //         Colors.orange,
            //       ),
            //     ),
            //     const SizedBox(width: 12),
            //     Expanded(
            //       child: _summaryCard(
            //         "Available Tables",
            //         availableTables.toString(),
            //         Icons.event_seat,
            //         Colors.green,
            //       ),
            //     ),
            //     const SizedBox(width: 12),
            //     Expanded(
            //       child: _summaryCard(
            //         "Total Orders",
            //         totalKotOrders.toString(),
            //         Icons.receipt_long,
            //         Colors.blue,
            //       ),
            //     ),
            //     const SizedBox(width: 12),
            //     Expanded(
            //       child: _summaryCard(
            //         "Online Orders",
            //         "0",
            //         Icons.language,
            //         Colors.purple,
            //       ),
            //     ),
            //     const SizedBox(width: 12),
            //     Expanded(
            //       child: _summaryCard(
            //         "Total Reservations",
            //         totalReservations.toString(),
            //         Icons.calendar_today,
            //         Colors.cyan,
            //       ),
            //     ),
            //   ],
            // ),
            // const SizedBox(height: 5),
            // Row(
            //   children: [
            //     Expanded(
            //       child: Divider(
            //         color: Colors.grey.shade400,
            //         thickness: 1,
            //       ),
            //     ),
            //     Padding(
            //       padding: const EdgeInsets.symmetric(horizontal: 12),
            //       child: Text(
            //         "QUICK ACCESS",
            //         style: TextStyle(
            //           fontWeight: FontWeight.w600,
            //           color: Colors.grey.shade600,
            //           fontSize: 16,
            //           letterSpacing: 1,
            //         ),
            //       ),
            //     ),
            //     Expanded(
            //       child: Divider(
            //         color: Colors.grey.shade400,
            //         thickness: 1,
            //       ),
            //     ),
            //   ],
                Row(
                  children: [
                    Expanded(
                      child: _kotStatusWidget(
                        "Queue",
                        "00", // Static value
                        // Icons.queue,
                    Icons.room_service,
                    const Color(0xFF4E4949),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _kotStatusWidget(
                        "Preparing",
                        "00", // Static value
                        Icons.access_time_outlined,
                        const Color(0xFFE39106),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _kotStatusWidget(
                        "Ready",
                        "00", // Static value
                        Icons.check_circle_outline,
                        const Color(0xFF1A5FCB),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _kotStatusWidget(
                        "Served",
                        "00", // Static value
                        Icons.done_all,
                        const Color(0xFF02B443),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _kotStatusWidget(
                        "Cancelled",
                        "00", // Static value
                        Icons.cancel_outlined,
                        const Color(0xFFEA2F38),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: Colors.grey.shade400,
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
                        color: Colors.grey.shade400,
                        thickness: 1,
                      ),
                    ),
                  ],
                ),
                _sectionTitle("Restaurant Operations"),

                const SizedBox(height: 5),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 250,
                      child: _moduleCard(
                        title: "Tables",
                        subtitle: "Floor Plan",
                        count: occupiedTables.toString(),
                        countLabel: "Occupied",
                        isCurrent: true,
                        color: const Color(0xffF5A25D),
                        icon: Icons.grid_view_rounded,
                        gradient: const RadialGradient(
                          center: Alignment(0.82, 0.85),
                          radius: 1.18,
                          colors: [
                            Color(0xFFF0AE80),
                            Color(0xFFE8925A),
                          ],
                        ),
                        boxShadows: const [
                          BoxShadow(
                            color: Color(0x141C2333),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                          BoxShadow(
                            color: Color(0x99E8925A),
                            blurRadius: 20,
                            offset: Offset(0, 6),
                          ),
                        ],
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TablesScreen(
                                pin: widget.pin,
                                token: widget.token,
                                restaurantId: widget.restaurantId,
                                restaurantName: widget.restaurantName,
                                loadedTables: [],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(width: 16),

                    BlocBuilder<OrderBloc, OrderState>(
                      builder: (context, state) {
                        final activeOrderCount = state.orderItems.isNotEmpty ? "1" : "0";

                        return SizedBox(
                          width: 250,
                          child: _moduleCard(
                            title: "Take Aways",
                            subtitle: "Walk-in Orders",
                            count: activeOrderCount,
                            countLabel: "Active",
                            color: const Color(0xff5FCB89),
                            gradient: const RadialGradient(
                              center: Alignment(0.82, 0.85),
                              radius: 1.18,
                              colors: [
                                Color(0xFF79D89E),
                                Color(0xFF5CB87A),
                              ],
                            ),
                            boxShadows: const [
                              BoxShadow(
                                color: Color(0x141C2333),
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                              BoxShadow(
                                color: Color(0x995CB87A),
                                blurRadius: 20,
                                offset: Offset(0, 6),
                              ),
                            ],
                            icon: Icons.inventory_2_outlined,
                            onTap: () {
                              final orderBloc = context.read<OrderBloc>();
                              final state = orderBloc.state;

                              if (state.orderItems.isEmpty) {
                                debugPrint("🧹 No active order found. Resetting OrderBloc.");
                                orderBloc.add(ResetOrder());
                              } else {
                                debugPrint(
                                  "✅ Active takeaway order found. orderId: ${state.orderId}, items: ${state.orderItems.length}",
                                );
                              }

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DashboardScreen(
                                    pin: widget.pin,
                                    token: widget.token,
                                    restaurantId: widget.restaurantId,
                                    restaurantName: widget.restaurantName,
                                    userPermissions: widget.userPermissions,
                                    isTakeAway: true,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 16),

                    SizedBox(
                      width: 250,
                      child: _moduleCard(
                        title: "Online Orders",
                        subtitle: "Delivery",
                        count: "0",
                        countLabel: "Pending",
                        color: const Color(0xff9B7AE7),
                        icon: Icons.language,
                        gradient: const RadialGradient(
                          center: Alignment(0.82, 0.85),
                          radius: 1.18,
                          colors: [
                            Color(0xFFA890DC),
                            Color(0xFF9076C8),
                          ],
                        ),
                        boxShadows: const [
                          BoxShadow(
                            color: Color(0x141C2333),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                          BoxShadow(
                            color: Color(0x999076C8),
                            blurRadius: 20,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),
                _sectionTitle("Kitchen & Orders"),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 250,
                      child: _whiteModuleCard(
                        title: "KOT Status",
                        count: kotStatusCount.toString(),
                        countLabel: "In Kitchen",
                        icon: Icons.restaurant_menu,
                        iconColor: Colors.red,
                        description: "Monitor live kitchen order tickets and prep times",
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
                    SizedBox(
                      width: 250,
                      child: _whiteModuleCard(
                        title: "Orders",
                        count: activeOrdersCount.toString(),
                        countLabel: "Total",
                        icon: Icons.receipt_long,
                        iconColor: Colors.blue,
                        description: "View, modify and settle all active orders",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BlocProvider(
                                create: (context) =>
                                    OrderstatusBloc(OrderstatusRepository()),
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
                    if (_userPermissions?.canViewTips == true) ...[
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 250,
                        child: _whiteModuleCard(
                          title: "Tips",
                          count: "$_currency${totalTipAmount.toStringAsFixed(2)}",
                          // count: "₹${totalTipAmount.toStringAsFixed(2)}",
                          // count: totalTipAmount.toStringAsFixed(2),
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
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                _sectionTitle("Customer Management"),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 250,
                      child: _whiteModuleCard(
                        title: "Reservation",
                        count: upcomingReservations.toString(),
                        countLabel: "Upcoming",
                        icon: Icons.calendar_today,
                        iconColor: Colors.blue,
                        description: "Accept, confirm and seat table reservations",
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
                    SizedBox(
                      width: 250,
                      child: _whiteModuleCard(
                        title: "Customers",
                        count: "48",
                        countLabel: "Profiles",
                        icon: Icons.people_outline,
                        iconColor: Colors.purple,
                        description: "Profiles, loyalty history and preferences",
                      ),
                    ),
                    if (_userPermissions?.canViewVendors == true) ...[
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 250,
                        child: _whiteModuleCard(
                          // title: "Vendors",
                          title: "Today's Vendor Payments",
                          // count: vendorcount.toInt().toString(),
                          count: todayVendorPaymentsCount.toString(),
                          countLabel: "Vendors",
                          icon: Icons.local_shipping_outlined,
                          iconColor: Colors.orange,
                          description: "Manage supplier profiles, orders and deliveries",
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
                  ],
                )
              ],
            ),
          ),
          ]),
      ),
    )))
    );
  }
  Widget _restaurantOverview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        const Text(
          "Restaurant Overview",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),

        _topSellingItems(),

        const SizedBox(height: 18),

        _tableStatusWidget(),
      ],
    );
  }
  Widget _topSellingItems() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            blurRadius: 6,
            color: Colors.black12,
          )
        ],
      ),
      child: Column(
        children: [

          const Row(
            children: [
              Expanded(
                child: Text(
                  "Top Selling Items",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Text("Category"),
              SizedBox(width: 40),
              Text("Qty"),
            ],
          ),

          const Divider(),

          _foodRow("Chicken Biryani", "Main Course", "48"),
          _foodRow("Chicken Dum Biryani", "Main Course", "35"),
          _foodRow("Paneer Biryani", "Main Course", "28"),
          _foodRow("Chicken 65", "Starters", "21"),
        ],
      ),
    );
  }
  Widget _foodRow(
      String name,
      String category,
      String qty,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [

          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.orange.shade200,
            child: const Icon(Icons.fastfood),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(name),
          ),

          SizedBox(
            width: 100,
            child: Text(
              category,
              style: const TextStyle(color: Colors.red),
            ),
          ),

          SizedBox(
            width: 40,
            child: Text(
              qty,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
  Widget _tableStatusWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            blurRadius: 6,
            color: Colors.black12,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          const Text(
            "Table Status",
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 18),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [

              _statusBox("15", "Available", Colors.green),

              _statusBox("17", "Dine-In", Colors.red),

              _statusBox("2", "Ready", Colors.blue),

              _statusBox("8", "Shared", Colors.orange),

              _statusBox("6", "Reserve", Colors.grey),
            ],
          )
        ],
      ),
    );
  }
  Widget _statusBox(
      String count,
      String title,
      Color color,
      ) {
    return Container(
      width: 70,
      height: 90,
      decoration: BoxDecoration(
        color: color.withOpacity(.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [

          Text(
            count,
            style: TextStyle(
              color: color,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
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
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              _currentTime.toLowerCase(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: const [],
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
      height: 74,
      padding: const EdgeInsets.all(14),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            width: 0.80,
            color: const Color(0x191C2333),
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        shadows: [
          BoxShadow(
            color: Color(0x19000000),
            blurRadius: 2,
            offset: Offset(0, 1),
            spreadRadius: -1,
          ),
          BoxShadow(
            color: Color(0x19000000),
            blurRadius: 3,
            offset: Offset(0, 1),
            spreadRadius: 0,
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
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),        ],
      ),
    );
  }
  Widget _kotStatusWidget(
      String title,
      String value,
      IconData icon,
      Color color,
      ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            width: 0.8,
            color: color.withOpacity(0.25),
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        shadows: const [
          BoxShadow(
            color: Color(0x2602B443),
            blurRadius: 2,
            offset: Offset(0, 1),
            spreadRadius: -1,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: color,
              size: 22,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Color(0xFF1C2333),
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          const SizedBox(width: 12),

          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 28,
            ),
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
    required List<BoxShadow> boxShadows,
    required Gradient gradient,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 95,
        width: 170,
        padding: const EdgeInsets.all(14),
        decoration: ShapeDecoration(
          gradient: gradient,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          shadows: boxShadows,
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
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Container(
                      width: 45,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            count.padLeft(2, '0'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            countLabel,
                            style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 8,
                                fontWeight: FontWeight.w600
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 2),

                // if (isCurrent)
                //   Container(
                //     padding: const EdgeInsets.symmetric(
                //       horizontal: 8,
                //       vertical: 3,
                //     ),
                //     decoration: BoxDecoration(
                //       color: Colors.white24,
                //       borderRadius: BorderRadius.circular(8),
                //     ),
                //     // child: const Text(
                //     //   "CURRENT",
                //     //   style: TextStyle(
                //     //     color: Colors.white,
                //     //     fontSize: 9,
                //     //     fontWeight: FontWeight.w600,
                //     //   ),
                //     // ),
                //   ),

                // const Spacer(),

                const Text(
                  "Open Module →",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                  ),
                ),
              ],
            ),

            /// BOTTOM RIGHT ICON
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 12,
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
        height: 110,
        padding: const EdgeInsets.all(14),
        decoration: ShapeDecoration(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            side: const BorderSide(
              width: 0.1,
              color: Color(0x191C2333),
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          shadows: const [
            BoxShadow(
              color: Color(0x0A1C2333),
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
            BoxShadow(
              color: Color(0x144D5462), // Reduced opacity for a softer shadow
              blurRadius: 4,
              offset: Offset(2, 4),
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
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 14,
                  ),
                ),

                const Spacer(),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      count.toString().padLeft(2, '0'),
                      style: TextStyle(
                        color: iconColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
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
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF23263A),
              ),
            ),

            // const SizedBox(height: 2),

            // Expanded(
            //   child: Text(
            //     description,
            //     style: const TextStyle(
            //       color: Color(0xFF6B7280),
            //       fontSize: 13,
            //       height: 1.4,
            //     ),
            //   ),
            // ),

            const SizedBox(height: 4),

            const Text(
              "Open Module →",
              style: TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}