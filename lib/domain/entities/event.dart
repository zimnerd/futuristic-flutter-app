class EventCoordinates {
  final double lat;
  final double lng;

  const EventCoordinates({
    required this.lat,
    required this.lng,
  });

  factory EventCoordinates.fromJson(Map<String, dynamic> json) {
    return EventCoordinates(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lat': lat,
      'lng': lng,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventCoordinates && lat == other.lat && lng == other.lng;

  @override
  int get hashCode => lat.hashCode ^ lng.hashCode;

  @override
  String toString() => 'EventCoordinates(lat: $lat, lng: $lng)';
}

class Event {
  final String id;
  final String title;
  final String description;
  final String location;
  final EventCoordinates coordinates;
  final DateTime date;
  final String? image;
  final String category;
  final String? createdBy;
  final DateTime createdAt;
  final List<EventAttendance> attendees;
  final bool isAttending;
  final int attendeeCount;

  const Event({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.coordinates,
    required this.date,
    this.image,
    required this.category,
    this.createdBy,
    required this.createdAt,
    this.attendees = const [],
    this.isAttending = false,
    this.attendeeCount = 0,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      location: json['location'] as String,
      coordinates: EventCoordinates.fromJson(json['coordinates'] as Map<String, dynamic>),
      date: DateTime.parse(json['date'] as String),
      image: json['image'] as String?,
      category: json['category'] as String,
      createdBy: json['createdBy'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      attendees: (json['attendees'] as List<dynamic>?)
          ?.map((e) => EventAttendance.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      isAttending: json['isAttending'] as bool? ?? false,
      attendeeCount: json['attendeeCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'location': location,
      'coordinates': coordinates.toJson(),
      'date': date.toIso8601String(),
      'image': image,
      'category': category,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'attendees': attendees.map((e) => e.toJson()).toList(),
      'isAttending': isAttending,
      'attendeeCount': attendeeCount,
    };
  }

  Event copyWith({
    String? id,
    String? title,
    String? description,
    String? location,
    EventCoordinates? coordinates,
    DateTime? date,
    String? image,
    String? category,
    String? createdBy,
    DateTime? createdAt,
    List<EventAttendance>? attendees,
    bool? isAttending,
    int? attendeeCount,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      coordinates: coordinates ?? this.coordinates,
      date: date ?? this.date,
      image: image ?? this.image,
      category: category ?? this.category,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      attendees: attendees ?? this.attendees,
      isAttending: isAttending ?? this.isAttending,
      attendeeCount: attendeeCount ?? this.attendeeCount,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Event && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Event(id: $id, title: $title, date: $date)';
}

class EventAttendance {
  final String id;
  final String userId;
  final String eventId;
  final String status;
  final DateTime timestamp;
  final Map<String, dynamic>? user;

  const EventAttendance({
    required this.id,
    required this.userId,
    required this.eventId,
    required this.status,
    required this.timestamp,
    this.user,
  });

  factory EventAttendance.fromJson(Map<String, dynamic> json) {
    return EventAttendance(
      id: json['id'] as String,
      userId: json['userId'] as String,
      eventId: json['eventId'] as String,
      status: json['status'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      user: json['user'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'eventId': eventId,
      'status': status,
      'timestamp': timestamp.toIso8601String(),
      'user': user,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventAttendance && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'EventAttendance(id: $id, status: $status)';
}

class CreateEventRequest {
  final String title;
  final String description;
  final String location;
  final EventCoordinates coordinates;
  final DateTime date;
  final String? image;
  final String category;

  const CreateEventRequest({
    required this.title,
    required this.description,
    required this.location,
    required this.coordinates,
    required this.date,
    this.image,
    required this.category,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'location': location,
      'coordinates': coordinates.toJson(),
      'date': date.toIso8601String(),
      'image': image,
      'category': category,
    };
  }
}

// Event categories - matching backend schema
class EventCategories {
  static const String music = 'music';
  static const String sports = 'sports';
  static const String food = 'food';
  static const String drinks = 'drinks';
  static const String culture = 'culture';
  static const String outdoors = 'outdoors';
  static const String networking = 'networking';
  static const String education = 'education';
  static const String wellness = 'wellness';
  static const String social = 'social';

  static const List<String> all = [
    music,
    sports,
    food,
    drinks,
    culture,
    outdoors,
    networking,
    education,
    wellness,
    social,
  ];

  static String getDisplayName(String category) {
    switch (category) {
      case music:
        return 'Music';
      case sports:
        return 'Sports';
      case food:
        return 'Food';
      case drinks:
        return 'Drinks';
      case culture:
        return 'Culture';
      case outdoors:
        return 'Outdoors';
      case networking:
        return 'Networking';
      case education:
        return 'Education';
      case wellness:
        return 'Wellness';
      case social:
        return 'Social';
      default:
        return category;
    }
  }
}