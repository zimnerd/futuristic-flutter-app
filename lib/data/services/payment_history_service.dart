import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../models/payment_transaction.dart';
import '../models/api_response.dart';
import '../../core/utils/logger.dart';

/// Service for managing payment history
class PaymentHistoryService {
  final String baseUrl;
  final Map<String, String> headers;

  // Stream controller for reactive updates
  final StreamController<List<PaymentTransaction>> _historyController =
      StreamController<List<PaymentTransaction>>.broadcast();

  PaymentHistoryService({
    required this.baseUrl,
    this.headers = const {'Content-Type': 'application/json'},
  });

  // Streams
  Stream<List<PaymentTransaction>> get historyStream =>
      _historyController.stream;

  /// Simple HTTP GET method
  Future<Map<String, dynamic>> _get(
    String endpoint, {
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      var uri = Uri.parse('$baseUrl$endpoint');
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(
          queryParameters: queryParams.map((k, v) => MapEntry(k, v.toString())),
        );
      }

      final response = await http.get(uri, headers: headers);
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  /// Simple HTTP POST method
  Future<Map<String, dynamic>> _post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(body),
      );
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  /// Get payment history with optional filtering
  Future<ApiResponse<List<PaymentTransaction>>> getPaymentHistory({
    PaymentHistoryFilter? filter,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      // Build query parameters
      final queryParams = <String, dynamic>{'page': page, 'limit': limit};

      if (filter != null) {
        if (filter.type != null) queryParams['type'] = filter.type!.name;
        if (filter.status != null) queryParams['status'] = filter.status!.name;
        if (filter.startDate != null)
          queryParams['start_date'] = filter.startDate!.toIso8601String();
        if (filter.endDate != null)
          queryParams['end_date'] = filter.endDate!.toIso8601String();
        if (filter.subscriptionId != null)
          queryParams['subscription_id'] = filter.subscriptionId;
        if (filter.minAmount != null)
          queryParams['min_amount'] = filter.minAmount;
        if (filter.maxAmount != null)
          queryParams['max_amount'] = filter.maxAmount;
      }

      final response = await _get(
        '/payments/history',
        queryParams: queryParams,
      );

      if (response['success'] == true) {
        final transactionsList = response['data'] as List;
        final transactions = transactionsList
            .map(
              (json) =>
                  PaymentTransaction.fromJson(json as Map<String, dynamic>),
            )
            .toList();

        // Cache recent transactions locally
        await _cacheTransactions(transactions, page == 1);

        _historyController.add(transactions);
        return ApiResponse.success(transactions);
      } else {
        return ApiResponse.error(
          response['error'] ?? 'Failed to fetch payment history',
        );
      }
    } catch (e) {
      // Fallback to cached data
      final cachedTransactions = await _getCachedTransactions();
      if (cachedTransactions.isNotEmpty) {
        final filtered = filter != null
            ? cachedTransactions.where((t) => filter.matches(t)).toList()
            : cachedTransactions;
        return ApiResponse.success(filtered);
      }

      return ApiResponse.error('Failed to fetch payment history: $e');
    }
  }

  /// Get transaction by ID
  Future<ApiResponse<PaymentTransaction>> getTransactionById(
    String transactionId,
  ) async {
    try {
      final response = await _get('/payments/transactions/$transactionId');

      if (response['success'] == true) {
        final transaction = PaymentTransaction.fromJson(
          response['data'] as Map<String, dynamic>,
        );
        return ApiResponse.success(transaction);
      } else {
        return ApiResponse.error(response['error'] ?? 'Transaction not found');
      }
    } catch (e) {
      // Try to find in cached transactions
      final cachedTransactions = await _getCachedTransactions();
      final transaction = cachedTransactions
          .where((t) => t.id == transactionId)
          .firstOrNull;

      if (transaction != null) {
        return ApiResponse.success(transaction);
      }

      return ApiResponse.error('Failed to fetch transaction: $e');
    }
  }

  /// Download transaction receipt
  Future<ApiResponse<String>> downloadReceipt(String transactionId) async {
    try {
      final response = await _get(
        '/payments/transactions/$transactionId/receipt',
      );

      if (response['success'] == true) {
        return ApiResponse.success(response['data']['receipt_url'] as String);
      } else {
        return ApiResponse.error(
          response['error'] ?? 'Failed to generate receipt',
        );
      }
    } catch (e) {
      return ApiResponse.error('Failed to download receipt: $e');
    }
  }

