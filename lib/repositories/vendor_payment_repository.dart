import 'dart:convert';
import 'package:http/http.dart' as http;

import '../constants/constants.dart';
import '../models/vendor_payment_model.dart';

// import '../models/vendor_payments_model.dart';

class VendorPaymentRepository {
  static String get baseUrl =>
      "${AppConstants.baseApiPath}/vendor_payments/create-vendor-payment";
  Future<Map<String, dynamic>> createVendorPayment({
    required String token,
    required int vendorId,
    required String invoiceNo,
    required double amount,
    required String paymentMethod,
    required String purpose,
    required String notes,
  }) async {
    try {
      print("========== CREATE VENDOR PAYMENT ==========");
      print("Token: $token");

      final response = await http.post(
        Uri.parse(
          "${AppConstants.baseApiPath}/vendor_payments/create-vendor-payment",
        ),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "vendor_id": vendorId,
          "invoice_no": invoiceNo,
          "amount": amount,
          "payment_method": paymentMethod,
          "purpose": purpose,
          "notes": notes,
        }),
      );

      print("Status Code : ${response.statusCode}");
      print("Response : ${response.body}");

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 &&
          data["success"] == true) {
        return Map<String, dynamic>.from(data);
      }

      throw Exception(
        data["message"] ??
            "Failed to create vendor payment",
      );
    } catch (e) {
      print("Create Vendor Payment Error: $e");
      rethrow;
    }
  }
  Future<Map<String, dynamic>> getVendors({
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          "${AppConstants.baseApiPath}/vendor_payments/get-vendors",
        ),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data["success"] == true) {
        return {
          "vendor_count": data["vendor_count"] ?? 0,
          "vendors": List<Map<String, dynamic>>.from(data["data"]),
        };
      }

      throw Exception(data["message"] ?? "Failed to fetch vendors");
    } catch (e) {
      print("Get Vendors Error: $e");
      rethrow;
    }
  }
  Future<List<VendorPaymentModel>> getVendorPayments({
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          "${AppConstants.baseApiPath}/vendor_payments/get-vendor-payments",
        ),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      print("Vendor Payments Status: ${response.statusCode}");
      print("Vendor Payments Response: ${response.body}");

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 &&
          data["success"] == true) {
        return (data["data"] as List)
            .map(
              (e) => VendorPaymentModel.fromJson(e),
        )
            .toList();
      }

      throw Exception(
        data["message"] ??
            "Failed to fetch vendor payments",
      );
    } catch (e) {
      print("Vendor Payment Error: $e");
      rethrow;
    }
  }
  Future<VendorPaymentDetailsModel> getVendorPaymentById({
    required String token,
    required int vendorPaymentId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          "${AppConstants.baseApiPath}/vendor_payments/get-vendor-payment-by-id?vendor_payment_id=$vendorPaymentId",
        ),
        headers: {
          "Authorization": "Bearer $token",
        },
      );

      print(response.body);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 &&
          data["success"] == true) {
        return VendorPaymentDetailsModel.fromJson(
          data["data"],
        );
      }

      throw Exception(
        data["message"] ??
            "Failed to fetch vendor payment details",
      );
    } catch (e) {
      rethrow;
    }
  }
  Future<List<VendorPaymentModel>> searchVendorPayments({
    required String token,
    required String search,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          "${AppConstants.baseApiPath}/vendor_payments/get-vendor-payments?search=$search",
        ),
        headers: {
          "Authorization": "Bearer $token",
        },
      );

      print("Search Status : ${response.statusCode}");
      print("Search Response : ${response.body}");

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 &&
          data["success"] == true) {
        return (data["data"] as List)
            .map(
              (e) => VendorPaymentModel.fromJson(e),
        )
            .toList();
      }

      return [];
    } catch (e) {
      print("Search Vendor Payments Error: $e");
      rethrow;
    }
  }
  Future<List<VendorPaymentModel>> getVendorPaymentsByDate({
    required String token,
    required String date,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          "${AppConstants.baseApiPath}/vendor_payments/get-vendor-payments?date=$date",
        ),
        headers: {
          "Authorization": "Bearer $token",
        },
      );

      print("DATE FILTER STATUS : ${response.statusCode}");
      print("DATE FILTER RESPONSE : ${response.body}");

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 &&
          data["success"] == true) {
        return (data["data"] as List)
            .map(
              (e) => VendorPaymentModel.fromJson(e),
        )
            .toList();
      }

      return [];
    } catch (e) {
      print("Date Filter Error : $e");
      rethrow;
    }
  }
  Future<Map<String, dynamic>> deleteVendorPayment({
    required String token,
    required int vendorPaymentId,
  }) async {
    try {
      final url =
          "${AppConstants.baseApiPath}/vendor_payments/delete-vendor-payment?vendor_payment_id=$vendorPaymentId";
      print("DELETE URL : $url");

      final response = await http.delete(
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      print("DELETE STATUS : ${response.statusCode}");
      print("DELETE RESPONSE : ${response.body}");

      if (response.body.isEmpty) {
        throw Exception("Server returned empty response");
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 &&
          data["success"] == true) {
        return data;
      }

      throw Exception(
        data["message"] ?? "Failed to delete vendor payment",
      );
    } catch (e) {
      print("DELETE ERROR : $e");
      rethrow;
    }
  }
}