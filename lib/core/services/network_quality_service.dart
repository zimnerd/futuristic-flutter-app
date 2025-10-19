import 'dart:async';
import 'dart:math';
import 'package:logger/logger.dart';
import '../../domain/services/websocket_service.dart';

/// Network quality levels based on overall score
enum NetworkQuality {
  excellent, // Green - Score 80-100
  good, // Yellow - Score 60-79
  fair, // Orange - Score 40-59
  poor, // Red - Score 0-39
  unknown, // Gray - No data
}

/// Comprehensive network quality metrics
class NetworkQualityMetrics {
  final int txQuality; // 0-5 (Agora transmit quality: 0=excellent, 5=poor)
  final int rxQuality; // 0-5 (Agora receive quality)
  final int packetLossRate; // 0-100 (percentage)
  final int jitter; // ms (variation in packet delay)
  final int rtt; // ms (round trip time / latency)
  final int uplinkBandwidth; // kbps
  final int downlinkBandwidth; // kbps
  final NetworkQuality overallQuality;
  final int qualityScore; // 0-100
  final DateTime timestamp;

  // Optional detailed stats
  final int? cpuUsage; // 0-100 percentage
  final int? memoryUsage; // 0-100 percentage
  final int? videoDelay; // ms
  final int? audioBitrate; // kbps
  final int? videoBitrate; // kbps

  NetworkQualityMetrics({
    required this.txQuality,
    required this.rxQuality,
    required this.packetLossRate,
    required this.jitter,
    required this.rtt,
    required this.uplinkBandwidth,
    required this.downlinkBandwidth,
    required this.overallQuality,
    required this.qualityScore,
    required this.timestamp,
    this.cpuUsage,
    this.memoryUsage,
    this.videoDelay,
    this.audioBitrate,
    this.videoBitrate,
  });

  /// Convert to JSON for WebSocket transmission
  Map<String, dynamic> toJson() {
    return {
      'txQuality': txQuality,
      'rxQuality': rxQuality,
      'packetLossRate': packetLossRate,
      'jitter': jitter,
      'rtt': rtt,
      'uplinkBandwidth': uplinkBandwidth,
      'downlinkBandwidth': downlinkBandwidth,
      'qualityScore': qualityScore,
      'overallQuality': overallQuality.name,
      'timestamp': timestamp.toIso8601String(),
      if (cpuUsage != null) 'cpuUsage': cpuUsage,
      if (memoryUsage != null) 'memoryUsage': memoryUsage,
      if (videoDelay != null) 'videoDelay': videoDelay,
      if (audioBitrate != null) 'audioBitrate': audioBitrate,
      if (videoBitrate != null) 'videoBitrate': videoBitrate,
    };
  }

  /// Human-readable quality description
  String get qualityDescription {
    switch (overallQuality) {
      case NetworkQuality.excellent:
        return 'Excellent';
      case NetworkQuality.good:
        return 'Good';
      case NetworkQuality.fair:
        return 'Fair';
      case NetworkQuality.poor:
        return 'Poor';
      case NetworkQuality.unknown:
        return 'Unknown';
    }
  }

  /// Quality color for UI (hex string)
  String get qualityColor {
    switch (overallQuality) {
      case NetworkQuality.excellent:
        return '#00D95F'; // Green
      case NetworkQuality.good:
        return '#FFB800'; // Yellow
      case NetworkQuality.fair:
        return '#FF8A00'; // Orange
      case NetworkQuality.poor:
        return '#FF3B3B'; // Red
      case NetworkQuality.unknown:
        return '#9E9E9E'; // Gray
    }
  }

  /// Quality icon emoji
  String get qualityIcon {
    switch (overallQuality) {
      case NetworkQuality.excellent:
        return '🟢';
      case NetworkQuality.good:
        return '🟡';
      case NetworkQuality.fair:
        return '🟠';
      case NetworkQuality.poor:
        return '🔴';
      case NetworkQuality.unknown:
        return '⚪';
    }
  }
}

/// Service to monitor and aggregate network quality metrics during calls
class NetworkQualityService {
  static final NetworkQualityService _instance =
      NetworkQualityService._internal();
  factory NetworkQualityService() => _instance;
  NetworkQualityService._internal();

  final Logger _logger = Logger();

