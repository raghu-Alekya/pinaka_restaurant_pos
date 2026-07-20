class CreateVendorPaymentRequest {
  final int vendorId;
  final String invoiceNo;
  final double amount;
  final String paymentMethod;
  final String purpose;
  final String notes;

  CreateVendorPaymentRequest({
    required this.vendorId,
    required this.invoiceNo,
    required this.amount,
    required this.paymentMethod,
    required this.purpose,
    required this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      "vendor_id": vendorId,
      "invoice_no": invoiceNo,
      "amount": amount,
      "payment_method": paymentMethod,
      "purpose": purpose,
      "notes": notes,
    };
  }
}
class VendorModel {
  final int vendorId;
  final String vendorName;
  final String phoneNumber;
  final String email;

  VendorModel({
    required this.vendorId,
    required this.vendorName,
    required this.phoneNumber,
    required this.email,
  });

  factory VendorModel.fromJson(Map<String, dynamic> json) {
    return VendorModel(
      vendorId: json["vendor_id"] ?? 0,
      vendorName: json["vendor_name"] ?? "",
      phoneNumber: json["phone_number"] ?? "",
      email: json["email"] ?? "",
    );
  }
}

class VendorPaymentModel {
  final int vendorPaymentId;
  final String vendorId;
  final String vendorName;
  final String phoneNumber;
  final String invoiceNo;
  final String amount;
  final String purpose;
  final String paymentMethod;
  final String notes;
  final String paymentDate;
  final String createdDatetime;

  VendorPaymentModel({
    required this.vendorPaymentId,
    required this.vendorId,
    required this.vendorName,
    required this.phoneNumber,
    required this.invoiceNo,
    required this.amount,
    required this.purpose,
    required this.paymentMethod,
    required this.notes,
    required this.paymentDate,
    required this.createdDatetime,
  });

  factory VendorPaymentModel.fromJson(
      Map<String, dynamic> json) {
    return VendorPaymentModel(
      vendorPaymentId: json["vendor_payment_id"] ?? 0,
      vendorId: json["vendor_id"]?.toString() ?? "",
      vendorName: json["vendor_name"] ?? "",
      phoneNumber: json["phone_number"]?.toString() ?? "",
      invoiceNo: json["invoice_no"] ?? "",
      amount: json["amount"]?.toString() ?? "0",
      purpose: json["purpose"] ?? "",
      paymentMethod: json["payment_method"] ?? "",
      notes: json["notes"] ?? "",
      paymentDate: json["payment_date"] ?? "",
      createdDatetime: json["created_datetime"] ?? "",
    );
  }
}

class VendorPaymentDetailsModel {
  final int vendorPaymentId;
  final int vendorId;
  final String vendorName;
  final String phoneNumber;
  final String invoiceNo;
  final String amount;
  final String paymentMethod;
  final String purpose;
  final String notes;

  VendorPaymentDetailsModel({
    required this.vendorPaymentId,
    required this.vendorId,
    required this.vendorName,
    required this.phoneNumber,
    required this.invoiceNo,
    required this.amount,
    required this.paymentMethod,
    required this.purpose,
    required this.notes,
  });

  factory VendorPaymentDetailsModel.fromJson(
      Map<String, dynamic> json) {
    return VendorPaymentDetailsModel(
      vendorPaymentId:
      int.tryParse(json["vendor_payment_id"].toString()) ?? 0,
      vendorId:
      int.tryParse(json["vendor_id"].toString()) ?? 0,
      vendorName: json["vendor_name"] ?? "",
      phoneNumber: json["phone_number"]?.toString() ?? "",
      invoiceNo: json["invoice_no"] ?? "",
      amount: json["amount"]?.toString() ?? "",
      paymentMethod: json["payment_method"] ?? "",
      purpose: json["purpose"] ?? "",
      notes: json["notes"] ?? "",
    );
  }
}
class VendorPaymentsResponseModel {
  final bool success;
  final int totalCount;
  final int filteredCount;
  final int todayPaymentsCount;
  final List<VendorPaymentModel> payments;

  VendorPaymentsResponseModel({
    required this.success,
    required this.totalCount,
    required this.filteredCount,
    required this.todayPaymentsCount,
    required this.payments,
  });

  factory VendorPaymentsResponseModel.fromJson(
      Map<String, dynamic> json) {
    return VendorPaymentsResponseModel(
      success: json["success"] ?? false,
      totalCount: json["total_count"] ?? 0,
      filteredCount: json["filtered_count"] ?? 0,
      todayPaymentsCount: json["today_payments_count"] ?? 0,
      payments: (json["data"] as List? ?? [])
          .map((e) => VendorPaymentModel.fromJson(e))
          .toList(),
    );
  }
}