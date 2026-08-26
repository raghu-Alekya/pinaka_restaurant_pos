import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';

import '../../models/UserPermissions.dart';
import '../../models/vendor_payment_model.dart';
import '../../models/view_mode.dart';
import '../../repositories/vendor_payment_repository.dart';
import '../../utils/SessionManager.dart';
import '../widgets/top_bar.dart';
import '../widgets/widget_add_vendor_payouts.dart';
import 'home_screen.dart';

class _VendorPaymentsCache {
  static List<VendorPaymentModel>? _cache;
  static DateTime? _lastFetchTime;
  static const Duration _cacheDuration = Duration(minutes: 5);

  static List<VendorPaymentModel>? get() {
    if (_cache != null && _lastFetchTime != null) {
      final age = DateTime.now().difference(_lastFetchTime!);
      if (age < _cacheDuration) return _cache;
    }
    return null;
  }

  static void set(List<VendorPaymentModel> data) {
    _cache = data;
    _lastFetchTime = DateTime.now();
  }

  static void clear() {
    _cache = null;
    _lastFetchTime = null;
  }
}

class _VendorPaymentIdTracker {
  static Set<int> _ids = {};

  static Set<int> get() => _ids;

  static void set(List<VendorPaymentModel> list) {
    _ids = list.map((e) => e.vendorPaymentId).toSet();
  }

  static Set<int> findNew(List<VendorPaymentModel> incoming) {
    final newIds = incoming.map((e) => e.vendorPaymentId).toSet();
    return newIds.difference(_ids);
  }
}

class Vendorpaymentsscreen extends StatefulWidget {
  final String token;
  final String pin;
  final String restaurantId;
  final String restaurantName;
  final UserPermissions? userPermissions;

  const Vendorpaymentsscreen({
    super.key,
    required this.token,
    required this.pin,
    required this.restaurantId,
    required this.restaurantName,
    this.userPermissions,
  });

  @override
  State<Vendorpaymentsscreen> createState() => _VendorpaymentsscreenState();
}

class _VendorpaymentsscreenState extends State<Vendorpaymentsscreen> {
  dynamic _userPermissions;
  dynamic _selectedUser;
  bool hasData = false;
  final VendorPaymentRepository _repository = VendorPaymentRepository();
  ViewMode _currentViewMode = ViewMode.normal;

  List<VendorPaymentModel> vendorPayments = [];
  bool isLoading = false;
  final TextEditingController searchController = TextEditingController();
  final TextEditingController _datevendorController = TextEditingController();
  DateTime? selectedDate;
  int currentPage = 1;
  int totalPages = 1;
  static const int rowsPerPage = 8;
  String _currency = "₹";

  // Auto-refresh only when new items appear
  Timer? _autoRefreshTimer;
  static const Duration _autoRefreshInterval = Duration(seconds: 3);
  bool _isDateFiltered = false;
  bool _isSearchActive = false;

  @override
  void initState() {
    super.initState();
    _loadVendorPayments();
    _loadPermissions();
    _loadCurrency();
    selectedDate = DateTime.now();

    _datevendorController.text =
    "${selectedDate!.day.toString().padLeft(2, '0')}/"
        "${selectedDate!.month.toString().padLeft(2, '0')}/"
        "${selectedDate!.year}";

    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    _stopAutoRefresh();
    _autoRefreshTimer = Timer.periodic(_autoRefreshInterval, (_) {
      if (mounted && !_isSearchActive) {
        _checkForNewPayments();
      }
    });
  }

