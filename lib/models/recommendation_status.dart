/// Model for recommendation generation status
class RecommendationStatus {
  final String status; // "idle" | "summarizing" | "generating" | "ready"
  final DateTime? recommendationsReadyAt;
  final DateTime? nextAllowedGenerationAt;

  RecommendationStatus({
    required this.status,
    this.recommendationsReadyAt,
    this.nextAllowedGenerationAt,
  });

  factory RecommendationStatus.fromJson(Map<String, dynamic> json) {
    return RecommendationStatus(
      status: json['status'] ?? 'idle',
      recommendationsReadyAt: json['recommendationsReadyAt'] != null
          ? DateTime.parse(json['recommendationsReadyAt'])
          : null,
      nextAllowedGenerationAt: json['nextAllowedGenerationAt'] != null
          ? DateTime.parse(json['nextAllowedGenerationAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'recommendationsReadyAt': recommendationsReadyAt?.toIso8601String(),
      'nextAllowedGenerationAt': nextAllowedGenerationAt?.toIso8601String(),
    };
  }

  /// Check if recommendations are ready
  bool get isReady => status == 'ready';

  /// Check if generation is in progress
  bool get isGenerating =>
      status == 'summarizing' || status == 'generating';

  /// Check if user can request new generation
  bool get canGenerateNow =>
      nextAllowedGenerationAt == null ||
      DateTime.now().isAfter(nextAllowedGenerationAt!);

  /// Get remaining time until next generation is allowed
  Duration? getTimeUntilNextGeneration() {
    if (nextAllowedGenerationAt == null) return null;
    final remaining = nextAllowedGenerationAt!.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }
}
