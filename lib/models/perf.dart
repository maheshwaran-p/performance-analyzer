// Fixed PerformanceProvider class to handle API response properly
import 'package:flutter/material.dart';
import 'package:performance_analzer2/service/api_service.dart';

class PerformanceData {
  final int overallScore;
  final Map<String, int> categoryScores;
  final List<Achievement> recentAchievements;
  final List<Suggestion> suggestions;
  final ActivityCounts activityCounts;

  PerformanceData({
    required this.overallScore,
    required this.categoryScores,
    required this.recentAchievements,
    required this.suggestions,
    required this.activityCounts,
  });

  factory PerformanceData.fromJson(Map<String, dynamic> json) {
    // Parse category scores with explicit type checking
    Map<String, int> categoryScores = {};
    if (json['categoryScores'] != null) {
      (json['categoryScores'] as Map<String, dynamic>).forEach((key, value) {
        // Ensure value is treated as int
        categoryScores[key] = value is int ? value : int.tryParse(value.toString()) ?? 0;
      });
    }

    // Parse recent achievements safely
    List<Achievement> achievements = [];
    if (json['recentAchievements'] != null) {
      for (var item in (json['recentAchievements'] as List)) {
        achievements.add(Achievement.fromJson(item as Map<String, dynamic>));
      }
    }

    // Parse suggestions safely
    List<Suggestion> suggestions = [];
    if (json['suggestions'] != null) {
      for (var item in (json['suggestions'] as List)) {
        suggestions.add(Suggestion.fromJson(item as Map<String, dynamic>));
      }
    }

    // Parse overall score with safety
    int overallScore = 0;
    if (json['overallScore'] != null) {
      overallScore = json['overallScore'] is int 
          ? json['overallScore'] 
          : int.tryParse(json['overallScore'].toString()) ?? 0;
    }

    return PerformanceData(
      overallScore: overallScore,
      categoryScores: categoryScores,
      recentAchievements: achievements,
      suggestions: suggestions,
      activityCounts: ActivityCounts.fromJson(
        json['activityCounts'] == null 
            ? {} 
            : json['activityCounts'] as Map<String, dynamic>
      ),
    );
  }
}

class Achievement {
  final String type;
  final String title;
  final String description;
  final String date;
  final String icon;

  Achievement({
    required this.type,
    required this.title,
    required this.description,
    required this.date,
    required this.icon,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      type: json['type']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      icon: json['icon']?.toString() ?? 'star',
    );
  }
}

class Suggestion {
  final String category;
  final String title;
  final String description;

  Suggestion({
    required this.category,
    required this.title,
    required this.description,
  });

  factory Suggestion.fromJson(Map<String, dynamic> json) {
    return Suggestion(
      category: json['category']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
    );
  }
}

class ActivityCounts {
  final int certificates;
  final int research;
  final int publications;
  final int guestLectures;
  final int selfDevelopment;
  final int total;

  ActivityCounts({
    required this.certificates,
    required this.research,
    required this.publications,
    required this.guestLectures,
    required this.selfDevelopment,
    required this.total,
  });

  factory ActivityCounts.fromJson(Map<String, dynamic> json) {
    // Safety function to handle non-int values
    int safeInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      return int.tryParse(value.toString()) ?? 0;
    }

    return ActivityCounts(
      certificates: safeInt(json['certificates']),
      research: safeInt(json['research']),
      publications: safeInt(json['publications']),
      guestLectures: safeInt(json['guestLectures']),
      selfDevelopment: safeInt(json['selfDevelopment']),
      total: safeInt(json['total']),
    );
  }
}

class PerformanceProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  PerformanceData? _performanceData;
  bool _isLoading = false;
  String _error = '';

  PerformanceData? get performanceData => _performanceData;
  bool get isLoading => _isLoading;
  String get error => _error;

  Future<void> fetchPerformanceData(String email) async {
    try {
      setLoading(true);
      
      final response = await _apiService.getPerformance(email);
      
      // Add more detailed logging for debugging
      print('API Response: $response');
      
      if (response.containsKey('success') && response['success'] == true) {
        if (response.containsKey('performance') && response['performance'] != null) {
          final performanceJson = response['performance'] as Map<String, dynamic>;
          _performanceData = PerformanceData.fromJson(performanceJson);
          _error = '';
        } else {
          _error = 'Performance data is missing or null';
          _performanceData = null;
        }
      } else {
        _error = response['error'] ?? 'Failed to fetch performance data';
        _performanceData = null;
      }
    } catch (e) {
      print('Exception in fetchPerformanceData: $e');
      _error = 'Error: ${e.toString()}';
      _performanceData = null;
    } finally {
      setLoading(false);
    }
  }
  
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  // Helper method to get icon data from icon name
  IconData getIconForName(String iconName) {
    switch (iconName) {
      case 'school':
        return Icons.school;
      case 'science':
        return Icons.science;
      case 'article':
        return Icons.article;
      case 'record_voice_over':
        return Icons.record_voice_over;
      case 'trending_up':
        return Icons.trending_up;
      default:
        return Icons.star;
    }
  }
  
  // Helper method to get color for category
  Color getCategoryColor(String category) {
    switch (category) {
      case 'Technical Skills':
        return Colors.blue;
      case 'Research':
        return Colors.purple;
      case 'Teaching & Presentation':
        return Colors.orange;
      case 'Professional Development':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
