import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/achievement_model.dart';

class AchievementService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Predefined achievements
  static final List<Achievement> defaultAchievements = [
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
    Achievement(
      id: 'streak_7',
      title: '7-Day Streak',
      description: 'Complete workouts for 7 consecutive days',
      icon: '🔥',
      requirementValue: 7,
    ),
    Achievement(
      id: 'premium_member',
      title: 'Premium Member',
      description: 'Purchase the premium plan',
      icon: '💎',
      requirementValue: 1,
    ),
    Achievement(
      id: 'push_pull_leg_beginner',
      title: 'Push Pull Leg Beginner',
      description: 'Unlock the Push Pull Leg beginner workout',
      icon: '🏋‍♂',
      requirementValue: 1,
    ),
    Achievement(
      id: 'single_muscle_beginner',
      title: 'Single Muscle Beginner',
      description: 'Unlock the Single Muscle beginner workout',
      icon: '💪',
      requirementValue: 1,
    ),
    Achievement(
      id: 'weekly_active_days',
      title: 'Weekly Active Days',
      description: 'Complete your workouts on all active days of the week',
      icon: '📅',
      requirementValue: 7,  // Will be updated based on user's goal
    ),
    Achievement(
      id: 'weekly_hours',
      title: 'Weekly Hours Completed',
      description: 'Complete the required workout hours in a week',
      icon: '⏱',
      requirementValue: 5,  // Will be updated based on user's goal
    ),
    Achievement(
      id: 'weekly_calories',
      title: 'Weekly Calories Burned',
      description: 'Burn the required number of calories in a week',
      icon: '🔥',
      requirementValue: 1000,  // Will be updated based on user's goal
    ),
    Achievement(
      id: 'complete_access',
      title: 'Complete Access',
      description: 'Purchase full access to all features and workouts',
      icon: '🔑',
      requirementValue: 1,
    ),
  ];

  Future<void> saveAchievement(Achievement achievement) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final achievementRef = _database.ref('userAchievements/$userId/${achievement.id}');
    await achievementRef.set(achievement.toJson());
  }

  Future<List<Achievement>> fetchAchievements() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return [];

    // Get user goals to update requirement values
    final goalsRef = _database.ref('userGoals/$userId');
    final goalsSnapshot = await goalsRef.get();
    
    if (goalsSnapshot.exists) {
      final goals = Map<String, dynamic>.from(goalsSnapshot.value as Map);
      // Update requirement values based on user goals
      final weeklyActiveIndex = defaultAchievements.indexWhere((a) => a.id == 'weekly_active_days');
      if (weeklyActiveIndex != -1) {
        defaultAchievements[weeklyActiveIndex] = defaultAchievements[weeklyActiveIndex].copyWith(
          requirementValue: goals['workoutDays'] ?? 7
        );
      }
      
      final weeklyHoursIndex = defaultAchievements.indexWhere((a) => a.id == 'weekly_hours');
      if (weeklyHoursIndex != -1) {
        defaultAchievements[weeklyHoursIndex] = defaultAchievements[weeklyHoursIndex].copyWith(
          requirementValue: goals['weeklyHours'] ?? 5
        );
      }
      
      final weeklyCaloriesIndex = defaultAchievements.indexWhere((a) => a.id == 'weekly_calories');
      if (weeklyCaloriesIndex != -1) {
        defaultAchievements[weeklyCaloriesIndex] = defaultAchievements[weeklyCaloriesIndex].copyWith(
          requirementValue: goals['calorieGoal'] ?? 1000
        );
      }
    }

    final achievementsRef = _database.ref('userAchievements/$userId');
    final snapshot = await achievementsRef.get();

    if (!snapshot.exists) {
      // Initialize default achievements for new users
      for (var achievement in defaultAchievements) {
        await saveAchievement(achievement);
      }
      return defaultAchievements;
    }

    final achievements = <Achievement>[];
    final data = Map<String, dynamic>.from(snapshot.value as Map);
    
    data.forEach((key, value) {
      achievements.add(Achievement.fromJson(Map<String, dynamic>.from(value)));
    });

    return achievements;
  }

  Future<void> checkAchievements() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekKey = '${weekStart.year}-${weekStart.month}-${weekStart.day}';

    // Get weekly stats
    final weeklyStatsRef = _database.ref('weeklyStats/$userId/$weekKey');
    final statsSnapshot = await weeklyStatsRef.get();
    
    if (!statsSnapshot.exists) return;
    
    final stats = Map<String, dynamic>.from(statsSnapshot.value as Map);
    
    // Get workout history
    final historyRef = _database.ref('workoutHistory/$userId');
    final historySnapshot = await historyRef.get();
    
    if (!historySnapshot.exists) return;
    
    final history = Map<String, dynamic>.from(historySnapshot.value as Map);
    
    // Check first workout achievement
    await _checkFirstWorkout(history);
    
    // Check streak achievements
    await _checkStreakAchievements(history);
    
    // Check weekly goals achievements
    await _checkWeeklyGoals(stats);
    
    // Check premium status
    await _checkPremiumStatus();
    
    // Check workout unlocks
    await _checkWorkoutUnlocks();
  }

  Future<void> _checkFirstWorkout(Map<String, dynamic> history) async {
    final firstStepAchievement = defaultAchievements.firstWhere((a) => a.id == 'first_step');
    if (history.isNotEmpty) {
      await saveAchievement(firstStepAchievement.copyWith(
        isUnlocked: true,
        progress: 1.0
      ));
    }
  }

  Future<void> _checkStreakAchievements(Map<String, dynamic> history) async {
    // Sort workouts by date
    var sortedWorkouts = history.entries.map((e) {
      final workout = Map<String, dynamic>.from(e.value);
      return DateTime.parse(workout['completedAt']);
    }).toList()..sort();

    int currentStreak = 1;
    int maxStreak = 1;
    DateTime? lastWorkoutDate;

    for (var workoutDate in sortedWorkouts) {
      if (lastWorkoutDate != null) {
        if (workoutDate.difference(lastWorkoutDate).inDays == 1) {
          currentStreak++;
          maxStreak = currentStreak > maxStreak ? currentStreak : maxStreak;
        } else if (workoutDate.difference(lastWorkoutDate).inDays > 1) {
          currentStreak = 1;
        }
      }
      lastWorkoutDate = workoutDate;
    }

    // Check each streak achievement
    for (var days in [3, 5, 7]) {
      final streakAchievement = defaultAchievements.firstWhere((a) => a.id == 'streak_$days');
      await saveAchievement(streakAchievement.copyWith(
        progress: maxStreak.toDouble(),
        isUnlocked: maxStreak >= days
      ));
    }
  }

  Future<void> _checkWeeklyGoals(Map<String, dynamic> stats) async {
    // Check weekly active days
    final activeWorkoutDays = stats['activeWorkoutDays'] as int? ?? 0;
    final weeklyActiveDaysAchievement = defaultAchievements.firstWhere((a) => a.id == 'weekly_active_days');
    await saveAchievement(weeklyActiveDaysAchievement.copyWith(
      progress: activeWorkoutDays.toDouble(),
      isUnlocked: activeWorkoutDays >= weeklyActiveDaysAchievement.requirementValue
    ));

    // Check weekly hours
    final totalDuration = (stats['totalDuration'] as int? ?? 0) / 60.0; // Convert minutes to hours
    final weeklyHoursAchievement = defaultAchievements.firstWhere((a) => a.id == 'weekly_hours');
    await saveAchievement(weeklyHoursAchievement.copyWith(
      progress: totalDuration,
      isUnlocked: totalDuration >= weeklyHoursAchievement.requirementValue
    ));

    // Check weekly calories
    final totalCalories = stats['totalCalories'] as int? ?? 0;
    final weeklyCaloriesAchievement = defaultAchievements.firstWhere((a) => a.id == 'weekly_calories');
    await saveAchievement(weeklyCaloriesAchievement.copyWith(
      progress: totalCalories.toDouble(),
      isUnlocked: totalCalories >= weeklyCaloriesAchievement.requirementValue
    ));
  }

  Future<void> _checkPremiumStatus() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final userRef = _database.ref('users/$userId');
    final userSnapshot = await userRef.get();
    
    if (userSnapshot.exists) {
      final userData = Map<String, dynamic>.from(userSnapshot.value as Map);
      final isPremium = userData['isPremium'] as bool? ?? false;
      final hasFullAccess = userData['hasFullAccess'] as bool? ?? false;

      // Check premium member achievement
      final premiumAchievement = defaultAchievements.firstWhere((a) => a.id == 'premium_member');
      await saveAchievement(premiumAchievement.copyWith(
        isUnlocked: isPremium,
        progress: isPremium ? 1.0 : 0.0
      ));

      // Check complete access achievement
      final completeAccessAchievement = defaultAchievements.firstWhere((a) => a.id == 'complete_access');
      await saveAchievement(completeAccessAchievement.copyWith(
        isUnlocked: hasFullAccess,
        progress: hasFullAccess ? 1.0 : 0.0
      ));
    }
  }

  Future<void> _checkWorkoutUnlocks() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final unlocksRef = _database.ref('workoutUnlocks/$userId');
    final unlocksSnapshot = await unlocksRef.get();
    
    if (unlocksSnapshot.exists) {
      final unlocks = Map<String, dynamic>.from(unlocksSnapshot.value as Map);

      // Check Push Pull Leg beginner
      final pushPullLegAchievement = defaultAchievements.firstWhere((a) => a.id == 'push_pull_leg_beginner');
      final hasPPL = unlocks['pushPullLegBeginner'] as bool? ?? false;
      await saveAchievement(pushPullLegAchievement.copyWith(
        isUnlocked: hasPPL,
        progress: hasPPL ? 1.0 : 0.0
      ));

      // Check Single Muscle beginner
      final singleMuscleAchievement = defaultAchievements.firstWhere((a) => a.id == 'single_muscle_beginner');
      final hasSingleMuscle = unlocks['singleMuscleBeginner'] as bool? ?? false;
      await saveAchievement(singleMuscleAchievement.copyWith(
        isUnlocked: hasSingleMuscle,
        progress: hasSingleMuscle ? 1.0 : 0.0
      ));
    }
  }
}