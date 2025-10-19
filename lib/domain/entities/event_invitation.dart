import 'package:equatable/equatable.dart';
import '../../data/models/user_model.dart';
import 'event.dart';

class EventInvitation extends Equatable {
  final String id;
  final String eventId;
  final String invitedById;
  final String invitedUserId;
  final EventInvitationStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;
  final Event? event;
  final UserModel? invitedBy;
  final UserModel? invitedUser;

  const EventInvitation({
    required this.id,
    required this.eventId,
    required this.invitedById,
    required this.invitedUserId,
    required this.status,
    required this.createdAt,
    this.respondedAt,
    this.event,
    this.invitedBy,
    this.invitedUser,
  });

  factory EventInvitation.fromJson(Map<String, dynamic> json) {
    return EventInvitation(
      id: json['id'] as String,
      eventId: json['eventId'] as String,
      invitedById: json['invitedById'] as String,
      invitedUserId: json['invitedUserId'] as String,
      status: EventInvitationStatus.values.firstWhere(
        (e) => e.name.toLowerCase() == (json['status'] as String).toLowerCase(),
        orElse: () => EventInvitationStatus.pending,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      respondedAt: json['respondedAt'] != null
          ? DateTime.parse(json['respondedAt'] as String)
          : null,
      event: json['event'] != null
          ? Event.fromJson(json['event'] as Map<String, dynamic>)
          : null,
      invitedBy: json['invitedBy'] != null
          ? UserModel.fromJson(json['invitedBy'] as Map<String, dynamic>)
          : null,
      invitedUser: json['invitedUser'] != null
          ? UserModel.fromJson(json['invitedUser'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
      'invitedById': invitedById,
      'invitedUserId': invitedUserId,
      'status': status.name.toUpperCase(),
      'createdAt': createdAt.toIso8601String(),
      'respondedAt': respondedAt?.toIso8601String(),
      'event': event?.toJson(),
      'invitedBy': invitedBy?.toJson(),
      'invitedUser': invitedUser?.toJson(),
    };
  }

  EventInvitation copyWith({
    String? id,
    String? eventId,
    String? invitedById,
    String? invitedUserId,
    EventInvitationStatus? status,
    DateTime? createdAt,
    DateTime? respondedAt,
    Event? event,
    UserModel? invitedBy,
    UserModel? invitedUser,
  }) {
    return EventInvitation(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      invitedById: invitedById ?? this.invitedById,
      invitedUserId: invitedUserId ?? this.invitedUserId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
      event: event ?? this.event,
      invitedBy: invitedBy ?? this.invitedBy,
      invitedUser: invitedUser ?? this.invitedUser,
    );
  }

  @override
  List<Object?> get props => [
    id,
    eventId,
    invitedById,
    invitedUserId,
    status,
    createdAt,
    respondedAt,
    event,
    invitedBy,
    invitedUser,
  ];
}

enum EventInvitationStatus { pending, accepted, declined }

class CreateEventInvitationRequest {
  final String eventId;
  final List<String> userIds;

  const CreateEventInvitationRequest({
    required this.eventId,
    required this.userIds,
  });

  Map<String, dynamic> toJson() {
    return {'eventId': eventId, 'userIds': userIds};
  }
}

class RespondToInvitationRequest {
  final String invitationId;
  final EventInvitationStatus status;

  const RespondToInvitationRequest({
    required this.invitationId,
    required this.status,
  });

  Map<String, dynamic> toJson() {
    return {'invitationId': invitationId, 'status': status.name.toUpperCase()};
  }
}
