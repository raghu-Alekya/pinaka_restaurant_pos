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
  static const int rowsPerPage = 9;
  @override
  void initState() {
    super.initState();
    _loadPermissions();

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
    final int totalOrders = tipsData?.orders.length ?? 0;
    return Scaffold(
      backgroundColor: const Color(0xFFE4E9F9),
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
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          clipBehavior: Clip.antiAlias,
          decoration: ShapeDecoration(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            shadows: const [
              BoxShadow(
                color: Color(0x3F474747),
                blurRadius: 10,
                offset: Offset(0, 1),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            children: [
              /// Header
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (_) => HomeScreen(
                              pin: widget.pin,
                              token: widget.token,
                              restaurantId: widget.restaurantId,
                              restaurantName: widget.restaurantName,
                            ),
                          ),
                              (route) => false,
                        );
                      },
                      child: Container(
                        width: 100,
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B4259),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x19000000),
                              blurRadius: 4,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Row(
                          children: const [
                            Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Back',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),

                    const Text(
                      'Tips',
                      style: TextStyle(
                        color: Color(0xFF3D3D3D),
                        fontSize: 24,
                        fontFamily: 'Inter',
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
                          color: const Color(0xFFF0F0F0),
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
                          style: const TextStyle(
                            color: Color(0xFF7E7E7E),
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
                          decoration: const InputDecoration(
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
                              color: Color(0xFF6D6D6D),
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
                          color: const Color(0xFFF6F8FF),
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
                            const Text(
                              "Total tip:",
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF383838),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "₹ ${tipsData?.totalTipAmt.toStringAsFixed(2) ?? '0.00'}",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF022A7E),
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
                  padding: const EdgeInsets.symmetric(horizontal: 32,vertical: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Container(
                          height: 40,
                          decoration: const BoxDecoration(
                            color: Color(0xFF4260A0),
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
                              ? const Center(
                            child: Text(
                              'No tips data available',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
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
                                itemCount: currentPageOrders.length,
                                itemBuilder: (context, index) {
                                  final tip = currentPageOrders[index];

                                  return Container(
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEEEEF8),
                                      border: const Border(
                                        bottom: BorderSide(
                                          color: Color(0xFFE1E1E1),
                                        ),
                                      ),
                                      borderRadius: index == currentPageOrders.length - 1
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
                                              style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Color(0xFF3D3D3D),
                                                  fontWeight:  FontWeight.w500
                                              ),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Center(
                                            child: Text(
                                              '#${tip.orderId}',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Color(0xFF3D3D3D),
                                                fontWeight:  FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Center(
                                            child: Text(
                                              tip.orderAmt.toStringAsFixed(2),
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Color(0xFF3D3D3D),
                                                fontWeight:  FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Center(
                                            child: Text(
                                              tip.orderTipAmt.toStringAsFixed(2),
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Color(0xFF3D3D3D),
                                                fontWeight:  FontWeight.w500,
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