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
    // Handle attendees array - convert from the API format to EventAttendance
    List<EventAttendance> attendeesList = [];
    if (json['attendees'] is List) {
      attendeesList = (json['attendees'] as List<dynamic>)
          .map((attendee) {
            if (attendee is Map<String, dynamic>) {
              final attendeeId = attendee['id'] as String? ?? '';
              final eventId = json['id'] as String? ?? '';

              if (attendeeId.isNotEmpty && eventId.isNotEmpty) {
                return EventAttendance(
                  id: attendeeId,
                  userId: attendeeId,
                  eventId: eventId,
                  status:
                      'attending', // Default status since API doesn't provide this
                  timestamp: DateTime.now(), // Default timestamp
                  user: {
                    'id': attendeeId,
                    'firstName': attendee['firstName'] as String? ?? 'Unknown',
                    'lastName': attendee['lastName'] as String? ?? 'User',
                    'username':
                        attendee['username'] as String? ?? 'unknown_user',
                  },
                );
              }
            }
            return null;
          })
          .where((attendee) => attendee != null)
          .cast<EventAttendance>()
          .toList();
    }

    // Handle date parsing - API uses 'startTime'
    DateTime eventDate;
    try {
      final startTimeStr = json['startTime'] as String?;
      if (startTimeStr != null && startTimeStr.isNotEmpty) {
        eventDate = DateTime.parse(startTimeStr);
      } else {
        eventDate = DateTime.now(); // Fallback to current time
      }
    } catch (e) {
      eventDate = DateTime.now(); // Fallback to current time
    }

    // Handle coordinates - provide default if missing
    EventCoordinates eventCoordinates;
    if (json['coordinates'] != null) {
      eventCoordinates = EventCoordinates.fromJson(
        json['coordinates'] as Map<String, dynamic>,
      );
    } else {
      // Default to Cape Town coordinates if missing
      eventCoordinates = const EventCoordinates(lat: -33.9249, lng: 18.4241);
    }

    // Handle category - extract from tags array or use default
    String eventCategory = 'general';
    if (json['tags'] is List && (json['tags'] as List).isNotEmpty) {
      eventCategory = json['tags'][0] as String;
    } else if (json['category'] is String) {
      eventCategory = json['category'] as String;
    }

    return Event(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled Event',
      description: json['description'] as String? ?? 'No description available',
      location: json['location'] as String? ?? 'Location TBD',
      coordinates: eventCoordinates,
      date: eventDate,
      image: json['image'] as String?,
      category: eventCategory,
      createdBy: json['creatorId'] as String?, // Safe null handling
      createdAt: eventDate, // Use startTime as createdAt fallback
      attendees: attendeesList,
      isAttending: false, // Default to false, will be determined by app logic
      attendeeCount: json['currentAttendees'] as int? ?? attendeesList.length,
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
/// Event Category entity to match backend structure
class EventCategory {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? color;
  final String? icon;
  final DateTime createdAt;
  final DateTime updatedAt;

  const EventCategory({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.color,
    this.icon,
    required this.createdAt,
    required this.updatedAt,
  });

  factory EventCategory.fromJson(Map<String, dynamic> json) {
    return EventCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String?,
      color: json['color'] as String?,
      icon: json['icon'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'description': description,
      'color': color,
      'icon': icon,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventCategory &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Legacy EventCategories class for backward compatibility
/// TODO: Remove once all references are updated to use EventCategory model
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