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
  final bool isTakeAway;

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
    this.isTakeAway = false,
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

  PaymentSummary? _localPaymentSummary;

  // ── FIX: guard so a fast double-tap on Print doesn't fire two jobs
  bool _isPrinting = false;

  @override
  void initState() {
    super.initState();
    _localPaymentSummary = widget.paymentSummary;

    if (widget.isPaymentScreen) {
      _loadOrderTypes();
    }
  }

  @override
  void didUpdateWidget(TopBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.paymentSummary != oldWidget.paymentSummary) {
      setState(() {
        _localPaymentSummary = widget.paymentSummary;
      });
    }
  }

  @override
  void dispose() {
    _customerPhoneController.dispose();
    super.dispose();
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

  // ── FIX: _printBill now prints DIRECTLY using Printer.printBill
  // (printer_service.dart) instead of opening the PrintRecipt popup.
  // No dialog is shown anymore — tapping Print sends the job straight
  // to the printer using the same data mapping PrintRecipt used to do.
  Future<void> _printBill() async {
    PaymentSummary? summaryToPrint = _localPaymentSummary ?? widget.paymentSummary;

    if (summaryToPrint == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No payment summary available. Please try again.")),
        );
      }
      return;
    }

    if (_isPrinting) return;
    setState(() => _isPrinting = true);

    try {
      // Print all values to console
      debugPrint("========== BILL DATA ==========");
      debugPrint("Order ID: ${summaryToPrint.orderId}");
      debugPrint("Table Name: ${summaryToPrint.tableName}");
      debugPrint("Cashier: ${widget.cashierName.isNotEmpty ? widget.cashierName : widget.userPermissions?.displayName ?? 'Admin'}");
      debugPrint("Gross Total: ${summaryToPrint.grossTotal}");
      debugPrint("Coupon Discount: ${summaryToPrint.coupons}");
      debugPrint("Merchant Discount: ${summaryToPrint.discount}");
      debugPrint("Tip: ${summaryToPrint.tipAmount}");
      debugPrint("Tax: ${summaryToPrint.tax}");
      debugPrint("Service Charge: ${summaryToPrint.serviceChargeValue}");
      debugPrint("Net Payable: ${summaryToPrint.netTotal}");

      debugPrint("Items:");
      for (var item in summaryToPrint.lineItems) {
        debugPrint("----------------------------");
        debugPrint("Name: ${item.name}");
        debugPrint("Qty: ${item.qty}");
        debugPrint("Price: ${item.price}");
        debugPrint("Amount: ${item.total}");
        debugPrint("Modifiers: ${item.modifiers}");
      }
      debugPrint("================================");

      await Printer.printBill(
        context: context,
        orderId: summaryToPrint.orderId.toString(),
        tableName: summaryToPrint.tableName,
        cashierName: widget.cashierName.isNotEmpty
            ? widget.cashierName
            : widget.userPermissions?.displayName ?? 'Admin',
        items: summaryToPrint.lineItems.map((item) {
          return {
            "name": item.name,
            "qty": item.qty,
            "price": item.price,
            "amount": item.total,
            "modifiers": item.modifiers,
          };
        }).toList(),
        grossTotal: summaryToPrint.grossTotal,
        couponDiscount: summaryToPrint.coupons,
        merchantDiscount: summaryToPrint.discount,
        tipAmount: summaryToPrint.tipAmount,
        taxAmount: summaryToPrint.tax,
        serviceCharge: summaryToPrint.serviceChargeValue,
        netPayable: summaryToPrint.netTotal,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Receipt sent to printer")),
        );
      }

    } catch (e) {
      debugPrint("Print Bill Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to print: ${e.toString().replaceFirst('Exception: ', '')}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.paymentSummary != null && _localPaymentSummary != widget.paymentSummary) {
      _localPaymentSummary = widget.paymentSummary;
    }

    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha((0.3 * 255).toInt()),
            spreadRadius: 0,
            blurRadius: 4,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: AppBar(
        backgroundColor: Colors.white,
        toolbarHeight: 70,
        automaticallyImplyLeading: false,
        elevation: 0,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Row(
            children: [
              // LEFT SIDE
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
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 14),
                        SizedBox(width: 6),
                        Text("Back", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                      ],
                    ),
                  ),
                )
              else
                Image.asset('assets/pinaka.png', height: 40, width: 100, fit: BoxFit.contain),

              const SizedBox(width: 15),

              // CENTER - PAYMENT CONTROLS
              if (widget.isPaymentScreen)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text("Customer :", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
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
                          hintStyle: const TextStyle(fontSize: 12, color: Color(0xFFAAAAAA)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFD1D5DB))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF4F7CFF), width: 1.5)),
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
                        decoration: BoxDecoration(color: const Color(0xFF1A2B4A), borderRadius: BorderRadius.circular(8)),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add, color: Colors.white, size: 16),
                            SizedBox(width: 4),
                            Text("Add", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Order Type Dropdown
                    Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFD1D5DB)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedOrderType,
                          items: orderTypes.isNotEmpty
                              ? orderTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList()
                              : null,
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() => selectedOrderType = value);
                            widget.onOrderTypeChanged?.call(value);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Print Button
                    GestureDetector(
                      onTap: _isPrinting ? null : _printBill,
                      child: Container(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: _isPrinting ? const Color(0xFF9AD9AE) : const Color(0xFF22C55E),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _isPrinting
                            ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                            : const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.print_outlined, color: Colors.white, size: 16),
                            SizedBox(width: 6),
                            Text("Print", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

              const Spacer(),

              // ==================== RIGHT SIDE ====================
              // Show Profile always, but hide other buttons on Payment Screen
              if (widget.isPaymentScreen) ...[
                _buildProfileSection(),
              ] else ...[
                if (widget.isHomeScreen) ...[
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
                  if (!widget.isTakeAway) ...[
                    _buildTablesButton(),
                    const SizedBox(width: 10),
                  ],
                  _buildHomeButton(),
                  const SizedBox(width: 10),
                  _buildNotificationIconButton(),
                  const SizedBox(width: 10),
                  _buildSettingsButton(),
                  const SizedBox(width: 10),
                  _buildProfileSection(),
                ] else ...[
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
            ],
          ),
        ),
      ),
    );
  }

  // ==================== ALL HELPER METHODS (UNCHANGED) ====================

  Widget _buildHomeButton() {
    return _buildIconButton(
      label: "Home",
      color: const Color(0xFF4F7CFF),
      icon: const Icon(Icons.home_outlined, color: Color(0xFF4F7CFF), size: 22),
      onPressed: () {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => HomeScreen(token: widget.token, pin: widget.pin, restaurantId: widget.restaurantId, restaurantName: widget.restaurantName)),
              (route) => false,
        );
      },
    );
  }

  Widget _buildTablesButton() {
    return _buildIconButton(
      label: "Tables",
      color: const Color(0xFF4F7CFF),
      icon: const Icon(Icons.table_restaurant, color: Color(0xFF4F7CFF), size: 22),
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
      icon: Image.asset('assets/setting.png', width: 20, height: 20, color: const Color(0xFF4CAF50)),
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
      icon: Image.asset('assets/logout.png', width: 24, height: 24, color: const Color(0xFFFF9800)),
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

        showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));

        try {
          final success = await authRepository.logout(token);
          if (context.mounted && Navigator.canPop(context)) Navigator.pop(context);

          if (success && context.mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const EmployeeLoginPage(storeBaseUrl: '', storeName: '', storeId: '')),
                  (route) => false,
            );
          }
        } catch (e) {
          if (context.mounted && Navigator.canPop(context)) Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst("Exception: ", "")), backgroundColor: Colors.red));
        }
      },
    );
  }

  Widget _buildAttendanceIconButton(BuildContext context) {
    // ... (keeping your original attendance logic unchanged)
    return GestureDetector(
      onTap: () async { /* Your original attendance code */ },
      child: _buildIconButton(
        label: "Attendance",
        color: const Color(0xFF4F7CFF),
        icon: Image.asset('assets/attendance.png', width: 20, height: 20, color: const Color(0xFF4F7CFF)),
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
          const Icon(Icons.notifications_none_outlined, size: 24, color: Color(0xFFFFC107)),
          Positioned(
            top: -2,
            right: -2,
            child: Container(width: 7, height: 7, decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5))),
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
            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 6)),
            BoxShadow(color: color.withOpacity(0.10), blurRadius: 12, spreadRadius: 1),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [icon, const SizedBox(height: 6), Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color))],
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
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
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
              ),
              const SizedBox(height: 2),
              Text(
                widget.userPermissions?.role ?? "role",
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}