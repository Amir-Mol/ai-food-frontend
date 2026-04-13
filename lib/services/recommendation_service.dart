import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ai_food_app/config.dart';
import 'package:ai_food_app/models/recommendation_status.dart';
import 'package:ai_food_app/ai_recommendation.dart';

/// Service for recommendation API calls
class RecommendationService {
  static const String _baseUrl = AppConfig.apiBaseUrl;
  final _secureStorage = const FlutterSecureStorage();

  /// Get authorization token from secure storage
  Future<String?> _getToken() async {
    return await _secureStorage.read(key: 'access_token');
  }

  /// Get headers with authorization
  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Check current recommendation generation status
  Future<RecommendationStatus> checkStatus() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/api/recommendation-status'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return RecommendationStatus.fromJson(jsonResponse);
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Token expired');
      } else {
        throw Exception(
            'Failed to check status: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error checking recommendation status: $e');
    }
  }

  /// Trigger recommendation generation after onboarding completion
  Future<void> completeOnboarding() async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/api/user/complete-onboarding'),
        headers: headers,
        body: '', // Empty body to ensure headers are properly sent
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to trigger generation: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error completing onboarding: $e');
    }
  }

  /// Get pre-generated recommendations (synchronous, no wait)
  Future<List<AiRecommendation>> getRecommendations() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/api/recommendations/'),  // Fixed: Added trailing slash
        headers: headers,
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final List recommendations = jsonResponse['recommendations'] ?? [];
        return recommendations
            .map((json) => AiRecommendation.fromJson(json))
            .toList();
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Token expired');
      } else {
        throw Exception(
            'Failed to load recommendations: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading recommendations: $e');
    }
  }

  /// Submit feedback for a recommendation
  /// Returns: nextAllowedGenerationAt (DateTime when user can request new recommendations)
  Future<DateTime?> submitFeedback({
    required String recommendationId,
    required String action, // "liked" or "disliked"
    int? rating, // Optional: 1-5 rating
    String? comment, // Optional: user comment
  }) async {
    try {
      final headers = await _getHeaders();
      final body = jsonEncode({
        'action': action,
        'rating': rating,
        'comment': comment,
      });

      final response = await http.post(
        Uri.parse('$_baseUrl/api/recommendations/$recommendationId/feedback'),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        // Extract nextAllowedGenerationAt from response
        if (jsonResponse['nextAllowedGenerationAt'] != null) {
          return DateTime.parse(jsonResponse['nextAllowedGenerationAt']);
        }
        return null;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Token expired');
      } else {
        throw Exception(
            'Failed to submit feedback: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error submitting feedback: $e');
    }
  }

  /// Poll for status updates (convenience method for polling loops)
  /// Returns the updated status
  Future<RecommendationStatus> pollStatus() async {
    return checkStatus();
  }
}
