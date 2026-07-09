import 'package:flutter/material.dart';

import '../../models/UserPermissions.dart';

import '../../models/vendor_payment_model.dart';
import '../../repositories/vendor_payment_repository.dart';
import '../../utils/SessionManager.dart';
import '../widgets/top_bar.dart';
import '../widgets/widget_add_vendor_payouts.dart';
import 'home_screen.dart';

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
  bool hasData = false; // change to true when API returns data
  final VendorPaymentRepository _repository =
  VendorPaymentRepository();

  List<VendorPaymentModel> vendorPayments = [];
  bool isLoading = false;
  final TextEditingController searchController =
  TextEditingController();
  final TextEditingController _datevendorController = TextEditingController();
  DateTime? selectedDate;
  int currentPage = 1;
  int totalPages = 1;
  static const int rowsPerPage = 8;
  @override
  void initState() {
    super.initState();
    _loadVendorPayments();
    _loadPermissions();

    selectedDate = DateTime.now();

    _datevendorController.text =
    "${selectedDate!.day.toString().padLeft(2, '0')}/"
        "${selectedDate!.month.toString().padLeft(2, '0')}/"
        "${selectedDate!.year}";

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
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  "Are you sure you want to delete this vendor payment?\nThis action cannot be undone.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
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
  Future<void> _deleteVendorPayment(
      int vendorPaymentId,
      ) async {
    try {
      final response =
      await _repository.deleteVendorPayment(
        token: widget.token,
        vendorPaymentId: vendorPaymentId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response["message"] ??
                "Vendor payment deleted successfully",
          ),
          duration: Duration(seconds: 1),
          backgroundColor: Colors.green,
        ),
      );

      _loadVendorPayments();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 1),
        ),

      );
    }
  }
  Future<void> _filterVendorPaymentsByDate(
      String date,
      ) async {
    try {
      setState(() {
        isLoading = true;
      });

      final data =
      await _repository.getVendorPaymentsByDate(
        token: widget.token,
        date: date,
      );

      setState(() {
        vendorPayments = data;

        totalPages = (vendorPayments.length / rowsPerPage).ceil();

        if (totalPages == 0) {
          totalPages = 1;
        }

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
  Future<void> _loadVendorPayments() async {
    try {
      setState(() {
        isLoading = true;
      });

      final data =
      await _repository.getVendorPayments(
        token: widget.token,
      );

      setState(() {
        vendorPayments = data;

        totalPages = (vendorPayments.length / rowsPerPage).ceil();

        if (totalPages == 0) {
          totalPages = 1;
        }

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
  Future<void> _searchVendorPayments(
      String keyword,
      ) async {
    try {
      setState(() {
        isLoading = true;
      });

      final data =
      await _repository.searchVendorPayments(
        token: widget.token,
        search: keyword,
      );

      setState(() {
        vendorPayments = data;

        totalPages = (vendorPayments.length / rowsPerPage).ceil();

        if (totalPages == 0) {
          totalPages = 1;
        }

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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE4E9F9),
      body: SafeArea(
        child: Column(
          children: [
            TopBar(
              userPermissions: _userPermissions,
              isHomeScreen: false,
              restaurantId: widget.restaurantId,
              restaurantName: widget.restaurantName,
              // selectedUser: _selectedUser,
              token: widget.token,
              pin: widget.pin,
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x3F474747),
                        blurRadius: 10,
                        offset: Offset(0, 1),
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

                            // const SizedBox(width: 20),

                            const Text(
                              'Vendor Management',
                              style: TextStyle(
                                color: Color(0xFF3D3D3D),
                                fontSize: 24,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Container(
                              width: 300,
                              height: 40,
                              decoration: ShapeDecoration(
                                color: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                shadows: const [
                                  BoxShadow(
                                    color: Color(0x4204347F),
                                    blurRadius: 10,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: TextField(
                                controller: searchController,
                                cursorColor: Colors.black,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 7,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.search,
                                    color: Colors.black,
                                  ),
                                  hintText: "Search by name or phone number",
                                  hintStyle: TextStyle(
                                    color: Color(0xFFC3C2C2),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
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
                            const Spacer(),

                            /// Date
                            SizedBox(
                              width: 180,
                              height: 40,
                              child: Container(
                                decoration: ShapeDecoration(
                                  color: const Color(0xFFF0F0F0),
                                  shape: RoundedRectangleBorder(
                                    side: BorderSide(
                                      width: 1,
                                      color: const Color(0xFFA5A5A5),
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
                                child: TextField(
                                  controller:_datevendorController,
                                  readOnly: true,
                                  textAlignVertical: TextAlignVertical.center,
                                  style: const TextStyle(
                                    color: Color(0xFF7E7E7E),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  onTap: () async {
                                    final pickedDate = await showDatePicker(
                                      context: context,
                                      initialDate: selectedDate ?? DateTime.now(),
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime(2100),
                                    );

                                    if (pickedDate != null) {
                                      setState(() {
                                        selectedDate = pickedDate;

                                        _datevendorController.text =
                                        "${pickedDate.day.toString().padLeft(2, '0')}/"
                                            "${pickedDate.month.toString().padLeft(2, '0')}/"
                                            "${pickedDate.year}";
                                      });

                                      final apiDate =
                                          "${pickedDate.year}-"
                                          "${pickedDate.month.toString().padLeft(2, '0')}-"
                                          "${pickedDate.day.toString().padLeft(2, '0')}";

                                      await _filterVendorPaymentsByDate(apiDate);
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

                            /// add payout
                            InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () async {
                                final result = await showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (_) => AddVendorPayoutDialog(
                                    token: widget.token,
                                  ),
                                );

                                if (result == true) {
                                  _loadVendorPayments();
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
                            )
                          ],
                        ),
                      ),
                      //  Table header
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Color(0xFFF2F2F2),
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

                                // Empty State / Table Data
                                Expanded(
                                    child: isLoading
                                        ? const Center(
                                      child: CircularProgressIndicator(),
                                    )
                                        : vendorPayments.isEmpty
                                        ? const Center(
                                      child: Text(
                                        "No Vendor Payments Found",
                                      ),
                                    )
                                        : Builder(
                                      builder: (context) {
                                        final startIndex = (currentPage - 1) * rowsPerPage;

                                        final endIndex =
                                        (startIndex + rowsPerPage) > vendorPayments.length
                                            ? vendorPayments.length
                                            : (startIndex + rowsPerPage);

                                        final currentPagePayments =
                                        vendorPayments.sublist(startIndex, endIndex);

                                        return ListView.builder(
                                          itemCount: currentPagePayments.length,
                                          itemBuilder: (context, index) {
                                            final payment = currentPagePayments[index];

                                            return _dataRow(
                                                invoiceNo: payment.invoiceNo.isEmpty
                                                    ? "-"
                                                    : payment.invoiceNo,
                                                vendorName: payment.vendorName.isEmpty
                                                    ? "-"
                                                    : payment.vendorName,
                                                date: payment.paymentDate,
                                                contact: payment.phoneNumber,
                                                amount: "₹${(double.tryParse(payment.amount) ?? 0.0).toStringAsFixed(2)}",
                                                mode: payment.paymentMethod,
                                                purpose: payment.purpose.isEmpty
                                                    ? "-"
                                                    : payment.purpose,
                                                note: payment.notes.isEmpty
                                                    ? "-"
                                                    : payment.notes,
                                                onEdit: () async {
                                                  try {
                                                    final data =
                                                    await _repository.getVendorPaymentById(
                                                      token: widget.token,
                                                      vendorPaymentId: payment.vendorPaymentId,
                                                    );

                                                    if (!mounted) return;

                                                    final result = await showDialog(
                                                      context: context,
                                                      barrierDismissible: false,
                                                      builder: (_) => AddVendorPayoutDialog(
                                                        token: widget.token,
                                                        editData: data,
                                                      ),
                                                    );

                                                    if (result == true) {
                                                      _loadVendorPayments();
                                                    }
                                                  } catch (e) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        content: Text(e.toString()
                                                        ),
                                                        duration: Duration(seconds: 1),
                                                        backgroundColor: Colors.red,
                                                      ),

                                                    );
                                                  }
                                                },

                                                onDelete: () async {
                                                  final confirm = await _showDeleteDialog();

                                                  if (confirm == true) {
                                                    await _deleteVendorPayment(
                                                      payment.vendorPaymentId,
                                                    );
                                                  }
                                                });
                                          },
                                        );
                                      },
                                    )
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Total Vendor Payments: ${vendorPayments.length}",
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
                      )
                    ],
                  ),
                ),
              ),
            )
          ],
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
          fontWeight: selected
              ? FontWeight.w600
              : FontWeight.w400,
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
    Widget cell(String text) {
      return Expanded(
        child: Container(
          height: 50,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Color(0xFFE0E0E0),
              ),
            ),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF1D1D1D),
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      );
    }

    return Container(
      color: Color(0xFFFCFCFF),
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
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Color(0xFFE0E0E0),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: onEdit,
                    icon: const Icon(
                      Icons.edit_outlined,
                      color: Colors.blue,
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
        decoration: const BoxDecoration(
          color: Color(0xFF2A3558),
        ),
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