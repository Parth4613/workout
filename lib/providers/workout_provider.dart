import 'package:flutter/foundation.dart';

class WorkoutProvider with ChangeNotifier {
  final List<String> _completedWorkouts = [];
  final Map<String, int> _weeklyWorkouts = {};
  int _totalCaloriesBurned = 0;
  bool _isPremium = false;
  
  List<String> get completedWorkouts => List.unmodifiable(_completedWorkouts);
  Map<String, int> get weeklyWorkouts => Map.unmodifiable(_weeklyWorkouts);
  int get totalCaloriesBurned => _totalCaloriesBurned;
  bool get isPremium => _isPremium;

  void upgradeToPremium() {
    _isPremium = true;
    notifyListeners();
  }

  bool canAccessWorkout(String difficulty) {
    if (difficulty.toLowerCase() == 'beginner') return true;
    return _isPremium;
  }

  void completeWorkout(String workoutId, String date, int calories) {
    _completedWorkouts.add(workoutId);
    _totalCaloriesBurned += calories;
    
    // Update weekly tracking
    final weekKey = getWeekKey(DateTime.parse(date));
    _weeklyWorkouts[weekKey] = (_weeklyWorkouts[weekKey] ?? 0) + 1;
    
    notifyListeners();
  }

  bool isWorkoutCompleted(String workoutId) {
    return _completedWorkouts.contains(workoutId);
  }

  int getWeeklyWorkouts() {
    final currentWeek = getWeekKey(DateTime.now());
    return _weeklyWorkouts[currentWeek] ?? 0;
  }

  String getWeekKey(DateTime date) {
    // Get the start of the week (Monday)
    final monday = date.subtract(Duration(days: date.weekday - 1));
    return '${monday.year}-${monday.month}-${monday.day}';
  }
}