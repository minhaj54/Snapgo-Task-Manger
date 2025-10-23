class Task {
  final String id;
  final String title;
  final String description;
  final String assignedTo; // Can be comma-separated usernames for multiple users
  final DateTime deadline;
  final String status; // 'pending' | 'in-progress' | 'completed'
  final DateTime? createdAt; // read-only, from DB (createdAt or $createdAt)

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.assignedTo,
    required this.deadline,
    required this.status,
    this.createdAt,
  });

  // Get list of assigned users
  List<String> get assignedUsers => assignedTo.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

  Map<String, dynamic> toMap() => {
    'title': title,
    'description': description,
    'assignedTo': assignedTo,
    'deadline': deadline.toIso8601String(),
    'status': status,
  };

  factory Task.fromMap(Map<String, dynamic> map) => Task(
    id: map['\$id'] ?? '',
    title: map['title'] ?? '',
    description: map['description'] ?? '',
    assignedTo: map['assignedTo'] ?? '',
    deadline: _parseDate(map['deadline']),
    status: (map['status'] ?? 'pending') as String,
    createdAt: _parseDateOrNull(map['createdAt'] ?? map['\$createdAt']),
  );
}

DateTime _parseDate(dynamic value) {
  if (value is DateTime) return value;
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value) ?? DateTime.now();
  }
  return DateTime.now();
}

DateTime? _parseDateOrNull(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }
  return null;
}