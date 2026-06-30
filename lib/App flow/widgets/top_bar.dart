import 'package:flutter/material.dart';
import 'package:pinaka_restaurant_pos/App%20flow/widgets/print_receipt.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/UserPermissions.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/employee_repository.dart';
import '../ui/CheckinPopup.dart';
import '../ui/DailyAttendanceScreen.dart';
import '../ui/SettingsScreen.dart';
import '../ui/employee_login_page.dart';
import '../ui/home_screen.dart';
import '../ui/tables_screen.dart';
import 'LogoutConfirmationDialog.dart';

// Added for Payment Screen support
import '../../models/payment/payment_summary_model.dart';
import '../../repositories/ordertype_payment.dart';

// Added for Print support
import '../../printer/printer_service.dart';

class TopBar extends StatefulWidget implements PreferredSizeWidget {
  final String token;
  final String pin;
  final UserPermissions? userPermissions;
  final Function(UserPermissions)? onPermissionsReceived;
  final bool isHomeScreen;
  final bool isOrderPanel;
  final bool showTablesIcon;
  final VoidCallback? onTablesTap;
  final String restaurantId;
  final String restaurantName;

  // ── Payment Screen parameters ──────────────────────────
  final bool isPaymentScreen;
  final PaymentSummary? paymentSummary;
  final VoidCallback? onBackPressed;
  final ValueChanged<String>? onOrderTypeChanged;
  final ValueChanged<String>? onCustomerPhoneChanged;
  final VoidCallback? onAddCustomer;

  // ── Additional parameters for PrintRecipt ──────────────
  final String cashierName;
  final List<Map<String, dynamic>> loadedTables;
  final int? zoneId;

