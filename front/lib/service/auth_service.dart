import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';

const _keyToken = 'auth_token';
const _keyUserId = 'auth_user_id';
const _keyFamilyId = 'auth_family_id';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final ApiClient _api = ApiClient.instance;

  /// Returns saved access token or null.
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  /// Save token and user info after login/register.
  Future<void> _saveSession({
    required String token,
    required String userId,
    required String familyId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
    await prefs.setString(_keyUserId, userId);
    await prefs.setString(_keyFamilyId, familyId);
    _api.setToken(token);
  }

  /// Clear session (logout).
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyFamilyId);
    _api.setToken(null);
  }

  /// Restore token from storage (call on app start).
  Future<bool> restoreSession() async {
    final token = await getToken();
    if (token == null || token.isEmpty) return false;
    _api.setToken(token);
    return true;
  }

  /// Login with email and password. Returns error message or null on success.
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    final res = await _api.post('/auth/login', body: {
      'email': email,
      'password': password,
    });
    if (res.statusCode != 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>?;
      return data?['detail']?.toString() ?? 'Login failed';
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final user = data['user'] as Map<String, dynamic>;
    await _saveSession(
      token: data['access_token'] as String,
      userId: user['id'] as String,
      familyId: user['family_id'] as String,
    );
    return null;
  }

  /// Register. If [familyCode] is empty, creates a new family; otherwise joins existing.
  Future<String?> register({
    required String email,
    required String password,
    String familyCode = '',
  }) async {
    final body = <String, dynamic>{
      'email': email,
      'password': password,
    };
    if (familyCode.isNotEmpty) body['family_code'] = familyCode;

    final res = await _api.post('/auth/register', body: body);
    if (res.statusCode != 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>?;
      return data?['detail']?.toString() ?? 'Registration failed';
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final user = data['user'] as Map<String, dynamic>;
    await _saveSession(
      token: data['access_token'] as String,
      userId: user['id'] as String,
      familyId: user['family_id'] as String,
    );
    return null;
  }
}
