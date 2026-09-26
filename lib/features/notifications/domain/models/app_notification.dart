enum NotificationType {
  treatment,
  scan,
  system,
  community
}

class AppNotification {
  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  final NotificationType type;
  final bool isRead;
  final String? relatedId; // e.g. scanId or postId

  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.type,
    this.isRead = false,
    this.relatedId,
  });

  AppNotification copyWith({
    bool? isRead,
  }) {
    return AppNotification(
      id: id,
      title: title,
      message: message,
      createdAt: createdAt,
      type: type,
      isRead: isRead ?? this.isRead,
      relatedId: relatedId,
    );
  }

  Map<String, dynamic> toLocalJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
      'type': type.name,
      'isRead': isRead,
      'relatedId': relatedId,
    };
  }

  factory AppNotification.fromLocalJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      type: NotificationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => NotificationType.system,
      ),
      isRead: json['isRead'] as bool? ?? false,
      relatedId: json['relatedId'] as String?,
    );
  }
}
