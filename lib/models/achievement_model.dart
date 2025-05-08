class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final int requirementValue;
  bool isUnlocked;
  double progress;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.requirementValue,
    this.isUnlocked = false,
    this.progress = 0.0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'icon': icon,
    'requirementValue': requirementValue,
    'isUnlocked': isUnlocked,
    'progress': progress,
  };

  factory Achievement.fromJson(Map<String, dynamic> json) => Achievement(
    id: json['id'],
    title: json['title'],
    description: json['description'],
    icon: json['icon'],
    requirementValue: json['requirementValue'],
    isUnlocked: json['isUnlocked'],
    progress: json['progress'],
  );
}