import 'package:flutter/material.dart';
import 'package:pinaka_restaurant_pos/App%20flow/widgets/print_receipt.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/UserPermissions.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/employee_repository.dart';
import '../../utils/theme_provider.dart';
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
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/Bloc Event/subcategory_event.dart';
import '../../blocs/Bloc Event/minisubcategory_event.dart';
import '../../blocs/Bloc Event/product_event.dart';
import '../../blocs/Bloc Logic/subcategory_bloc.dart';
import '../../blocs/Bloc Logic/minisubcategory_bloc.dart';
import '../../blocs/Bloc Logic/product_bloc.dart';

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
  final bool showSearchBar;
  final TextEditingController? searchController;
  final FocusNode? searchFocusNode;
  final LayerLink? searchLink;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onSearchTap;
  final Future<bool> Function()? onHomePressed;
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
    this.showSearchBar = false,
    this.searchController,
    this.searchFocusNode,
    this.searchLink,
    this.onSearchChanged,
    this.onSearchTap,
    this.onHomePressed,
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

  List<String> get _filteredOrderTypes {
    if (widget.isTakeAway) {
      return orderTypes.where((t) => t.toLowerCase().contains("takeaway")).toList();
    } else {
      return orderTypes.where((t) => t.toLowerCase().contains("dine in")).toList();
    }
  }

  Future<void> _loadOrderTypes() async {
    try {
      final repo = OrderTypesInPaymentScreenRepository();
      final result = await repo.getOrderTypes(token: widget.token);
      if (result != null && mounted) {
        setState(() {
          orderTypes = result.orderTypes;

          final filtered = widget.isTakeAway
              ? orderTypes.where((t) => t.toLowerCase().contains("takeaway")).toList()
              : orderTypes.where((t) => t.toLowerCase().contains("dine in")).toList();

          selectedOrderType = widget.paymentSummary?.orderType != null &&
              filtered.contains(widget.paymentSummary?.orderType)
              ? widget.paymentSummary?.orderType
              : (filtered.isNotEmpty ? filtered.first : null);
        });
      }
    } catch (e) {
      debugPrint(" Order Types Error in TopBar: $e");
    }
  }

  Future<void> _printBill() async {
    PaymentSummary? summaryToPrint = _localPaymentSummary ?? widget.paymentSummary;

    if (summaryToPrint == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No payment summary available. Please try again."),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 1),
          ),
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
        couponDetails: summaryToPrint.couponDetails,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Receipt sent to printer"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      }

    } catch (e) {
      debugPrint("Print Bill Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to print: ${e.toString().replaceFirst('Exception: ', '')}"),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 1),
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
              blurRadius: 2,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: AppBar(
          backgroundColor: Colors.white,
          toolbarHeight: 60,
          automaticallyImplyLeading: false,
          elevation: 0,
          titleSpacing: 0,
          title: SizedBox(
            height: 60,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
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
                    Image.asset('assets/pinaka.png', height: 50, width: 100, fit: BoxFit.contain),

                  const SizedBox(width: 75),

                  if (widget.showSearchBar)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: CompositedTransformTarget(
                          link: widget.searchLink!,
                          child: Container(
                            height: 42,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFE5E7EB),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 12,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: widget.searchController,
                              focusNode: widget.searchFocusNode,
                              onTap: widget.onSearchTap,
                              onChanged: widget.onSearchChanged,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF111827),
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: InputDecoration(
                                hintText: "Search item or short code....",
                                hintStyle: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF9CA3AF),
                                  fontWeight: FontWeight.w400,
                                ),
                                prefixIcon: const Padding(
                                  padding: EdgeInsets.only(left: 10, right: 8),
                                  child: Icon(
                                    Icons.search_rounded,
                                    size: 20,
                                    color: Color(0xFFB6BDC7),
                                  ),
                                ),
                                prefixIconConstraints: const BoxConstraints(
                                  minWidth: 42,
                                  minHeight: 42,
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 11,
                                  horizontal: 6,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // CENTER - PAYMENT CONTROLS
                  if (widget.isPaymentScreen)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [

                        // const Text("Customer :", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
                        // const SizedBox(width: 8),
                        // SizedBox(
                        //   width: 170,
                        //   height: 38,
                        //   child: TextField(
                        //     controller: _customerPhoneController,
                        //     keyboardType: TextInputType.phone,
                        //     style: const TextStyle(fontSize: 13),
                        //     onChanged: widget.onCustomerPhoneChanged,
                        //     decoration: InputDecoration(
                        //       hintText: "Mobile number",
                        //       hintStyle: const TextStyle(fontSize: 12, color: Color(0xFFAAAAAA)),
                        //       contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        //       enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFD1D5DB))),
                        //       focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF4F7CFF), width: 1.5)),
                        //       filled: true,
                        //       fillColor: Colors.white,
                        //     ),
                        //   ),
                        // ),
                        // const SizedBox(width: 8),
                        // GestureDetector(
                        //   onTap: widget.onAddCustomer,
                        //   child: Container(
                        //     height: 38,
                        //     padding: const EdgeInsets.symmetric(horizontal: 16),
                        //     decoration: BoxDecoration(color: const Color(0xFF1A2B4A), borderRadius: BorderRadius.circular(8)),
                        //     child: const Row(
                        //       mainAxisSize: MainAxisSize.min,
                        //       children: [
                        //         Icon(Icons.add, color: Colors.white, size: 16),
                        //         SizedBox(width: 4),
                        //         Text("Add", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                        //       ],
                        //     ),
                        //   ),
                        // ),
                        const SizedBox(width: 625),
                        // Order Type Dropdown
                        Container(
                          width: 235,
                          height: 40,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FBFF),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFFE6E6E6),
                              width: 1,
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedOrderType,
                              isExpanded: true,
                              hint: const Text("Dine In"),
                              items:
                              orderTypes.map((type) {
                                return DropdownMenuItem<String>(
                                  value: type,
                                  child: Text(type),
                                );
                              }).toList(),
                              onChanged: (value) async {
                                if (value == null) return;

                                setState(() {
                                  selectedOrderType = value;
                                });

                                final result =
                                await OrderTypesInPaymentScreenRepository()
                                    .updateOrderType(
                                  token: widget.token,
                                  orderId: widget.paymentSummary!.orderId,
                                  orderType: value,
                                );

                                if (result?.success == true) {
                                  ScaffoldMessenger.of(
                                    context,
                                  ).showSnackBar(
                                    SnackBar(
                                      content: Text(result!.message),
                                      duration: Duration(seconds: 1),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
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
                      _buildThemeButton(),
                      const SizedBox(width: 10),
                      _buildSettingsButton(),
                      const SizedBox(width: 10),
                      _buildLogoutButton(),
                      const SizedBox(width: 10),
                      _buildProfileSection(),
                    ] else if (widget.isOrderPanel) ...[
                      _buildHomeButton(),
                      const SizedBox(width: 10),
                      if (!widget.isTakeAway) ...[
                        _buildTablesButton(),
                        const SizedBox(width: 10),
                      ],

                      _buildNotificationIconButton(),
                      const SizedBox(width: 10),
                      _buildThemeButton(),
                      const SizedBox(width: 10),
                      _buildSettingsButton(),
                      const SizedBox(width: 10),
                      _buildProfileSection(),
                    ] else ...[
                      _buildHomeButton(),
                      const SizedBox(width: 10),
                      _buildNotificationIconButton(),
                      const SizedBox(width: 10),
                      _buildThemeButton(),
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
        )
    );
  }

  // ==================== ALL HELPER METHODS (UNCHANGED) ====================

  Widget _buildHomeButton() {
    return GestureDetector(
      onTap: () async {
        bool shouldNavigate = true;

        if (widget.onHomePressed != null) {
          shouldNavigate = await widget.onHomePressed!();
        }

        if (!shouldNavigate) return;

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
      child: Container(
        width: 55,
        height: 55,
        decoration: BoxDecoration(
          color: const Color(0xFF7B4597),
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(
              color: Color(0x667B4597),
              blurRadius: 4,
              offset: Offset(0, 0),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.home_outlined,
              color: Colors.white,
              size: 24,
            ),
            SizedBox(height: 4),
            Text(
              "Home",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTablesButton() {
    return GestureDetector(
      onTap: () {
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
      child: Container(
        width: 55,
        height: 55,
        decoration: BoxDecoration(
          color: const Color(0xFF048DCB),
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(
              color: Color(0x4C048ECC),
              blurRadius: 4,
              offset: Offset(0, 0),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.table_restaurant,
              color: Colors.white,
              size: 24,
            ),
            SizedBox(height: 3),
            Text(
              "Tables",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildThemeButton() {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return GestureDetector(
      onTap: () {
        themeProvider.toggleTheme();
      },
      child: Container(
        width: 55,
        height: 55,
        decoration: BoxDecoration(
          color: const Color(0xFF6366F1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              themeProvider.isDark
                  ? Icons.light_mode
                  : Icons.dark_mode,
              color: Colors.white,
            ),
            Text(
              themeProvider.isDark ? "Light" : "Dark",
              style: const TextStyle(color: Colors.white, fontSize: 9),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsButton() {
    return GestureDetector(
      onTap: () {
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
      child: Container(
        width: 55,
        height: 55,
        decoration: BoxDecoration(
          color: const Color(0xFF4CAF50),
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(
              color: Color(0x664CAF50),
              blurRadius: 4,
              offset: Offset(0, 0),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/setting.png',
              width: 22,
              height: 22,
              color: Colors.white,
            ),
            const SizedBox(height: 3),
            const Text(
              "Settings",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: () async {
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
            Navigator.pop(context);
          }
          if (success && context.mounted) {
            // ✅ ADD — purge stale category/subcategory/product state & caches
            // so the next login doesn't show leftover data from this session.
            // Guarded with try/catch since TopBar is reused on screens where
            // these Blocs may not be provided above it in the tree.
            try {
              context.read<SubCategoryBloc>().add(ResetSubCategory());
              context.read<MiniSubCategoryBloc>().add(ResetMiniSubCategory());
              context.read<ProductBloc>().add(ClearProducts());
            } catch (_) {
              // Blocs not available on this screen — safe to ignore.
            }

            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const EmployeeLoginPage(storeBaseUrl: '', storeName: '', storeId: '')),
                  (route) => false,
            );
          }
          // if (success && context.mounted) {
          //   Navigator.pushAndRemoveUntil(
          //     context,
          //     MaterialPageRoute(
          //       builder: (_) => const EmployeeLoginPage(
          //         storeBaseUrl: '',
          //         storeName: '',
          //         storeId: '',
          //       ),
          //     ),
          //         (route) => false,
          //   );
          // }
        } catch (e) {
          if (context.mounted && Navigator.canPop(context)) {
            Navigator.pop(context);
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                e.toString().replaceFirst("Exception: ", ""),
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 1),
            ),
          );
        }
      },
      child: Container(
        width: 55,
        height: 55,
        decoration: BoxDecoration(
          color: const Color(0xFFFF9800),
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66FF9800),
              blurRadius: 4,
              offset: Offset(0, 0),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.logout,
              color: Colors.white,
              size: 22,
            ),
            const SizedBox(height: 3),
            const Text(
              "Logout",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
  // Widget _buildLogoutButton() {
  //   return _buildIconButton(
  //     label: "Logout",
  //     color: const Color(0xFFFF9800),
  //     icon: Image.asset('assets/logout.png', width: 24, height: 24, color: const Color(0xFFFF9800)),
  //     onPressed: () async {
  //       final result = await showDialog<bool>(
  //         context: context,
  //         barrierDismissible: false,
  //         builder: (_) => LogoutConfirmationDialog(
  //           onCancel: () => Navigator.pop(context, false),
  //           onConfirm: () => Navigator.pop(context, true),
  //         ),
  //       );
  //
  //       if (result != true) return;
  //
  //       final prefs = await SharedPreferences.getInstance();
  //       final token = prefs.getString('token') ?? "";
  //
  //       final authRepository = AuthRepository();
  //
  //       showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
  //
  //       try {
  //         final success = await authRepository.logout(token);
  //         if (context.mounted && Navigator.canPop(context)) Navigator.pop(context);
  //
  //         if (success && context.mounted) {
  //           // ✅ ADD — purge stale category/subcategory/product state & caches
  //           // so the next login doesn't show leftover data from this session.
  //           // Guarded with try/catch since TopBar is reused on screens where
  //           // these Blocs may not be provided above it in the tree.
  //           try {
  //             context.read<SubCategoryBloc>().add(ResetSubCategory());
  //             context.read<MiniSubCategoryBloc>().add(ResetMiniSubCategory());
  //             context.read<ProductBloc>().add(ClearProducts());
  //           } catch (_) {
  //             // Blocs not available on this screen — safe to ignore.
  //           }
  //
  //           Navigator.pushAndRemoveUntil(
  //             context,
  //             MaterialPageRoute(builder: (_) => const EmployeeLoginPage(storeBaseUrl: '', storeName: '', storeId: '')),
  //                 (route) => false,
  //           );
  //         }
  //       } catch (e) {
  //         if (context.mounted && Navigator.canPop(context)) Navigator.pop(context);
  //         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst("Exception: ", "")), backgroundColor: Colors.red));
  //       }
  //     },
  //   );
  // }

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

          final currentShift =
          await repository.getCurrentShift(widget.token);

          if (currentShift != null) {
            final presentIds =
            List<int>.from(currentShift['shift_emp'] ?? []);
            final absentIds =
            List<int>.from(currentShift['shift_absent_emp'] ?? []);

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

            final shiftData =
            await EmployeeRepository().getCurrentShift(widget.token);

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
              const SnackBar(content: Text('Failed to load employees'),
                backgroundColor: Colors.red,
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
      child: Container(
        width: 55,
        height: 55,
        decoration: BoxDecoration(
          color: const Color(0xFF4F7CFF),
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(
              color: Color(0x664F7CFF),
              blurRadius: 4,
              offset: Offset(0, 0), // Horizontal shadow only
            ),

          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/attendance.png',
              width: 22,
              height: 22,
              color: Colors.white,
            ),
            const SizedBox(height: 3),
            const Text(
              "Attendance",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationIconButton({VoidCallback? onPressed}) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFFEACA00),
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66D8C300),
              blurRadius: 4,
              offset: Offset(0, 0),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(
                  Icons.notifications_none_outlined,
                  color: Colors.white,
                  size: 24,
                ),
                Positioned(
                  top: 1,
                  right: -1,
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF0303),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            const Text(
              "Alerts",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
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

    final bool isPayment = widget.isPaymentScreen;

    return Container(
      height: isPayment ? 42 : 55,
      padding: EdgeInsets.symmetric(
        horizontal: isPayment ? 10 : 14,
      ),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        shadows: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 4,
            offset: Offset(0, 0),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: isPayment ? 15 : 20,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                ? NetworkImage(avatarUrl)
                : const AssetImage('assets/loginname.png') as ImageProvider,
          ),
          SizedBox(width: isPayment ? 8 : 12),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.userPermissions?.displayName ?? "username",
                style: TextStyle(
                  fontSize: isPayment ? 11 : 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2C2B2B),
                ),
              ),
              SizedBox(height: isPayment ? 1 : 2),
              Text(
                widget.userPermissions?.role ?? "role",
                style: TextStyle(
                  fontSize: isPayment ? 9 : 12,
                  color: Colors.grey.shade600,
                  height: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}