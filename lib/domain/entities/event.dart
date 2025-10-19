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
  // Basic Event Information
  final String id;
  final String title;
  final String description;
  final String location;
  final EventCoordinates coordinates;
  final DateTime date;
  final String? image;
  final String category; // Legacy: slug string
  final EventCategory?
  categoryDetails; // Full category object with icon, color, etc.
  final String? createdBy;
  final DateTime createdAt;
  
  // Attendance Tracking
  final List<EventAttendance> attendees;
  final bool isAttending;
  final int attendeeCount;
  final int? maxAttendees; // Maximum number of attendees allowed
  
  // Engagement Metrics (NEW)
  final int viewCount;
  final int uniqueViewers;
  final int shareCount;
  final int messageCount;
  final int clickCount;
  final DateTime? firstViewedAt;
  final DateTime? lastActivityAt;
  final double engagementRate;

  // Success Indicators (NEW)
  final int actualAttendeeCount;
  final double attendanceRate;
  final double satisfactionScore;
  final int feedbackCount;
  final Map<String, double>? conversionRate;

  // Quality Metrics (NEW)
  final double popularityScore;
  final double organizerReliability;
  final double eventSuccessScore;

  const Event({
    // Basic Event Information
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.coordinates,
    required this.date,
    this.image,
    required this.category,
    this.categoryDetails,
    this.createdBy,
    required this.createdAt,
    // Attendance Tracking
    this.attendees = const [],
    this.isAttending = false,
    this.attendeeCount = 0,
    this.maxAttendees,
    // Engagement Metrics (NEW)
    this.viewCount = 0,
    this.uniqueViewers = 0,
    this.shareCount = 0,
    this.messageCount = 0,
    this.clickCount = 0,
    this.firstViewedAt,
    this.lastActivityAt,
    this.engagementRate = 0.0,
    // Success Indicators (NEW)
    this.actualAttendeeCount = 0,
    this.attendanceRate = 0.0,
    this.satisfactionScore = 0.0,
    this.feedbackCount = 0,
    this.conversionRate,
    // Quality Metrics (NEW)
    this.popularityScore = 0.0,
    this.organizerReliability = 0.0,
    this.eventSuccessScore = 0.0,
  });

  factory Event.fromJson(Map<String, dynamic> json, {String? currentUserId}) {
    // Handle wrapped API response
    final eventData = json['data'] ?? json;
    
    // Handle attendees array - convert from the API format to EventAttendance
    // Note: In listing view, attendees array is omitted for privacy (only count is sent)
    List<EventAttendance> attendeesList = [];
    bool userIsAttending = false;

    // Check if API provided explicit isUserAttending flag (from listing endpoint)
    if (eventData['isUserAttending'] is bool) {
      userIsAttending = eventData['isUserAttending'] as bool;
    }

    // If attendees array is present (from details endpoint), parse it
    if (eventData['attendees'] is List) {
      attendeesList = (eventData['attendees'] as List<dynamic>)
          .map((attendee) {
            if (attendee is Map<String, dynamic>) {
              final attendeeId = attendee['id'] as String? ?? '';
              final eventId = eventData['id'] as String? ?? '';

              // Check if current user is in attendees list (details view)
              if (currentUserId != null && attendeeId == currentUserId) {
                userIsAttending = true;
              }

              if (attendeeId.isNotEmpty && eventId.isNotEmpty) {
                return EventAttendance(
                  id: attendeeId,
                  userId: attendeeId,
                  eventId: eventId,
                  status: 'attending',
                  timestamp: DateTime.now(),
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
      final startTimeStr = eventData['startTime'] as String?;
      if (startTimeStr != null && startTimeStr.isNotEmpty) {
        eventDate = DateTime.parse(startTimeStr);
      } else {
        eventDate = DateTime.now();
      }
    } catch (e) {
      eventDate = DateTime.now();
    }

    // Handle coordinates - provide default if missing
    EventCoordinates eventCoordinates;
    if (eventData['coordinates'] != null) {
      eventCoordinates = EventCoordinates.fromJson(
        eventData['coordinates'] as Map<String, dynamic>,
      );
    } else {
      // Default to Cape Town coordinates if missing
      eventCoordinates = const EventCoordinates(lat: -33.9249, lng: 18.4241);
    }

    // Handle category - prioritize category object's slug, fallback to tags
    String eventCategory = 'general';
    EventCategory? categoryDetails;
    
    if (eventData['category'] is Map<String, dynamic>) {
      // API returns category as object with id, name, slug, icon, color, etc.
      final categoryObj = eventData['category'] as Map<String, dynamic>;
      eventCategory =
          categoryObj['slug'] as String? ??
          categoryObj['name'] as String? ??
          'general';
      
      // Parse full category object
      try {
        categoryDetails = EventCategory.fromJson(categoryObj);
      } catch (e) {
        // If parsing fails, just use slug
        categoryDetails = null;
      }
    } else if (eventData['category'] is String) {
      // Legacy: category as direct string
      eventCategory = eventData['category'] as String;
    } else if (eventData['tags'] is List &&
        (eventData['tags'] as List).isNotEmpty) {
      // Fallback: extract from tags array
      eventCategory = eventData['tags'][0] as String;
    }

    // Parse attendee count - handle both old format (currentAttendees) and new format (_count.attendees)
    int parsedAttendeeCount = 0;
    if (eventData['_count'] != null &&
        eventData['_count']['attendees'] != null) {
      // New privacy-protected format: { "_count": { "attendees": 14 } }
      parsedAttendeeCount = eventData['_count']['attendees'] as int;
    } else if (eventData['currentAttendees'] != null) {
      // Legacy format: { "currentAttendees": 14 }
      parsedAttendeeCount = eventData['currentAttendees'] as int;
    } else {
      // Fallback: count from attendees array if present
      parsedAttendeeCount = attendeesList.length;
    }

    // Parse conversionRate Map if present
    Map<String, double>? parsedConversionRate;
    if (eventData['conversionRate'] is Map) {
      final conversionMap = eventData['conversionRate'] as Map<String, dynamic>;
      parsedConversionRate = {
        'viewToClick':
            (conversionMap['viewToClick'] as num?)?.toDouble() ?? 0.0,
        'clickToRegister':
            (conversionMap['clickToRegister'] as num?)?.toDouble() ?? 0.0,
        'registerToAttend':
            (conversionMap['registerToAttend'] as num?)?.toDouble() ?? 0.0,
      };
    }

    return Event(
      // Basic Event Information
      id: eventData['id'] as String? ?? '',
      title: eventData['title'] as String? ?? 'Untitled Event',
      description:
          eventData['description'] as String? ?? 'No description available',
      location: eventData['location'] as String? ?? 'Location TBD',
      coordinates: eventCoordinates,
      date: eventDate,
      image: eventData['image'] as String?,
      category: eventCategory,
      categoryDetails: categoryDetails,
      createdBy: eventData['creatorId'] as String?,
      createdAt: eventDate,
      // Attendance Tracking
      attendees: attendeesList,
      isAttending: userIsAttending,
      attendeeCount: parsedAttendeeCount,
      maxAttendees: eventData['maxAttendees'] as int?,
      // Engagement Metrics (NEW)
      viewCount: eventData['viewCount'] as int? ?? 0,
      uniqueViewers: eventData['uniqueViewers'] as int? ?? 0,
      shareCount: eventData['shareCount'] as int? ?? 0,
      messageCount: eventData['messageCount'] as int? ?? 0,
      clickCount: eventData['clickCount'] as int? ?? 0,
      firstViewedAt: eventData['firstViewedAt'] != null
          ? DateTime.tryParse(eventData['firstViewedAt'].toString())
          : null,
      lastActivityAt: eventData['lastActivityAt'] != null
          ? DateTime.tryParse(eventData['lastActivityAt'].toString())
          : null,
      engagementRate: (eventData['engagementRate'] as num?)?.toDouble() ?? 0.0,
      // Success Indicators (NEW)
      actualAttendeeCount: eventData['actualAttendeeCount'] as int? ?? 0,
      attendanceRate: (eventData['attendanceRate'] as num?)?.toDouble() ?? 0.0,
      satisfactionScore:
          (eventData['satisfactionScore'] as num?)?.toDouble() ?? 0.0,
      feedbackCount: eventData['feedbackCount'] as int? ?? 0,
      conversionRate: parsedConversionRate,
      // Quality Metrics (NEW)
      popularityScore:
          (eventData['popularityScore'] as num?)?.toDouble() ?? 0.0,
      organizerReliability:
          (eventData['organizerReliability'] as num?)?.toDouble() ?? 0.0,
      eventSuccessScore:
          (eventData['eventSuccessScore'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      // Basic Event Information
      'id': id,
      'title': title,
      'description': description,
      'location': location,
      'coordinates': coordinates.toJson(),
      'date': date.toIso8601String(),
      'image': image,
      'category': category,
      'categoryDetails': categoryDetails?.toJson(),
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      // Attendance Tracking
      'attendees': attendees.map((e) => e.toJson()).toList(),
      'isAttending': isAttending,
      'attendeeCount': attendeeCount,
      'maxAttendees': maxAttendees,
      // Engagement Metrics
      'viewCount': viewCount,
      'uniqueViewers': uniqueViewers,
      'shareCount': shareCount,
      'messageCount': messageCount,
      'clickCount': clickCount,
      'firstViewedAt': firstViewedAt?.toIso8601String(),
      'lastActivityAt': lastActivityAt?.toIso8601String(),
      'engagementRate': engagementRate,
      // Success Indicators
      'actualAttendeeCount': actualAttendeeCount,
      'attendanceRate': attendanceRate,
      'satisfactionScore': satisfactionScore,
      'feedbackCount': feedbackCount,
      'conversionRate': conversionRate,
      // Quality Metrics
      'popularityScore': popularityScore,
      'organizerReliability': organizerReliability,
      'eventSuccessScore': eventSuccessScore,
    };
  }

  Event copyWith({
    // Basic Event Information
    String? id,
    String? title,
    String? description,
    String? location,
    EventCoordinates? coordinates,
    DateTime? date,
    String? image,
    String? category,
    EventCategory? categoryDetails,
    String? createdBy,
    DateTime? createdAt,
    // Attendance Tracking
    List<EventAttendance>? attendees,
    bool? isAttending,
    int? attendeeCount,
    int? maxAttendees,
    // Engagement Metrics
    int? viewCount,
    int? uniqueViewers,
    int? shareCount,
    int? messageCount,
    int? clickCount,
    DateTime? firstViewedAt,
    DateTime? lastActivityAt,
    double? engagementRate,
    // Success Indicators
    int? actualAttendeeCount,
    double? attendanceRate,
    double? satisfactionScore,
    int? feedbackCount,
    Map<String, double>? conversionRate,
    // Quality Metrics
    double? popularityScore,
    double? organizerReliability,
    double? eventSuccessScore,
  }) {
    return Event(
      // Basic Event Information
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      coordinates: coordinates ?? this.coordinates,
      date: date ?? this.date,
      image: image ?? this.image,
      category: category ?? this.category,
      categoryDetails: categoryDetails ?? this.categoryDetails,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      // Attendance Tracking
      attendees: attendees ?? this.attendees,
      isAttending: isAttending ?? this.isAttending,
      attendeeCount: attendeeCount ?? this.attendeeCount,
      maxAttendees: maxAttendees ?? this.maxAttendees,
      // Engagement Metrics
      viewCount: viewCount ?? this.viewCount,
      uniqueViewers: uniqueViewers ?? this.uniqueViewers,
      shareCount: shareCount ?? this.shareCount,
      messageCount: messageCount ?? this.messageCount,
      clickCount: clickCount ?? this.clickCount,
      firstViewedAt: firstViewedAt ?? this.firstViewedAt,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      engagementRate: engagementRate ?? this.engagementRate,
      // Success Indicators
      actualAttendeeCount: actualAttendeeCount ?? this.actualAttendeeCount,
      attendanceRate: attendanceRate ?? this.attendanceRate,
      satisfactionScore: satisfactionScore ?? this.satisfactionScore,
      feedbackCount: feedbackCount ?? this.feedbackCount,
      conversionRate: conversionRate ?? this.conversionRate,
      // Quality Metrics
      popularityScore: popularityScore ?? this.popularityScore,
      organizerReliability: organizerReliability ?? this.organizerReliability,
      eventSuccessScore: eventSuccessScore ?? this.eventSuccessScore,
    );
  }

  // Computed Properties for Analytics

  /// Classifies attendance health into 5 tiers based on attendance rate
  /// Returns: 'excellent' (≥90%), 'good' (75-89%), 'moderate' (60-74%),
  /// 'poor' (40-59%), 'critical' (<40%), or 'pending' (no data/future event)
  String get attendanceHealth {
    // Check if event has occurred and has attendance data
    if (date.isAfter(DateTime.now()) || actualAttendeeCount == 0) {
      return 'pending';
    }

    final rate = attendanceRate;
    if (rate >= 90) return 'excellent';
    if (rate >= 75) return 'good';
    if (rate >= 60) return 'moderate';
    if (rate >= 40) return 'poor';
    return 'critical';
  }

  /// Calculates weighted engagement score (0-100) combining multiple metrics
  /// Formula: 30pts view-to-engagement + 25pts registration + 20pts community
  /// + 15pts viral + 10pts recency
  double get engagementScore {
    double score = 0.0;

    // 30pts: View-to-engagement ratio
    if (uniqueViewers > 0) {
      final engagementActions = clickCount + shareCount;
      final viewEngagementRatio = (engagementActions / uniqueViewers).clamp(0, 1);
      score += viewEngagementRatio * 30;
    }

    // 25pts: Registration conversion
    if (viewCount > 0 && attendeeCount > 0) {
      final registrationRate = (attendeeCount / viewCount).clamp(0, 1);
      score += registrationRate * 25;
    }

    // 20pts: Community engagement (messages)
    if (attendeeCount > 0 && messageCount > 0) {
      final messagesPerAttendee = messageCount / attendeeCount;
      final communityScore = (messagesPerAttendee / 10).clamp(0, 1); // Normalize to 10 messages
      score += communityScore * 20;
    }

    // 15pts: Viral coefficient (shares)
    if (uniqueViewers > 0 && shareCount > 0) {
      final viralCoefficient = (shareCount / uniqueViewers).clamp(0, 1);
      score += viralCoefficient * 15;
    }

    // 10pts: Recency bonus (if activity within last 7 days)
    if (lastActivityAt != null) {
      final daysSinceActivity = DateTime.now().difference(lastActivityAt!).inDays;
      if (daysSinceActivity <= 7) {
        final recencyBonus = (1 - (daysSinceActivity / 7)).clamp(0, 1);
        score += recencyBonus * 10;
      }
    }

    return score.clamp(0, 100);
  }

  /// Provides human-readable popularity tier based on popularityScore
  /// Returns: 'viral' (≥80), 'popular' (60-79), 'moderate' (40-59),
  /// 'low' (20-39), or 'new' (<20)
  String get popularityLevel {
    if (popularityScore >= 80) return 'viral';
    if (popularityScore >= 60) return 'popular';
    if (popularityScore >= 40) return 'moderate';
    if (popularityScore >= 20) return 'low';
    return 'new';
  }

  /// Determines if event is considered successful based on multiple criteria
  /// Criteria: Past event + ≥70% attendance + ≥4.0 satisfaction + ≥5 feedback
  bool get isSuccessfulEvent {
    // Must be a past event
    if (date.isAfter(DateTime.now())) {
      return false;
    }

    // Check all success criteria
    final hasGoodAttendance = attendanceRate >= 70.0;
    final hasHighSatisfaction = satisfactionScore >= 4.0;
    final hasEnoughFeedback = feedbackCount >= 5;

    return hasGoodAttendance && hasHighSatisfaction && hasEnoughFeedback;
  }

  /// Analyzes conversion funnel with health classification and bottleneck detection
  /// Returns Map with keys: health, bottleneck, viewToClick, clickToRegister,
  /// registerToAttend, overallConversion (all percentages formatted as strings)
  Map<String, String> get conversionFunnelSummary {
    final summary = <String, String>{};

    // Default values if no conversion data
    if (conversionRate == null || conversionRate!.isEmpty) {
      summary['health'] = 'no_data';
      summary['bottleneck'] = 'none';
      summary['viewToClick'] = '0%';
      summary['clickToRegister'] = '0%';
      summary['registerToAttend'] = '0%';
      summary['overallConversion'] = '0%';
      return summary;
    }

    // Extract conversion rates
    final viewToClick = conversionRate!['viewToClick'] ?? 0.0;
    final clickToRegister = conversionRate!['clickToRegister'] ?? 0.0;
    final registerToAttend = conversionRate!['registerToAttend'] ?? 0.0;

    // Calculate overall conversion
    final overallConversion = viewToClick * clickToRegister * registerToAttend;

    // Format as percentages
    summary['viewToClick'] = '${(viewToClick * 100).toStringAsFixed(1)}%';
    summary['clickToRegister'] = '${(clickToRegister * 100).toStringAsFixed(1)}%';
    summary['registerToAttend'] = '${(registerToAttend * 100).toStringAsFixed(1)}%';
    summary['overallConversion'] = '${(overallConversion * 100).toStringAsFixed(1)}%';

    // Determine health classification
    if (overallConversion >= 0.15) {
      summary['health'] = 'excellent';
    } else if (overallConversion >= 0.10) {
      summary['health'] = 'good';
    } else if (overallConversion >= 0.05) {
      summary['health'] = 'moderate';
    } else {
      summary['health'] = 'poor';
    }

    // Identify bottleneck (weakest conversion stage)
    final rates = {
      'view_to_click': viewToClick,
      'click_to_register': clickToRegister,
      'register_to_attend': registerToAttend,
    };
    final weakestStage = rates.entries.reduce((a, b) => a.value < b.value ? a : b);
    summary['bottleneck'] = weakestStage.key;

    return summary;
  }

  /// Provides user-facing quality tier for premium features
  /// Composite of eventSuccessScore + popularityScore + engagementScore
  /// Returns: 'premium' (≥80), 'great' (60-79), 'good' (40-59), 'standard' (<40)
  String get eventQualityDisplay {
    // Calculate composite quality score (average of 3 metrics)
    final compositeScore = (eventSuccessScore + popularityScore + engagementScore) / 3;

    if (compositeScore >= 80) return 'premium';
    if (compositeScore >= 60) return 'great';
    if (compositeScore >= 40) return 'good';
    return 'standard';
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
  final int eventCount; // Number of events in this category

  const EventCategory({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.color,
    this.icon,
    required this.createdAt,
    required this.updatedAt,
    this.eventCount = 0, // Default to 0 events
  });

  factory EventCategory.fromJson(Map<String, dynamic> json) {
    // Extract event count from _count.events if available
    int eventCount = 0;
    if (json['_count'] != null && json['_count']['events'] != null) {
      eventCount = json['_count']['events'] as int;
    }

    return EventCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String?,
      color: json['color'] as String?,
      icon: json['icon'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      eventCount: eventCount,
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
      'eventCount': eventCount,
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
/// Note: Still in use by events_screen.dart, category_chip.dart, and event_card.dart
/// Migration to EventCategory model pending
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