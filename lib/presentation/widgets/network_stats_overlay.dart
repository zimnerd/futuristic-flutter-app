import 'package:flutter/material.dart';
import 'package:pulse_dating_app/core/theme/theme_extensions.dart';
import '../../core/services/network_quality_service.dart';

/// Detailed network statistics overlay modal
///
/// Bottom sheet modal showing comprehensive network quality metrics.
/// Features:
/// - Real-time metric updates
/// - Quality score with color coding
/// - Detailed metrics: latency, packet loss, jitter, bandwidth
/// - CPU and memory usage (when available)
/// - Video/audio stats (when available)
/// - Export/share functionality
class NetworkStatsOverlay extends StatelessWidget {
  const NetworkStatsOverlay({super.key});

  /// Show the overlay as a modal bottom sheet
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const NetworkStatsOverlay(),
    );
  }

  Color _getQualityColor(BuildContext context, NetworkQuality quality) {
    switch (quality) {
      case NetworkQuality.excellent:
        return Colors.green;
      case NetworkQuality.good:
        return Colors.yellow.shade700;
      case NetworkQuality.fair:
        return Colors.orange;
      case NetworkQuality.poor:
        return Colors.red;
      case NetworkQuality.unknown:
        return context.outlineColor;
    }
  }

  Widget _buildMetricRow({
    required BuildContext context,
    required String label,
    required String value,
    required IconData icon,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: context.outlineColor.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: context.onSurfaceVariantColor,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: valueColor ?? context.onSurfaceColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, top: 16.0, bottom: 8.0),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: context.onSurfaceColor,
            ),
          ),
        ),
        ...children,
        const Divider(height: 24),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final networkQualityService = NetworkQualityService();

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: context.onSurfaceColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: context.outlineColor.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Network Statistics',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Content
          Expanded(
            child: StreamBuilder<NetworkQualityMetrics>(
              stream: networkQualityService.metricsStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Waiting for network data...'),
                      ],
                    ),
                  );
                }

                final metrics = snapshot.data!;
                final qualityColor = _getQualityColor(
                  context,
                  metrics.overallQuality,
                );

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Overall Quality Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: qualityColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: qualityColor, width: 2),
                        ),
                        child: Column(
                          children: [
                            Text(
                              metrics.qualityDescription,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: qualityColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Quality Score: ${metrics.qualityScore}/100',
                              style: TextStyle(
                                fontSize: 16,
                                color: qualityColor,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Connection Quality Section
                      _buildSection(
                        
                        context: context, 
                        title: 'Connection Quality',
                        children: [
                          _buildMetricRow(
                            
                            context: context, 
                            label: 'Transmit Quality',
                            value: '${metrics.txQuality}/5',
                            icon: Icons.arrow_upward,
                            valueColor: metrics.txQuality >= 4
                                ? Colors.green
                                : Colors.orange,
                          ),
                          _buildMetricRow(
                            
                            context: context, 
                            label: 'Receive Quality',
                            value: '${metrics.rxQuality}/5',
                            icon: Icons.arrow_downward,
                            valueColor: metrics.rxQuality >= 4
                                ? Colors.green
                                : Colors.orange,
                          ),
                        ],
                      ),

                      // Network Metrics Section
                      _buildSection(
                        
                        context: context, 
                        title: 'Network Metrics',
                        children: [
                          _buildMetricRow(
                            
                            context: context, 
                            label: 'Latency (RTT)',
                            value: '${metrics.rtt} ms',
                            icon: Icons.access_time,
                            valueColor: metrics.rtt < 100
                                ? Colors.green
                                : Colors.orange,
                          ),
                          _buildMetricRow(
                            
                            context: context, 
                            label: 'Jitter',
                            value: '${metrics.jitter} ms',
                            icon: Icons.show_chart,
                            valueColor: metrics.jitter < 30
                                ? Colors.green
                                : Colors.orange,
                          ),
                          _buildMetricRow(
                            
                            context: context, 
                            label: 'Packet Loss',
                            value: '${metrics.packetLossRate}%',
                            icon: Icons.warning_amber,
                            valueColor: metrics.packetLossRate < 5
                                ? Colors.green
                                : Colors.red,
                          ),
                        ],
                      ),

                      // Bandwidth Section
                      _buildSection(
                        
                        context: context, 
                        title: 'Bandwidth',
                        children: [
                          _buildMetricRow(
                            
                            context: context, 
                            label: 'Upload',
                            value:
                                '${(metrics.uplinkBandwidth / 1000).toStringAsFixed(1)} Mbps',
                            icon: Icons.upload,
                          ),
                          _buildMetricRow(
                            
                            context: context, 
                            label: 'Download',
                            value:
                                '${(metrics.downlinkBandwidth / 1000).toStringAsFixed(1)} Mbps',
                            icon: Icons.download,
                          ),
                        ],
                      ),

                      // System Resources (if available)
                      if (metrics.cpuUsage != null ||
                          metrics.memoryUsage != null)
                        _buildSection(
                          
                          context: context, 
                          title: 'System Resources',
                          children: [
                            if (metrics.cpuUsage != null)
                              _buildMetricRow(
                                
                                context: context, 
                                label: 'CPU Usage',
                                value: '${metrics.cpuUsage}%',
                                icon: Icons.memory,
                                valueColor: (metrics.cpuUsage ?? 0) < 70
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                            if (metrics.memoryUsage != null)
                              _buildMetricRow(
                                
                                context: context, 
                                label: 'Memory Usage',
                                value: '${metrics.memoryUsage}%',
                                icon: Icons.storage,
                                valueColor: (metrics.memoryUsage ?? 0) < 80
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                          ],
                        ),

                      // Video Stats (if available)
                      if (metrics.videoDelay != null ||
                          metrics.videoBitrate != null)
                        _buildSection(
                          
                          context: context, 
                          title: 'Video Statistics',
                          children: [
                            if (metrics.videoDelay != null)
                              _buildMetricRow(
                                
                                context: context, 
                                label: 'Video Delay',
                                value: '${metrics.videoDelay} ms',
                                icon: Icons.videocam,
                              ),
                            if (metrics.videoBitrate != null)
                              _buildMetricRow(
                                
                                context: context, 
                                label: 'Video Bitrate',
                                value:
                                    '${(metrics.videoBitrate! / 1000).toStringAsFixed(1)} Mbps',
                                icon: Icons.video_settings,
                              ),
                          ],
                        ),

                      // Audio Stats (if available)
                      if (metrics.audioBitrate != null)
                        _buildSection(
                          
                          context: context, 
                          title: 'Audio Statistics',
                          children: [
                            _buildMetricRow(
                              
                              context: context, 
                              label: 'Audio Bitrate',
                              value: '${metrics.audioBitrate} kbps',
                              icon: Icons.mic,
                            ),
                          ],
                        ),

                      // Timestamp
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Center(
                          child: Text(
                            'Last updated: ${_formatTimestamp(metrics.timestamp)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: context.outlineColor.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 5) {
      return 'Just now';
    } else if (difference.inSeconds < 60) {
      return '${difference.inSeconds} seconds ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }
}
