import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Base URL of the FastAPI backend.
/// - Web / Windows desktop: localhost works fine
/// - Android emulator: 10.0.2.2 maps to host machine
/// - Physical device: replace with your machine's LAN IP (e.g. 192.168.1.x)
String get baseUrl {
  if (kIsWeb) return 'http://localhost:8000/api';
  if (Platform.isAndroid) return 'http://10.0.2.2:8000/api';
  return 'http://localhost:8000/api';
}

const _timeout = Duration(seconds: 15);
const _timeoutLong = Duration(seconds: 60); // for AI calls

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  String? _token;

  void setToken(String? token) {
    _token = token;
  }

  Map<String, String> get _headers {
    final map = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_token != null && _token!.isNotEmpty) {
      map['Authorization'] = 'Bearer $_token';
    }
    return map;
  }

  Future<http.Response> get(String path) async {
    return http
        .get(Uri.parse('$baseUrl$path'), headers: _headers)
        .timeout(_timeout);
  }

  Future<http.Response> post(String path,
      {Map<String, dynamic>? body, bool longTimeout = false}) async {
    return http
        .post(
          Uri.parse('$baseUrl$path'),
          headers: _headers,
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(longTimeout ? _timeoutLong : _timeout);
  }

  Future<http.Response> patch(String path, {Map<String, dynamic>? body}) async {
    return http
        .patch(
          Uri.parse('$baseUrl$path'),
          headers: _headers,
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(_timeout);
  }

  Future<http.Response> delete(String path) async {
    return http
        .delete(Uri.parse('$baseUrl$path'), headers: _headers)
        .timeout(_timeout);
  }
}

