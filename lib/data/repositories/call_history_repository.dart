import '../../core/network/api_client.dart';

/// Call history filters for filtering calls
class CallHistoryFilters {
  final String? type; // 'VIDEO' or 'AUDIO'
  final String? status; // e.g., 'ENDED', 'MISSED', 'REJECTED', 'CANCELLED'
  final DateTime? startDate;
  final DateTime? endDate;

  CallHistoryFilters({this.type, this.status, this.startDate, this.endDate});

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {};
    if (type != null) json['type'] = type;
    if (status != null) json['status'] = status;
    if (startDate != null) json['startDate'] = startDate!.toIso8601String();
    if (endDate != null) json['endDate'] = endDate!.toIso8601String();
    return json;
  }
}

/// Pagination options for call history
class PaginationOptions {
  final int page;
  final int limit;

  PaginationOptions({required this.page, required this.limit});

  Map<String, dynamic> toJson() {
    return {'page': page, 'limit': limit};
  }
}

/// Participant in a call
class CallParticipant {
  final String id;
  final String callId;
  final String userId;
  final String role;
  final String status;
  final CallParticipantUser user;

  CallParticipant({
    required this.id,
    required this.callId,
    required this.userId,
    required this.role,
    required this.status,
    required this.user,
  });

  factory CallParticipant.fromJson(Map<String, dynamic> json) {
    return CallParticipant(
      id: json['id'] as String,
      callId: json['callId'] as String,
      userId: json['userId'] as String,
      role: json['role'] as String,
      status: json['status'] as String,
      user: CallParticipantUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

/// User information for call participant
class CallParticipantUser {
  final String id;
  final String username;
  final String? profileImage;
  final String? firstName;
  final String? lastName;

  CallParticipantUser({
    required this.id,
    required this.username,
    this.profileImage,
    this.firstName,
    this.lastName,
  });

  factory CallParticipantUser.fromJson(Map<String, dynamic> json) {
    return CallParticipantUser(
      id: json['id'] as String,
      username: json['username'] as String,
      profileImage: json['profileImage'] as String?,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
    );
  }

  String get displayName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    } else if (firstName != null) {
      return firstName!;
    }
    return username;
  }
}

/// Call history item
class CallHistoryItem {
  final String id;
  final String hostId;
  final String type; // 'VIDEO' or 'AUDIO'
  final String status;
  final bool isGroup;
  final int? duration;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final DateTime createdAt;
  final int? averageQuality;
  final int? snapshotCount;
  final List<CallParticipant> participants;

  CallHistoryItem({
    required this.id,
    required this.hostId,
    required this.type,
    required this.status,
    required this.isGroup,
    this.duration,
    this.startedAt,
    this.endedAt,
    required this.createdAt,
    this.averageQuality,
    this.snapshotCount,
    required this.participants,
  });

