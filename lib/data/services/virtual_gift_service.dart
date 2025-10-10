import 'package:logger/logger.dart';
import '../models/virtual_gift.dart';
import '../../core/network/api_client.dart';

/// Service for handling virtual gift operations
class VirtualGiftService {
  final ApiClient _apiClient;
  final Logger _logger = Logger();

  VirtualGiftService(this._apiClient);

  /// Get all available virtual gifts
  Future<List<VirtualGift>> getAvailableGifts() async {
    try {
      final response = await _apiClient.get('/virtual-gifts/catalog');

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data['gifts'] ?? [];
        final gifts = data.map((json) => VirtualGift.fromJson(json)).toList();
        
        _logger.d('Retrieved ${gifts.length} available virtual gifts');
        return gifts;
      } else {
        _logger.e('Failed to get available gifts: ${response.statusMessage}');
        return [];
      }
    } catch (e) {
      _logger.e('Error getting available gifts: $e');
      return [];
    }
  }

  /// Get gifts by category
  Future<List<VirtualGift>> getGiftsByCategory(GiftCategory category) async {
    try {
      final response = await _apiClient.get(
        '/api/v1/virtual-gifts/category/${category.name}',
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data['gifts'] ?? [];
        final gifts = data.map((json) => VirtualGift.fromJson(json)).toList();
        
        _logger.d('Retrieved ${gifts.length} gifts in category: ${category.name}');
        return gifts;
      } else {
        _logger.e('Failed to get gifts by category: ${response.statusMessage}');
        return [];
      }
    } catch (e) {
      _logger.e('Error getting gifts by category: $e');
      return [];
    }
  }

  /// Send a virtual gift to a user
  Future<GiftTransaction?> sendGift({
    required String recipientId,
    required String giftId,
    String? message,
    bool isAnonymous = false,
  }) async {
    try {
      final response = await _apiClient.post(
        '/api/v1/virtual-gifts/send',
        data: {
          'recipientId': recipientId,
          'giftId': giftId,
          'message': message,
          'isAnonymous': isAnonymous,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final transaction = GiftTransaction.fromJson(response.data!);
        _logger.d('Gift sent successfully: ${transaction.id}');
        return transaction;
      } else {
        _logger.e('Failed to send gift: ${response.statusMessage}');
        return null;
      }
    } catch (e) {
      _logger.e('Error sending gift: $e');
      return null;
    }
  }

  /// Get received gifts for the current user
  Future<List<GiftTransaction>> getReceivedGifts({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _apiClient.get(
        '/api/v1/virtual-gifts/transactions',
        queryParameters: {
          'page': page.toString(),
          'limit': limit.toString(),
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data['transactions'] ?? [];
        final transactions = data.map((json) => GiftTransaction.fromJson(json)).toList();
        
        _logger.d('Retrieved ${transactions.length} received gifts (page $page)');
        return transactions;
      } else {
        _logger.e('Failed to get received gifts: ${response.statusMessage}');
        return [];
      }
    } catch (e) {
      _logger.e('Error getting received gifts: $e');
      return [];
    }
  }

  /// Get sent gifts for the current user
  Future<List<GiftTransaction>> getSentGifts({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _apiClient.get(
        '/api/v1/virtual-gifts/transactions',
        queryParameters: {
          'page': page.toString(),
          'limit': limit.toString(),
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data['transactions'] ?? [];
        final transactions = data.map((json) => GiftTransaction.fromJson(json)).toList();
        
        _logger.d('Retrieved ${transactions.length} sent gifts (page $page)');
        return transactions;
      } else {
        _logger.e('Failed to get sent gifts: ${response.statusMessage}');
        return [];
      }
    } catch (e) {
      _logger.e('Error getting sent gifts: $e');
      return [];
    }
  }

  /// Thank someone for a gift received
  Future<bool> thankForGift(String transactionId, String message) async {
    try {
      final response = await _apiClient.post(
        '/api/v1/virtual-gifts/transactions/$transactionId/receive',
        data: {
          'transactionId': transactionId,
          'thankYouMessage': message,
        },
      );

      if (response.statusCode == 200) {
        _logger.d('Thank you sent for gift transaction: $transactionId');
        return true;
      } else {
        _logger.e('Failed to send thank you: ${response.statusMessage}');
        return false;
      }
    } catch (e) {
      _logger.e('Error sending thank you: $e');
      return false;
    }
  }

  /// Get gift transaction details
  Future<GiftTransaction?> getGiftTransaction(String transactionId) async {
    try {
      final response = await _apiClient.get(
        '/api/v1/virtual-gifts/transactions/$transactionId',
      );

      if (response.statusCode == 200 && response.data != null) {
        final transaction = GiftTransaction.fromJson(response.data!);
        _logger.d('Retrieved gift transaction: $transactionId');
        return transaction;
      } else {
        _logger.e('Failed to get gift transaction: ${response.statusMessage}');
        return null;
      }
    } catch (e) {
      _logger.e('Error getting gift transaction: $e');
      return null;
    }
  }

  /// Get user's gift statistics
  Future<Map<String, dynamic>?> getUserGiftStats() async {
    try {
      final response = await _apiClient.get('/virtual-gifts/stats');

      if (response.statusCode == 200 && response.data != null) {
        final stats = {
          'totalGiftsSent': response.data['totalGiftsSent'] ?? 0,
          'totalGiftsReceived': response.data['totalGiftsReceived'] ?? 0,
          'totalCoinsSpent': response.data['totalCoinsSpent'] ?? 0,
          'totalCoinsEarned': response.data['totalCoinsEarned'] ?? 0,
          'favoriteGiftCategory': response.data['favoriteGiftCategory'] ?? 'flowers',
          'mostSentGift': response.data['mostSentGift'],
          'mostReceivedGift': response.data['mostReceivedGift'],
        };
        
        _logger.d('Retrieved user gift statistics');
        return stats;
      } else {
        _logger.e('Failed to get gift statistics: ${response.statusMessage}');
        return null;
      }
    } catch (e) {
      _logger.e('Error getting gift statistics: $e');
      return null;
    }
  }

  /// Mark gift notification as read
  Future<bool> markGiftNotificationAsRead(String transactionId) async {
    try {
      final response = await _apiClient.patch(
        '/api/v1/virtual-gifts/notification/$transactionId/read',
        data: {'isRead': true},
      );

      if (response.statusCode == 200) {
        _logger.d('Gift notification marked as read: $transactionId');
        return true;
      } else {
        _logger.e('Failed to mark gift notification as read: ${response.statusMessage}');
        return false;
      }
    } catch (e) {
      _logger.e('Error marking gift notification as read: $e');
      return false;
    }
  }

  /// Get popular gifts
  Future<List<VirtualGift>> getPopularGifts({int limit = 10}) async {
    try {
      final response = await _apiClient.get(
        '/api/v1/virtual-gifts/popular',
        queryParameters: {'limit': limit.toString()},
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data['gifts'] ?? [];
        final gifts = data.map((json) => VirtualGift.fromJson(json)).toList();
        
        _logger.d('Retrieved ${gifts.length} popular gifts');
        return gifts;
      } else {
        _logger.e('Failed to get popular gifts: ${response.statusMessage}');
        return [];
      }
    } catch (e) {
      _logger.e('Error getting popular gifts: $e');
      return [];
    }
  }

  /// Get recent gift activity feed
  Future<List<GiftTransaction>> getGiftActivityFeed({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _apiClient.get(
        '/api/v1/virtual-gifts/activity',
        queryParameters: {
          'page': page.toString(),
          'limit': limit.toString(),
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data['activities'] ?? [];
        final activities = data.map((json) => GiftTransaction.fromJson(json)).toList();
        
        _logger.d('Retrieved ${activities.length} gift activities (page $page)');
        return activities;
      } else {
        _logger.e('Failed to get gift activity feed: ${response.statusMessage}');
        return [];
      }
    } catch (e) {
      _logger.e('Error getting gift activity feed: $e');
      return [];
    }
  }
}
