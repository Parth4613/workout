import 'workout.dart';

class ExerciseLibrary {
  // Chest Exercises
  static final Exercise pushUps = Exercise(
    name: 'Push-ups',
    description: 'Classic push-ups targeting chest, shoulders, and triceps',
    targetMuscles: 'Chest, Shoulders, Triceps',
    sets: 3,
    reps: 12,
    calories: 45,
    imageUrl: 'assets/images/workouts/pushup.jpg',
  );

  static final Exercise benchPress = Exercise(
    name: 'Bench Press',
    description: 'Barbell bench press for chest development',
    targetMuscles: 'Chest, Shoulders, Triceps',
    sets: 4,
    reps: 10,
    calories: 30,
    imageUrl: 'assets/images/workouts/bench_press.jpg',
  );

  // Legs Exercises
  static final Exercise squats = Exercise(
    name: 'Squats',
    description: 'Basic squats targeting quadriceps, hamstrings, and glutes',
    targetMuscles: 'Quadriceps, Hamstrings, Glutes',
    sets: 4,
    reps: 15,
    calories: 60,
    imageUrl: 'assets/images/workouts/squat.jpg',
  );

  static final Exercise lunges = Exercise(
    name: 'Lunges',
    description: 'Forward lunges for leg strength and stability',
    targetMuscles: 'Quadriceps, Hamstrings, Glutes',
    sets: 3,
    reps: 12,
    calories: 30,
    imageUrl: 'assets/images/workouts/lunges.jpg',
  );

  // Back Exercises
  static final Exercise pullUps = Exercise(
    name: 'Pull-ups',
    description: 'Basic pull-ups targeting back and biceps',
    targetMuscles: 'Back, Biceps',
    sets: 3,
    reps: 8,
    calories: 55,
    imageUrl: 'assets/images/workouts/pullup.jpg',
  );

  static final Exercise rows = Exercise(
    name: 'Bent Over Rows',
    description: 'Barbell rows for back thickness and strength',
    targetMuscles: 'Back, Biceps',
    sets: 3,
    reps: 12,
    calories: 30,
    imageUrl: 'assets/images/workouts/rows.jpg',
  );

  // Core Exercises
  static final Exercise plank = Exercise(
    name: 'Plank',
    description: 'Core stabilization exercise',
    targetMuscles: 'Core, Shoulders',
    sets: 3,
    reps: 1,
    calories: 10,
    imageUrl: 'assets/images/workouts/plank.jpg',
  );

  static final Exercise crunches = Exercise(
    name: 'Crunches',
    description: 'Basic crunches for core strength',
    targetMuscles: 'Core',
    sets: 3,
    reps: 20,
    calories: 15,
    imageUrl: 'assets/images/workouts/crunches.jpg',
  );

  // Helper method to get exercises by category
  static List<Exercise> getExercisesByCategory(String category) {
    switch (category.toLowerCase()) {
      case 'chest':
        return [pushUps, benchPress];
      case 'legs':
        return [squats, lunges];
      case 'back':
        return [pullUps, rows];
      case 'core':
        return [plank, crunches];
      default:
        return [];
    }
  }

  // Predefined workout templates
  static final Map<String, List<Exercise>> workoutTemplates = {
    'Full Body': [pushUps, squats, pullUps, plank],
    'Upper Body': [pushUps, benchPress, pullUps, rows],
    'Lower Body': [squats, lunges],
    'Core Focus': [plank, crunches],
  };
}