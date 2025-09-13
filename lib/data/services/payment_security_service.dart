import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Security service for payment and authentication protection
class PaymentSecurityService {
  static const String _keyDeviceFingerprint = 'device_fingerprint';
  static const String _keySecuritySettings = 'security_settings';
  static const String _keySecurityLogs = 'security_logs';
  static const String _keyTrustedDevices = 'trusted_devices';
  
  // Logger instance
  final Logger _logger = Logger();
  
  // Stream controllers for security events
  final StreamController<SecurityEvent> _securityEventController = 
      StreamController<SecurityEvent>.broadcast();
  final StreamController<SecuritySettings> _settingsController = 
      StreamController<SecuritySettings>.broadcast();

  // Streams
  Stream<SecurityEvent> get securityEventStream => _securityEventController.stream;
  Stream<SecuritySettings> get settingsStream => _settingsController.stream;

  /// Generate device fingerprint
  Future<String> generateDeviceFingerprint() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final prefs = await SharedPreferences.getInstance();
      
      // Try to get existing fingerprint first
      final existingFingerprint = prefs.getString(_keyDeviceFingerprint);
      if (existingFingerprint != null) {
        return existingFingerprint;
      }

      // Generate new fingerprint
      String fingerprint;
      
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        final components = [
          androidInfo.model,
          androidInfo.manufacturer,
          androidInfo.id,
          androidInfo.hardware,
          androidInfo.device,
        ];
        fingerprint = _hashComponents(components);
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        final components = [
          iosInfo.model,
          iosInfo.systemName,
          iosInfo.systemVersion,
          iosInfo.identifierForVendor ?? '',
          iosInfo.localizedModel,
        ];
        fingerprint = _hashComponents(components);
      } else {
        // Fallback for other platforms
        fingerprint = _generateRandomFingerprint();
      }

      // Store fingerprint
      await prefs.setString(_keyDeviceFingerprint, fingerprint);
      return fingerprint;
    } catch (e) {
      // Fallback to random fingerprint
      final fingerprint = _generateRandomFingerprint();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyDeviceFingerprint, fingerprint);
      return fingerprint;
    }
  }

  /// Get device fingerprint
  Future<String> getDeviceFingerprint() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyDeviceFingerprint) ?? await generateDeviceFingerprint();
  }

  /// Validate payment transaction security
  Future<SecurityValidationResult> validatePaymentSecurity({
    required double amount,
    required String paymentMethodId,
    Map<String, dynamic>? metadata,
  }) async {
    final issues = <SecurityIssue>[];
    final recommendations = <String>[];

    // Check amount thresholds
    final settings = await getSecuritySettings();
    if (amount > settings.largeTransactionThreshold) {
      issues.add(SecurityIssue.largeAmount);
      recommendations.add('Consider additional verification for large amounts');
    }

    // Check velocity (multiple transactions in short time)
    final recentTransactions = await _getRecentTransactionCount();
    if (recentTransactions > settings.velocityLimit) {
      issues.add(SecurityIssue.highVelocity);
      recommendations.add('Multiple transactions detected. Consider adding delay');
    }

    // Check device trust
    final deviceFingerprint = await getDeviceFingerprint();
    final isTrustedDevice = await _isDeviceTrusted(deviceFingerprint);
    if (!isTrustedDevice) {
      issues.add(SecurityIssue.untrustedDevice);
      recommendations.add('New device detected. Consider additional verification');
    }

    // Check for suspicious patterns
    if (metadata != null && _detectSuspiciousPatterns(metadata)) {
      issues.add(SecurityIssue.suspiciousPattern);
      recommendations.add('Suspicious activity pattern detected');
    }

    // Determine risk level
    final riskLevel = _calculateRiskLevel(issues);

    // Log security check
    await _logSecurityEvent(SecurityEvent(
      type: SecurityEventType.paymentValidation,
      riskLevel: riskLevel,
      deviceFingerprint: deviceFingerprint,
      amount: amount,
      issues: issues,
      timestamp: DateTime.now(),
    ));

    return SecurityValidationResult(
      isValid: riskLevel != RiskLevel.high,
      riskLevel: riskLevel,
      issues: issues,
      recommendations: recommendations,
      requiresAdditionalAuth: riskLevel == RiskLevel.high || 
                             issues.contains(SecurityIssue.largeAmount),
    );
  }

  /// Encrypt sensitive data
  String encryptSensitiveData(String data, String key) {
    try {
      // Simple XOR encryption for demo (use proper encryption in production)
      final keyBytes = utf8.encode(key);
      final dataBytes = utf8.encode(data);
      final encrypted = <int>[];

      for (int i = 0; i < dataBytes.length; i++) {
        encrypted.add(dataBytes[i] ^ keyBytes[i % keyBytes.length]);
      }

      return base64Encode(encrypted);
    } catch (e) {
      throw SecurityException('Encryption failed: $e');
    }
  }

  /// Decrypt sensitive data
  String decryptSensitiveData(String encryptedData, String key) {
    try {
      final keyBytes = utf8.encode(key);
      final encryptedBytes = base64Decode(encryptedData);
      final decrypted = <int>[];

      for (int i = 0; i < encryptedBytes.length; i++) {
        decrypted.add(encryptedBytes[i] ^ keyBytes[i % keyBytes.length]);
      }

      return utf8.decode(decrypted);
    } catch (e) {
      throw SecurityException('Decryption failed: $e');
    }
  }

  /// Get security settings
  Future<SecuritySettings> getSecuritySettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_keySecuritySettings);
      
      if (settingsJson != null) {
        final json = jsonDecode(settingsJson) as Map<String, dynamic>;
        return SecuritySettings.fromJson(json);
      }
      
      // Return default settings
      return SecuritySettings.defaults();
    } catch (e) {
      return SecuritySettings.defaults();
    }
  }

  /// Update security settings
  Future<void> updateSecuritySettings(SecuritySettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keySecuritySettings, jsonEncode(settings.toJson()));
      _settingsController.add(settings);
      
      await _logSecurityEvent(SecurityEvent(
        type: SecurityEventType.settingsChanged,
        riskLevel: RiskLevel.low,
        deviceFingerprint: await getDeviceFingerprint(),
        timestamp: DateTime.now(),
      ));
    } catch (e) {
      _logger.e('Error updating security settings: $e');
    }
  }

  /// Add trusted device
  Future<void> addTrustedDevice(String deviceFingerprint) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final trustedDevices = await _getTrustedDevices();
      
      if (!trustedDevices.contains(deviceFingerprint)) {
        trustedDevices.add(deviceFingerprint);
        await prefs.setStringList(_keyTrustedDevices, trustedDevices);
        
        await _logSecurityEvent(SecurityEvent(
          type: SecurityEventType.deviceTrusted,
          riskLevel: RiskLevel.low,
          deviceFingerprint: deviceFingerprint,
          timestamp: DateTime.now(),
        ));
      }
    } catch (e) {
      _logger.e('Error adding trusted device: $e');
    }
  }

  /// Remove trusted device
  Future<void> removeTrustedDevice(String deviceFingerprint) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final trustedDevices = await _getTrustedDevices();
      
      if (trustedDevices.remove(deviceFingerprint)) {
        await prefs.setStringList(_keyTrustedDevices, trustedDevices);
        
        await _logSecurityEvent(SecurityEvent(
          type: SecurityEventType.deviceUntrusted,
          riskLevel: RiskLevel.medium,
          deviceFingerprint: deviceFingerprint,
          timestamp: DateTime.now(),
        ));
      }
    } catch (e) {
      _logger.e('Error removing trusted device: $e');
    }
  }

  /// Get security logs
  Future<List<SecurityEvent>> getSecurityLogs({int limit = 50}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final logsJson = prefs.getString(_keySecurityLogs);
      
      if (logsJson != null) {
        final logsList = jsonDecode(logsJson) as List;
        final events = logsList
            .map((json) => SecurityEvent.fromJson(json as Map<String, dynamic>))
            .toList();
        
        // Sort by timestamp (newest first) and limit
        events.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        return events.take(limit).toList();
      }
      
      return [];
    } catch (e) {
      _logger.e('Error getting security logs: $e');
      return [];
    }
  }

  /// Clear security logs
  Future<void> clearSecurityLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keySecurityLogs);
    } catch (e) {
      _logger.e('Error clearing security logs: $e');
    }
  }

  /// Generate secure random token
  String generateSecureToken({int length = 32}) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random.secure();
    return String.fromCharCodes(
      Iterable.generate(length, (_) => chars.codeUnitAt(random.nextInt(chars.length)))
    );
  }

  /// Hash sensitive data
  String hashSensitiveData(String data) {
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Private helper methods
  String _hashComponents(List<String> components) {
    final combined = components.join('|');
    return hashSensitiveData(combined);
  }

  String _generateRandomFingerprint() {
    return generateSecureToken(length: 64);
  }

  Future<List<String>> _getTrustedDevices() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_keyTrustedDevices) ?? [];
  }

  Future<bool> _isDeviceTrusted(String deviceFingerprint) async {
    final trustedDevices = await _getTrustedDevices();
    return trustedDevices.contains(deviceFingerprint);
  }

  Future<int> _getRecentTransactionCount() async {
    // Simplified - in production, this would check actual transaction history
    final prefs = await SharedPreferences.getInstance();
    final lastCheck = prefs.getInt('last_velocity_check') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    // Reset counter if more than 1 hour has passed
    if (now - lastCheck > 3600000) {
      await prefs.setInt('last_velocity_check', now);
      await prefs.setInt('recent_transaction_count', 0);
      return 0;
    }
    
    return prefs.getInt('recent_transaction_count') ?? 0;
  }

  bool _detectSuspiciousPatterns(Map<String, dynamic> metadata) {
    // Simplified suspicious pattern detection
    final userAgent = metadata['user_agent'] as String?;
    final ipAddress = metadata['ip_address'] as String?;
    
    // Check for common suspicious indicators
    if (userAgent != null && userAgent.toLowerCase().contains('bot')) {
      return true;
    }
    
    if (ipAddress != null && _isSuspiciousIP(ipAddress)) {
      return true;
    }
    
    return false;
  }

  bool _isSuspiciousIP(String ip) {
    // Simplified IP checking - in production, use proper IP reputation services
    final suspiciousRanges = ['10.0.0.', '192.168.', '127.0.0.'];
    return suspiciousRanges.any((range) => ip.startsWith(range));
  }

  RiskLevel _calculateRiskLevel(List<SecurityIssue> issues) {
    if (issues.isEmpty) return RiskLevel.low;
    
    final highRiskIssues = [SecurityIssue.suspiciousPattern, SecurityIssue.highVelocity];
    if (issues.any((issue) => highRiskIssues.contains(issue))) {
      return RiskLevel.high;
    }
    
    if (issues.length >= 2) return RiskLevel.medium;
    return RiskLevel.low;
  }

  Future<void> _logSecurityEvent(SecurityEvent event) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final logsJson = prefs.getString(_keySecurityLogs);
      
      List<SecurityEvent> events;
      if (logsJson != null) {
        final logsList = jsonDecode(logsJson) as List;
        events = logsList
            .map((json) => SecurityEvent.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        events = [];
      }
      
      events.add(event);
      
      // Keep only last 100 events
      if (events.length > 100) {
        events = events.skip(events.length - 100).toList();
      }
      
      final newLogsJson = jsonEncode(events.map((e) => e.toJson()).toList());
      await prefs.setString(_keySecurityLogs, newLogsJson);
      
      _securityEventController.add(event);
    } catch (e) {
      _logger.e('Error logging security event: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _securityEventController.close();
    _settingsController.close();
  }
}