  void _stopAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
  }

  // ✅ Only updates UI when brand-new payments appear (no unnecessary rebuilds)
  Future<void> _checkForNewPayments() async {
    if (isLoading || vendorPayments.isEmpty) return;

    try {
      List<VendorPaymentModel> response;

      if (_isDateFiltered && selectedDate != null) {
        final apiDate = DateFormat("d MMMM, yyyy").format(selectedDate!);
        response = await _repository.getVendorPaymentsByDate(
          token: widget.token,
          date: apiDate,
        );
      } else {
        response = await _repository.getVendorPayments(token: widget.token);
      }

      if (!mounted || response.isEmpty) return;

      final newIds = _VendorPaymentIdTracker.findNew(response);
      if (newIds.isEmpty) return; // ← nothing new → do nothing

      debugPrint("🆕 Found ${newIds.length} new vendor payment(s)");

      final existingIds = vendorPayments.map((e) => e.vendorPaymentId).toSet();
      final newItems =
      response
          .where((p) => !existingIds.contains(p.vendorPaymentId))
          .toList();

      if (newItems.isEmpty) return;

      // Newest first
      final updatedList = [...newItems, ...vendorPayments];

      _VendorPaymentsCache.set(updatedList);
      _VendorPaymentIdTracker.set(updatedList);

      setState(() {
        vendorPayments = updatedList;
        currentPage = 1;
        totalPages = (vendorPayments.length / rowsPerPage).ceil();
        if (totalPages == 0) totalPages = 1;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${newItems.length} new vendor payment${newItems.length > 1 ? 's' : ''} received!',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      debugPrint("❌ Auto-refresh error: $e");
    }
  }
  Future<void> _refreshVendorPayments() async {
    if (isLoading) return;

    await _loadVendorPayments(forceRefresh: true);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Vendor payments refreshed"),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  Future<void> _loadCurrency() async {
    final currency = await SessionManager.getCurrencySymbol();
    if (mounted) {
      setState(() {
        _currency = currency ?? "₹";
      });
    }
  }

  Future<void> _loadPermissions() async {
    final savedPermissions = await SessionManager.loadPermissions();
    if (savedPermissions != null) {
      setState(() {
        _userPermissions = savedPermissions;
      });
    }
  }

  Future<bool?> _showDeleteDialog() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: 35,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Delete Vendor Payment",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Are you sure you want to delete this vendor payment?\nThis action cannot be undone.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop(false);
                        },
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 45),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text("Cancel"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop(true);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          minimumSize: const Size(0, 45),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          "Delete",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _deleteVendorPayment(int vendorPaymentId) async {
    try {
      final response = await _repository.deleteVendorPayment(
        token: widget.token,
        vendorPaymentId: vendorPaymentId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response["message"] ?? "Vendor payment deleted successfully",
          ),
          duration: const Duration(seconds: 1),
          backgroundColor: Colors.green,
        ),
      );

      _loadVendorPayments();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _filterVendorPaymentsByDate(String date) async {
    try {
      setState(() {
        isLoading = true;
        _isDateFiltered = true;
        _isSearchActive = false;
      });

      final data = await _repository.getVendorPaymentsByDate(
        token: widget.token,
        date: date,
      );

      _VendorPaymentsCache.set(data);
      _VendorPaymentIdTracker.set(data);

      setState(() {
        vendorPayments = data;
        totalPages = (vendorPayments.length / rowsPerPage).ceil();
        if (totalPages == 0) totalPages = 1;
        currentPage = 1;
      });
    } catch (e) {
      print(e);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadVendorPayments({bool forceRefresh = false}) async {
    try {
      if (mounted) {
        setState(() {
          isLoading = true;
          _isDateFiltered = false;
          _isSearchActive = false;
        });
      }

      // Only use cache when we DON'T explicitly want fresh data
      if (!forceRefresh) {
        final cached = _VendorPaymentsCache.get();

        if (cached != null && cached.isNotEmpty) {
          if (!mounted) return;

          setState(() {
            vendorPayments = List<VendorPaymentModel>.from(cached);
            totalPages = (vendorPayments.length / rowsPerPage).ceil();

            if (totalPages == 0) {
              totalPages = 1;
            }

            currentPage = 1;
            isLoading = false;
          });

          _VendorPaymentIdTracker.set(cached);
          return;
        }
      }

      // Force fresh API request
      final data = await _repository.getVendorPayments(
        token: widget.token,
      );

      // Replace cache with latest server data
      _VendorPaymentsCache.set(data);
      _VendorPaymentIdTracker.set(data);

      if (!mounted) return;

      setState(() {
        vendorPayments = data;
        totalPages = (vendorPayments.length / rowsPerPage).ceil();

        if (totalPages == 0) {
          totalPages = 1;
        }

        currentPage = 1;
      });
    } catch (e) {
      debugPrint("❌ Load vendor payments error: $e");
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _searchVendorPayments(String keyword) async {
    try {
      setState(() {
        isLoading = true;
        _isSearchActive = true;
        _isDateFiltered = false;
      });

      final data = await _repository.searchVendorPayments(
        token: widget.token,
        search: keyword,
      );

      setState(() {
        vendorPayments = data;
        totalPages = (vendorPayments.length / rowsPerPage).ceil();
        if (totalPages == 0) totalPages = 1;
        currentPage = 1;
      });
    } catch (e) {
      print(e);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _stopAutoRefresh();
    searchController.dispose();
    _datevendorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: TopBar(
        token: widget.token,
        pin: widget.pin,
        restaurantId: widget.restaurantId,
        restaurantName: widget.restaurantName,
        userPermissions: _userPermissions,
        isHomeScreen: false,
        onPermissionsReceived: (permissions) {
          setState(() {
            _userPermissions = permissions;

            if (_userPermissions?.canDefaultLayout == 'gridCommonImage') {
              _currentViewMode = ViewMode.gridCommonImage;
            } else {
              _currentViewMode = ViewMode.normal;
            }
          });
        },
      ),
      backgroundColor:
      isDark ? const Color(0xFF161A26) : const Color(0xFFF6F6F6),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF202433) : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color:
                        isDark
                            ? Colors.black.withOpacity(.45)
                            : const Color(0x3F474747),
                        blurRadius: 10,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Header Row
                      Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Row(
                          children: [
                            Text(
                              'Vendor Management',
                              style: TextStyle(
                                color:
                                isDark
                                    ? Colors.white
                                    : const Color(0xFF3D3D3D),
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              width: 300,
                              height: 40,
                              decoration: ShapeDecoration(
                                color:
                                isDark
                                    ? const Color(0xFF2B3042)
                                    : Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color:
                                    isDark
                                        ? Colors.white24
                                        : Colors.transparent,
                                  ),
                                ),
                                shadows: [
                                  BoxShadow(
                                    color:
                                    isDark
                                        ? Colors.black.withOpacity(.35)
                                        : const Color(0x4204347F),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: TextField(
                                controller: searchController,
                                cursorColor:
                                isDark ? Colors.white : Colors.black,

                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.only(
                                    left: 16,
                                    right: 16,
                                    top: 4,
                                    bottom:
                                    6, // moves hint/text slightly upward
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.search,
                                    color: Colors.black,
                                  ),
                                  hintText: "Search by name or phone number",
                                  hintStyle: TextStyle(
                                    color:
                                    isDark
                                        ? Colors.white54
                                        : const Color(0xFFC3C2C2),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500, // hint weight
                                  ),
                                ),
                                onChanged: (value) {
                                  if (value.trim().isEmpty) {
                                    _loadVendorPayments();
                                  } else {
                                    _searchVendorPayments(value.trim());
                                  }
                                },
                              ),
                            ),

                            const SizedBox(width: 20),

                            /// Date
                            SizedBox(
                              width: 180,
                              height: 40,
                              child: Container(
                                decoration: BoxDecoration(
                                  color:
                                  isDark
                                      ? const Color(0xFF12171E)
                                      : Colors.white,
                                  border: Border.all(
                                    color:
                                    isDark
                                        ? const Color(0xFF374151)
                                        : Colors.grey.shade300,
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow:
                                  isDark
                                      ? [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(
                                        0.35,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                      : const [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: TextField(
                                  controller: _datevendorController,
                                  readOnly: true,
                                  textAlignVertical: TextAlignVertical.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color:
                                    isDark
                                        ? Colors.white
                                        : const Color(0xFF111827),
                                  ),
                                  onTap: () async {
                                    final pickedDate = await showDatePicker(
                                      context: context,
                                      initialDate:
                                      selectedDate ?? DateTime.now(),
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime(2030),
                                      builder: (context, child) {
                                        return Theme(
                                          data: Theme.of(context).copyWith(
                                            colorScheme:
                                            isDark
                                                ? const ColorScheme.dark(
                                              primary: Color(
                                                0xFFFFFFFF,
                                              ),
                                              onPrimary: Colors.black,
                                              surface: Color(
                                                0xFF1F2937,
                                              ),
                                              onSurface: Colors.white,
                                            )
                                                : Theme.of(
                                              context,
                                            ).colorScheme,
                                            dialogTheme: DialogThemeData(
                                              backgroundColor:
                                              isDark
                                                  ? const Color(0xFF1F2937)
                                                  : Colors.white,
                                            ),
                                          ),
                                          child: child!,
                                        );
                                      },
                                    );
                                    if (pickedDate != null) {
                                      setState(() {
                                        selectedDate = pickedDate;
                                        _datevendorController.text =
                                        "${pickedDate.day.toString().padLeft(2, '0')}/"
                                            "${pickedDate.month.toString().padLeft(2, '0')}/"
                                            "${pickedDate.year}";
                                      });

                                      final apiDate = DateFormat(
                                        "d MMMM, yyyy",
                                      ).format(pickedDate);
                                      await _filterVendorPaymentsByDate(
                                        apiDate,
                                      );
                                    }
                                  },
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    suffixIcon: Icon(
                                      Icons.calendar_today,
                                      size: 18,
                                      color:
                                      isDark
                                          ? Colors.white70
                                          : const Color(0xFF6B7280),
                                    ),
                                  ),
                                ),
                              ),
                            ),


                            const SizedBox(width: 16),

                            /// add payout
                            InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () async {
                                final result = await showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder:
                                      (_) => AddVendorPayoutDialog(
                                    token: widget.token,
                                  ),
                                );
                                if (result == true) {
                                  await _loadVendorPayments(forceRefresh: true);
                                }
                              },
                              child: Container(
                                width: 200,
                                height: 40,
                                decoration: ShapeDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment(0.51, 1.00),
                                    end: Alignment(0.04, -0.20),
                                    colors: [
                                      Color(0xFFFF3849),
                                      Color(0xFFFF5362),
                                    ],
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      "Add New",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),

                            /// Refresh button
                            InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: isLoading ? null : _refreshVendorPayments,
                              child: Container(
                                width: 42,
                                height: 40,
                                decoration: ShapeDecoration(
                                  color: isDark
                                      ? const Color(0xFF202433)
                                      : Colors.white,
                                  shape: RoundedRectangleBorder(
                                    side: BorderSide(
                                      width: 1,
                                      color: isDark
                                          ? const Color(0xFF4B5563)
                                          : const Color(0xFF152148),
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Center(
                                  child:
                                  isLoading
                                      ? SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color:
                                      isDark
                                          ? Colors.white
                                          : const Color(0xFF2A3558),
                                    ),
                                  )
                                      : Icon(
                                    Icons.sync,
                                    size: 22,
                                    color:
                                    isDark
                                        ? Colors.white
                                        : const Color(0xFF2A3558),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Table
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color:
                              isDark
                                  ? const Color(0xFF202433)
                                  : const Color(0xFFF2F2F2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                // Header Row
                                Container(
                                  height: 50,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF2A3558),
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(8),
                                      topRight: Radius.circular(8),
                                    ),
                                  ),
                                  child: const Row(
                                    children: [
                                      Expanded(
                                        child: Center(
                                          child: Text(
                                            'Invoice No.',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Center(
                                          child: Text(
                                            'Vendor Name',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Center(
                                          child: Text(
                                            'Date',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Center(
                                          child: Text(
                                            'Contact',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Center(
                                          child: Text(
                                            'Amount',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Center(
                                          child: Text(
                                            'Mode',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Center(
                                          child: Text(
                                            'Purpose',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Center(
                                          child: Text(
                                            'Note',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Center(
                                          child: Text(
                                            'Actions',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Data / Empty / Loading
                                Expanded(
                                  child:
                                  isLoading
                                      ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                      : vendorPayments.isEmpty
                                      ? Center(
                                    child: Text(
                                      "No Vendor Payments Found",
                                      style: TextStyle(
                                        color:
                                        isDark
                                            ? Colors.white70
                                            : Colors.black87,
                                      ),
                                    ),
                                  )
                                      : Builder(
                                    builder: (context) {
                                      final startIndex =
                                          (currentPage - 1) *
                                              rowsPerPage;
                                      final endIndex =
                                      (startIndex + rowsPerPage) >
                                          vendorPayments.length
                                          ? vendorPayments.length
                                          : (startIndex +
                                          rowsPerPage);

                                      final currentPagePayments =
                                      vendorPayments.sublist(
                                        startIndex,
                                        endIndex,
                                      );

                                      return ListView.builder(
                                        itemCount:
                                        currentPagePayments.length,
                                        itemBuilder: (context, index) {
                                          final payment =
                                          currentPagePayments[index];

                                          return _dataRow(
                                            invoiceNo:
                                            payment
                                                .invoiceNo
                                                .isEmpty
                                                ? "-"
                                                : payment.invoiceNo,
                                            vendorName:
                                            payment
                                                .vendorName
                                                .isEmpty
                                                ? "-"
                                                : payment
                                                .vendorName,
                                            date: payment.paymentDate,
                                            contact:
                                            payment.phoneNumber,
                                            amount:
                                            "$_currency${(double.tryParse(payment.amount) ?? 0.0).toStringAsFixed(2)}",
                                            mode: payment.paymentMethod,
                                            purpose:
                                            payment.purpose.isEmpty
                                                ? "-"
                                                : payment.purpose,
                                            note:
                                            payment.notes.isEmpty
                                                ? "-"
                                                : payment.notes,
                                            onEdit: () async {
                                              try {
                                                final data = await _repository
                                                    .getVendorPaymentById(
                                                  token:
                                                  widget.token,
                                                  vendorPaymentId:
                                                  payment
                                                      .vendorPaymentId,
                                                );

                                                if (!mounted) return;

                                                final result = await showDialog(
                                                  context: context,
                                                  barrierDismissible:
                                                  false,
                                                  builder:
                                                      (
                                                      _,
                                                      ) => AddVendorPayoutDialog(
                                                    token:
                                                    widget
                                                        .token,
                                                    editData: data,
                                                  ),
                                                );

                                                if (result == true) {
                                                  await _loadVendorPayments(forceRefresh: true);
                                                }
                                              } catch (e) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      e.toString(),
                                                    ),
                                                    duration:
                                                    const Duration(
                                                      seconds: 1,
                                                    ),
                                                    backgroundColor:
                                                    Colors.red,
                                                  ),
                                                );
                                              }
                                            },
                                            onDelete: () async {
                                              final confirm =
                                              await _showDeleteDialog();

                                              if (confirm == true) {
                                                await _deleteVendorPayment(
                                                  payment
                                                      .vendorPaymentId,
                                                );
                                              }
                                            },
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ),

                                // Pagination
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 8,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Total Vendor Payments: ${vendorPayments.length}",
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color:
                                          isDark
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                      ),
                                      Container(
                                        margin: const EdgeInsets.only(right: 5),
                                        decoration: BoxDecoration(
                                          color:
                                          isDark
                                              ? const Color(0xFF2B3042)
                                              : Colors.white,
                                          border: Border.all(
                                            color:
                                            isDark
                                                ? Colors.white24
                                                : const Color(0xFFEFEFEF),
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            GestureDetector(
                                              onTap:
                                              currentPage > 1
                                                  ? () {
                                                setState(() {
                                                  currentPage--;
                                                });
                                              }
                                                  : null,
                                              child: _paginationTextButton(
                                                "Previous",
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  currentPage = 1;
                                                });
                                              },
                                              child: _pageButton(
                                                1,
                                                selected: currentPage == 1,
                                              ),
                                            ),
                                            if (totalPages >= 2)
                                              GestureDetector(
                                                onTap: () {
                                                  setState(() {
                                                    currentPage = 2;
                                                  });
                                                },
                                                child: _pageButton(
                                                  2,
                                                  selected: currentPage == 2,
                                                ),
                                              ),
                                            if (totalPages >= 3)
                                              GestureDetector(
                                                onTap: () {
                                                  setState(() {
                                                    currentPage = 3;
                                                  });
                                                },
                                                child: _pageButton(
                                                  3,
                                                  selected: currentPage == 3,
                                                ),
                                              ),
                                            if (totalPages > 4)
                                              _paginationTextButton("..."),
                                            if (totalPages > 4)
                                              GestureDetector(
                                                onTap: () {
                                                  setState(() {
                                                    currentPage = totalPages;
                                                  });
                                                },
                                                child: _pageButton(
                                                  totalPages,
                                                  selected:
                                                  currentPage == totalPages,
                                                ),
                                              ),
                                            GestureDetector(
                                              onTap:
                                              currentPage < totalPages
                                                  ? () {
                                                setState(() {
                                                  currentPage++;
                                                });
                                              }
                                                  : null,
                                              child: _paginationTextButton(
                                                "Next",
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _paginationTextButton(String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2B3042) : Colors.white,
        border: Border(
          right: BorderSide(
            color: isDark ? Colors.white24 : const Color(0xFFEFEFEF),
          ),
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          color: isDark ? Colors.white70 : const Color(0xFF727272),
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _pageButton(int page, {bool selected = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 28,
      height: 32,
      decoration: BoxDecoration(
        color:
        selected
            ? const Color(0xFFFF4D20)
            : (isDark ? const Color(0xFF2B3042) : Colors.white),
        border: Border(
          right: BorderSide(
            color: isDark ? Colors.white24 : const Color(0xFFEFEFEF),
          ),
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        '$page',
        style: TextStyle(
          color:
          selected
              ? Colors.white
              : (isDark ? Colors.white70 : const Color(0xFF727272)),
          fontSize: 11,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );
  }

  Widget _dataRow({
    required String invoiceNo,
    required String vendorName,
    required String date,
    required String contact,
    required String amount,
    required String mode,
    required String purpose,
    required String note,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget cell(String text) {
      return Expanded(
        child: Container(
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isDark ? Colors.white12 : const Color(0xFFE0E0E0),
              ),
            ),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white : const Color(0xFF1D1D1D),
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      );
    }

    return Container(
      color: isDark ? const Color(0xFF2B3042) : const Color(0xFFFCFCFF),
      child: Row(
        children: [
          cell(invoiceNo),
          cell(vendorName),
          cell(date),
          cell(contact),
          cell(amount),
          cell(mode),
          cell(purpose),
          cell(note),
          Expanded(
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? Colors.white12 : const Color(0xFFE0E0E0),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: onEdit,
                    icon: Icon(
                      Icons.edit_outlined,
                      color: isDark ? const Color(0xFF4C81F1) : Colors.blue,
                      size: 20,
                    ),
                  ),
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerCell(String title, double flex) {
    return Expanded(
      flex: (flex * 10).toInt(),
      child: Container(
        height: 60,
        alignment: Alignment.center,
        decoration: const BoxDecoration(color: Color(0xFF2A3558)),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
