/// Model for recommendation generation status
class RecommendationStatus {
  final String status; // "idle" | "summarizing" | "generating" | "ready"
  final DateTime? recommendationsReadyAt;
  final int? waitingMinutes;  // Minutes to wait before next generation

  RecommendationStatus({
    required this.status,
    this.recommendationsReadyAt,
    this.waitingMinutes,
  });

  factory RecommendationStatus.fromJson(Map<String, dynamic> json) {
    return RecommendationStatus(
      status: json['status'] ?? 'idle',
      recommendationsReadyAt: json['recommendationsReadyAt'] != null
          ? DateTime.parse(json['recommendationsReadyAt'])
          : null,
      waitingMinutes: json['waitingMinutes'] != null
          ? json['waitingMinutes'] as int
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'recommendationsReadyAt': recommendationsReadyAt?.toIso8601String(),
      'waitingMinutes': waitingMinutes,
    };
  }

  /// Check if recommendations are ready
  bool get isReady => status == 'ready';

  /// Check if generation is in progress
  bool get isGenerating =>
      status == 'summarizing' || status == 'generating';

  /// Check if user can request new generation
  bool get canGenerateNow => waitingMinutes == null || waitingMinutes! <= 0;

  /// Get remaining time until next generation is allowed (in minutes)
  int? getMinutesUntilNextGeneration() {
    return waitingMinutes;
  }
}
