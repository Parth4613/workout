import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

final FirebaseDatabase _database = FirebaseDatabase.instance;

class ProgressPage extends StatefulWidget {
  const ProgressPage({Key? key}) : super(key: key);

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  String _selectedPeriod = 'Weekly';
  Map<String, dynamic> _userGoals = {};
  Map<String, dynamic> _workoutStats = {
    'weeklyCalories': 0,
    'activeWorkoutDays': 0,
    'avgTimePerDay': 0.0,
  };
  bool _isLoading = true;

  late final Map<String, List<double>> activityData = _initActivityData();
  late final Map<String, List<String>> periodLabels = _initPeriodLabels();

  Map<String, List<String>> _initPeriodLabels() {
    return {
      'Weekly': ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
    };
  }

  Map<String, List<double>> _initActivityData() {
    return {
      'Weekly': List.filled(7, 0.0),
    };
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await Future.wait<void>([
      _fetchGoals(),
      Future<void>(() async => await _fetchWorkoutStats()),
    ]);
    setState(() => _isLoading = false);
  }

  Future<void> _fetchGoals() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      try {
        print("Fetching goals for user: $userId");
        final snapshot = await _database.ref('userGoals/$userId').get();
        if (snapshot.exists) {
          setState(() {
            _userGoals = Map<String, dynamic>.from(snapshot.value as Map);
            print("Goals fetched: $_userGoals");
          });
        } else {
          print("No goals found, setting defaults");
          setState(() {
            _userGoals = {
              'workoutDays': 4,
              'calorieGoal': 2000,
              'weeklyHours': 6,
            };
          });
        }
      } catch (e) {
        print("Error fetching goals: $e");
        setState(() {
          _userGoals = {
            'workoutDays': 4,
            'calorieGoal': 2000,
            'weeklyHours': 6,
          };
        });
      }
    } else {
      print("No user ID available");
    }
  }

  Future<void> _fetchWorkoutStats() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      print("No user ID available for workout stats");
      return;
    }

    try {
      final now = DateTime.now();
      print("DEBUG: Current date: ${now.toString()}");

      DateTime startDate = now.subtract(Duration(days: now.weekday - 1));
      startDate = DateTime(startDate.year, startDate.month, startDate.day);
      DateTime endDate = startDate.add(const Duration(days: 6));
      int daysToShow = 7;

      print("DEBUG: Start date: $startDate");
      print("DEBUG: End date: $endDate");

      List<double> newActivityData = List.filled(daysToShow, 0.0);

      Map<String, dynamic> periodStats = {
        'weeklyCalories': 0,
        'activeWorkoutDays': Set<int>(),
        'totalDuration': 0,
      };

      final workoutHistoryRef = _database.ref('workoutHistory/$userId');
      final historySnapshot = await workoutHistoryRef.get();
      
      if (historySnapshot.exists) {
        final historyData = Map<String, dynamic>.from(historySnapshot.value as Map);
        Map<int, Map<String, dynamic>> dayWorkouts = {};
        
        historyData.forEach((key, value) {
          if (value != null) {
            final workout = Map<String, dynamic>.from(value as Map);
            if (workout.containsKey('completedAt')) {
              DateTime completedAt = DateTime.parse(workout['completedAt'] as String).toLocal();
              
              if (completedAt.isAfter(startDate.subtract(const Duration(minutes: 1))) && 
                  completedAt.isBefore(endDate.add(const Duration(days: 1)))) {
                
                int dayIndex = completedAt.weekday - 1;
                
                print("DEBUG: Processing workout completed at $completedAt, dayIndex: $dayIndex");

                if (!dayWorkouts.containsKey(dayIndex)) {
                  dayWorkouts[dayIndex] = {
                    'count': 0,
                    'calories': 0,
                    'duration': 0,
                  };
                }

                dayWorkouts[dayIndex]!['count'] = (dayWorkouts[dayIndex]!['count'] as int) + 1;
                (periodStats['activeWorkoutDays'] as Set<int>).add(dayIndex);
                
                if (workout.containsKey('caloriesBurned')) {
                  int calories = workout['caloriesBurned'] as int? ?? 0;
                  dayWorkouts[dayIndex]!['calories'] = (dayWorkouts[dayIndex]!['calories'] as int) + calories;
                  periodStats['weeklyCalories'] = (periodStats['weeklyCalories'] as int) + calories;
                }
                
                if (workout.containsKey('duration')) {
                  int duration = workout['duration'] as int? ?? 0;
                  dayWorkouts[dayIndex]!['duration'] = (dayWorkouts[dayIndex]!['duration'] as int) + duration;
                  periodStats['totalDuration'] = (periodStats['totalDuration'] as int) + duration;
                }
              }
            }
          }
        });

        print("DEBUG: Day workouts data: $dayWorkouts");
        
        dayWorkouts.forEach((day, stats) {
          if (day >= 0 && day < newActivityData.length) {
            newActivityData[day] = stats['count'] > 0 ? 1.0 : 0.0;
          }
        });

        setState(() {
          activityData[_selectedPeriod] = newActivityData;
          _workoutStats = {
            'weeklyCalories': periodStats['weeklyCalories'],
            'activeWorkoutDays': (periodStats['activeWorkoutDays'] as Set<int>).length,
            'avgTimePerDay': periodStats['totalDuration'] > 0 
                ? (periodStats['totalDuration'] as int).toDouble() / daysToShow 
                : 0.0,
          };
        });
      }
    } catch (e, stackTrace) {
      print("Error fetching workout stats: $e");
      print("Stack trace: $stackTrace");
      setState(() {
        activityData[_selectedPeriod] = List.filled(7, 0.0);
        _workoutStats = {
          'weeklyCalories': 0,
          'activeWorkoutDays': 0,
          'avgTimePerDay': 0.0,
        };
      });
    }
  }

  Future<void> _saveGoals(int workoutDays, int calorieGoal, int weeklyHours) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      try {
        print("Saving goals for user: $userId");
        await _database.ref('userGoals/$userId').update({
          'workoutDays': workoutDays,
          'calorieGoal': calorieGoal,
          'weeklyHours': weeklyHours,
        });
        print("Goals saved successfully");
        _fetchGoals();
      } catch (e) {
        print("Error saving goals: $e");
      }
    }
  }

  Widget _buildGoalsCard() {
    int workoutDays = _userGoals['workoutDays'] ?? 5;
    int calorieGoal = _userGoals['calorieGoal'] ?? 2000;
    int weeklyHours = _userGoals['weeklyHours'] ?? 6;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Your Goals', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    double workoutValue = workoutDays.toDouble();
                    double calorieValue = calorieGoal.toDouble();
                    double hoursValue = weeklyHours.toDouble();
                    
                    showDialog(
                      context: context,
                      builder: (context) {
                        return StatefulBuilder(
                          builder: (context, setState) {
                            return AlertDialog(
                              title: const Text('Edit Goals'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('Weekly Active Days: ${workoutValue.round()}'),
                                  Slider(
                                    value: workoutValue,
                                    min: 1,
                                    max: 7,
                                    divisions: 6,
                                    onChanged: (value) {
                                      setState(() => workoutValue = value);
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  Text('Weekly Hours: ${hoursValue.round()}'),
                                  Slider(
                                    value: hoursValue,
                                    min: 1,
                                    max: 20,
                                    divisions: 19,
                                    onChanged: (value) {
                                      setState(() => hoursValue = value);
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  Text('Weekly Calorie Goal: ${calorieValue.round()}'),
                                  Slider(
                                    value: calorieValue,
                                    min: 1000,
                                    max: 7000,
                                    divisions: 12,
                                    onChanged: (value) {
                                      setState(() => calorieValue = value);
                                    },
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    _saveGoals(
                                      workoutValue.round(),
                                      calorieValue.round(),
                                      hoursValue.round(),
                                    );
                                    Navigator.pop(context);
                                  },
                                  child: const Text('Save'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildGoalProgress('Weekly Active Days', workoutDays, 7, const Color(0xFF4285F4)),
            const SizedBox(height: 16),
            _buildGoalProgress('Weekly Hours', weeklyHours, 20, const Color(0xFF4285F4)),
            const SizedBox(height: 16),
            _buildGoalProgress('Weekly Calories', calorieGoal, 3500, const Color(0xFF4285F4)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4285F4)),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Progress', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildActivityCard(),
                  const SizedBox(height: 16),
                  _buildMetricsRow(),
                  const SizedBox(height: 16),
                  _buildGoalsCard(),
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildActivityCard() {
    final now = DateTime.now();
    final todayIndex = now.weekday - 1;
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Weekly Activity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(
                7,
                (index) => _buildActivityBar(
                  activityData['Weekly']![index],
                  periodLabels['Weekly']![index],
                  index == todayIndex,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityBar(double height, String label, bool isHighlighted) {
    final double barHeight = height > 0 ? 120 * height : 2;
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 30,
          height: barHeight,
          decoration: BoxDecoration(
            color: isHighlighted ? const Color(0xFF4285F4) : const Color(0xFFA4CAFB),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 30,
          child: Text(
            label, 
            style: const TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricsRow() {
    String formatTime(double seconds) {
      if (seconds < 60) {
        return "${seconds.toInt()}s";
      }
      final minutes = (seconds / 60).toInt();
      if (minutes < 60) {
        return "${minutes}m";
      }
      final hours = (minutes / 60).toInt();
      final remainingMinutes = minutes % 60;
      return "${hours}h ${remainingMinutes}m";
    }

    return Row(
      children: [
        Expanded(child: _buildMetricCard('${_workoutStats['activeWorkoutDays']}', 'Active Days')),
        const SizedBox(width: 12),
        Expanded(child: _buildMetricCard('${_workoutStats['weeklyCalories']}', 'Weekly Calories')),
        const SizedBox(width: 12),
        Expanded(child: _buildMetricCard(
          formatTime(_workoutStats['avgTimePerDay'] ?? 0),
          'Avg Time/Day'
        )),
      ],
    );
  }

  Widget _buildMetricCard(String value, String label) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalProgress(String label, num target, num maxTarget, Color color) {
    num currentValue = 0;
    String displayValue = '';
    String displayTarget = '';
    
    switch (label) {
      case 'Weekly Active Days':
        currentValue = _workoutStats['activeWorkoutDays'] ?? 0;
        displayValue = currentValue.toString();
        displayTarget = target.toString();
        break;
      case 'Weekly Calories':
        currentValue = _workoutStats['weeklyCalories'] ?? 0;
        displayValue = currentValue.toString();
        displayTarget = target.toString();
        break;
      case 'Weekly Hours':
        double totalSeconds = (_workoutStats['avgTimePerDay'] ?? 0) * 7;
        double totalMinutes = totalSeconds / 60; // Convert seconds to minutes
        currentValue = totalMinutes / 60; // Convert minutes to hours for progress calculation
        
        if (totalSeconds < 60) {
          // Show as seconds if less than a minute
          displayValue = "${totalSeconds.toInt()} sec";
          displayTarget = "$target hrs";
        } else if (totalMinutes < 60) {
          // Show minutes and seconds if less than an hour
          int minutes = totalMinutes.floor();
          displayValue = "$minutes min";
          displayTarget = "$target hrs";
        } else {
          // Show hours
          displayValue = "${currentValue.toStringAsFixed(1)} hrs";
          displayTarget = "$target hrs";
        }
        break;
    }

    final double progress = currentValue / target;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            color: color,
            backgroundColor: color.withOpacity(0.3),
            minHeight: 10,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label == 'Weekly Hours' 
              ? '$displayValue / $displayTarget'
              : '$currentValue / $target', 
          style: const TextStyle(fontSize: 12, color: Colors.grey)
        ),
      ],
    );
  }
}