/// Security validation result
class SecurityValidationResult {
  final bool isValid;
  final RiskLevel riskLevel;
  final List<SecurityIssue> issues;
  final List<String> recommendations;
  final bool requiresAdditionalAuth;

  const SecurityValidationResult({
    required this.isValid,
    required this.riskLevel,
    required this.issues,
    required this.recommendations,
    required this.requiresAdditionalAuth,
  });
}

/// Security settings model
class SecuritySettings {
  final double largeTransactionThreshold;
  final int velocityLimit;
  final bool requireBiometricAuth;
  final bool enableDeviceFingerprinting;
  final bool logSecurityEvents;
  final int sessionTimeoutMinutes;

  const SecuritySettings({
    required this.largeTransactionThreshold,
    required this.velocityLimit,
    required this.requireBiometricAuth,
    required this.enableDeviceFingerprinting,
    required this.logSecurityEvents,
    required this.sessionTimeoutMinutes,
  });

  factory SecuritySettings.defaults() {
    return const SecuritySettings(
      largeTransactionThreshold: 100.0,
      velocityLimit: 5,
      requireBiometricAuth: true,
      enableDeviceFingerprinting: true,
      logSecurityEvents: true,
      sessionTimeoutMinutes: 30,
    );
  }

  factory SecuritySettings.fromJson(Map<String, dynamic> json) {
    return SecuritySettings(
      largeTransactionThreshold: (json['largeTransactionThreshold'] as num).toDouble(),
      velocityLimit: json['velocityLimit'] as int,
      requireBiometricAuth: json['requireBiometricAuth'] as bool,
      enableDeviceFingerprinting: json['enableDeviceFingerprinting'] as bool,
      logSecurityEvents: json['logSecurityEvents'] as bool,
      sessionTimeoutMinutes: json['sessionTimeoutMinutes'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'largeTransactionThreshold': largeTransactionThreshold,
      'velocityLimit': velocityLimit,
      'requireBiometricAuth': requireBiometricAuth,
      'enableDeviceFingerprinting': enableDeviceFingerprinting,
      'logSecurityEvents': logSecurityEvents,
      'sessionTimeoutMinutes': sessionTimeoutMinutes,
    };
  }
}

/// Security event model
class SecurityEvent {
  final SecurityEventType type;
  final RiskLevel riskLevel;
  final String deviceFingerprint;
  final double? amount;
  final List<SecurityIssue> issues;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  const SecurityEvent({
    required this.type,
    required this.riskLevel,
    required this.deviceFingerprint,
    this.amount,
    this.issues = const [],
    required this.timestamp,
    this.metadata,
  });

