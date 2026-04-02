class NutritionalInfo {
  final double? calories;
  final double? protein;
  final double? carbs;
  final double? fat;
  final double? sugars;
  final double? sodium;

  NutritionalInfo({
    this.calories,
    this.protein,
    this.carbs,
    this.fat,
    this.sugars,
    this.sodium,
  });

  factory NutritionalInfo.fromJson(Map<String, dynamic> json) {
    // Helper to safely parse a value to a double
    double? _toDouble(dynamic value) {
      if (value is num) {
        return value.toDouble();
      }
      return null;
    }

    return NutritionalInfo(
      calories: _toDouble(json['calories']),
      protein: _toDouble(json['protein']),
      carbs: _toDouble(json['carbs']),
      fat: _toDouble(json['fat']),
      sugars: _toDouble(json['sugars']),
      sodium: _toDouble(json['sodium']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'sugars': sugars,
      'sodium': sodium,
    };
  }
}

class AiRecommendation {
  final String recipeId;
  final String name;
  final String explanation;
  final String imageUrl;
  final double healthScore;
  final List<String> ingredients;
  final String recipeUrl;
  final NutritionalInfo nutritionalInfo;

  AiRecommendation({
    required this.recipeId,
    required this.name,
    required this.explanation,
    required this.imageUrl,
    required this.healthScore,
    required this.ingredients,
    required this.recipeUrl,
    required this.nutritionalInfo,
  });

  factory AiRecommendation.fromJson(Map<String, dynamic> json) {
    List<String> _parseStringList(dynamic value) {
      if (value is List) {
        return value.map((item) => item.toString()).toList();
      }
      return [];
    }

    return AiRecommendation(
      recipeId: json['recipeId'] ?? 'unknown_id',
      name: json['name'] ?? 'Unnamed Recipe',
      explanation: json['explanation'] ?? 'No explanation provided.',
      imageUrl: json['imageUrl'] ?? 'https://via.placeholder.com/300',
      healthScore: (json['healthScore'] as num?)?.toDouble() ?? 0.0,
      ingredients: _parseStringList(json['ingredients']),
      recipeUrl: json['recipeUrl'] ?? '',
      nutritionalInfo: json['nutritionalInfo'] != null
          ? NutritionalInfo.fromJson(json['nutritionalInfo'])
          : NutritionalInfo(), // Provide empty nutritional info if null
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'recipeId': recipeId,
      'name': name,
      'explanation': explanation,
      'imageUrl': imageUrl,
      'healthScore': healthScore,
      'ingredients': ingredients,
      'recipeUrl': recipeUrl,
      'nutritionalInfo': nutritionalInfo.toJson(),
    };
  }
}