/// Represents a family member with health data.
class Person {
  /// Optional: set when loaded from API.
  final String? id;
  final String name;
  final String phone;
  final DateTime dob;
  final String gender;
  final String bloodType;
  final String rhFactor;
  final double height; // meters
  final double weight; // kg
  final double sugarLevel; // g/L
  final int systolicBP;
  final int diastolicBP;
  final int heartRate;
  final List<String> allergies;
  final List<String> chronicDiseases;
  final bool vaccinesUpToDate;

  const Person({
    this.id,
    required this.name,
    required this.phone,
    required this.dob,
    required this.gender,
    required this.bloodType,
    required this.rhFactor,
    required this.height,
    required this.weight,
    required this.sugarLevel,
    required this.systolicBP,
    required this.diastolicBP,
    required this.heartRate,
    this.allergies = const [],
    this.chronicDiseases = const [],
    this.vaccinesUpToDate = true,
  });

  /// From API JSON (camelCase).
  factory Person.fromJson(Map<String, dynamic> json) {
    return Person(
      id: json['id'] as String?,
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      dob: DateTime.tryParse(json['dob'] as String? ?? '') ?? DateTime.now(),
      gender: json['gender'] as String? ?? '',
      bloodType: json['bloodType'] as String? ?? '',
      rhFactor: json['rhFactor'] as String? ?? '',
      height: (json['height'] as num?)?.toDouble() ?? 0,
      weight: (json['weight'] as num?)?.toDouble() ?? 0,
      sugarLevel: (json['sugarLevel'] as num?)?.toDouble() ?? 0,
      systolicBP: json['systolicBP'] as int? ?? 0,
      diastolicBP: json['diastolicBP'] as int? ?? 0,
      heartRate: json['heartRate'] as int? ?? 0,
      allergies: (json['allergies'] as List<dynamic>?)?.cast<String>() ?? [],
      chronicDiseases: (json['chronicDiseases'] as List<dynamic>?)?.cast<String>() ?? [],
      vaccinesUpToDate: json['vaccinesUpToDate'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'name': name,
        'phone': phone,
        'dob': dob.toIso8601String(),
        'gender': gender,
        'bloodType': bloodType,
        'rhFactor': rhFactor,
        'height': height,
        'weight': weight,
        'sugarLevel': sugarLevel,
        'systolicBP': systolicBP,
        'diastolicBP': diastolicBP,
        'heartRate': heartRate,
        'allergies': allergies,
        'chronicDiseases': chronicDiseases,
        'vaccinesUpToDate': vaccinesUpToDate,
      };

  /// BMI = weight / height^2 (kg/m²)
  double get bmi {
    if (height <= 0) return 0;
    return weight / (height * height);
  }

  /// Age from date of birth.
  int get age {
    final now = DateTime.now();
    int a = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
      a--;
    }
    return a;
  }

  Person copyWith({
    String? id,
    String? name,
    String? phone,
    DateTime? dob,
    String? gender,
    String? bloodType,
    String? rhFactor,
    double? height,
    double? weight,
    double? sugarLevel,
    int? systolicBP,
    int? diastolicBP,
    int? heartRate,
    List<String>? allergies,
    List<String>? chronicDiseases,
    bool? vaccinesUpToDate,
  }) {
    return Person(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      dob: dob ?? this.dob,
      gender: gender ?? this.gender,
      bloodType: bloodType ?? this.bloodType,
      rhFactor: rhFactor ?? this.rhFactor,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      sugarLevel: sugarLevel ?? this.sugarLevel,
      systolicBP: systolicBP ?? this.systolicBP,
      diastolicBP: diastolicBP ?? this.diastolicBP,
      heartRate: heartRate ?? this.heartRate,
      allergies: allergies ?? this.allergies,
      chronicDiseases: chronicDiseases ?? this.chronicDiseases,
      vaccinesUpToDate: vaccinesUpToDate ?? this.vaccinesUpToDate,
    );
  }
}
