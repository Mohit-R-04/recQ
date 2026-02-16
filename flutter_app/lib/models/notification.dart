class AppNotification {
  final String? id;
  final String title;
  final String message;
  final String notificationType;
  final bool isRead;
  final String? createdAt;
  final String? readAt;
  final String? matchId;
  final String? itemId;

  AppNotification({
    this.id,
    required this.title,
    required this.message,
    required this.notificationType,
    this.isRead = false,
    this.createdAt,
    this.readAt,
    this.matchId,
    this.itemId,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id']?.toString(),
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      notificationType: json['notificationType'] ?? 'GENERAL',
      isRead: json['isRead'] ?? false,
      createdAt: json['createdAt'],
      readAt: json['readAt'],
      matchId: json['matchId']?.toString(),
      itemId: json['itemId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'message': message,
      'notificationType': notificationType,
      'isRead': isRead,
      if (createdAt != null) 'createdAt': createdAt,
      if (readAt != null) 'readAt': readAt,
      if (matchId != null) 'matchId': matchId,
      if (itemId != null) 'itemId': itemId,
    };
  }

  String get timeAgo {
    if (createdAt == null) return '';

    try {
      final created = DateTime.parse(createdAt!);
      final now = DateTime.now();
      final difference = now.difference(created);

      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return '';
    }
  }

  bool get isMatchNotification =>
      notificationType == 'MATCH_FOUND' ||
      notificationType == 'MATCH_CONFIRMED';
}
