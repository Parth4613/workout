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
    progress: (json['progress'] is int) ? (json['progress'] as int).toDouble() : (json['progress'] as num).toDouble(),
  );

  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    String? icon,
    int? requirementValue,
    bool? isUnlocked,
    double? progress,
  }) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      requirementValue: requirementValue ?? this.requirementValue,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      progress: progress ?? this.progress,
    );
  }
}