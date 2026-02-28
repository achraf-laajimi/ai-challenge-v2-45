import 'person.dart';

/// Represents a family unit with father, mother, children and history.
class Family {
  final String? id;
  final String? familyCode;
  final Person? father;
  final Person? mother;
  final List<Person> children;
  final List<String> familyHistory;

  const Family({
    this.id,
    this.familyCode,
    required this.father,
    required this.mother,
    this.children = const [],
    this.familyHistory = const [],
  });

  /// All members in order: father, mother, then children (nulls omitted).
  List<Person> get allMembers {
    final list = <Person>[];
    if (father != null) list.add(father!);
    if (mother != null) list.add(mother!);
    list.addAll(children);
    return list;
  }

  /// From API JSON (camelCase: familyCode, familyHistory, createdAt).
  factory Family.fromJson(Map<String, dynamic> json) {
    Person? parsePerson(dynamic v) {
      if (v == null || v is! Map<String, dynamic>) return null;
      return Person.fromJson(v);
    }

    final f = parsePerson(json['father']);
    final m = parsePerson(json['mother']);
    final ch = (json['children'] as List<dynamic>?)
        ?.map((e) => Person.fromJson(e as Map<String, dynamic>))
        .toList() ?? [];

    return Family(
      id: json['id'] as String?,
      familyCode: json['familyCode'] as String?,
      father: f,
      mother: m,
      children: ch,
      familyHistory: (json['familyHistory'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }
}