  const TopBar({
    Key? key,
    required this.token,
    required this.pin,
    this.userPermissions,
    this.onPermissionsReceived,
    this.isHomeScreen = false,
    this.isOrderPanel = false,
    this.showTablesIcon = false,
    this.onTablesTap,
    required this.restaurantId,
    required this.restaurantName,
    this.isPaymentScreen = false,
    this.paymentSummary,
    this.onBackPressed,
    this.onOrderTypeChanged,
    this.onCustomerPhoneChanged,
    this.onAddCustomer,
    this.cashierName = '',
    this.loadedTables = const [],
    this.zoneId,
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(75);

  @override
  _TopBarState createState() => _TopBarState();
}

class _TopBarState extends State<TopBar> {
  bool isLightMode = true;
  bool _isAttendanceDialogOpen = false;
  bool _isCheckInDone = false;
  UserPermissions? _permissions;

  // ── Payment Screen state ───────────────────────────────
  List<String> orderTypes = [];
  String? selectedOrderType;
  final TextEditingController _customerPhoneController = TextEditingController();

  // Store payment summary locally
  PaymentSummary? _localPaymentSummary;

  @override
  void initState() {
    super.initState();
    // Store initial payment summary
    _localPaymentSummary = widget.paymentSummary;

    // Debug: Log initial state
    debugPrint("🔍 TopBar initState - Payment Summary: ${_localPaymentSummary != null ? 'Available' : 'NULL'}");
    if (_localPaymentSummary != null) {
      debugPrint("🔍 Order ID: ${_localPaymentSummary!.orderId}");
      debugPrint("🔍 Table Name: ${_localPaymentSummary!.tableName}");
      debugPrint("🔍 Net Total: ${_localPaymentSummary!.netTotal}");
    }

    if (widget.isPaymentScreen) {
      _loadOrderTypes();
    }
  }

  @override
  void didUpdateWidget(TopBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update local copy when widget receives new payment summary
    if (widget.paymentSummary != oldWidget.paymentSummary) {
      debugPrint("🔍 TopBar didUpdateWidget - Payment Summary updated");
      setState(() {
        _localPaymentSummary = widget.paymentSummary;
      });
      if (_localPaymentSummary != null) {
        debugPrint("🔍 New Order ID: ${_localPaymentSummary!.orderId}");
        debugPrint("🔍 New Net Total: ${_localPaymentSummary!.netTotal}");
      }
    }
  }

  @override
  void dispose() {
    _customerPhoneController.dispose();
    super.dispose();
  }

  void toggleMode() {
    setState(() {
      isLightMode = !isLightMode;
    });
  }

  void _handlePermissions(UserPermissions permissions) {
    setState(() {
      _permissions = permissions;
    });
    widget.onPermissionsReceived?.call(permissions);
  }

  Future<void> _loadOrderTypes() async {
    try {
      final repo = OrderTypesInPaymentScreenRepository();
      final result = await repo.getOrderTypes(token: widget.token);
      if (result != null && mounted) {
        setState(() {
          orderTypes = result.orderTypes;
          selectedOrderType = widget.paymentSummary?.orderType ?? "Dine In";
        });
      }
    } catch (e) {
      debugPrint(" Order Types Error in TopBar: $e");
    }
  }

  // ✅ Updated _printBill with better null handling
  Future<void> _printBill() async {
    debugPrint("🖨️ ========== PRINT BUTTON CLICKED ==========");
    debugPrint("🖨️ Timestamp: ${DateTime.now()}");
    debugPrint("🖨️ Is Payment Screen: ${widget.isPaymentScreen}");
    debugPrint("🖨️ Payment Summary from widget: ${widget.paymentSummary != null ? 'Available' : 'NULL'}");
    debugPrint("🖨️ Local Payment Summary: ${_localPaymentSummary != null ? 'Available' : 'NULL'}");

    // Try to get payment summary from multiple sources
    PaymentSummary? summaryToPrint = _localPaymentSummary ?? widget.paymentSummary;

    // Check if payment summary is available
    if (summaryToPrint == null) {
      debugPrint("❌ ERROR: No payment summary available from any source!");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("No payment summary available. Please try again."),
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    try {
      // 📝 Log Payment Summary Details
      debugPrint("📋 ===== PAYMENT SUMMARY DETAILS ===== ");
      debugPrint("📋 Order ID: ${summaryToPrint.orderId}");
      debugPrint("📋 Table Name: ${summaryToPrint.tableName}");
      debugPrint("📋 Order Type: ${summaryToPrint.orderType ?? 'N/A'}");
      debugPrint("📋 Gross Total: ${summaryToPrint.grossTotal}");
      debugPrint("📋 Net Total: ${summaryToPrint.netTotal}");
      debugPrint("📋 Tax Amount: ${summaryToPrint.tax}");
      debugPrint("📋 Coupon Discount: ${summaryToPrint.coupons}");
      debugPrint("📋 Merchant Discount: ${summaryToPrint.discount}");
      debugPrint("📋 Tip Amount: ${summaryToPrint.tipAmount}");
      debugPrint("📋 Service Charge: ${summaryToPrint.serviceChargeValue}");
      debugPrint("📋 Service Charge %: ${summaryToPrint.serviceChargePercentage}");
      debugPrint("📋 Cashier: ${widget.cashierName.isNotEmpty ? widget.cashierName : widget.userPermissions?.displayName ?? 'Admin'}");

      // 📝 Log Line Items
      debugPrint("📋 ===== LINE ITEMS (${summaryToPrint.lineItems.length}) ===== ");
      for (int i = 0; i < summaryToPrint.lineItems.length; i++) {
        final item = summaryToPrint.lineItems[i];
        debugPrint("📋 Item ${i+1}: ${item.name} | Qty: ${item.qty} | Price: ${item.price} | Total: ${item.total}");
        if (item.modifiers.isNotEmpty) {
          debugPrint("📋   Modifiers: ${item.modifiers.join(', ')}");
        }
      }

      // 📝 Log JSON
      try {
        final jsonData = {
          'orderId': summaryToPrint.orderId,
          'tableName': summaryToPrint.tableName,
          'orderType': summaryToPrint.orderType,
          'grossTotal': summaryToPrint.grossTotal,
          'netTotal': summaryToPrint.netTotal,
          'tax': summaryToPrint.tax,
          'coupons': summaryToPrint.coupons,
          'discount': summaryToPrint.discount,
          'tipAmount': summaryToPrint.tipAmount,
          'serviceChargeValue': summaryToPrint.serviceChargeValue,
          'serviceChargePercentage': summaryToPrint.serviceChargePercentage,
        };
        debugPrint("📋 Summary JSON: ${jsonData.toString()}");
      } catch (e) {
        debugPrint("⚠️ Could not convert to JSON: $e");
      }

      debugPrint("🖨️ ===== OPENING PRINT RECEIPT DIALOG ===== ");

      // ✅ Fix: Cast to non-nullable using ! since we already checked null
      final result = await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => PrintRecipt(
          paymentSummary: summaryToPrint!, // Use ! since we know it's not null
          cashierName: widget.cashierName.isNotEmpty
              ? widget.cashierName
              : widget.userPermissions?.displayName ?? 'Admin',
          pin: widget.pin,
          token: widget.token,
          restaurantId: widget.restaurantId,
          restaurantName: widget.restaurantName,
          loadedTables: widget.loadedTables,
          zoneId: widget.zoneId,
        ),
      );

      debugPrint("🖨️ Print dialog closed with result: $result");
      debugPrint("🖨️ ========== PRINT FLOW COMPLETED ==========");

    } catch (e, stackTrace) {
      debugPrint("❌ ===== PRINT ERROR =====");
      debugPrint("❌ Error: $e");
      debugPrint("❌ Stack Trace: $stackTrace");
      debugPrint("❌ ==========================");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to open print dialog: ${e.toString().replaceFirst('Exception: ', '')}"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Size get preferredSize => Size.fromHeight(70);

  @override
  Widget build(BuildContext context) {
    // Update local summary from widget on each build (safety net)
    if (widget.paymentSummary != null && _localPaymentSummary != widget.paymentSummary) {
      _localPaymentSummary = widget.paymentSummary;
      debugPrint("🔍 Build - Updated local summary from widget");
    }

    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha((0.3 * 255).toInt()),
            spreadRadius: 0,
            blurRadius: 4,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: AppBar(
        backgroundColor: Colors.white,
        toolbarHeight: 70,
        automaticallyImplyLeading: false,
        elevation: 0,
        scrolledUnderElevation: 0.0,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Row(
            children: [
              /// LEFT SIDE — Logo or Back button (Payment Screen)
              if (widget.isPaymentScreen)
                GestureDetector(
                  onTap: widget.onBackPressed ?? () => Navigator.pop(context),
                  child: Container(
                    width: 84,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A2B4A),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                        SizedBox(width: 6),
                        Text(
                          "Back",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Image.asset(
                  'assets/pinaka.png',
                  height: 40,
                  width: 100,
                  fit: BoxFit.contain,
                ),

              const SizedBox(width: 15),

              /// ── PAYMENT SCREEN CENTER CONTROLS ──────────
              if (widget.isPaymentScreen)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      "Customer :",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(width: 8),

                    SizedBox(
                      width: 170,
                      height: 38,
                      child: TextField(
                        controller: _customerPhoneController,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(fontSize: 13),
                        onChanged: widget.onCustomerPhoneChanged,
                        decoration: InputDecoration(
                          hintText: "Mobile number",
                          hintStyle: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFAAAAAA),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFFD1D5DB),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFF4F7CFF),
                              width: 1.5,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    GestureDetector(
                      onTap: widget.onAddCustomer,
                      child: Container(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A2B4A),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.add, color: Colors.white, size: 16),
                            SizedBox(width: 4),
                            Text("Add",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                )),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 14),

                    // ORDER TYPE
                    Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFD1D5DB),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedOrderType,
                          items: orderTypes.isNotEmpty
                              ? orderTypes.map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            );
                          }).toList()
                              : null,
                          onChanged: (value) async {
                            if (value == null) return;
                            setState(() => selectedOrderType = value);
                            widget.onOrderTypeChanged?.call(value);
                          },
                        ),
                      ),
                    ),

                    const SizedBox(width: 14),

                    // PRINT - Updated to use _printBill
                    GestureDetector(
                      onTap: () {
                        debugPrint("🖨️ PRINT BUTTON TAPPED - UI Interaction");
                        _printBill();
                      },
                      child: Container(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.print_outlined,
                                color: Colors.white, size: 16),
                            SizedBox(width: 6),
                            Text("Print",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                )),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

              /// PUSH EVERYTHING ELSE TO RIGHT
              const Spacer(),

              if (widget.isHomeScreen) ...[
                // HOME SCREEN
                if (widget.userPermissions?.canUpdateShiftAttendance ?? false) ...[
                  _buildAttendanceIconButton(context),
                  const SizedBox(width: 10),
                ],

                _buildNotificationIconButton(),
                const SizedBox(width: 10),

                _buildSettingsButton(),
                const SizedBox(width: 10),

                _buildLogoutButton(),
                const SizedBox(width: 10),

                _buildProfileSection(),
              ] else if (widget.isOrderPanel) ...[
                // ORDER PANEL SCREEN
                _buildTablesButton(),
                const SizedBox(width: 10),

                _buildHomeButton(),
                const SizedBox(width: 10),

                _buildNotificationIconButton(),
                const SizedBox(width: 10),

                _buildSettingsButton(),
                const SizedBox(width: 10),

                _buildProfileSection(),
              ] else ...[
                // ALL OTHER SCREENS (including Payment Screen)
                _buildHomeButton(),
                const SizedBox(width: 10),

                _buildNotificationIconButton(),
                const SizedBox(width: 10),

                _buildSettingsButton(),
                const SizedBox(width: 10),

                _buildLogoutButton(),
                const SizedBox(width: 10),

                _buildProfileSection(),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomeButton() {
    return _buildIconButton(
      label: "Home",
      color: const Color(0xFF4F7CFF),
      icon: const Icon(
        Icons.home_outlined,
        color: Color(0xFF4F7CFF),
        size: 22,
      ),
      onPressed: () {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => HomeScreen(
              token: widget.token,
              pin: widget.pin,
              restaurantId: widget.restaurantId,
              restaurantName: widget.restaurantName,
            ),
          ),
              (route) => false,
        );
      },
    );
  }

