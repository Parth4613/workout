import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import '../models/achievement_model.dart';

class AchievementProvider with ChangeNotifier {
  List<Achievement> _achievements = [];
  SharedPreferences? _prefs;

  List<Achievement> get achievements => [..._achievements];

  AchievementProvider() {
    _initAchievements();
  }

  Future<void> _initAchievements() async {
    _prefs = await SharedPreferences.getInstance();
    _loadAchievements();

    if (_achievements.isEmpty) {
      _achievements = [
        Achievement(
          id: 'first_step',
          title: 'First Step',
          description: 'Complete your first workout',
          icon: '🏅',
          requirementValue: 1,
        ),
        Achievement(
          id: 'streak_3',
          title: '3-Day Streak',
          description: 'Complete workouts for 3 consecutive days',
          icon: '🔥',
          requirementValue: 3,
        ),
        Achievement(
          id: 'streak_5',
          title: '5-Day Streak',
          description: 'Complete workouts for 5 consecutive days',
          icon: '🔥',
          requirementValue: 5,
        ),
        // Add other achievements
      ];
      _saveAchievements();
    }
  }

  Future<void> _loadAchievements() async {
    final achievementsJson = _prefs?.getString('achievements');
    if (achievementsJson != null) {
      final List<dynamic> decoded = json.decode(achievementsJson);
      _achievements = decoded.map((item) => Achievement.fromJson(item)).toList();
    }
  }

  Future<void> _saveAchievements() async {
    final achievementsJson = json.encode(
      _achievements.map((a) => a.toJson()).toList(),
    );
    await _prefs?.setString('achievements', achievementsJson);
  }

  Future<void> updateAchievement(String id, double progress) async {
    final achievement = _achievements.firstWhere((a) => a.id == id);
    achievement.progress = progress.clamp(0.0, 1.0);
    
    if (achievement.progress >= 1.0 && !achievement.isUnlocked) {
      achievement.isUnlocked = true;
      
      // Show achievement unlock notification using overlay
      final overlay = OverlayEntry(
        builder: (context) => Positioned(
          top: MediaQuery.of(context).padding.top + 20,
          left: 20,
          right: 20,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      achievement.icon,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Achievement Unlocked!',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          achievement.title,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Show notification
      final context = _achievements.first as BuildContext;
      Overlay.of(context).insert(overlay);

      // Remove notification after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        overlay.remove();
      });
    }
    
    await _saveAchievements();
    notifyListeners();
  }
}