  /// Export payment history
  Future<ApiResponse<String>> exportPaymentHistory({
    PaymentHistoryFilter? filter,
    String format = 'csv', // csv, pdf, excel
  }) async {
    try {
      final body = <String, dynamic>{'format': format};

      if (filter != null) {
        if (filter.type != null) body['type'] = filter.type!.name;
        if (filter.status != null) body['status'] = filter.status!.name;
        if (filter.startDate != null)
          body['start_date'] = filter.startDate!.toIso8601String();
        if (filter.endDate != null)
          body['end_date'] = filter.endDate!.toIso8601String();
        if (filter.subscriptionId != null)
          body['subscription_id'] = filter.subscriptionId;
        if (filter.minAmount != null) body['min_amount'] = filter.minAmount;
        if (filter.maxAmount != null) body['max_amount'] = filter.maxAmount;
      }

      final response = await _post('/payments/export', body);

      if (response['success'] == true) {
        return ApiResponse.success(response['data']['download_url'] as String);
      } else {
        return ApiResponse.error(
          response['error'] ?? 'Failed to export payment history',
        );
      }
    } catch (e) {
      return ApiResponse.error('Failed to export payment history: $e');
    }
  }

  /// Get payment statistics
  Future<ApiResponse<PaymentStats>> getPaymentStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (startDate != null)
        queryParams['start_date'] = startDate.toIso8601String();
      if (endDate != null) queryParams['end_date'] = endDate.toIso8601String();

      final response = await _get('/payments/stats', queryParams: queryParams);

