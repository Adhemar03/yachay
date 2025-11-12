class Achievement {
  final String id; // internal id (e.g., 'racha_5')
  final int? dbId; // achievement_id from DB if available
  final String title;
  final String description;
  final String? iconUrl; // icon filename or URL
  final bool unlocked;
  final DateTime? unlockedAt;

  const Achievement({
    required this.id,
    this.dbId,
    required this.title,
    required this.description,
    this.iconUrl,
    this.unlocked = false,
    this.unlockedAt,
  });

  Achievement copyWith({
    bool? unlocked,
    DateTime? unlockedAt,
    int? dbId,
    String? iconUrl,
    String? title,
    String? description,
  }) {
    return Achievement(
      id: id,
      dbId: dbId ?? this.dbId,
      title: title ?? this.title,
      description: description ?? this.description,
      iconUrl: iconUrl ?? this.iconUrl,
      unlocked: unlocked ?? this.unlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'dbId': dbId,
        'title': title,
        'description': description,
        'iconUrl': iconUrl,
        'unlocked': unlocked,
        'unlockedAt': unlockedAt?.toIso8601String(),
      };

  factory Achievement.fromMap(Map<String, dynamic> m) => Achievement(
        id: m['id'] as String,
        dbId: m['dbId'] as int?,
        title: m['title'] as String,
        description: m['description'] as String,
        iconUrl: m['iconUrl'] as String?,
        unlocked: m['unlocked'] as bool? ?? false,
        unlockedAt: m['unlockedAt'] != null
            ? DateTime.parse(m['unlockedAt'] as String)
            : null,
      );
}
