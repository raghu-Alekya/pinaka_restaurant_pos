import 'package:flutter/material.dart';
import 'package:pinaka_restaurant_pos/repositories/TIP_repository.dart';
import '../../models/UserPermissions.dart';
import '../../models/tip_model.dart';
// import '../../models/tips/tips_screen_model.dart';
// import '../../repositories/tips_repository/tips_screen_repository.dart';
import '../../utils/SessionManager.dart';
import '../widgets/top_bar.dart';
import 'home_screen.dart';

enum ViewMode { normal, gridCommonImage }

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

class _TipsScreenState extends State<TipsScreen> {
  UserPermissions? _userPermissions;
  ViewMode _currentViewMode = ViewMode.normal;
  int currentPage = 1;
  int totalPages = 1; // API count
  TipsScreenModel? tipsData;
  bool isLoading = false;
  final TextEditingController _datetipController = TextEditingController();
  DateTime? selectedDate;
  static const int rowsPerPage = 10;
  String _currency = "₹";
  @override
  void initState() {
    super.initState();
    _loadPermissions();
    _loadCurrency();

    selectedDate = DateTime.now();

    _datetipController.text =
    "${selectedDate!.day.toString().padLeft(2, '0')}/"
        "${selectedDate!.month.toString().padLeft(2, '0')}/"
        "${selectedDate!.year}";

    fetchTips(
      "${selectedDate!.year}-"
          "${selectedDate!.month.toString().padLeft(2, '0')}-"
          "${selectedDate!.day.toString().padLeft(2, '0')}",
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
  Future<void> fetchTips(String date) async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await TipssummaryRepository().getTips(
        token: widget.token,
        tipDate: date,
      );

      setState(() {
        tipsData = response;

        totalPages =
            (response!.orders.length / rowsPerPage).ceil();

        if (totalPages == 0) {
          totalPages = 1;
        }

        currentPage = 1;
      });
      debugPrint(
        "Orders Count: ${response?.orders.length}",
      );
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
  @override
  void dispose() {
    _datetipController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final int totalOrders = tipsData?.orders.length ?? 0;
    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF161A26)
          : const Color(0xFFF6F6F6),
      appBar: TopBar(
        token: widget.token,
        pin: widget.pin,restaurantId: widget.restaurantId,
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
        padding: const EdgeInsets.all(16.0), //  space from all sides
        child: Container(
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: ShapeDecoration(
            color: isDark
                ? const Color(0xFF202433)
                : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            shadows: [
              BoxShadow(
                color: isDark
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

                    /// Date
                    SizedBox(
                      width: 180,
                      height: 40,
                      child: Container(
                        decoration: ShapeDecoration(
                          color: isDark
                              ? const Color(0xFF2B3042)
                              : const Color(0xFFF0F0F0),
                          shape: RoundedRectangleBorder(
                            side: const BorderSide(
                              width: 1,
                              color: Color(0xFFA5A5A5),
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
                        child: TextField(
                          controller: _datetipController,
                          readOnly: true,
                          textAlignVertical: TextAlignVertical.center,
                          style:  TextStyle(
                            color: isDark
                                ? Colors.white70
                                : const Color(0xFF7E7E7E),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );

                            if (picked != null) {
                              setState(() {
                                selectedDate = picked;
                                _datetipController.text =
                                "${picked.day.toString().padLeft(2, '0')}/"
                                    "${picked.month.toString().padLeft(2, '0')}/"
                                    "${picked.year}";
                              });

                              await fetchTips(
                                "${picked.year}-"
                                    "${picked.month.toString().padLeft(2, '0')}-"
                                    "${picked.day.toString().padLeft(2, '0')}",
                              );
                            }
                          },
                          decoration:  InputDecoration(
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            suffixIcon: Icon(
                              Icons.calendar_month,
                              size: 20,
                              color: isDark
                                  ? Colors.white70
                                  : const Color(0xFF6D6D6D),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    /// Total Tip
                    Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: ShapeDecoration(
                          color: isDark
                              ? const Color(0xFF2B3042)
                              : const Color(0xFFF6F8FF),
                          shape: RoundedRectangleBorder(
                            side: BorderSide(
                              width: 1,
                              color: const Color(0xFF415F9F),
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          shadows: [
                            BoxShadow(
                              color: Color(0x19000000),
                              blurRadius: 4,
                              offset: Offset(0, 1),
                              spreadRadius: 0,
                            )
                          ],
                        ),
                        child: Row(
                          children: [
                             Text(
                              "Total tip:",
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white70 : const Color(0xFF383838),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "$_currency ${tipsData?.totalTipAmt.toStringAsFixed(2) ?? '0.00'}",
                              // "₹ ${tipsData?.totalTipAmt.toStringAsFixed(2) ?? '0.00'}",
                              style:  TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? const Color(0xFF498FFF)
                                    : const Color(0xFF022A7E),
                              ),
                            ),
                          ],
                        )
                    ),
                  ],
                ),
              ),

              /// Remaining screen content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF202433)
                          : const Color(0xFFF2F2F2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        /// Header
                        Container(
                          height: 45,
                          decoration: BoxDecoration(
                            color: isDark
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

                        Expanded(
                          child: isLoading
                              ? const Center(
                            child: CircularProgressIndicator(),
                          )
                              : tipsData == null || tipsData!.orders.isEmpty
                              ? Center(
                            child: Text(
                              'No tips data available',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark
                                    ? Colors.white70
                                    : Colors.grey,
                              ),
                            ),
                          )
                              : Builder(
                            builder: (context) {
                              final startIndex =
                                  (currentPage - 1) * rowsPerPage;

                              final endIndex =
                              (startIndex + rowsPerPage) >
                                  tipsData!.orders.length
                                  ? tipsData!.orders.length
                                  : (startIndex + rowsPerPage);

                              final currentPageOrders =
                              tipsData!.orders.sublist(
                                startIndex,
                                endIndex,
                              );

                              return ListView.builder(
                                padding:
                                const EdgeInsets.only(bottom: 8),
                                itemCount: currentPageOrders.length,
                                itemBuilder: (context, index) {
                                  final tip = currentPageOrders[index];

                                  return Container(
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(0xFF2B3042)
                                          : const Color(0xFFFCFCFF),
                                      border: Border(
                                        bottom: BorderSide(
                                          color: isDark
                                              ? Colors.white12
                                              : const Color(0xFFE0E0E0),
                                        ),
                                      ),
                                      borderRadius: index ==
                                          currentPageOrders.length -
                                              1
                                          ? const BorderRadius.only(
                                        bottomLeft:
                                        Radius.circular(8),
                                        bottomRight:
                                        Radius.circular(8),
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
                                                color: isDark
                                                    ? Colors.white
                                                    : const Color(
                                                    0xFF3D3D3D),
                                                fontWeight:
                                                FontWeight.w500,
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
                                                color: isDark
                                                    ? Colors.white
                                                    : const Color(
                                                    0xFF3D3D3D),
                                                fontWeight:
                                                FontWeight.w500,
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
                                                color: isDark
                                                    ? Colors.white
                                                    : const Color(
                                                    0xFF3D3D3D),
                                                fontWeight:
                                                FontWeight.w500,
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
                                                color: isDark
                                                    ? Colors.white
                                                    : const Color(
                                                    0xFF3D3D3D),
                                                fontWeight:
                                                FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 8),
                          child: Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Total Orders: $totalOrders",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                              Container(
                                margin:
                                const EdgeInsets.only(right: 5),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF2B3042)
                                      : Colors.white,
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.white24
                                        : const Color(0xFFEFEFEF),
                                  ),
                                  borderRadius:
                                  BorderRadius.circular(4),
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
                                      child:
                                      _paginationTextButton(context,"Previous"),
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
                                      _paginationTextButton(context,"..."),
                                    if (totalPages > 4)
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            currentPage =
                                                totalPages;
                                          });
                                        },
                                        child: _pageButton(
                                          totalPages,
                                          selected: currentPage ==
                                              totalPages,
                                        ),
                                      ),
                                    GestureDetector(
                                      onTap: currentPage <
                                          totalPages
                                          ? () {
                                        setState(() {
                                          currentPage++;
                                        });
                                      }
                                          : null,
                                      child: _paginationTextButton(context,"Next"),
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
              )
            ],
          ),
        ),
      ),
    );
  }
  Widget _paginationTextButton(BuildContext context, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(
            color: isDark
                ? const Color(0xFF2B4267)
                : const Color(0xFFEFEFEF),
          ),
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          color: isDark
              ? Colors.white
              : const Color(0xFF727272),
          fontSize: 11,
        ),
      ),
    );
  }
  Widget _pageButton(
      int page, {
        bool selected = false,
      }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 28,
      height: 32,
      decoration: BoxDecoration(
        color: selected
            ? const Color(0xFFFF4D20)
            : (isDark ? const Color(0xFF2B4267) : Colors.white),
        border: Border(
          right: BorderSide(
            color: isDark
                ? const Color(0xFF2B4267)
                : const Color(0xFFEFEFEF),
          ),
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        '$page',
        style: TextStyle(
          color: selected
              ? Colors.white
              : (isDark ? Colors.white : const Color(0xFF727272)),
          fontSize: 11,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );
  }
}