      if (response['success'] == true) {
        final stats = PaymentStats.fromJson(
          response['data'] as Map<String, dynamic>,
        );
        return ApiResponse.success(stats);
      } else {
        return ApiResponse.error(
          response['error'] ?? 'Failed to fetch payment statistics',
        );
      }
    } catch (e) {
      // Generate basic stats from cached data
      final cachedTransactions = await _getCachedTransactions();
      if (cachedTransactions.isNotEmpty) {
        final stats = _generateStatsFromCache(
          cachedTransactions,
          startDate,
          endDate,
        );
        return ApiResponse.success(stats);
      }

      return ApiResponse.error('Failed to fetch payment statistics: $e');
    }
  }

  /// Search transactions
  Future<ApiResponse<List<PaymentTransaction>>> searchTransactions({
    required String query,
    PaymentHistoryFilter? filter,
    int limit = 10,
  }) async {
    try {
      final body = <String, dynamic>{'query': query, 'limit': limit};

      if (filter != null) {
        if (filter.type != null) body['type'] = filter.type!.name;
        if (filter.status != null) body['status'] = filter.status!.name;
        if (filter.startDate != null)
          body['start_date'] = filter.startDate!.toIso8601String();
        if (filter.endDate != null)
          body['end_date'] = filter.endDate!.toIso8601String();
      }

      final response = await _post('/payments/search', body);

      if (response['success'] == true) {
        final transactionsList = response['data'] as List;
        final transactions = transactionsList
            .map(
              (json) =>
                  PaymentTransaction.fromJson(json as Map<String, dynamic>),
            )
            .toList();

        return ApiResponse.success(transactions);
      } else {
        return ApiResponse.error(response['error'] ?? 'Search failed');
      }
    } catch (e) {
      // Fallback to local search in cached data
      final cachedTransactions = await _getCachedTransactions();
      final results = cachedTransactions.where((transaction) {
        final queryLower = query.toLowerCase();
        return transaction.description.toLowerCase().contains(queryLower) ||
            transaction.id.toLowerCase().contains(queryLower) ||
            (transaction.subscriptionId?.toLowerCase().contains(queryLower) ??
                false);
      }).toList();

      if (filter != null) {
        return ApiResponse.success(
          results.where((t) => filter.matches(t)).toList(),
        );
      }

      return ApiResponse.success(results);
    }
  }

  /// Cache transactions locally
  Future<void> _cacheTransactions(
    List<PaymentTransaction> transactions,
    bool clearFirst,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      List<PaymentTransaction> allTransactions;

      if (clearFirst) {
        allTransactions = transactions;
      } else {
        final existing = await _getCachedTransactions();
        final combined = <String, PaymentTransaction>{};

        // Add existing transactions
        for (final transaction in existing) {
          combined[transaction.id] = transaction;
        }

        // Add new transactions (will overwrite duplicates)
        for (final transaction in transactions) {
          combined[transaction.id] = transaction;
        }

        allTransactions = combined.values.toList();
      }

      // Sort by date (newest first) and limit to 100 transactions
      allTransactions.sort((a, b) => b.processedAt.compareTo(a.processedAt));
      if (allTransactions.length > 100) {
        allTransactions = allTransactions.take(100).toList();
      }

      final jsonList = allTransactions.map((t) => t.toJson()).toList();
      await prefs.setString(
        'cached_payment_transactions',
        jsonEncode(jsonList),
      );
    } catch (e) {
      AppLogger.error('Error caching transactions: $e');
    }
  }

  /// Get cached transactions
  Future<List<PaymentTransaction>> _getCachedTransactions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('cached_payment_transactions');

      if (cachedData != null) {
        final jsonList = jsonDecode(cachedData) as List;
        return jsonList
            .map(
              (json) =>
                  PaymentTransaction.fromJson(json as Map<String, dynamic>),
            )
            .toList();
      }

      return [];
    } catch (e) {
      AppLogger.error('Error getting cached transactions: $e');
      return [];
    }
  }

  /// Generate stats from cached data
  PaymentStats _generateStatsFromCache(
    List<PaymentTransaction> transactions,
    DateTime? startDate,
    DateTime? endDate,
  ) {
    var filtered = transactions;

    if (startDate != null) {
      filtered = filtered
          .where((t) => t.processedAt.isAfter(startDate))
          .toList();
    }
    if (endDate != null) {
      filtered = filtered
          .where((t) => t.processedAt.isBefore(endDate))
          .toList();
    }

    final completed = filtered.where(
      (t) => t.status == PaymentTransactionStatus.completed,
    );
    final totalAmount = completed.fold(0.0, (sum, t) => sum + t.amount);
    final refunded = filtered.where(
      (t) => t.status == PaymentTransactionStatus.refunded,
    );
    final totalRefunded = refunded.fold(0.0, (sum, t) => sum + t.amount);

    return PaymentStats(
      totalTransactions: filtered.length,
      totalAmount: totalAmount,
      totalRefunded: totalRefunded,
      successfulTransactions: completed.length,
      failedTransactions: filtered
          .where((t) => t.status == PaymentTransactionStatus.failed)
          .length,
      averageTransactionAmount: completed.isNotEmpty
          ? totalAmount / completed.length
          : 0,
      currency: transactions.isNotEmpty ? transactions.first.currency : 'USD',
    );
  }

  /// Get user's coin balance
  Future<Map<String, dynamic>> getCoinBalance(String accessToken) async {
    try {
      final uri = Uri.parse('$baseUrl/premium/coins/balance');
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        AppLogger.error('Failed to get coin balance: ${response.statusCode}');
        return {'totalCoins': 0};
      }
    } catch (e) {
      AppLogger.error('Error getting coin balance: $e');
      return {'totalCoins': 0};
    }
  }

  /// Dispose of resources
  void dispose() {
    _historyController.close();
  }
}

/// Payment statistics model
class PaymentStats {
  final int totalTransactions;
  final double totalAmount;
  final double totalRefunded;
  final int successfulTransactions;
  final int failedTransactions;
  final double averageTransactionAmount;
  final String currency;

  const PaymentStats({
    required this.totalTransactions,
    required this.totalAmount,
    required this.totalRefunded,
    required this.successfulTransactions,
    required this.failedTransactions,
    required this.averageTransactionAmount,
    required this.currency,
  });

  factory PaymentStats.fromJson(Map<String, dynamic> json) {
    return PaymentStats(
      totalTransactions: json['totalTransactions'] as int,
      totalAmount: (json['totalAmount'] as num).toDouble(),
      totalRefunded: (json['totalRefunded'] as num).toDouble(),
      successfulTransactions: json['successfulTransactions'] as int,
      failedTransactions: json['failedTransactions'] as int,
      averageTransactionAmount: (json['averageTransactionAmount'] as num)
          .toDouble(),
      currency: json['currency'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalTransactions': totalTransactions,
      'totalAmount': totalAmount,
      'totalRefunded': totalRefunded,
      'successfulTransactions': successfulTransactions,
      'failedTransactions': failedTransactions,
      'averageTransactionAmount': averageTransactionAmount,
      'currency': currency,
    };
  }
}

extension on Iterable<PaymentTransaction> {
  PaymentTransaction? get firstOrNull {
    return isEmpty ? null : first;
  }
}
