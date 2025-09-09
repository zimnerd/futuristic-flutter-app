/// Simple message model without complex JSON generation
/// Part of the clean architecture - easy to read and maintain
class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String? receiverId;
  final String content;
  final String type; // text, image, video, audio, location
  final String? mediaUrl;
  final Map<String, dynamic>? metadata;
  final bool isRead;
  final bool isEdited;
  final bool isDeleted;
  final DateTime? readAt;
  final DateTime? editedAt;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.receiverId,
    required this.content,
    this.type = 'text',
    this.mediaUrl,
    this.metadata,
    this.isRead = false,
    this.isEdited = false,
    this.isDeleted = false,
    this.readAt,
    this.editedAt,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  // Simple JSON methods without code generation
  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] ?? '',
      conversationId: json['conversationId'] ?? '',
      senderId: json['senderId'] ?? '',
      receiverId: json['receiverId'],
      content: json['content'] ?? '',
      type: json['type'] ?? 'text',
      mediaUrl: json['mediaUrl'],
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
      isRead: json['isRead'] ?? false,
      isEdited: json['isEdited'] ?? false,
      isDeleted: json['isDeleted'] ?? false,
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt']) : null,
      editedAt: json['editedAt'] != null
          ? DateTime.parse(json['editedAt'])
          : null,
      deletedAt: json['deletedAt'] != null
          ? DateTime.parse(json['deletedAt'])
          : null,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'type': type,
      'mediaUrl': mediaUrl,
      'metadata': metadata,
      'isRead': isRead,
      'isEdited': isEdited,
      'isDeleted': isDeleted,
      'readAt': readAt?.toIso8601String(),
      'editedAt': editedAt?.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  MessageModel copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? receiverId,
    String? content,
    String? type,
    String? mediaUrl,
    Map<String, dynamic>? metadata,
    bool? isRead,
    bool? isEdited,
    bool? isDeleted,
    DateTime? readAt,
    DateTime? editedAt,
    DateTime? deletedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MessageModel(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      type: type ?? this.type,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      metadata: metadata ?? this.metadata,
      isRead: isRead ?? this.isRead,
      isEdited: isEdited ?? this.isEdited,
      isDeleted: isDeleted ?? this.isDeleted,
      readAt: readAt ?? this.readAt,
      editedAt: editedAt ?? this.editedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'MessageModel(id: $id, senderId: $senderId, type: $type)';
}
