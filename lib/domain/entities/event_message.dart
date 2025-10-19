/// Event message entity representing a chat message in an event
class EventMessage {
  final String id;
  final String eventId;
  final String userId;
  final String userName;
  final String? userAvatarUrl;
  final String content;
  final DateTime createdAt;
  final bool isMe;

  const EventMessage({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.userName,
    this.userAvatarUrl,
    required this.content,
    required this.createdAt,
    this.isMe = false,
  });

  factory EventMessage.fromJson(
    Map<String, dynamic> json,
    String? currentUserId,
  ) {
    return EventMessage(
      id: json['id'] ?? '',
      eventId: json['eventId'] ?? json['event_id'] ?? '',
      userId: json['userId'] ?? json['user_id'] ?? '',
      userName:
          json['userName'] ??
          json['user_name'] ??
          json['user']?['name'] ??
          'Unknown User',
      userAvatarUrl:
          json['userAvatarUrl'] ??
          json['user_avatar_url'] ??
          json['user']?['avatar_url'],
      content: json['content'] ?? json['message'] ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt'] ?? json['created_at'] ?? '') ??
          DateTime.now(),
      isMe:
          currentUserId != null &&
          (json['userId'] ?? json['user_id']) == currentUserId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
      'userId': userId,
      'userName': userName,
      'userAvatarUrl': userAvatarUrl,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  EventMessage copyWith({
    String? id,
    String? eventId,
    String? userId,
    String? userName,
    String? userAvatarUrl,
    String? content,
    DateTime? createdAt,
    bool? isMe,
  }) {
    return EventMessage(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      isMe: isMe ?? this.isMe,
    );
  }

  @override
  String toString() {
    return 'EventMessage(id: $id, eventId: $eventId, userId: $userId, userName: $userName, content: $content, createdAt: $createdAt, isMe: $isMe)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EventMessage &&
        other.id == id &&
        other.eventId == eventId &&
        other.userId == userId &&
        other.content == content;
  }

  @override
  int get hashCode {
    return id.hashCode ^ eventId.hashCode ^ userId.hashCode ^ content.hashCode;
  }
}
