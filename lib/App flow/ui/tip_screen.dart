import 'package:flutter/material.dart';
import 'package:pinaka_restaurant_pos/repositories/TIP_repository.dart';
import '../../models/UserPermissions.dart';
import '../../models/tip_model.dart';
import '../../utils/SessionManager.dart';
import '../widgets/top_bar.dart';
import 'home_screen.dart';
import 'dart:async';

enum ViewMode { normal, gridCommonImage }

// Cache class for Tips data
class _TipsCache {
  static final Map<String, TipsScreenModel> _cache = {};
  static final Map<String, DateTime> _lastFetchTime = {};
  static const Duration _cacheDuration = Duration(minutes: 5);

  static TipsScreenModel? get(String date) {
    if (_cache.containsKey(date) && _lastFetchTime.containsKey(date)) {
      final age = DateTime.now().difference(_lastFetchTime[date]!);
      if (age < _cacheDuration) {
        return _cache[date];
      }
    }
    return null;
  }

  static void set(String date, TipsScreenModel data) {
    _cache[date] = data;
    _lastFetchTime[date] = DateTime.now();
  }

  static bool has(String date) => _cache.containsKey(date);

  static void clear() {
    _cache.clear();
    _lastFetchTime.clear();
  }
}

//  Track last known order IDs for incremental updates
class _OrderIdTracker {
  static final Map<String, Set<int>> _orderIds = {};

  static Set<int> get(String date) => _orderIds[date] ?? {};

  static void set(String date, Set<int> ids) {
    _orderIds[date] = ids;
  }

  static Set<int> findNewOrders(String date, List<TipOrder> newOrders) {
    final existing = get(date);
    final newIds = newOrders.map((o) => o.orderId).toSet();
    return newIds.difference(existing);
  }
}

class TipsScreen extends StatefulWidget {
  final String token;
  final String pin;
  final String restaurantId;
  final String restaurantName;
  final UserPermissions? userPermissions;

  const TipsScreen({
    super.key,
    required this.token,
    required this.pin,
    required this.restaurantId,
    required this.restaurantName,
    this.userPermissions,
  });

  @override
  State<TipsScreen> createState() => _TipsScreenState();
}

