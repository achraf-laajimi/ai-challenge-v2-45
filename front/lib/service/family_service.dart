import 'dart:convert';

import '../models/family.dart';
import 'api_client.dart';

class FamilyService {
  FamilyService._();
  static final FamilyService instance = FamilyService._();

  final ApiClient _api = ApiClient.instance;

  /// Get current user's family (requires auth).
  Future<Family?> getMyFamily() async {
    final res = await _api.get('/families/me');
    if (res.statusCode != 200) return null;
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return Family.fromJson(data);
  }

  /// Update family (e.g. family history).
  Future<Family?> updateMyFamily({List<String>? familyHistory}) async {
    final body = <String, dynamic>{};
    if (familyHistory != null) body['family_history'] = familyHistory;
    final res = await _api.patch('/families/me', body: body.isNotEmpty ? body : null);
    if (res.statusCode != 200) return null;
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return Family.fromJson(data);
  }
}
