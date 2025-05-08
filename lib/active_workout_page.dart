import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'models/workout.dart';
import 'providers/achievement.dart';
import 'models/achievement_model.dart';

class ActiveWorkoutPage extends StatefulWidget {
  final Workout workout;

  const ActiveWorkoutPage({
    Key? key,
    required this.workout,
  }) : super(key: key);

  @override
  State<ActiveWorkoutPage> createState() => _ActiveWorkoutPageState();
}

class _ActiveWorkoutPageState extends State<ActiveWorkoutPage> {
  int _currentExerciseIndex = 0;
  bool _isCompleted = false;
  final _database = FirebaseDatabase.instance;
  final _auth = FirebaseAuth.instance;

  Future<void> _completeWorkout() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final now = DateTime.now();
    final workoutId = '${widget.workout.id}_${now.millisecondsSinceEpoch}';

    // Save workout completion to Firebase
    await _database.ref('workoutHistory/$userId/$workoutId').set({
      'workoutId': widget.workout.id,
      'title': widget.workout.title,
      'completedAt': now.toIso8601String(),
      'duration': widget.workout.duration,
      'caloriesBurned': widget.workout.calories,
      'difficulty': widget.workout.difficulty,
    });

    // Update weekly stats
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekKey = '${weekStart.year}-${weekStart.month}-${weekStart.day}';
    final weeklyStatsRef = _database.ref('weeklyStats/$userId/$weekKey');
    
    final snapshot = await weeklyStatsRef.get();
    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      await weeklyStatsRef.update({
        'totalCalories': (data['totalCalories'] ?? 0) + widget.workout.calories,
        'totalWorkouts': (data['totalWorkouts'] ?? 0) + 1,
        'totalDuration': (data['totalDuration'] ?? 0) + widget.workout.duration,
      });
    } else {
      await weeklyStatsRef.set({
        'totalCalories': widget.workout.calories,
        'totalWorkouts': 1,
        'totalDuration': widget.workout.duration,
        'weekStart': weekStart.toIso8601String(),
      });
    }

    // Check achievements
    final achievementProvider = Provider.of<AchievementProvider>(context, listen: false);
    await achievementProvider.checkAchievements();

    setState(() => _isCompleted = true);
  }

  @override
  Widget build(BuildContext context) {
    final currentExercise = widget.workout.exercises[_currentExerciseIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.workout.title),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(
              value: (_currentExerciseIndex + 1) / widget.workout.exercises.length,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            const SizedBox(height: 24),
            Text(
              currentExercise.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              currentExercise.description,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${currentExercise.sets} sets × ${currentExercise.reps} reps',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isCompleted
          ? ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Workout Complete! 🎉'),
            )
          : Row(
              children: [
                if (_currentExerciseIndex > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _currentExerciseIndex--;
                        });
                      },
                      child: const Text('Previous'),
                    ),
                  ),
                if (_currentExerciseIndex > 0)
                  const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_currentExerciseIndex < widget.workout.exercises.length - 1) {
                        setState(() {
                          _currentExerciseIndex++;
                        });
                      } else {
                        _completeWorkout();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      _currentExerciseIndex < widget.workout.exercises.length - 1
                        ? 'Next Exercise'
                        : 'Complete Workout',
                    ),
                  ),
                ),
              ],
            ),
      ),
    );
  }
}