import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/pulse_colors.dart';
import '../../../data/models/chat_model.dart';
import '../../../domain/entities/message.dart' as entities;
import '../media/media_grid.dart';
import '../media/media_viewer.dart';
import '../common/robust_network_image.dart';
import 'voice_message_bubble.dart';
import '../messaging/message_status_indicator.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isCurrentUser;
  final VoidCallback? onLongPress;
  final VoidCallback? onRetry;
  final Function(String)? onReaction;
  final VoidCallback? onReply;
  final VoidCallback? onMediaTap;
  final String? currentUserId;
  final bool isHighlighted;
  final String? searchQuery;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
    this.onLongPress,
    this.onRetry,
    this.onReaction,
    this.onReply,
    this.onMediaTap,
    this.currentUserId,
    this.isHighlighted = false,
    this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Column(
          children: [
            // Reply preview (if replying to another message)
            if (message.replyTo != null) _buildReplyPreview(context),

            // Main message row
            Row(
              mainAxisAlignment: isCurrentUser
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Avatar for received messages
                if (!isCurrentUser) _buildAvatar(),

                // Message bubble - keeping existing structure for now
                Flexible(
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    padding: _hasMedia()
                        ? EdgeInsets.zero
                        : const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: _hasMedia()
                          ? Colors.transparent
                          : isHighlighted
                          ? (isCurrentUser
                                ? PulseColors.primary.withValues(alpha: 0.9)
                                : PulseColors.secondary.withValues(alpha: 0.2))
                          : (isCurrentUser
                                ? PulseColors.primary
                                : Colors.grey[50]),
                      border: isHighlighted
                          ? Border.all(color: PulseColors.primary, width: 2)
                          : null,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft: Radius.circular(isCurrentUser ? 20 : 6),
                        bottomRight: Radius.circular(isCurrentUser ? 6 : 20),
                      ),
                      boxShadow: _hasMedia()
                          ? []
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Media content (images, videos, etc.)
                        if (_hasMedia()) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(20),
                              topRight: const Radius.circular(20),
                              bottomLeft: Radius.circular(
                                message.content?.isNotEmpty == true
                                    ? 4
                                    : (isCurrentUser ? 20 : 6),
                              ),
                              bottomRight: Radius.circular(
                                message.content?.isNotEmpty == true
                                    ? 4
                                    : (isCurrentUser ? 6 : 20),
                              ),
                            ),
                            child: _buildMediaContent(context),
                          ),
                        ],

                        // Location content
                        if (_hasLocation()) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(20),
                              topRight: const Radius.circular(20),
                              bottomLeft: Radius.circular(
                                message.content?.isNotEmpty == true
                                    ? 4
                                    : (isCurrentUser ? 20 : 6),
                              ),
                              bottomRight: Radius.circular(
                                message.content?.isNotEmpty == true
                                    ? 4
                                    : (isCurrentUser ? 6 : 20),
                              ),
                            ),
                            child: _buildLocationContent(context),
                          ),
                        ],

                        // Voice message content
                        if (_hasVoiceMessage()) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(20),
                              topRight: const Radius.circular(20),
                              bottomLeft: Radius.circular(
                                message.content?.isNotEmpty == true
                                    ? 4
                                    : (isCurrentUser ? 20 : 6),
                              ),
                              bottomRight: Radius.circular(
                                message.content?.isNotEmpty == true
                                    ? 4
                                    : (isCurrentUser ? 6 : 20),
                              ),
                            ),
                            child: _buildVoiceMessageContent(context),
                          ),
                        ],

                        // Text content with media or location
                        if ((_hasMedia() ||
                                _hasLocation() ||
                                _hasVoiceMessage()) &&
                            message.content != null &&
                            message.content!.isNotEmpty) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isCurrentUser
                                  ? PulseColors.primary
                                  : Colors.grey[50],
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(
                                  isCurrentUser ? 20 : 6,
                                ),
                                bottomRight: Radius.circular(
                                  isCurrentUser ? 6 : 20,
                                ),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  message.content!,
                                  style: TextStyle(
                                    color: isCurrentUser
                                        ? Colors.white
                                        : Colors.black87,
                                    fontSize: 16,
                                    height: 1.3,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      DateFormat(
                                        'h:mm a',
                                      ).format(message.createdAt),
                                      style: TextStyle(
                                        color: isCurrentUser
                                            ? Colors.white.withValues(
                                                alpha: 0.7,
                                              )
                                            : Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                    if (isCurrentUser) ...[
                                      const SizedBox(width: 4),
                                      MessageStatusIndicator(
                                        status: message.status,
                                        onRetry: onRetry,
                                        size: 16,
                                        color: Colors.white.withValues(
                                          alpha: 0.7,
                                        ),
                                        readColor: Colors.blue.shade300,
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ]
                        // Text-only content
                        else if (!_hasMedia() &&
                            !_hasLocation() &&
                            message.content != null &&
                            message.content!.isNotEmpty) ...[
                          _buildHighlightedText(
                            message.content!,
                            isCurrentUser,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                DateFormat('h:mm a').format(message.createdAt),
                                style: TextStyle(
                                  color: isCurrentUser
                                      ? Colors.white.withValues(alpha: 0.7)
                                      : Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                              if (isCurrentUser) ...[
                                const SizedBox(width: 4),
                                MessageStatusIndicator(
                                  status: message.status,
                                  onRetry: onRetry,
                                  size: 16,
                                  color: Colors.white.withValues(alpha: 0.7),
                                  readColor: Colors.blue.shade300,
                                ),
                              ],
                            ],
                          ),
                        ],
                        
                        // Media-only content timestamp
                        if (_hasMedia() &&
                            (message.content == null ||
                                message.content!.isEmpty)) ...[
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        DateFormat(
                                          'h:mm a',
                                        ).format(message.createdAt),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      if (isCurrentUser) ...[
                                        const SizedBox(width: 4),
                                        MessageStatusIndicator(
                                          status: message.status,
                                          onRetry: onRetry,
                                          size: 14,
                                          color: Colors.white,
                                          readColor: Colors.blue.shade300,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                
                if (isCurrentUser) const SizedBox(width: 8),
              ],
            ),
            
            // Reactions row
            if (message.reactions?.isNotEmpty == true) _buildReactions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Padding(
      padding: const EdgeInsets.only(right: 8, bottom: 4),
      child: CircleAvatar(
        radius: 16,
        backgroundColor: Colors.grey[300],
        backgroundImage: message.senderAvatar != null
            ? NetworkImage(message.senderAvatar!) // ✅ Use NetworkImage instead
            : null,
        child: message.senderAvatar == null
            ? Text(
                message.senderUsername.isNotEmpty
                    ? message.senderUsername[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildReplyPreview(BuildContext context) {
    final replyTo = message.replyTo!;
    return Container(
      margin: EdgeInsets.only(
        left: isCurrentUser ? 60 : 40,
        right: isCurrentUser ? 16 : 60,
        bottom: 4,
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 3,
              decoration: BoxDecoration(
                color: isCurrentUser
                    ? PulseColors.primary.withValues(alpha: 0.8)
                    : Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      replyTo.senderUsername,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isCurrentUser
                            ? PulseColors.primary
                            : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _getPreviewText(replyTo),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReactions(BuildContext context) {
    final reactions = message.reactions ?? [];
    if (reactions.isEmpty) return const SizedBox.shrink();

    // Group reactions by emoji
    final groupedReactions = <String, List<MessageReaction>>{};
    for (final reaction in reactions) {
      groupedReactions.putIfAbsent(reaction.emoji, () => []).add(reaction);
    }

    return Container(
      margin: EdgeInsets.only(
        left: isCurrentUser ? 20 : 4,
        right: isCurrentUser ? 4 : 20,
        top: 4,
      ),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: groupedReactions.entries.map((entry) {
          final emoji = entry.key;
          final reactionList = entry.value;
          final hasUserReacted =
              currentUserId != null &&
              reactionList.any((r) => r.userId == currentUserId);

          return GestureDetector(
            onTap: () => onReaction?.call(emoji),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: hasUserReacted
                    ? PulseColors.primary.withValues(alpha: 0.1)
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: hasUserReacted
                    ? Border.all(color: PulseColors.primary, width: 1)
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 14)),
                  if (reactionList.length > 1) ...[
                    const SizedBox(width: 4),
                    Text(
                      reactionList.length.toString(),
                      style: TextStyle(
                        fontSize: 12,
                        color: hasUserReacted
                            ? PulseColors.primary
                            : Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Check if message has media content
  bool _hasMedia() {
    return message.mediaUrls != null &&
        message.mediaUrls!.isNotEmpty &&
        (message.type == entities.MessageType.image ||
            message.type == entities.MessageType.video ||
            message.type == entities.MessageType.gif ||
            message.type == entities.MessageType.audio);
  }

  /// Check if message is a voice message
  bool _hasVoiceMessage() {
    return message.type == entities.MessageType.audio &&
        message.mediaUrls != null &&
        message.mediaUrls!.isNotEmpty;
  }

  /// Check if message has location content
  bool _hasLocation() {
    return message.type == entities.MessageType.location &&
        message.mediaUrls != null &&
        message.mediaUrls!.isNotEmpty &&
        message.mediaUrls!.any((url) => url.startsWith('geo:'));
  }

  /// Build location content widget
  Widget _buildLocationContent(BuildContext context) {
    if (!_hasLocation()) return const SizedBox.shrink();

    // Extract coordinates from geo URL
    final geoUrl = message.mediaUrls!.firstWhere(
      (url) => url.startsWith('geo:'),
      orElse: () => '',
    );

    if (geoUrl.isEmpty) return const SizedBox.shrink();

    // Parse coordinates from geo:lat,lng format
    final coords = geoUrl.substring(4).split(','); // Remove 'geo:' prefix
    if (coords.length < 2) return const SizedBox.shrink();

    final lat = double.tryParse(coords[0]);
    final lng = double.tryParse(coords[1]);
    if (lat == null || lng == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => _openLocationViewer(context, lat, lng),
      child: Container(
        width: 280,
        height: 160,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Stack(
          children: [
            // Map placeholder with gradient
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    PulseColors.primary.withValues(alpha: 0.1),
                    PulseColors.secondary.withValues(alpha: 0.1),
                  ],
                ),
              ),
            ),

            // Location icon and coordinates
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_on, size: 40, color: PulseColors.primary),
                  const SizedBox(height: 8),
                  Text(
                    'Location',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

            // Tap to view overlay
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Tap to view',
                  style: TextStyle(color: Colors.white, fontSize: 11),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Open location in external map application
  void _openLocationViewer(BuildContext context, double lat, double lng) async {
    // Try to open in external maps app using url_launcher
    try {
      // Try Apple Maps first (iOS), then Google Maps
      final appleMapsUrl = Uri.parse('https://maps.apple.com/?q=$lat,$lng');
      final googleMapsUrl = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
      );

      if (Platform.isIOS) {
        if (await canLaunchUrl(appleMapsUrl)) {
          await launchUrl(appleMapsUrl, mode: LaunchMode.externalApplication);
          return;
        }
      }

      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
        return;
      }

      // Fallback: show coordinates dialog
      if (context.mounted) {
        _showLocationDialog(context, lat, lng);
      }
    } catch (e) {
      // Show fallback dialog on error
      if (context.mounted) {
        _showLocationDialog(context, lat, lng);
      }
    }
  }

  /// Show location coordinates in a dialog (fallback)
  void _showLocationDialog(BuildContext context, double lat, double lng) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.location_on, color: PulseColors.primary),
            SizedBox(width: 8),
            Text('Location'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Coordinates:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 4),
            SelectableText(
              'Latitude: $lat\nLongitude: $lng',
              style: const TextStyle(fontFamily: 'monospace'),
            ),
            const SizedBox(height: 16),
            Text(
              'Tap the coordinates above to copy them, or use a map application to navigate to this location.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Build voice message content widget
  Widget _buildVoiceMessageContent(BuildContext context) {
    if (message.mediaUrls == null || message.mediaUrls!.isEmpty) {
      return const SizedBox.shrink();
    }

    final audioUrl = message.mediaUrls!.first;
    final duration = message.metadata?['duration'] ?? 0;
    final waveformData = List<double>.from(
      message.metadata?['waveform'] ?? List.generate(20, (index) => 0.5),
    );

    return VoiceMessageBubble(
      audioUrl: audioUrl,
      duration: duration,
      waveformData: waveformData,
      isCurrentUser: isCurrentUser,
    );
  }

  /// Build media content widget
  Widget _buildMediaContent(BuildContext context) {
    // Check if message is uploading (has pending media)
    if (message.status == MessageStatus.sending &&
        message.metadata?['pendingMediaIds'] != null) {
      return _buildUploadingPlaceholder(context);
    }

    // Check if we have actual media URLs
    if (!_hasMedia()) return const SizedBox.shrink();

    final mediaUrls = message.mediaUrls!;
    final heroTag = 'message_${message.id}';

    // Single image with optimized display
    if (mediaUrls.length == 1) {
      return _buildSingleImage(context, mediaUrls.first, heroTag);
    }

    // Multiple images with grid layout
    return MediaGrid(
      mediaUrls: mediaUrls,
      messageType: message.type,
      isCurrentUser: isCurrentUser,
      heroTagPrefix: heroTag,
    );
  }

  /// Build uploading placeholder for pending media
  Widget _buildUploadingPlaceholder(BuildContext context) {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Uploading...',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Build single image with modern styling
  Widget _buildSingleImage(
    BuildContext context,
    String imageUrl,
    String heroTag,
  ) {
    // Add cache buster for recently uploaded images
    final cacheBustedUrl = _addCacheBuster(imageUrl);
    final blurhash =
        message.metadata?['blurhash']
            as String?; // ✅ Extract blurhash from metadata

    return GestureDetector(
      onTap: () => _openMediaViewer(context, [imageUrl], 0, heroTag),
      child: Hero(
        tag: '${heroTag}_0',
        child: Container(
          constraints: const BoxConstraints(maxWidth: 280, maxHeight: 300),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: RobustNetworkImage(
              imageUrl: cacheBustedUrl, // Use cache-busted URL
              blurhash: blurhash, // ✅ Progressive loading with blurhash
              fit: BoxFit.cover,
              width: 280,
              height: 300,
            ),
          ),
        ),
      ),
    );
  }

  /// Add cache buster to URL for recently uploaded images
  String _addCacheBuster(String url) {
    try {
      final uri = Uri.parse(url);
      final now = DateTime.now().millisecondsSinceEpoch;

      // Add timestamp query parameter to force cache refresh
      return uri
          .replace(
            queryParameters: {
              ...uri.queryParameters,
              't': now.toString(),
            },
          )
          .toString();
    } catch (e) {
      // If URL parsing fails, return original
      return url;
    }
  }

  /// Open media viewer for full-screen viewing
  void _openMediaViewer(
    BuildContext context,
    List<String> mediaUrls,
    int initialIndex,
    String heroTag,
  ) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondaryAnimation) => MediaViewer(
          mediaUrls: mediaUrls,
          initialIndex: initialIndex,
          messageType: message.type,
          heroTag: heroTag,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  String _getPreviewText(MessageModel message) {
    switch (message.type) {
      case entities.MessageType.image:
        return '📷 Photo';
      case entities.MessageType.video:
        return '🎥 Video';
      case entities.MessageType.audio:
        return '🎵 Audio';
      case entities.MessageType.gif:
        return '🎭 GIF';
      case entities.MessageType.sticker:
        return '😊 Sticker';
      case entities.MessageType.location:
        return '📍 Location';
      case entities.MessageType.contact:
        return '👤 Contact';
      case entities.MessageType.file:
        return '📎 File';
      default:
        return message.content ?? '';
    }
  }
  
  Widget _buildHighlightedText(String content, bool isCurrentUser) {
    // If no search query or not highlighted, show normal text
    if (searchQuery == null || searchQuery!.isEmpty || !isHighlighted) {
      return Text(
        content,
        style: TextStyle(
          color: isCurrentUser ? Colors.white : Colors.black87,
          fontSize: 16,
          height: 1.3,
        ),
      );
    }
    
    // Build highlighted text
    final List<TextSpan> spans = [];
    final String lowerContent = content.toLowerCase();
    final String lowerQuery = searchQuery!.toLowerCase();
    
    int start = 0;
    int index = lowerContent.indexOf(lowerQuery, start);
    
    while (index != -1) {
      // Add text before the match
      if (index > start) {
        spans.add(TextSpan(
          text: content.substring(start, index),
          style: TextStyle(
            color: isCurrentUser ? Colors.white : Colors.black87,
            fontSize: 16,
            height: 1.3,
          ),
        ));
      }
      
      // Add highlighted match
      spans.add(TextSpan(
        text: content.substring(index, index + searchQuery!.length),
        style: TextStyle(
          color: isCurrentUser ? Colors.black : Colors.white,
          backgroundColor: isCurrentUser 
              ? Colors.yellow.withValues(alpha: 0.8) 
              : PulseColors.primary.withValues(alpha: 0.8),
          fontSize: 16,
          height: 1.3,
          fontWeight: FontWeight.bold,
        ),
      ));
      
      start = index + searchQuery!.length;
      index = lowerContent.indexOf(lowerQuery, start);
    }
    
    // Add remaining text
    if (start < content.length) {
      spans.add(TextSpan(
        text: content.substring(start),
        style: TextStyle(
          color: isCurrentUser ? Colors.white : Colors.black87,
          fontSize: 16,
          height: 1.3,
        ),
      ));
    }
    
    return RichText(
      text: TextSpan(children: spans),
    );
  }
}