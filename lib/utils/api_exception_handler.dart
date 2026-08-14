import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class ApiExceptionHandler {
  /// Handles multipart requests and catches network errors.
  static Future<http.StreamedResponse> multipart(
      http.MultipartRequest request,
      ) async {
    try {
      return await request.send();
    } on SocketException {
      // DNS or no internet
      throw Exception('No internet connection or server unreachable.');
    } on http.ClientException catch (e) {
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to connect to the server. Please try again.');
    }
  }

  /// Parses error from HTTP response.
  static String parseError(
      http.Response response, {
        String defaultMessage = 'An error occurred',
      }) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map && body.containsKey('message')) {
        return body['message'];
      }
      if (body is Map && body.containsKey('error')) {
        return body['error'];
      }
    } catch (_) {}
    return '${response.statusCode}: $defaultMessage';
  }
}