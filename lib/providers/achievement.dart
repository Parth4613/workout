import 'package:flutter/foundation.dart';
import '../models/achievement_model.dart';
import '../services/achievement_service.dart';

class AchievementProvider with ChangeNotifier {
  final AchievementService _achievementService = AchievementService();
  List<Achievement> _achievements = [];
  bool _isLoading = false;

  List<Achievement> get achievements => List.unmodifiable(_achievements);
  bool get isLoading => _isLoading;

  Future<void> loadAchievements() async {
    _isLoading = true;
    notifyListeners();

    try {
      _achievements = await _achievementService.fetchAchievements();
    } catch (e) {
      debugPrint('Error loading achievements: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> checkAchievements() async {
    try {
      await _achievementService.checkAchievements();
      await loadAchievements(); // Reload achievements after checking
    } catch (e) {
      debugPrint('Error checking achievements: $e');
    }
  }

  Future<void> unlockAchievement(Achievement achievement) async {
    try {
      achievement.isUnlocked = true;
      achievement.progress = achievement.requirementValue.toDouble();
      await _achievementService.saveAchievement(achievement);
      
      final index = _achievements.indexWhere((a) => a.id == achievement.id);
      if (index != -1) {
        _achievements[index] = achievement;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error unlocking achievement: $e');
    }
  }

  Future<void> updateProgress(Achievement achievement, double progress) async {
    try {
      achievement.progress = progress;
      if (progress >= achievement.requirementValue) {
        achievement.isUnlocked = true;
      }
      await _achievementService.saveAchievement(achievement);
      
      final index = _achievements.indexWhere((a) => a.id == achievement.id);
      if (index != -1) {
        _achievements[index] = achievement;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating achievement progress: $e');
    }
  }
}