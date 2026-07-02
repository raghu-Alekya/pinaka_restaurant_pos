import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiExceptionHandler {
  static const Duration _timeout = Duration(seconds: 30);

  /// Handles MultipartRequest
  static Future<http.StreamedResponse> multipart(
      http.MultipartRequest request,
      ) async {
    try {
      return await request.send().timeout(_timeout);
    } on TimeoutException {
      throw Exception(
        "Request timed out. Please check your internet connection.",
      );
    } on http.ClientException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception("Something went wrong. Please try again.");
    }
  }

  /// Handles GET/POST/PUT requests
  static Future<http.Response> request(
      Future<http.Response> future,
      ) async {
    try {
      return await future.timeout(_timeout);
    } on TimeoutException {
      throw Exception(
        "Request timed out. Please check your internet connection.",
      );
    } on http.ClientException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception("Something went wrong. Please try again.");
    }
  }

  /// Parses API error response
  static String parseError(
      http.Response response, {
        String defaultMessage = "Something went wrong.",
      }) {
    try {
      final body = jsonDecode(response.body);

      if (body is Map<String, dynamic>) {
        if (body["message"] != null) {
          return body["message"].toString();
        }

        if (body["error"] != null) {
          return body["error"].toString();
        }
      }
    } catch (_) {}

    switch (response.statusCode) {
      case 400:
        return "Bad request.";
      case 401:
        return "Unauthorized.";
      case 403:
        return "Forbidden.";
      case 404:
        return "Resource not found.";
      case 500:
        return "Internal server error.";
      default:
        return defaultMessage;
    }
  }
}