class _TipsScreenState extends State<TipsScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  UserPermissions? _userPermissions;
  ViewMode _currentViewMode = ViewMode.normal;
  int currentPage = 1;
  int totalPages = 1;
  TipsScreenModel? tipsData;
  bool isLoading = false;
  final TextEditingController _datetipController = TextEditingController();
  DateTime? selectedDate;
  static const int rowsPerPage = 10;
  String _currency = "₹";
  bool _isRefreshing = false; // Sync/data refresh only
  bool _isResetting = false;  // Reset button only
  bool _hasNewTips = false;
  String _currentDate = '';
  bool _isInitialLoad = true;

  // Prevent stale responses
  int _fetchSequence = 0;

  // Auto-refresh – now more frequent for near-instant feel
  Timer? _autoRefreshTimer;
  static const Duration _autoRefreshInterval = Duration(seconds: 3);

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadPermissions();
    _loadCurrency();

    selectedDate = DateTime.now();
    _currentDate = _formatDate(selectedDate!);
    _datetipController.text = _formatDateForDisplay(selectedDate!);

    _loadTipsWithCache(_currentDate);
    _startAutoRefresh();

    _scrollController.addListener(_onScroll);
  }

  void _startAutoRefresh() {
    _stopAutoRefresh();
    _autoRefreshTimer = Timer.periodic(_autoRefreshInterval, (timer) {
      if (mounted && _currentDate.isNotEmpty) {
        _checkForNewOrders(_currentDate);
      }
    });
  }

  void _stopAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
  }

  void _onScroll() {
    if (!_scrollController.position.hasContentDimensions) return;
    if (_scrollController.position.maxScrollExtent == 0) return;

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      if (currentPage < totalPages && !isLoading) {
        setState(() {
          currentPage++;
        });
      }
    }
  }

  String _formatDate(DateTime date) {
    return "${date.year}-"
        "${date.month.toString().padLeft(2, '0')}-"
        "${date.day.toString().padLeft(2, '0')}";
  }

  String _formatDateForDisplay(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.year}";
  }

  Future<void> _loadCurrency() async {
    final currency = await SessionManager.getCurrencySymbol();
    if (mounted) {
      setState(() {
        _currency = currency ?? "₹";
      });
    }
  }
  Future<void> _refreshTipsData() async {
    if (_currentDate.isEmpty || _isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      final response = await TipssummaryRepository().getTips(
        token: widget.token,
        tipDate: _currentDate,
      );

      if (!mounted || response == null) return;

      _TipsCache.set(_currentDate, response);

      _OrderIdTracker.set(
        _currentDate,
        response.orders.map((o) => o.orderId).toSet(),
      );

      setState(() {
        tipsData = response;
        currentPage = 1;
        _updatePagination();
      });
    } catch (e) {
      debugPrint('❌ Error refreshing tips data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
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

  // ✅ Cache + sequence + _currentDate always in sync
  Future<void> _loadTipsWithCache(
      String date, {
        bool forceRefresh = false,
      }) async {
    final int mySequence = ++_fetchSequence;
    _currentDate = date;

    if (!forceRefresh) {
      final cachedData = _TipsCache.get(date);
      if (cachedData != null) {
        if (mounted) {
          setState(() {
            tipsData = cachedData;
            _updatePagination();
            _isInitialLoad = false;
            _isRefreshing = false;
            isLoading = false;
            _OrderIdTracker.set(
              date,
              cachedData.orders.map((o) => o.orderId).toSet(),
            );
          });
        }
        debugPrint(
          "✅ Loaded from cache for $date. Orders: ${cachedData.orders.length}",
        );
        return;
      }
    }

    if (isLoading && !forceRefresh) return;

    setState(() {
      isLoading = true;
      _isRefreshing = forceRefresh;
    });

    try {
      final response = await TipssummaryRepository().getTips(
        token: widget.token,
        tipDate: date,
      );

      if (mySequence != _fetchSequence) return;

      if (response != null && mounted) {
        _TipsCache.set(date, response);
        _OrderIdTracker.set(
          date,
          response.orders.map((o) => o.orderId).toSet(),
        );

        setState(() {
          tipsData = response;
          _updatePagination();
          _isInitialLoad = false;
          _isRefreshing = false;
          isLoading = false;
        });
        debugPrint(
          "🔄 Fetched from API for $date. Orders: ${response.orders.length}",
        );
      }
    } catch (e) {
      debugPrint("❌ Error fetching tips: $e");
      if (mounted) {
        setState(() {
          _isInitialLoad = false;
          _isRefreshing = false;
          isLoading = false;
        });
      }
    }
  }

  void _updatePagination() {
    if (tipsData != null) {
      totalPages = (tipsData!.orders.length / rowsPerPage).ceil();
      if (totalPages == 0) totalPages = 1;
      if (currentPage > totalPages) currentPage = 1;
    }
  }

  // ✅ IMPROVED – new tips appear instantly without manual refresh
  Future<void> _checkForNewOrders(String date) async {
    // Allow background check even if a short loading state exists
    if (tipsData == null) return;

    try {
      final response = await TipssummaryRepository().getTips(
        token: widget.token,
        tipDate: date,
      );

      if (response == null || !mounted) return;

      final newOrderIds = _OrderIdTracker.findNewOrders(date, response.orders);

      if (newOrderIds.isEmpty) return;

      debugPrint("🆕 Found ${newOrderIds.length} new tip(s)!");

      final existingData = _TipsCache.get(date) ?? tipsData;
      if (existingData == null) return;

      final existingIds = existingData.orders.map((o) => o.orderId).toSet();

      final newOrders =
      response.orders
          .where((o) => !existingIds.contains(o.orderId))
          .toList();

      if (newOrders.isEmpty) return;

      // Newest first
      final updatedOrders = [...newOrders, ...existingData.orders];

      final newTotalTip = updatedOrders.fold<double>(
        0.0,
            (sum, order) => sum + order.orderTipAmt,
      );

      final updatedData = TipsScreenModel(
        orders: updatedOrders,
        totalTipAmt: newTotalTip,
        date: date,
      );

      // Update cache + tracker
      _TipsCache.set(date, updatedData);
      _OrderIdTracker.set(date, updatedOrders.map((o) => o.orderId).toSet());

      // Only update UI when this is the currently viewed date
      if (date == _currentDate && mounted) {
        setState(() {
          tipsData = updatedData;
          currentPage = 1; // force first page so new tips are visible
          _updatePagination();
        });

        // Scroll to top so user sees the new entries immediately
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(0);
        }

        _showNewOrderNotification(newOrders.length);
      }
    } catch (e) {
      debugPrint("❌ Error checking for new orders: $e");
    }
  }

  void _showNewOrderNotification(int newOrderCount) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.notifications_active, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$newOrderCount new tip${newOrderCount > 1 ? 's' : ''} received!',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // Manual refresh (force)
  void refreshTips() {
    if (_currentDate.isNotEmpty) {
      _loadTipsWithCache(_currentDate, forceRefresh: true);
    }
  }

  void addNewOrders(String date, List<TipOrder> newOrders) {
    if (!mounted || date != _currentDate) return;

    final existingData = _TipsCache.get(date) ?? tipsData;
    if (existingData == null) return;

    final existingIds = existingData.orders.map((o) => o.orderId).toSet();
    final filteredNew =
    newOrders.where((o) => !existingIds.contains(o.orderId)).toList();

    if (filteredNew.isEmpty) return;

    final updatedOrders = [...filteredNew, ...existingData.orders];
    final newTotalTip = updatedOrders.fold<double>(
      0.0,
          (sum, order) => sum + order.orderTipAmt,
    );

    final updatedData = TipsScreenModel(
      orders: updatedOrders,
      totalTipAmt: newTotalTip,
      date: date,
    );

    _TipsCache.set(date, updatedData);
    _OrderIdTracker.set(date, updatedOrders.map((o) => o.orderId).toSet());

    setState(() {
      tipsData = updatedData;
      currentPage = 1;
      _updatePagination();
    });

    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }

    _showNewOrderNotification(filteredNew.length);
    setState(() {
      _hasNewTips = true;
    });
  }

  @override
  void dispose() {
    _datetipController.dispose();
    _stopAutoRefresh();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final int totalOrders = tipsData?.orders.length ?? 0;

    return Scaffold(
      backgroundColor:
      isDark ? const Color(0xFF161A26) : const Color(0xFFF6F6F6),
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: ShapeDecoration(
            color: isDark ? const Color(0xFF202433) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            shadows: [
              BoxShadow(
                color:
                isDark
                    ? Colors.black.withOpacity(0.35)
                    : const Color(0x3F474747),
                blurRadius: 10,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            children: [
              /// Header
              Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      'Tips',
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF1D1D1D),
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),

                    /// Date picker
                    SizedBox(
                      width: 180,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          color:
                          isDark ? const Color(0xFF12171E) : Colors.white,
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
                              color: Colors.black.withOpacity(0.35),
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
                          controller: _datetipController,
                          readOnly: true,
                          textAlignVertical: TextAlignVertical.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color:
                            isDark ? Colors.white : const Color(0xFF111827),
                          ),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme:
                                    isDark
                                        ? const ColorScheme.dark(
                                      primary: Color(0xFFFFFFFF),
                                      onPrimary: Colors.black,
                                      surface: Color(0xFF1F2937),
                                      onSurface: Colors.white,
                                    )
                                        : Theme.of(context).colorScheme,
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

                            if (picked != null) {
                              final newDate = _formatDate(picked);

                              setState(() {
                                selectedDate = picked;
                                _datetipController.text = _formatDateForDisplay(
                                  picked,
                                );
                                currentPage = 1;
                                _currentDate = newDate;
                              });

                              await _loadTipsWithCache(newDate);
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

                    /// Refresh Button
                    /// RESET Button
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                        _hasNewTips
                            ? Colors.red
                            : (isDark
                            ? const Color(0xFF374151)
                            : const Color(0xFFFDF8F8)),
                        foregroundColor:
                        _hasNewTips
                            ? Colors.white
                            : (isDark ? Colors.white70 : Colors.grey[700]),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 18,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color:
                            isDark
                                ? Colors.grey.shade600
                                : Colors.grey.shade300,
                          ),
                        ),
                      ),

                      // IMPORTANT: Reset uses _isResetting
                      onPressed: _isResetting
                          ? null
                          : () async {
                        setState(() {
                          _isResetting = true;

                          // Reset new-tip indicator
                          _hasNewTips = false;

                          // Reset date to today
                          final today = DateTime.now();

                          selectedDate = today;
                          _currentDate = _formatDate(today);
                          _datetipController.text =
                              _formatDateForDisplay(today);

                          // Reset pagination
                          currentPage = 1;
                        });

                        try {
                          await _loadTipsWithCache(
                            _currentDate,
                            forceRefresh: true,
                          );
                        } finally {
                          if (mounted) {
                            setState(() {
                              _isResetting = false;
                            });
                          }
                        }
                      },

                      icon:
                      _isResetting
                          ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : Icon(
                        Icons.refresh,
                        size: 16,
                        color:
                        _hasNewTips
                            ? Colors.white
                            : (isDark
                            ? Colors.white70
                            : Colors.grey[700]),
                      ),

                      label: Text(
                        "Reset",
                        style: TextStyle(
                          fontSize: 14,
                          color:
                          _hasNewTips
                              ? Colors.white
                              : (isDark
                              ? Colors.white70
                              : Colors.grey[700]),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    /// Total Tip
                    Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: ShapeDecoration(
                        color:
                        isDark
                            ? const Color(0xFF2B3042)
                            : const Color(0xFFF6F8FF),
                        shape: RoundedRectangleBorder(
                          side: const BorderSide(
                            width: 1,
                            color: Color(0xFF415F9F),
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        shadows: const [
                          BoxShadow(
                            color: Color(0x19000000),
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Text(
                            "Total tip:",
                            style: TextStyle(
                              fontSize: 12,
                              color:
                              isDark
                                  ? Colors.white70
                                  : const Color(0xFF383838),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "$_currency ${tipsData?.totalTipAmt.toStringAsFixed(2) ?? '0.00'}",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color:
                              isDark
                                  ? const Color(0xFF498FFF)
                                  : const Color(0xFF022A7E),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    /// REFRESH DATA Button
                    Container(
                      width: 40,
                      height: 40,
                      clipBehavior: Clip.antiAlias,
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
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),

                          // Only _isRefreshing controls this button
                          onTap: _isRefreshing
                              ? null
                              : _refreshTipsData,

                          child: Center(
                            child:
                            _isRefreshing
                                ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF152148),
                              ),
                            )
                                : Icon(
                              Icons.sync,
                              size: 22,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF152148),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              /// Table area
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 3,
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color:
                      isDark
                          ? const Color(0xFF202433)
                          : const Color(0xFFF2F2F2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        /// Column headers
                        Container(
                          height: 45,
                          decoration: BoxDecoration(
                            color:
                            isDark
                                ? const Color(0xFF2B4267)
                                : const Color(0xFF2A3558),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(8),
                              topRight: Radius.circular(8),
                            ),
                          ),
                          child: const Row(
                            children: [
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
                                    'Order ID',
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
                                    'Order Value',
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
                                    'Tip Amount',
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

                        /// Content
                        Expanded(child: _buildContent(isDark)),

                        /// Pagination
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Total Orders: $totalOrders",
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),

                              Container(
                                margin: const EdgeInsets.only(right: 5),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(
                                    color: const Color(0xFFEFEFEF),
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    GestureDetector(
                                      onTap: currentPage > 1
                                          ? () {
                                        setState(() {
                                          currentPage--;
                                        });
                                      }
                                          : null,
                                      child: _paginationTextButton("Previous"),
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
                                          selected: currentPage == totalPages,
                                        ),
                                      ),

                                    GestureDetector(
                                      onTap: currentPage < totalPages
                                          ? () {
                                        setState(() {
                                          currentPage++;
                                        });
                                      }
                                          : null,
                                      child: _paginationTextButton("Next"),
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
    );
  }

  Widget _buildContent(bool isDark) {
    // Same clean loading style as OrdersListTable
    if (_isRefreshing || ((_isInitialLoad || isLoading) && tipsData == null)) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF918E8C),
        ),
      );
    }
    if (tipsData == null || tipsData!.orders.isEmpty) {
      return Center(
        child: Text(
          'No tips data available',
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.white70 : Colors.grey,
          ),
        ),
      );
    }

    return _buildOptimizedListView(isDark);
  }

  Widget _buildOptimizedListView(bool isDark) {
    if (tipsData == null) return const SizedBox.shrink();

    final startIndex = (currentPage - 1) * rowsPerPage;
    final endIndex =
    (startIndex + rowsPerPage) > tipsData!.orders.length
        ? tipsData!.orders.length
        : (startIndex + rowsPerPage);

    if (startIndex >= tipsData!.orders.length) {
      return const SizedBox.shrink();
    }

    final currentPageOrders = tipsData!.orders.sublist(startIndex, endIndex);

    return ListView.builder(
      controller: _scrollController,
      key: PageStorageKey<String>('tips_list_${_currentDate}_$currentPage'),
      padding: const EdgeInsets.only(bottom: 8),
      itemCount: currentPageOrders.length,
      itemBuilder: (context, index) {
        final tip = currentPageOrders[index];
        final globalIndex = startIndex + index;

        return RepaintBoundary(
          key: ValueKey('tip_${tip.orderId}_$globalIndex'),
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2B3042) : const Color(0xFFFCFCFF),
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.white12 : const Color(0xFFE0E0E0),
                ),
              ),
              borderRadius:
              index == currentPageOrders.length - 1
                  ? const BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              )
                  : BorderRadius.zero,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Center(
                    child: Text(
                      tip.orderDate,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white : const Color(0xFF3D3D3D),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      '${tip.orderId}',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white : const Color(0xFF3D3D3D),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      "$_currency${tip.orderAmt.toStringAsFixed(2)}",
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white : const Color(0xFF3D3D3D),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      "$_currency${tip.orderTipAmt.toStringAsFixed(2)}",
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white : const Color(0xFF3D3D3D),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  Widget _paginationTextButton(String text) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        border: Border(
          right: BorderSide(
            color: Color(0xFFEFEFEF),
          ),
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF727272),
          fontSize: 11,
        ),
      ),
    );
  }
  Widget _pageButton(
      int page, {
        bool selected = false,
      }) {
    return Container(
      width: 28,
      height: 32,
      decoration: BoxDecoration(
        color: selected
            ? const Color(0xFFFF4D20)
            : Colors.white,
        border: const Border(
          right: BorderSide(
            color: Color(0xFFEFEFEF),
          ),
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        '$page',
        style: TextStyle(
          color: selected
              ? Colors.white
              : const Color(0xFF727272),
          fontSize: 11,
          fontWeight:
          selected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );
  }
}
