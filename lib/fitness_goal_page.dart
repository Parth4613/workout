import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FitnessGoalsPage extends StatefulWidget {
  const FitnessGoalsPage({super.key});

  @override
  State<FitnessGoalsPage> createState() => _FitnessGoalsPageState();
}

class _FitnessGoalsPageState extends State<FitnessGoalsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final PageController _pageController = PageController();
  
  // Default values
  double _workoutDays = 3;
  double _weeklyHours = 4;
  double _calorieGoal = 2000;
  
  bool _isLoading = false;

  int _currentStep = 0;
  final int _totalSteps = 3;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _saveGoalsAndContinue() async {
    if (_auth.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You need to be logged in to save goals')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _database.ref().child('userGoals').child(_auth.currentUser!.uid).set({
        'workoutDays': _workoutDays.toInt(),
        'weeklyHours': _weeklyHours.toInt(),
        'calorieGoal': _calorieGoal.toInt(),
        'createdAt': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving goals: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LinearProgressIndicator(
                value: (_currentStep + 1) / _totalSteps,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4285F4)),
              ),
              const SizedBox(height: 20),
              Text(
                'Step ${_currentStep + 1} of $_totalSteps',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) {
                    setState(() {
                      _currentStep = index;
                    });
                  },
                  children: [
                    _buildWorkoutDaysQuestion(),
                    _buildWeeklyHoursQuestion(),
                    _buildCalorieGoalQuestion(),
                  ],
                ),
              ),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_currentStep == _totalSteps - 1)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveGoalsAndContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4285F4),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Complete Setup',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4285F4),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Next',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWorkoutDaysQuestion() {
    return _buildQuestionCard(
      question: 'How many days per week do you want to work out?',
      value: '${_workoutDays.round()} days',
      sliderValue: _workoutDays,
      min: 1,
      max: 7,
      onChanged: (value) => setState(() => _workoutDays = value),
      recommendation: 'Recommended: 3-5 days for beginners',
    );
  }

  Widget _buildWeeklyHoursQuestion() {
    return _buildQuestionCard(
      question: 'How many hours per week can you commit?',
      value: '${_weeklyHours.round()} hours',
      sliderValue: _weeklyHours,
      min: 1,
      max: 20,
      onChanged: (value) => setState(() => _weeklyHours = value),
      recommendation: 'Recommended: 6-8 hours for optimal results',
    );
  }

  Widget _buildCalorieGoalQuestion() {
    // Calculate divisions for 500 calorie increments
    int divisions = ((7000 - 1000) / 500).round();
    
    return _buildQuestionCard(
      question: 'What\'s your weekly calorie burn goal?',
      value: '${_calorieGoal.round()} calories',
      sliderValue: _calorieGoal,
      min: 1000,
      max: 7000,
      onChanged: (value) => setState(() => _calorieGoal = value.roundToDouble()),
      recommendation: 'Recommended: 1500-2500 calories for steady weekly progress',
    );
  }

  Widget _buildQuestionCard({
    required String question,
    required String value,
    required double sliderValue,
    required double min,
    required double max,
    required Function(double) onChanged,
    required String recommendation,
  }) {
    // Calculate divisions based on the range
    int divisions;
    if (question.contains('calorie')) {
      divisions = ((max - min) / 500).round(); // 500 calorie increments
    } else {
      divisions = (max - min).toInt(); // Keep existing behavior for other sliders
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 40),
        Text(
          value,
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 20),
        Slider(
          value: sliderValue,
          min: min,
          max: max,
          divisions: divisions,
          label: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF4285F4),
        ),
        const SizedBox(height: 20),
        Text(
          recommendation,
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
      ],
    );
  }
}