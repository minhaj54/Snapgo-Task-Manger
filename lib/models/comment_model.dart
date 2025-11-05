class Comment {
  final String id;
  final String taskId;
  final String authorName;
  final String content;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Comment({
    required this.id,
    required this.taskId,
    required this.authorName,
    required this.content,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    final map = {
      'taskId': taskId,
      'authorName': authorName,
      'content': content,
    };
    
    // Only include updatedAt if it's not null (for updates)
    if (updatedAt != null) {
      map['updatedAt'] = updatedAt!.toIso8601String();
    }
    
    return map;
  }

  factory Comment.fromMap(Map<String, dynamic> map) => Comment(
    id: map['\$id'] ?? '',
    taskId: map['taskId'] ?? '',
    authorName: map['authorName'] ?? '',
    content: map['content'] ?? '',
    createdAt: _parseDateOrNull(map['createdAt'] ?? map['\$createdAt']),
    updatedAt: _parseDateOrNull(map['updatedAt'] ?? map['\$updatedAt']),
  );
}

DateTime? _parseDateOrNull(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }
  return null;
}

