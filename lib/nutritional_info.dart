/// Represents the nutritional information for a recipe.
class NutritionalInfo {
  final int calories;
  final int protein;
  final int carbs;
  final int fat;

  /// Creates an instance of [NutritionalInfo].
  NutritionalInfo({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  /// Creates a [NutritionalInfo] from a JSON map, handling nulls gracefully.
  factory NutritionalInfo.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      // Return default/zero values if the nutritional info is missing
      return NutritionalInfo(calories: 0, protein: 0, carbs: 0, fat: 0);
    }
    return NutritionalInfo(
      calories: json['calories'] as int? ?? 0,
      protein: json['protein'] as int? ?? 0,
      carbs: json['carbs'] as int? ?? 0,
      fat: json['fat'] as int? ?? 0,
    );
  }

  /// A formatted string representation of the nutritional information.
  /// Returns a message if all values are zero, indicating data is not available.
  @override
  String toString() {
    if (calories == 0 && protein == 0 && carbs == 0 && fat == 0) {
      return 'Nutritional information not available.';
    }
    return 'Calories: ${calories}kcal, Protein: ${protein}g, Carbs: ${carbs}g, Fat: ${fat}g';
  }
}