  Widget _buildTablesButton() {
    return _buildIconButton(
      label: "Tables",
      color: const Color(0xFF4F7CFF),
      icon: const Icon(
        Icons.table_restaurant,
        color: Color(0xFF4F7CFF),
        size: 22,
      ),
      onPressed: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => TablesScreen(
              loadedTables: const [],
              pin: widget.pin,
              token: widget.token,
              restaurantId: widget.restaurantId,
              restaurantName: widget.restaurantName,
              userPermissions: widget.userPermissions,
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingsButton() {
    return _buildIconButton(
      label: "Settings",
      color: const Color(0xFF4CAF50),
      icon: Image.asset(
        'assets/setting.png',
        width: 20,
        height: 20,
        color: const Color(0xFF4CAF50),
      ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SettingsScreen(
              token: widget.token,
              pin: widget.pin,
              userId: widget.userPermissions?.userId ?? '',
              displayName: widget.userPermissions?.displayName ?? '',
              role: widget.userPermissions?.role ?? '',
            ),
          ),
        );
      },
    );
  }

  Widget _buildLogoutButton() {
    return _buildIconButton(
      label: "Logout",
      color: const Color(0xFFFF9800),
      icon: Image.asset(
        'assets/logout.png',
        width: 24,
        height: 24,
        color: const Color(0xFFFF9800),
      ),
      onPressed: () async {
        final result = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (_) => LogoutConfirmationDialog(
            onCancel: () => Navigator.pop(context, false),
            onConfirm: () => Navigator.pop(context, true),
          ),
        );

        if (result != true) return;

        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token') ?? "";

        final authRepository = AuthRepository();

        // Show loader
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(
            child: CircularProgressIndicator(),
          ),
        );

        try {
          final success = await authRepository.logout(token);

          if (context.mounted && Navigator.canPop(context)) {
            Navigator.pop(context); // Close loader
          }

          if (!context.mounted) return;

          if (success) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (_) => const EmployeeLoginPage(
                  storeBaseUrl: '',
                  storeName: '',
                  storeId: '',
                ),
              ),
                  (route) => false,
            );
          }
        } catch (e) {
          if (context.mounted && Navigator.canPop(context)) {
            Navigator.pop(context); // Close loader
          }

          final message = e.toString().replaceFirst("Exception: ", "");

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 1),
            ),
          );
        }
      },
    );
  }

  Widget _buildAttendanceIconButton(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        if (_isAttendanceDialogOpen) return;

        setState(() {
          _isAttendanceDialogOpen = true;
        });

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(child: CircularProgressIndicator()),
        );

        try {
          final repository = EmployeeRepository();
          final response = await repository.getAllEmployees(widget.token);

          final List<Employee> employees = response.map((e) {
            return Employee(
              id: e['ID'].toString(),
              name: e['name'].toString(),
            );
          }).toList();

          final currentShift = await repository.getCurrentShift(widget.token);

          if (currentShift != null) {
            final presentIds = List<int>.from(currentShift['shift_emp'] ?? []);
            final absentIds = List<int>.from(currentShift['shift_absent_emp'] ?? []);

            for (var emp in employees) {
              final empId = int.tryParse(emp.id);
              if (presentIds.contains(empId)) {
                emp.status = 'Present';
              } else if (absentIds.contains(empId)) {
                emp.status = 'Absent';
              } else {
                emp.status = '';
              }
            }
          }

          if (context.mounted) {
            Navigator.pop(context);

            final shiftData = await EmployeeRepository().getCurrentShift(widget.token);

            await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => AttendancePopup(
                token: widget.token,
                employees: employees,
                isUpdateMode: true,
                currentShiftData: shiftData,
              ),
            );
          }
        } catch (e) {
          if (context.mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to load employees'),
                duration: Duration(seconds: 1),
              ),
            );
          }
        } finally {
          if (mounted) {
            setState(() {
              _isAttendanceDialogOpen = false;
            });
          }
        }
      },
      child: _buildIconButton(
        label: "Attendance",
        color: const Color(0xFF4F7CFF),
        icon: Image.asset(
          'assets/attendance.png',
          width: 20,
          height: 20,
          color: const Color(0xFF4F7CFF),
        ),
      ),
    );
  }

  Widget _buildExitIconButton() {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (context) => Checkinpopup(
            token: widget.token,
            onCheckIn: () {
              Navigator.of(context).pop();
              setState(() {
                _isCheckInDone = true;
              });
            },
            onCancel: () {
              Navigator.of(context).pop();
            },
            onPermissionsReceived: (permissions) {
              _handlePermissions(permissions);
            },
          ),
        );
      },
      child: _buildIconButton(
        label: "CheckIn",
        color: const Color(0xFFFF5A3C),
        icon: Image.asset(
          'assets/checkin.png',
          width: 20,
          height: 20,
          color: const Color(0xFFFF5A3C),
        ),
      ),
    );
  }

  Widget _buildNotificationIconButton({VoidCallback? onPressed}) {
    return _buildIconButton(
      label: "Notification",
      color: const Color(0xFFFFC107),
      onPressed: onPressed,
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(
            Icons.notifications_none_outlined,
            size: 24,
            color: Color(0xFFFFC107),
          ),
          /// 🔴 Notification Dot
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required Widget icon,
    required String label,
    required Color color,
    VoidCallback? onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 65,
        height: 51,
        margin: const EdgeInsets.only(right: 14, bottom: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            /// MAIN soft shadow
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
            /// COLORED glow shadow (very subtle)
            BoxShadow(
              color: color.withOpacity(0.10),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    final avatarUrl = widget.userPermissions?.avatar;

    return Container(
      height: 55,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                ? NetworkImage(avatarUrl)
                : const AssetImage('assets/loginname.png') as ImageProvider,
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.userPermissions?.displayName ?? "username",
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.userPermissions?.role ?? "role",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class TrianglePainter extends CustomPainter {
  final bool isLeft;
  final Color fillColor;
  final Color borderColor;

  TrianglePainter({
    required this.isLeft,
    required this.fillColor,
    this.borderColor = Colors.black,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final path = Path();
    if (isLeft) {
      path.moveTo(size.width, 0);
      path.lineTo(0, size.height / 2);
      path.lineTo(size.width, size.height);
      path.close();
    } else {
      path.moveTo(0, 0);
      path.lineTo(size.width, size.height / 2);
      path.lineTo(0, size.height);
      path.close();
    }

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}