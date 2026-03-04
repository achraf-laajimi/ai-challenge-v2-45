import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/ai_response.dart';
import 'api_client.dart';

class AiService {
  AiService._();
  static final AiService instance = AiService._();

  final ApiClient _api = ApiClient.instance;

  Future<String?> _getFamilyId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_family_id');
  }

  Future<AiAssistantResponse?> chat({
    String? personId,
    String? familyId,
    double? lat,
    double? lng,
    String? imageBase64,
    String? userMessage,
  }) async {
    final fid = familyId ?? await _getFamilyId();

    final body = <String, dynamic>{};

    if (personId != null) {
      body['person_id'] = personId;
    } else if (fid != null) {
      body['family_id'] = fid;
    } else {
      return null; 
    }

    if (lat != null && lng != null) {
      body['location'] = {'lat': lat, 'lng': lng};
    }

    if (imageBase64 != null) {
      body['image_base64'] = imageBase64;
    }

    if (userMessage != null && userMessage.isNotEmpty) {
      body['user_message'] = userMessage;
    }

    final res = await _api.post('/ai/assistant', body: body, longTimeout: true);
    if (res.statusCode != 200) return null;
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return AiAssistantResponse.fromJson(data);
  }
}
