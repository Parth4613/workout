import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';
import 'models/workout.dart';
import 'providers/achievement.dart';

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
  int currentExerciseIndex = 0;
  List<Set<int>> completedSets = [];
  late Timer _timer;
  Duration _elapsed = const Duration();
  bool _isActive = true;
  int _caloriesBurned = 0;
  Map<int, bool> _exerciseCompleted = {};

  @override
  void initState() {
    super.initState();
    completedSets = List.generate(
      widget.workout.exercises.length,
      (index) => <int>{},
    );
    _exerciseCompleted = {};
    startTimer();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isActive) {
        setState(() {
          _elapsed += const Duration(seconds: 1);
        });
      }
    });
  }

  String get formattedTime {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String minutes = twoDigits(_elapsed.inMinutes.remainder(60));
    String seconds = twoDigits(_elapsed.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Exercise get currentExercise {
    if (currentExerciseIndex >= widget.workout.exercises.length) {
      return widget.workout.exercises.last;
    }
    return widget.workout.exercises[currentExerciseIndex];
  }

  void completeSet(int setIndex) {
    setState(() {
      if (completedSets[currentExerciseIndex].contains(setIndex)) {
        completedSets[currentExerciseIndex].remove(setIndex);
      } else {
        completedSets[currentExerciseIndex].add(setIndex);
      }
    });
  }

  bool isSetCompleted(int setIndex) {
    if (currentExerciseIndex >= completedSets.length) {
      return false;
    }
    return completedSets[currentExerciseIndex].contains(setIndex);
  }

  bool isExerciseComplete() {
    if (currentExerciseIndex >= completedSets.length) {
      return true;
    }
    return completedSets[currentExerciseIndex].length == currentExercise.sets;
  }

  Future<void> _completeWorkout() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session expired. Please log in again.'),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      return;
    }

    try {
      final now = DateTime.now();

      // Update progress bar before any async operations
      setState(() {
        currentExerciseIndex = widget.workout.exercises.length - 1;
      });

      // Update first workout achievement
      if (mounted) {
        final achievementProvider = Provider.of<AchievementProvider>(context, listen: false);
        achievementProvider.updateAchievement('first_step', 1.0);
      }

      // Check if user data exists in database
      final userRef = FirebaseDatabase.instance.ref('users/${user.uid}');
      final userSnapshot = await userRef.get();
      if (!userSnapshot.exists) {
        // Create basic user data if it doesn't exist
        await userRef.set({
          'email': user.email,
          'createdAt': now.toIso8601String(),
          'lastActive': now.toIso8601String(),
        });
      } else {
        // Update last active timestamp
        await userRef.update({
          'lastActive': now.toIso8601String(),
        });
      }

      // Save to workout history
      final workoutRef = FirebaseDatabase.instance.ref('workoutHistory/${user.uid}').push();
      await workoutRef.set({
        'workoutId': widget.workout.id,
        'workoutTitle': widget.workout.title,
        'completedAt': now.toIso8601String(),
        'duration': _elapsed.inSeconds,
        'caloriesBurned': _caloriesBurned,
        'exercisesCompleted': widget.workout.exercises.length,
      });

      // Update weekly stats with retry mechanism
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekKey = '${weekStart.year}-${weekStart.month}-${weekStart.day}';
      final weeklyStatsRef = FirebaseDatabase.instance.ref('weeklyStats/${user.uid}/$weekKey');
      
      // Retry up to 3 times
      for (int i = 0; i < 3; i++) {
        try {
          final weeklySnapshot = await weeklyStatsRef.get();

          if (weeklySnapshot.exists) {
            final data = Map<String, dynamic>.from(weeklySnapshot.value as Map);
            await weeklyStatsRef.update({
              'totalCalories': (data['totalCalories'] ?? 0) + _caloriesBurned,
              'totalWorkouts': (data['totalWorkouts'] ?? 0) + 1,
              'totalDuration': (data['totalDuration'] ?? 0) + _elapsed.inSeconds,
              'lastUpdated': now.toIso8601String(),
            });
          } else {
            await weeklyStatsRef.set({
              'totalCalories': _caloriesBurned,
              'totalWorkouts': 1,
              'totalDuration': _elapsed.inSeconds,
              'weekStart': weekStart.toIso8601String(),
              'lastUpdated': now.toIso8601String(),
            });
          }
          break; // Success, exit retry loop
        } catch (e) {
          if (i == 2) throw e; // On last attempt, rethrow the error
          await Future.delayed(Duration(seconds: 1)); // Wait before retry
        }
      }

      if (!mounted) return;

      // Show completion message before navigation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Workout completed! Calories burned: $_caloriesBurned, Time: $formattedTime',
          ),
          backgroundColor: Colors.green,
        ),
      );

      // Add a small delay to ensure state updates and snackbar are processed
      await Future.delayed(const Duration(milliseconds: 100));

      if (!mounted) return;
      Navigator.popUntil(
        context,
        (route) => route.settings.name == '/workout' || route.isFirst,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving workout: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void onCompleteExercise() async {
    if (currentExerciseIndex >= widget.workout.exercises.length) {
      return;
    }

    if (!_exerciseCompleted.containsKey(currentExerciseIndex)) {
      setState(() {
        _caloriesBurned += currentExercise.calories;
        _exerciseCompleted[currentExerciseIndex] = true;
      });
    }

    if (currentExerciseIndex < widget.workout.exercises.length - 1) {
      setState(() {
        currentExerciseIndex++;
      });
    } else {
      // Workout completed
      _timer.cancel();
      _isActive = false; // Stop the timer updates
      await _completeWorkout();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.workout.title,
          style: const TextStyle(color: Colors.black),
        ),
        actions: [
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                formattedTime,
                style: TextStyle(
                  color: Colors.blue[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$_caloriesBurned cal',
                style: TextStyle(
                  color: Colors.orange[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Progress',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: currentExerciseIndex / widget.workout.exercises.length,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[400]!),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$currentExerciseIndex of ${widget.workout.exercises.length} exercises completed',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
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
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 24),
                ...List.generate(
                  currentExercise.sets,
                  (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: InkWell(
                      onTap: () => completeSet(index),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSetCompleted(index)
                                ? Colors.green
                                : Colors.grey[300]!,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              'Set ${index + 1}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              '${currentExercise.reps} reps',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            const Spacer(),
                            if (isSetCompleted(index))
                              const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: onCompleteExercise,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            currentExerciseIndex < widget.workout.exercises.length - 1
                ? 'Complete Exercise'
                : 'Finish Workout',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}