  factory SecurityEvent.fromJson(Map<String, dynamic> json) {
    return SecurityEvent(
      type: SecurityEventType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => SecurityEventType.other,
      ),
      riskLevel: RiskLevel.values.firstWhere(
        (e) => e.name == json['riskLevel'],
        orElse: () => RiskLevel.low,
      ),
      deviceFingerprint: json['deviceFingerprint'] as String,
      amount: json['amount'] as double?,
      issues: (json['issues'] as List?)
          ?.map((e) => SecurityIssue.values.firstWhere(
                (issue) => issue.name == e,
                orElse: () => SecurityIssue.other,
              ))
          .toList() ?? [],
      timestamp: DateTime.parse(json['timestamp'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'riskLevel': riskLevel.name,
      'deviceFingerprint': deviceFingerprint,
      'amount': amount,
      'issues': issues.map((e) => e.name).toList(),
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }
}

/// Security enums
enum RiskLevel { low, medium, high }

enum SecurityEventType {
  paymentValidation,
  deviceTrusted,
  deviceUntrusted,
  settingsChanged,
  suspiciousActivity,
  other,
}

enum SecurityIssue {
  largeAmount,
  highVelocity,
  untrustedDevice,
  suspiciousPattern,
  other,
}

/// Security exception
class SecurityException implements Exception {
  final String message;
  const SecurityException(this.message);
  
  @override
  String toString() => 'SecurityException: $message';
}

// Platform detection (simplified)
class Platform {
  static bool get isAndroid => true; // Would be Platform.isAndroid in real implementation
  static bool get isIOS => false;    // Would be Platform.isIOS in real implementation
}
