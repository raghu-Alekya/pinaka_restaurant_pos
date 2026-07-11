import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/vendor_payment_model.dart';
import '../../repositories/vendor_payment_repository.dart';

// import '../../models/vendor_payments_model.dart';
// import '../../repositories/vendor_payments_repository.dart';

class AddVendorPayoutDialog extends StatefulWidget {
  final String token;
  final VendorPaymentDetailsModel? editData;
  const AddVendorPayoutDialog({super.key,required this.token, this.editData,});

  @override
  State<AddVendorPayoutDialog> createState() =>
      _AddVendorPayoutDialogState();
}

class _AddVendorPayoutDialogState extends State<AddVendorPayoutDialog> {
  // String? selectedVendor;
  String? selectedPurpose = 'Purchase';
  String? selectedPaymentMode = 'Cash';
  final VendorPaymentRepository _repository =
  VendorPaymentRepository();

  bool isLoading = false;
  List<Map<String, dynamic>> vendors = [];

  int? selectedVendorId;
  final TextEditingController dateController =
  TextEditingController();
  final TextEditingController invoiceController =
  TextEditingController();
  final TextEditingController amountController =
  TextEditingController();
  final TextEditingController notesController =
  TextEditingController();

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF0A0A0A),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
  @override
  void initState() {
    super.initState();
    // for updating the date in the date field
    final today = DateTime.now();

    dateController.text =
    "${today.day.toString().padLeft(2, '0')}/"
        "${today.month.toString().padLeft(2, '0')}/"
        "${today.year}";
    //  editing the existing data
    if (widget.editData != null) {
      invoiceController.text =
          widget.editData!.invoiceNo;

      amountController.text =
          widget.editData!.amount;

      notesController.text =
          widget.editData!.notes;

      selectedPurpose =
          widget.editData!.purpose;

      selectedPaymentMode =
          widget.editData!.paymentMethod;

      selectedVendorId = widget.editData!.vendorId;
    }
    _loadVendors();
  }

  Future<void> _loadVendors() async {
    try {
      final result = await _repository.getVendors(
        token: widget.token,
      );

      setState(() {
        vendors = List<Map<String, dynamic>>.from(result["vendors"]);
      });
    } catch (e) {
      print("Vendor Load Error: $e");
    }
  }
  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFF717182),
        fontSize: 14,
      ),
      filled: true,
      fillColor: const Color(0xFFF3F3F5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 12,
      ),
    );
  }
  Future<void> _saveVendorPayment() async {
    if (selectedVendorId == null){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a vendor"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (selectedPurpose == null || selectedPurpose!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select purpose"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (amountController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter amount"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (selectedPaymentMode == null ||
        selectedPaymentMode!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select payment mode"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    try {
      setState(() {
        isLoading = true;
      });

      print("TOKEN:");
      print(widget.token);
      Map<String, dynamic> response;

      if (widget.editData == null) {
        response = await _repository.createVendorPayment(
          token: widget.token,
          vendorId: selectedVendorId!,
          invoiceNo: invoiceController.text.trim(),
          amount: double.tryParse(amountController.text.trim()) ?? 0,
          paymentMethod: selectedPaymentMode!,
          purpose: selectedPurpose!,
          notes: notesController.text.trim(),
        );
      } else {
        response = await _repository.updateVendorPayment(
          token: widget.token,
          vendorPaymentId: widget.editData!.vendorPaymentId,
          vendorId: selectedVendorId!,
          invoiceNo: invoiceController.text.trim(),
          amount: double.tryParse(amountController.text.trim()) ?? 0,
          paymentMethod: selectedPaymentMode!,
          purpose: selectedPurpose!,
          notes: notesController.text.trim(),
        );
      }
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response["message"]?.toString() ??
                "Vendor payment created successfully",
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceAll("Exception: ", ""),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 780,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.black.withOpacity(0.10),
            width: 0.8,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x19000000),
              blurRadius: 6,
              offset: Offset(0, 4),
              spreadRadius: -4,
            ),
            BoxShadow(
              color: Color(0x19000000),
              blurRadius: 15,
              offset: Offset(0, 10),
              spreadRadius: -3,
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Text(
                widget.editData == null
                    ? "Add Vendor Payout"
                    : "Edit Vendor Payout",
                style: const TextStyle(
                  color: Color(0xFF1E2939),
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 28),

              /// Row 1
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        _label("Select Vendor *"),
                        DropdownButtonFormField<int>(
                          value: selectedVendorId,
                          dropdownColor: const Color(0xFFF3F3F5),
                          decoration: _fieldDecoration("Vendor"),
                          items: vendors.map((vendor) {
                            return DropdownMenuItem<int>(
                              value: vendor["vendor_id"],
                              child: Text(vendor["vendor_name"] ?? ""),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedVendorId = value;
                            });
                          },
                        )
                      ],
                    ),
                  ),

                  const SizedBox(width: 20),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        _label("Date *"),
                        TextFormField(
                          controller: dateController,
                          readOnly: true,
                          decoration: _fieldDecoration(
                            "Select Date",
                          ).copyWith(
                            suffixIcon: const Icon(
                              Icons.calendar_month,
                              color: Color(0xFF7D7D7D),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 20),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        _label("Invoice No."),
                        TextFormField(
                          controller: invoiceController,
                          decoration: _fieldDecoration(
                            "Invoice number",
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              /// Row 2
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        _label("Purpose *"),
                        DropdownButtonFormField<String>(
                          value: selectedPurpose,
                          dropdownColor:
                          const Color(0xFFF3F3F5),
                          decoration:
                          _fieldDecoration("Purpose"),
                          items: const [
                            DropdownMenuItem(
                              value: "Purchase",
                              child: Text("Purchase"),
                            ),
                            DropdownMenuItem(
                              value: "Expenses",
                              child: Text("Expenses"),
                            ),

                          ],
                          onChanged: (value) {
                            setState(() {
                              selectedPurpose = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 20),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        _label("Amount (₹) *"),
                        TextFormField(
                          controller: amountController,
                          keyboardType:
                          TextInputType.number,
                          decoration:
                          _fieldDecoration("0.00"),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 20),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        _label("Payment Mode *"),
                        DropdownButtonFormField<String>(
                          value: selectedPaymentMode,
                          dropdownColor:
                          const Color(0xFFF3F3F5),
                          decoration:
                          _fieldDecoration("Cash"),
                          items: const [
                            DropdownMenuItem(
                              value: "Cash",
                              child: Text("Cash"),
                            ),
                            DropdownMenuItem(
                              value: "UPI",
                              child: Text("UPI"),
                            ),
                            DropdownMenuItem(
                              value: "Bank Transfer",
                              child:
                              Text("Bank Transfer"),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              selectedPaymentMode = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              /// Notes
              Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  _label("Notes"),
                  TextFormField(
                    controller: notesController,
                    maxLines: 2,
                    decoration: _fieldDecoration(
                      "Optional payment notes",
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              /// Buttons
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 45,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style:
                        OutlinedButton.styleFrom(
                          backgroundColor:
                          Colors.white,
                          side: BorderSide(
                            color: Colors.black
                                .withOpacity(0.10),
                          ),
                          shape:
                          RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(
                                8),
                          ),
                        ),
                        child: const Text(
                          "Cancel",
                          style: TextStyle(
                            color: Color(0xFF0A0A0A),
                            fontSize: 16,
                            fontWeight:
                            FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 20),

                  Expanded(
                    child: SizedBox(
                      height: 45,
                      child: ElevatedButton(
                        onPressed: isLoading
                            ? null
                            : () async {
                          await _saveVendorPayment();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00A63E),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            :  Text(
                          widget.editData == null ? "Save" : "Update",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}