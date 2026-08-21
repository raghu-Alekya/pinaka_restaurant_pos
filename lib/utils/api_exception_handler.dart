import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';

class ApiExceptionHandler {
  static Future<http.StreamedResponse> multipart(
      http.MultipartRequest request,
      ) async {
    try {
      return await request.send();
    } on SocketException {
      throw Exception('No internet connection. Please check your network.');
    } on http.ClientException catch (e) {
      throw Exception(_friendlyNetworkMessage(e));
    } catch (e) {
      throw Exception('Server connection failed. Please try again later.');
    }
  }

  static String parseError(
      http.Response response, {
        String defaultMessage = 'Something went wrong. Please try again.',
      }) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map) {
        if (body.containsKey('message') && body['message'] is String) {
          return _friendlyMessage(body['message']);
        }
        if (body.containsKey('error') && body['error'] is String) {
          return _friendlyMessage(body['error']);
        }
        if (body.containsKey('data') && body['data'] is Map) {
          final data = body['data'];
          if (data.containsKey('message') && data['message'] is String) {
            return _friendlyMessage(data['message']);
          }
        }
        if (body.containsKey('errors')) {
          final errors = body['errors'];
          if (errors is Map) {
            final firstError = errors.values.first;
            if (firstError is List && firstError.isNotEmpty) {
              return _friendlyMessage(firstError.first.toString());
            }
          }
        }
      }
    } catch (_) {}

    return _statusCodeMessage(response.statusCode) ?? defaultMessage;
  }

  /// ✅ Returns ONLY the friendly message – no "Exception: " prefix.
  static String parseException(dynamic error) {
    if (error is http.ClientException) {
      return _friendlyNetworkMessage(error);
    } else if (error is SocketException) {
      return 'No internet connection. Please check your network.';
    } else if (error is TimeoutException) {
      return 'Connection timed out. Please try again.';
    } else if (error is Exception) {
      String msg = error.toString();
      if (msg.startsWith('Exception: ')) {
        msg = msg.substring('Exception: '.length);
      }
      return _friendlyMessage(msg);
    } else if (error is String) {
      return _friendlyMessage(error);
    }
    return 'An unexpected error occurred. Please try again.';
  }

  static void showErrorSnackBar(
      BuildContext context,
      dynamic error, {
        String defaultMessage = 'An error occurred. Please try again.',
      }) {
    String message;
    try {
      message = parseException(error);
    } catch (_) {
      message = defaultMessage;
    }
    if (message.trim().isEmpty) message = defaultMessage;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ─── Internal helpers ──────────────────────────────────────────────────

  static String _friendlyMessage(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('invalid') && lower.contains('pin')) {
      return 'Invalid PIN. Please try again.';
    }
    if (lower.contains('authentication') || lower.contains('unauthorized')) {
      return 'Session expired. Please login again.';
    }
    if (lower.contains('not found')) {
      return 'The requested resource was not found.';
    }
    if (lower.contains('permission') || lower.contains('forbidden')) {
      return 'You don\'t have permission to perform this action.';
    }
    if (lower.contains('timeout') || lower.contains('timed out')) {
      return 'Request timed out. Please check your connection.';
    }
    if (lower.contains('duplicate') || lower.contains('already exists')) {
      return 'This item already exists.';
    }
    if (lower.contains('server') || lower.contains('internal')) {
      return 'Server error. Please try again later.';
    }
    if (raw.isNotEmpty) {
      return raw[0].toUpperCase() + raw.substring(1);
    }
    return raw;
  }

  static String _friendlyNetworkMessage(http.ClientException e) {
    if (e.message.contains('failed to connect')) {
      return 'Could not connect to the server. Check your network.';
    }
    if (e.message.contains('timeout')) {
      return 'Connection timed out. Please try again.';
    }
    return 'Network error. Please check your internet connection.';
  }

  static String? _statusCodeMessage(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Invalid request. Please check your input.';
      case 401:
        return 'Please login again.';
      case 403:
        return 'You don\'t have permission to do this.';
      case 404:
        return 'The requested resource was not found.';
      case 405:
        return 'Method not allowed.';
      case 408:
        return 'Request timed out. Please try again.';
      case 500:
      case 502:
      case 503:
      case 504:
        return 'Server error. Please try again later.';
      default:
        return null;
    }
  }
}