  factory CallHistoryItem.fromJson(Map<String, dynamic> json) {
    return CallHistoryItem(
      id: json['id'] as String,
      hostId: json['hostId'] as String,
      type: json['type'] as String,
      status: json['status'] as String,
      isGroup: json['isGroup'] as bool? ?? false,
      duration: json['duration'] as int?,
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'] as String)
          : null,
      endedAt: json['endedAt'] != null
          ? DateTime.parse(json['endedAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      averageQuality: json['averageQuality'] as int?,
      snapshotCount: json['snapshotCount'] as int?,
      participants: (json['participants'] as List<dynamic>)
          .map((p) => CallParticipant.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Pagination metadata
class PaginationMetadata {
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final bool hasNext;
  final bool hasPrev;

  PaginationMetadata({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrev,
  });

  factory PaginationMetadata.fromJson(Map<String, dynamic> json) {
    return PaginationMetadata(
      page: json['page'] as int,
      limit: json['limit'] as int,
      total: json['total'] as int,
      totalPages: json['totalPages'] as int,
      hasNext: json['hasNext'] as bool,
      hasPrev: json['hasPrev'] as bool,
    );
  }
}

/// Call history response
class CallHistoryResponse {
  final List<CallHistoryItem> calls;
  final PaginationMetadata pagination;

  CallHistoryResponse({required this.calls, required this.pagination});

  factory CallHistoryResponse.fromJson(Map<String, dynamic> json) {
    return CallHistoryResponse(
      calls: (json['calls'] as List<dynamic>)
          .map((c) => CallHistoryItem.fromJson(c as Map<String, dynamic>))
          .toList(),
      pagination: PaginationMetadata.fromJson(
        json['pagination'] as Map<String, dynamic>,
      ),
    );
  }
}

/// Quality distribution for call details
class QualityDistribution {
  final int excellent;
  final int good;
  final int fair;
  final int poor;

  QualityDistribution({
    required this.excellent,
    required this.good,
    required this.fair,
    required this.poor,
  });

  factory QualityDistribution.fromJson(Map<String, dynamic> json) {
    return QualityDistribution(
      excellent: json['excellent'] as int,
      good: json['good'] as int,
      fair: json['fair'] as int,
      poor: json['poor'] as int,
    );
  }
}

/// Quality statistics for call details
class QualityStatistics {
  final int average;
  final int min;
  final int max;
  final QualityDistribution distribution;
  final List<dynamic> snapshots;

  QualityStatistics({
    required this.average,
    required this.min,
    required this.max,
    required this.distribution,
    required this.snapshots,
  });

  factory QualityStatistics.fromJson(Map<String, dynamic> json) {
    return QualityStatistics(
      average: json['average'] as int,
      min: json['min'] as int,
      max: json['max'] as int,
      distribution: QualityDistribution.fromJson(
        json['distribution'] as Map<String, dynamic>,
      ),
      snapshots: json['snapshots'] as List<dynamic>,
    );
  }
}

/// Detailed call information
class CallDetails {
  final String id;
  final String hostId;
  final String type;
  final String status;
  final bool isGroup;
  final int? duration;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final DateTime createdAt;
  final List<CallParticipant> participants;
  final QualityStatistics? qualityStats;

  CallDetails({
    required this.id,
    required this.hostId,
    required this.type,
    required this.status,
    required this.isGroup,
    this.duration,
    this.startedAt,
    this.endedAt,
    required this.createdAt,
    required this.participants,
    this.qualityStats,
  });

  factory CallDetails.fromJson(Map<String, dynamic> json) {
    return CallDetails(
      id: json['id'] as String,
      hostId: json['hostId'] as String,
      type: json['type'] as String,
      status: json['status'] as String,
      isGroup: json['isGroup'] as bool? ?? false,
      duration: json['duration'] as int?,
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'] as String)
          : null,
      endedAt: json['endedAt'] != null
          ? DateTime.parse(json['endedAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      participants: (json['participants'] as List<dynamic>)
          .map((p) => CallParticipant.fromJson(p as Map<String, dynamic>))
          .toList(),
      qualityStats: json['qualityStats'] != null
          ? QualityStatistics.fromJson(
              json['qualityStats'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

/// Call statistics summary
class CallStatistics {
  final int totalCalls;
  final int videoCalls;
  final int audioCalls;
  final int completedCalls;
  final int missedCalls;
  final int rejectedCalls;
  final int cancelledCalls;
  final int totalDuration; // in seconds
  final int avgDuration; // in seconds

  CallStatistics({
    required this.totalCalls,
    required this.videoCalls,
    required this.audioCalls,
    required this.completedCalls,
    required this.missedCalls,
    required this.rejectedCalls,
    required this.cancelledCalls,
    required this.totalDuration,
    required this.avgDuration,
  });

  factory CallStatistics.fromJson(Map<String, dynamic> json) {
    return CallStatistics(
      totalCalls: json['totalCalls'] as int,
      videoCalls: json['videoCalls'] as int,
      audioCalls: json['audioCalls'] as int,
      completedCalls: json['completedCalls'] as int,
      missedCalls: json['missedCalls'] as int,
      rejectedCalls: json['rejectedCalls'] as int,
      cancelledCalls: json['cancelledCalls'] as int,
      totalDuration: json['totalDuration'] as int,
      avgDuration: json['avgDuration'] as int,
    );
  }
}

/// Repository for call history operations
class CallHistoryRepository {
  final ApiClient _apiClient;

  CallHistoryRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient.instance;

  /// Get paginated call history with optional filters
  Future<CallHistoryResponse> getCallHistory({
    int page = 1,
    int limit = 20,
    CallHistoryFilters? filters,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (filters != null) {
        final filterJson = filters.toJson();
        filterJson.forEach((key, value) {
          queryParams[key] = value.toString();
        });
      }

      final response = await _apiClient.dio.get(
        '/calls/history',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true && data['data'] != null) {
          return CallHistoryResponse.fromJson(
            data['data'] as Map<String, dynamic>,
          );
        }
      }
      throw Exception('Failed to fetch call history');
    } catch (e) {
      throw Exception('Error fetching call history: $e');
    }
  }

  /// Get detailed information about a specific call
  Future<CallDetails> getCallDetails(String callId) async {
    try {
      final response = await _apiClient.dio.get('/calls/history/$callId');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true && data['data'] != null) {
          return CallDetails.fromJson(data['data'] as Map<String, dynamic>);
        }
      }
      throw Exception('Failed to fetch call details');
    } catch (e) {
      throw Exception('Error fetching call details: $e');
    }
  }

  /// Delete a call from the user's call history (soft delete)
  Future<void> deleteCallRecord(String callId) async {
    try {
      final response = await _apiClient.dio.delete('/calls/history/$callId');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true) {
          return;
        }
      }
      throw Exception('Failed to delete call record');
    } catch (e) {
      throw Exception('Error deleting call record: $e');
    }
  }

  /// Get call statistics for the authenticated user
  Future<CallStatistics> getCallStats() async {
    try {
      final response = await _apiClient.dio.get('/calls/stats');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true && data['data'] != null) {
          return CallStatistics.fromJson(data['data'] as Map<String, dynamic>);
        }
      }
      throw Exception('Failed to fetch call statistics');
    } catch (e) {
      throw Exception('Error fetching call statistics: $e');
    }
  }
}
