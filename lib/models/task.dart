class Task {
  String? id;
  String title;
  String description;
  DateTime startDate;
  DateTime endDate;
  bool isCompleted;
  String userId;
  bool isDeleted;
  List<String> imageUrls;
  String? backgroundColorHex;

  Task({
    this.id,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    this.isCompleted = false,
    required this.userId,
    this.isDeleted = false,
    this.imageUrls = const [],
    this.backgroundColorHex,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'isCompleted': isCompleted,
      'userId': userId,
      'isDeleted': isDeleted,
      'imageUrls': imageUrls,
      'backgroundColorHex': backgroundColorHex,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      isCompleted: json['isCompleted'] ?? false,
      userId: json['userId'],
      isDeleted: json['isDeleted'] ?? false,
      imageUrls: (json['imageUrls'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      backgroundColorHex: json['backgroundColorHex'],
    );
  }

  // Helper methods để lấy thời gian định dạng đẹp
  String get formattedStartDate {
    return '${_formatDate(startDate)} ${_formatTime(startDate)}';
  }

  String get formattedEndDate {
    return '${_formatDate(endDate)} ${_formatTime(endDate)}';
  }

  String get formattedDateRange {
    return '${_formatDate(startDate)} ${_formatTime(startDate)} - ${_formatDate(endDate)} ${_formatTime(endDate)}';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  // Kiểm tra xem công việc có sắp đến hạn không
  bool get isDueSoon {
    final now = DateTime.now();
    final difference = endDate.difference(now);
    return !isCompleted && difference.inHours <= 24 && difference.inSeconds > 0;
  }

  bool get isOverdue {
    return !isCompleted && endDate.isBefore(DateTime.now());
  }
}