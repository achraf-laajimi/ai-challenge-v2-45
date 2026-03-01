// Models matching the backend /api/ai/assistant response schema.

class AiPlace {
  final String name;
  final String? address;
  final String? placeId;
  final bool? openNow;
  final double? lat;
  final double? lng;

  const AiPlace({
    required this.name,
    this.address,
    this.placeId,
    this.openNow,
    this.lat,
    this.lng,
  });

  factory AiPlace.fromJson(Map<String, dynamic> json) => AiPlace(
        name: json['name'] as String? ?? '',
        address: json['address'] as String?,
        placeId: json['place_id'] as String?,
        openNow: json['open_now'] as bool?,
        lat: (json['lat'] as num?)?.toDouble(),
        lng: (json['lng'] as num?)?.toDouble(),
      );
}

class AiNutrition {
  final String title;
  final String description;
  final List<String> shoppingList;

  const AiNutrition({
    required this.title,
    required this.description,
    this.shoppingList = const [],
  });

  factory AiNutrition.fromJson(Map<String, dynamic> json) => AiNutrition(
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        shoppingList:
            (json['shopping_list'] as List<dynamic>?)?.cast<String>() ?? [],
      );
}

class AiMealAnalysis {
  final bool isCompatible;
  final String reasoning;
  final String? alternativeSuggestion;

  const AiMealAnalysis({
    required this.isCompatible,
    required this.reasoning,
    this.alternativeSuggestion,
  });

  factory AiMealAnalysis.fromJson(Map<String, dynamic> json) => AiMealAnalysis(
        isCompatible: json['is_compatible'] as bool? ?? false,
        reasoning: json['reasoning'] as String? ?? '',
        alternativeSuggestion: json['alternative_suggestion'] as String?,
      );
}

class AiAssistantResponse {
  final String? personId;
  final List<AiPlace> doctors;
  final AiNutrition? nutrition;
  final AiMealAnalysis? mealAnalysis;
  final String? note;

  const AiAssistantResponse({
    this.personId,
    this.doctors = const [],
    this.nutrition,
    this.mealAnalysis,
    this.note,
  });

  factory AiAssistantResponse.fromJson(Map<String, dynamic> json) =>
      AiAssistantResponse(
        personId: json['person_id'] as String?,
        doctors: (json['doctors'] as List<dynamic>?)
                ?.map((e) => AiPlace.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        nutrition: json['nutrition'] != null
            ? AiNutrition.fromJson(json['nutrition'] as Map<String, dynamic>)
            : null,
        mealAnalysis: json['meal_analysis'] != null
            ? AiMealAnalysis.fromJson(
                json['meal_analysis'] as Map<String, dynamic>)
            : null,
        note: json['note'] as String?,
      );
}
