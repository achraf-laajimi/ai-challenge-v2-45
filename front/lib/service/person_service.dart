import 'dart:convert';

import '../models/person.dart';
import 'api_client.dart';

class PersonService {
  PersonService._();
  static final PersonService instance = PersonService._();

  final ApiClient _api = ApiClient.instance;

  /// List all persons in current user's family.
  Future<List<Person>> list() async {
    final res = await _api.get('/persons');
    if (res.statusCode != 200) return [];
    final list = jsonDecode(res.body) as List<dynamic>;
    return list.map((e) => Person.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Create a person. [familyId] must be current user's family id.
  /// [role] is 'father' | 'mother' | 'child'.
  Future<Person?> create({
    required String familyId,
    required String role,
    required Person person,
  }) async {
    final body = person.toJson()
      ..['family_id'] = familyId
      ..['role'] = role;
    final res = await _api.post('/persons', body: body);
    if (res.statusCode != 201) return null;
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return Person.fromJson(data);
  }

  /// Update a person by id.
  Future<Person?> update(String personId, Person person) async {
    final body = person.toJson();
    body.remove('id');
    final res = await _api.patch('/persons/$personId', body: body);
    if (res.statusCode != 200) return null;
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return Person.fromJson(data);
  }

  /// Delete a person by id.
  Future<bool> delete(String personId) async {
    final res = await _api.delete('/persons/$personId');
    return res.statusCode == 204;
  }
}
