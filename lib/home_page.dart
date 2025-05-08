import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import 'profile_page.dart';
import 'workout_page.dart';
import 'progress_page.dart';
import 'upgrade_page.dart';
import 'providers/avatar_provider.dart';
import 'providers/user_provider.dart';
import 'providers/achievement.dart';
import 'models/workout.dart';

class HomePage extends StatefulWidget {
  final int initialIndex;
  const HomePage({super.key, this.initialIndex = 0});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late int _selectedIndex;
  Map<String, dynamic> _workoutStats = {
    'totalCalories': 0,
    'totalWorkouts': 0,
    'totalDuration': 0,
  };
  Timer? _refreshTimer;
  StreamSubscription? _workoutHistorySubscription;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    
    // Refresh user data when the page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProvider>(context, listen: false).refreshUser();
      // Check achievements when loading the home page
      Provider.of<AchievementProvider>(context, listen: false).checkAchievements();
    });
    
    _fetchWorkoutStats();
    _setupAutoRefresh();
    _listenToWorkoutHistory();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _workoutHistorySubscription?.cancel();
    super.dispose();
  }

  void _setupAutoRefresh() {
    // Refresh stats every minute
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        _fetchWorkoutStats();
      }
    });
  }

  void _listenToWorkoutHistory() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    
    // Cancel any existing subscription
    _workoutHistorySubscription?.cancel();
    
    _workoutHistorySubscription = FirebaseDatabase.instance
        .ref('workoutHistory/$userId')
        .onValue
        .listen((event) async {
      if (event.snapshot.exists && mounted) {
        _fetchWorkoutStats();
        // Check achievements whenever workout history updates
        if (mounted) {
          await Provider.of<AchievementProvider>(context, listen: false).checkAchievements();
        }
      }
    });
  }

  void _fetchWorkoutStats() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    
    // Get workout history for current week
    final workoutHistoryRef = FirebaseDatabase.instance.ref('workoutHistory/$userId');
    final snapshot = await workoutHistoryRef.get();

    if (!snapshot.exists) {
      setState(() {
        _workoutStats = {
          'totalCalories': 0,
          'totalWorkouts': 0,
          'totalDuration': 0,
        };
      });
      return;
    }

    final workouts = Map<String, dynamic>.from(snapshot.value as Map);
    
    // Calculate weekly stats
    int totalCalories = 0;
    int totalWorkouts = 0;
    int totalDuration = 0;

    workouts.forEach((key, value) {
      try {
        final workout = Map<String, dynamic>.from(value as Map);
        if (!workout.containsKey('completedAt')) return;
        
        final completedAt = DateTime.parse(workout['completedAt'] as String);
        
        // Only count workouts from current week
        if (completedAt.isAfter(weekStart) || completedAt.isAtSameMomentAs(weekStart)) {
          // Handle potentially null or invalid values
          final calories = workout['calories'];
          if (calories != null) {
            totalCalories += (calories as num).toInt();
          }
          
          final duration = workout['duration'];
          if (duration != null) {
            totalDuration += (duration as num).toInt();
          }
          
          totalWorkouts++;
        }
      } catch (e) {
        debugPrint('Error processing workout: $e');
      }
    });

    setState(() {
      _workoutStats = {
        'totalCalories': totalCalories,
        'totalWorkouts': totalWorkouts,
        'totalDuration': totalDuration,
      };
    });
  }

  List<Widget> _getWidgetOptions() {
    return [
      _buildHomeContent(),
      const WorkoutPage(),
      const ProgressPage(),
      const UpgradePage(),
      const ProfilePage(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final widgetOptions = _getWidgetOptions();
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'Workouts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Progress',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.upgrade),
            label: 'Upgrade',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF4285F4),
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildHomeContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeHeader(),
          const SizedBox(height: 24),
          _buildWeeklySummary(),
          const SizedBox(height: 24),
          _buildTodaysWorkoutSection(),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    final avatarProvider = Provider.of<AvatarProvider>(context);
    // Use Consumer to listen for changes in the UserProvider
    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        final user = userProvider.user;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome back,',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF71757F),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.displayName ?? 'User',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A2138),
                  ),
                ),
              ],
            ),
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey[200],
              backgroundImage: avatarProvider.currentAvatar != null 
                  ? AssetImage(avatarProvider.currentAvatar!)
                  : null,
              child: avatarProvider.currentAvatar == null
                  ? Icon(Icons.person, size: 24, color: Colors.grey[600])
                  : null,
            ),
          ],
        );
      },
    );
  }

  Widget _buildWeeklySummary() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Weekly Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A2138),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                icon: Icons.fitness_center,
                iconColor: const Color(0xFF4285F4),
                iconBgColor: const Color(0xFFE8F1FE),
                value: '${_workoutStats['totalWorkouts']}',
                label: 'Workouts',
              ),
              _buildStatItem(
                icon: Icons.local_fire_department,
                iconColor: const Color(0xFFF85C5C),
                iconBgColor: const Color(0xFFFEE8E8),
                value: '${_workoutStats['totalCalories']}',
                label: 'Calories',
              ),
              _buildStatItem(
                icon: Icons.timer,
                iconColor: const Color(0xFF4CD964),
                iconBgColor: const Color(0xFFE8FEF0),
                value: '${(_workoutStats['totalDuration'] / 60).round()}',
                label: 'Minutes',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: iconBgColor,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 24,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A2138),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF71757F),
          ),
        ),
      ],
    );
  }

  Widget _buildTodaysWorkoutSection() {
    // Use the actual Full Body Workout with correct values
    final Workout workout = Workout(
      id: '1',
      title: 'Full Body Workout',
      description: 'Complete full body workout targeting all major muscle groups',
      duration: 20,
      calories: 120,
      difficulty: 'Beginner',
      category: 'Strength',
      imageUrl: 'assets/images/workouts/full_body.jpg',
      exercises: [
        Exercise(
          name: 'Push-ups',
          description: 'Classic push-ups targeting chest, shoulders, and triceps',
          targetMuscles: 'Chest, Shoulders, Triceps',
          sets: 3,
          reps: 12,
          calories: 45,
          imageUrl: 'assets/images/workouts/pushup.jpg',
        ),
        Exercise(
          name: 'Squats',
          description: 'Basic squats targeting quadriceps, hamstrings, and glutes',
          targetMuscles: 'Quadriceps, Hamstrings, Glutes',
          sets: 4,
          reps: 15,
          calories: 35,
          imageUrl: 'assets/images/workouts/squat.jpg',
        ),
        Exercise(
          name: 'Pull-ups',
          description: 'Basic pull-ups targeting back and biceps',
          targetMuscles: 'Back, Biceps',
          sets: 3,
          reps: 8,
          calories: 40,
          imageUrl: 'assets/images/workouts/pullup.jpg',
        ),
      ],
    );

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = 1; // Switch to Workouts page
        });
      },
      child: Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.asset(
                  workout.imageUrl,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    workout.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    workout.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.timer_outlined, size: 16, color: Colors.blue[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${workout.duration} min',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.local_fire_department_outlined, 
                           size: 16, 
                           color: Colors.orange[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${workout.calories} cal',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          workout.difficulty,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}