  // Current metrics
  int _txQuality = 0; // Default excellent
  int _rxQuality = 0;
  int _packetLossRate = 0;
  int _jitter = 0;
  int _rtt = 0;
  int _uplinkBandwidth = 0;
  int _downlinkBandwidth = 0;
  int? _cpuUsage;
  int? _memoryUsage;
  int? _videoDelay;
  int? _audioBitrate;
  int? _videoBitrate;

  // Active call tracking
  String? _currentCallId;
  WebSocketService? _webSocketService;
  bool _isMonitoring = false;

  // Stream controller for UI updates
  final StreamController<NetworkQualityMetrics> _metricsController =
      StreamController<NetworkQualityMetrics>.broadcast();

  // Quality update frequency (send to backend every N seconds)
  static const _backendUpdateIntervalSeconds = 5;
  Timer? _backendUpdateTimer;
  DateTime? _lastMetricsUpdate;

  /// Stream of network quality metrics for UI
  Stream<NetworkQualityMetrics> get metricsStream => _metricsController.stream;

  /// Current quality metrics (latest snapshot)
  NetworkQualityMetrics? get currentMetrics =>
      _lastMetricsUpdate != null ? _calculateMetrics() : null;

  /// Start monitoring network quality for a call
  void startMonitoring({
    required String callId,
    WebSocketService? webSocketService,
  }) {
    if (_isMonitoring) {
      _logger.w('Already monitoring network quality');
      return;
    }

    _currentCallId = callId;
    _webSocketService = webSocketService;
    _isMonitoring = true;
    _resetMetrics();

    _logger.i('Started network quality monitoring for call: $callId');

    // Start periodic backend updates
    _backendUpdateTimer = Timer.periodic(
      const Duration(seconds: _backendUpdateIntervalSeconds),
      (_) => _sendQualityUpdateToBackend(),
    );
  }

  /// Stop monitoring network quality
  void stopMonitoring() {
    if (!_isMonitoring) return;

    _isMonitoring = false;
    _backendUpdateTimer?.cancel();
    _backendUpdateTimer = null;
    _currentCallId = null;
    _webSocketService = null;

    _logger.i('Stopped network quality monitoring');
  }

  /// Update network quality from Agora onNetworkQuality callback
  void updateNetworkQuality({
    required int txQuality, // 0-5 (0=excellent, 5=poor)
    required int rxQuality, // 0-5
  }) {
    if (!_isMonitoring) return;

    _txQuality = txQuality;
    _rxQuality = rxQuality;

    _updateMetrics();
  }

  /// Update RTC statistics from Agora onRtcStats callback
  void updateRtcStats({
    required int cpuTotalUsage, // 0-100 percentage
    required int memoryUsageRatio, // 0-100 percentage
    required int txBytes,
    required int rxBytes,
    required int txAudioBytes,
    required int rxAudioBytes,
    required int txVideoBytes,
    required int rxVideoBytes,
  }) {
    if (!_isMonitoring) return;

    _cpuUsage = cpuTotalUsage;
    _memoryUsage = memoryUsageRatio;

    // Calculate bitrates (approximate - based on 1 second interval)
    _audioBitrate = (rxAudioBytes * 8) ~/ 1000; // Convert to kbps
    _videoBitrate = (rxVideoBytes * 8) ~/ 1000;

    // Calculate bandwidth (total)
    _uplinkBandwidth = (txBytes * 8) ~/ 1000;
    _downlinkBandwidth = (rxBytes * 8) ~/ 1000;

    _updateMetrics();
  }

  /// Update remote video statistics from Agora onRemoteVideoStats callback
  void updateRemoteVideoStats({
    required int uid,
    required int delay, // ms
    required int receivedBitrate, // kbps
    required int decoderOutputFrameRate,
    required int packetLossRate, // 0-100 percentage
  }) {
    if (!_isMonitoring) return;

    _videoDelay = delay;
    _packetLossRate = packetLossRate;

    // RTT approximation (delay * 2 for round trip)
    _rtt = delay * 2;

    _updateMetrics();
  }

