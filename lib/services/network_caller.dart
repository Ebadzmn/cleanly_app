import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/network/network_response.dart';
import '../core/network/network_exceptions.dart' as exceptions;

class NetworkCaller {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 90,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.none,
    ),
  );

  static const Duration timeoutDuration = Duration(seconds: 30);

  static Uri _parseUri(dynamic url, Map<String, dynamic>? queryParams) {
    Uri uri;
    if (url is Uri) {
      uri = url;
    } else {
      uri = Uri.parse(url.toString());
    }

    if (queryParams != null && queryParams.isNotEmpty) {
      final Map<String, String> stringParams = queryParams.map((key, value) => MapEntry(key, value.toString()));
      uri = uri.replace(queryParameters: {
        ...uri.queryParameters,
        ...stringParams,
      });
    }
    return uri;
  }

  static Future<Map<String, String>> _getHeadersWithAuth(Map<String, String>? headers) async {
    final finalHeaders = <String, String>{};
    if (headers != null) {
      finalHeaders.addAll(headers);
    }
    const secureStorage = FlutterSecureStorage();
    String? token = await secureStorage.read(key: 'auth_token');
    
    if (token == null || token.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      token = prefs.getString('token');
    }

    if (token != null && token.isNotEmpty) {
      finalHeaders['Authorization'] = 'Bearer $token';
    }
    if (!finalHeaders.containsKey('Content-Type') && !finalHeaders.containsKey('content-type')) {
      finalHeaders['Content-Type'] = 'application/json';
    }
    if (!finalHeaders.containsKey('Accept') && !finalHeaders.containsKey('accept')) {
      finalHeaders['Accept'] = 'application/json';
    }
    return finalHeaders;
  }

  static void _logRequest({
    required String method,
    required Uri url,
    required Map<String, String>? headers,
    required dynamic body,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('🚀 HTTP REQUEST');
    buffer.writeln('────────────────────────────────────────');
    buffer.writeln('URL:    $url');
    buffer.writeln('METHOD: $method');

    if (url.hasQuery) {
      buffer.writeln('QUERY PARAMS:');
      url.queryParameters.forEach((key, value) {
        buffer.writeln('  $key: $value');
      });
    }

    if (headers != null && headers.isNotEmpty) {
      buffer.writeln('HEADERS:');
      headers.forEach((key, value) {
        if (key.toLowerCase() == 'authorization' && value.length > 15) {
          buffer.writeln('  $key: ${value.substring(0, 15)}...');
        } else {
          buffer.writeln('  $key: $value');
        }
      });
    }

    if (body != null) {
      buffer.writeln('BODY:');
      if (body is Map) {
        body.forEach((key, value) {
          final displayValue = (key.toString().toLowerCase().contains('password')) ? '********' : value;
          buffer.writeln('  $key: $displayValue');
        });
      } else if (body is String) {
        try {
          final decoded = json.decode(body);
          const encoder = JsonEncoder.withIndent('  ');
          buffer.writeln(encoder.convert(decoded));
        } catch (_) {
          buffer.writeln('  $body');
        }
      } else {
        buffer.writeln('  $body');
      }
    }
    buffer.writeln('────────────────────────────────────────');
    _logger.i(buffer.toString());
  }

  static void _logResponse({
    required String method,
    required Uri url,
    required int statusCode,
    required Map<String, String> headers,
    required String body,
    required Duration duration,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('✅ HTTP RESPONSE');
    buffer.writeln('────────────────────────────────────────');
    buffer.writeln('URL:         $url');
    buffer.writeln('METHOD:      $method');
    buffer.writeln('STATUS CODE: $statusCode');
    buffer.writeln('LATENCY:     ${duration.inMilliseconds}ms');

    if (headers.isNotEmpty) {
      buffer.writeln('HEADERS:');
      headers.forEach((key, value) {
        buffer.writeln('  $key: $value');
      });
    }

    buffer.writeln('BODY:');
    try {
      final decoded = json.decode(body);
      const encoder = JsonEncoder.withIndent('  ');
      final prettyJson = encoder.convert(decoded);
      buffer.writeln(prettyJson);
    } catch (_) {
      buffer.writeln(body.length > 500 ? '${body.substring(0, 500)}... (truncated)' : body);
    }
    buffer.writeln('────────────────────────────────────────');

    if (statusCode >= 200 && statusCode < 300) {
      _logger.d(buffer.toString());
    } else {
      _logger.w(buffer.toString());
    }
  }

  static void _logError({
    required String method,
    required Uri url,
    required dynamic error,
    required StackTrace? stackTrace,
    required Duration duration,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('❌ HTTP ERROR');
    buffer.writeln('────────────────────────────────────────');
    buffer.writeln('URL:     $url');
    buffer.writeln('METHOD:  $method');
    buffer.writeln('LATENCY: ${duration.inMilliseconds}ms');
    buffer.writeln('ERROR:   $error');
    buffer.writeln('────────────────────────────────────────');
    _logger.e(buffer.toString(), error: error, stackTrace: stackTrace);
  }

  static NetworkResponse<dynamic> _processResponse(http.Response response) {
    dynamic data;
    try {
      if (response.body.isNotEmpty) {
        data = json.decode(response.body);
      }
    } catch (_) {
      data = response.body;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return NetworkResponse(
        isSuccess: true,
        statusCode: response.statusCode,
        data: data,
        message: data is Map ? data['message'] : null,
      );
    } else if (response.statusCode == 401) {
      throw exceptions.UnauthorizedException(data is Map ? data['message']?.toString() ?? "Unauthorized" : "Unauthorized");
    } else if (response.statusCode >= 500) {
      throw exceptions.ServerException(data is Map ? data['message']?.toString() ?? "Server error" : "Server error", response.statusCode);
    } else {
      return NetworkResponse(
        isSuccess: false,
        statusCode: response.statusCode,
        data: data,
        message: data is Map ? (data['message'] ?? data['error']?.toString() ?? data['errors']?.toString()) : null,
      );
    }
  }

  static Future<NetworkResponse<dynamic>> _handleRequest(
    Future<http.Response> Function() requestFunc,
    String method,
    Uri url,
  ) async {
    final startTime = DateTime.now();
    try {
      final response = await requestFunc().timeout(timeoutDuration);
      final duration = DateTime.now().difference(startTime);

      _logResponse(
        method: method,
        url: url,
        statusCode: response.statusCode,
        headers: response.headers,
        body: response.body,
        duration: duration,
      );

      return _processResponse(response);
    } on SocketException catch (e, stack) {
      final duration = DateTime.now().difference(startTime);
      _logError(method: method, url: url, error: e, stackTrace: stack, duration: duration);
      throw exceptions.NoInternetException();
    } on TimeoutException catch (e, stack) {
      final duration = DateTime.now().difference(startTime);
      _logError(method: method, url: url, error: e, stackTrace: stack, duration: duration);
      throw exceptions.TimeoutException();
    } catch (e, stack) {
      final duration = DateTime.now().difference(startTime);
      _logError(method: method, url: url, error: e, stackTrace: stack, duration: duration);
      if (e is exceptions.NetworkException) {
        rethrow;
      }
      throw exceptions.UnknownException(e.toString());
    }
  }

  // GET Request
  static Future<NetworkResponse<dynamic>> get(
    dynamic url, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParams,
  }) async {
    final parsedUrl = _parseUri(url, queryParams);
    final authHeaders = await _getHeadersWithAuth(headers);
    _logRequest(method: 'GET', url: parsedUrl, headers: authHeaders, body: null);

    return _handleRequest(() => http.get(parsedUrl, headers: authHeaders), 'GET', parsedUrl);
  }

  // POST Request
  static Future<NetworkResponse<dynamic>> post(
    dynamic url, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParams,
    Object? body,
    Encoding? encoding,
  }) async {
    final parsedUrl = _parseUri(url, queryParams);
    final authHeaders = await _getHeadersWithAuth(headers);
    _logRequest(method: 'POST', url: parsedUrl, headers: authHeaders, body: body);

    return _handleRequest(
      () => http.post(parsedUrl, headers: authHeaders, body: body, encoding: encoding),
      'POST',
      parsedUrl,
    );
  }

  // PUT Request
  static Future<NetworkResponse<dynamic>> put(
    dynamic url, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParams,
    Object? body,
    Encoding? encoding,
  }) async {
    final parsedUrl = _parseUri(url, queryParams);
    final authHeaders = await _getHeadersWithAuth(headers);
    _logRequest(method: 'PUT', url: parsedUrl, headers: authHeaders, body: body);

    return _handleRequest(
      () => http.put(parsedUrl, headers: authHeaders, body: body, encoding: encoding),
      'PUT',
      parsedUrl,
    );
  }

  // PATCH Request
  static Future<NetworkResponse<dynamic>> patch(
    dynamic url, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParams,
    Object? body,
    Encoding? encoding,
  }) async {
    final parsedUrl = _parseUri(url, queryParams);
    final authHeaders = await _getHeadersWithAuth(headers);
    _logRequest(method: 'PATCH', url: parsedUrl, headers: authHeaders, body: body);

    return _handleRequest(
      () => http.patch(parsedUrl, headers: authHeaders, body: body, encoding: encoding),
      'PATCH',
      parsedUrl,
    );
  }

  // DELETE Request
  static Future<NetworkResponse<dynamic>> delete(
    dynamic url, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParams,
    Object? body,
    Encoding? encoding,
  }) async {
    final parsedUrl = _parseUri(url, queryParams);
    final authHeaders = await _getHeadersWithAuth(headers);
    _logRequest(method: 'DELETE', url: parsedUrl, headers: authHeaders, body: body);

    return _handleRequest(
      () => http.delete(parsedUrl, headers: authHeaders, body: body, encoding: encoding),
      'DELETE',
      parsedUrl,
    );
  }

  // Send Multipart Request
  static Future<NetworkResponse<dynamic>> sendMultipart(http.MultipartRequest request) async {
    final authHeaders = await _getHeadersWithAuth(request.headers);
    request.headers.addAll(authHeaders);

    final url = request.url;
    final method = request.method;

    final requestBuffer = StringBuffer();
    requestBuffer.writeln('🚀 HTTP MULTIPART REQUEST');
    requestBuffer.writeln('────────────────────────────────────────');
    requestBuffer.writeln('URL:    $url');
    requestBuffer.writeln('METHOD: $method');

    if (request.headers.isNotEmpty) {
      requestBuffer.writeln('HEADERS:');
      request.headers.forEach((key, value) {
        if (key.toLowerCase() == 'authorization' && value.length > 15) {
          requestBuffer.writeln('  $key: ${value.substring(0, 15)}...');
        } else {
          requestBuffer.writeln('  $key: $value');
        }
      });
    }

    if (request.fields.isNotEmpty) {
      requestBuffer.writeln('FIELDS:');
      request.fields.forEach((key, value) {
        final displayValue = (key.toLowerCase().contains('password')) ? '********' : value;
        requestBuffer.writeln('  $key: $displayValue');
      });
    }

    if (request.files.isNotEmpty) {
      requestBuffer.writeln('FILES:');
      for (var file in request.files) {
        requestBuffer.writeln('  ${file.field}: ${file.filename} (${file.length} bytes)');
      }
    }
    requestBuffer.writeln('────────────────────────────────────────');
    _logger.i(requestBuffer.toString());

    return _handleRequest(() async {
      final streamedResponse = await request.send();
      return await http.Response.fromStream(streamedResponse);
    }, method, url);
  }
}
