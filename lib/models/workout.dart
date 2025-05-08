class Exercise {
  final String name;
  final String description;
  final String targetMuscles;
  final int sets;
  final int reps;
  final String? imageUrl;
  final int calories; // Added calories per exercise

  const Exercise({
    required this.name,
    required this.description,
    required this.targetMuscles,
    required this.sets,
    required this.reps,
    this.imageUrl,
    required this.calories,
  });
}

class Workout {
  final String id;
  final String title;
  final String description;
  final int duration;
  final int calories;
  final String difficulty;
  final String category;
  final String imageUrl;
  final List<Exercise> exercises;

  const Workout({
    required this.id,
    required this.title,
    required this.description,
    required this.duration,
    required this.calories,
    required this.difficulty,
    required this.category,
    required this.imageUrl,
    this.exercises = const [],
  });
}