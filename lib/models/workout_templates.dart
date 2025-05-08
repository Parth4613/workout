import 'workout.dart';
import 'exercises.dart';

class WorkoutTemplates {
  static final Workout fullBodyWorkout = Workout(
    id: '1',
    title: 'Full Body Workout',
    description: 'Complete full body workout targeting all major muscle groups',
    duration: 30,
    calories: 170,
    difficulty: 'Beginner',
    category: 'Strength',
    imageUrl: 'assets/images/workouts/full_body.jpg',
    exercises: ExerciseLibrary.workoutTemplates['Full Body']!,
  );

  static final Workout upperBodyWorkout = Workout(
    id: '2',
    title: 'Upper Body Blast',
    description: 'Intense upper body workout focusing on chest, back, and arms',
    duration: 30,
    calories: 160,
    difficulty: 'Intermediate',
    category: 'Strength',
    imageUrl: 'assets/images/workouts/upper_body.jpg',
    exercises: ExerciseLibrary.workoutTemplates['Upper Body']!,
  );

  static final Workout lowerBodyWorkout = Workout(
    id: '3',
    title: 'Lower Body Focus',
    description: 'Leg-focused workout to build strength and stability',
    duration: 15,
    calories: 90,
    difficulty: 'Beginner',
    category: 'Strength',
    imageUrl: 'assets/images/workouts/lower_body.jpg',
    exercises: ExerciseLibrary.workoutTemplates['Lower Body']!,
  );

  static final Workout coreWorkout = Workout(
    id: '4',
    title: 'Core Crusher',
    description: 'Core-focused workout for a stronger midsection',
    duration: 15,
    calories: 25,
    difficulty: 'Intermediate',
    category: 'Core',
    imageUrl: 'assets/images/workouts/core.jpg',
    exercises: ExerciseLibrary.workoutTemplates['Core Focus']!,
  );

  static final List<Workout> allWorkouts = [
    fullBodyWorkout,
    upperBodyWorkout,
    lowerBodyWorkout,
    coreWorkout,
  ];

  static List<Workout> getWorkoutsByCategory(String category) {
    return allWorkouts.where((workout) => workout.category == category).toList();
  }

  static List<Workout> getWorkoutsByDifficulty(String difficulty) {
    return allWorkouts.where((workout) => workout.difficulty == difficulty).toList();
  }
}