  /// Update remote audio statistics from Agora onRemoteAudioStats callback
  void updateRemoteAudioStats({
    required int uid,
    required int quality, // 0-5 (0=excellent, 5=poor)
    required int networkTransportDelay, // ms
    required int jitterBufferDelay, // ms
    required int audioLossRate, // 0-100 percentage
  }) {
    if (!_isMonitoring) return;

    _jitter = jitterBufferDelay;

    // Update packet loss (average with video)
    _packetLossRate = ((audioLossRate + _packetLossRate) / 2).round();

    // Update RTT (average with video)
    if (_rtt > 0) {
      _rtt = ((networkTransportDelay * 2 + _rtt) / 2).round();
    } else {
      _rtt = networkTransportDelay * 2;
    }

    _updateMetrics();
  }

  /// Calculate overall quality metrics
  NetworkQualityMetrics _calculateMetrics() {
    final score = _calculateQualityScore();
    final quality = _scoreToQuality(score);

    return NetworkQualityMetrics(
      txQuality: _txQuality,
      rxQuality: _rxQuality,
      packetLossRate: _packetLossRate,
      jitter: _jitter,
      rtt: _rtt,
      uplinkBandwidth: _uplinkBandwidth,
      downlinkBandwidth: _downlinkBandwidth,
      overallQuality: quality,
      qualityScore: score,
      timestamp: DateTime.now(),
      cpuUsage: _cpuUsage,
      memoryUsage: _memoryUsage,
      videoDelay: _videoDelay,
      audioBitrate: _audioBitrate,
      videoBitrate: _videoBitrate,
    );
  }

  /// Calculate quality score (0-100) from multiple metrics
  int _calculateQualityScore() {
    // Convert Agora quality (0=best, 5=worst) to score (0-100)
    final txScore = (5 - _txQuality) * 20; // 0→100, 5→0
    final rxScore = (5 - _rxQuality) * 20;

    // Packet loss penalty (0%=100, 10%=0)
    final packetLossScore = max(0, 100 - (_packetLossRate * 10));

    // Jitter penalty (0ms=100, 100ms=0)
    final jitterScore = max(0, 100 - _jitter);

    // RTT penalty (0ms=100, 500ms=0)
    final rttScore = max(0, 100 - (_rtt ~/ 5));

    // Weighted average (prioritize tx/rx quality from Agora)
    final weightedScore =
        (txScore * 0.25 +
                rxScore * 0.25 +
                packetLossScore * 0.2 +
                jitterScore * 0.15 +
                rttScore * 0.15)
            .round();

    return weightedScore.clamp(0, 100);
  }

  /// Convert quality score to NetworkQuality enum
  NetworkQuality _scoreToQuality(int score) {
    if (score >= 80) return NetworkQuality.excellent;
    if (score >= 60) return NetworkQuality.good;
    if (score >= 40) return NetworkQuality.fair;
    return NetworkQuality.poor;
  }

  /// Update metrics and notify UI
  void _updateMetrics() {
    _lastMetricsUpdate = DateTime.now();
    final metrics = _calculateMetrics();

    // Notify UI
    _metricsController.add(metrics);

    _logger.d(
      'Quality: ${metrics.qualityIcon} ${metrics.qualityDescription} (${metrics.qualityScore}/100) - '
      'RTT: ${metrics.rtt}ms, Loss: ${metrics.packetLossRate}%, Jitter: ${metrics.jitter}ms',
    );
  }

  /// Send quality update to backend via WebSocket
  void _sendQualityUpdateToBackend() {
    if (!_isMonitoring || _currentCallId == null || _webSocketService == null) {
      return;
    }

    final metrics = _calculateMetrics();

    try {
      _webSocketService!.emit('call:quality_update', {
        'callId': _currentCallId,
        'metrics': metrics.toJson(),
      });

      _logger.d('Sent quality update to backend: ${metrics.qualityScore}/100');
    } catch (e) {
      _logger.e('Failed to send quality update to backend: $e');
    }
  }

  /// Reset metrics to default values
  void _resetMetrics() {
    _txQuality = 0;
    _rxQuality = 0;
    _packetLossRate = 0;
    _jitter = 0;
    _rtt = 0;
    _uplinkBandwidth = 0;
    _downlinkBandwidth = 0;
    _cpuUsage = null;
    _memoryUsage = null;
    _videoDelay = null;
    _audioBitrate = null;
    _videoBitrate = null;
    _lastMetricsUpdate = null;
  }

  /// Dispose resources
  void dispose() {
    stopMonitoring();
    _metricsController.close();
  }
}
