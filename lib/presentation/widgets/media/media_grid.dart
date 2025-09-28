import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../theme/pulse_colors.dart';
import '../../../domain/entities/message.dart';
import 'media_viewer.dart';

/// Modern grid widget for displaying multiple media items in chat messages
class MediaGrid extends StatelessWidget {
  final List<String> mediaUrls;
  final MessageType messageType;
  final bool isCurrentUser;
  final String? heroTagPrefix;

  const MediaGrid({
    super.key,
    required this.mediaUrls,
    required this.messageType,
    required this.isCurrentUser,
    this.heroTagPrefix,
  });

  @override
  Widget build(BuildContext context) {
    if (mediaUrls.isEmpty) return const SizedBox.shrink();
    
    final mediaCount = mediaUrls.length;
    
    return Container(
      constraints: const BoxConstraints(
        maxWidth: 280,
        maxHeight: 300,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _buildMediaLayout(context, mediaCount),
      ),
    );
  }

  Widget _buildMediaLayout(BuildContext context, int count) {
    switch (count) {
      case 1:
        return _buildSingleMedia(context, 0);
      case 2:
        return _buildTwoMedia(context);
      case 3:
        return _buildThreeMedia(context);
      case 4:
        return _buildFourMedia(context);
      default:
        return _buildMoreMedia(context);
    }
  }

  Widget _buildSingleMedia(BuildContext context, int index) {
    return GestureDetector(
      onTap: () => _openMediaViewer(context, index),
      child: Hero(
        tag: _getHeroTag(index),
        child: AspectRatio(
          aspectRatio: 4 / 3,
          child: CachedNetworkImage(
            imageUrl: mediaUrls[index],
            fit: BoxFit.cover,
            placeholder: (context, url) => _buildPlaceholder(),
            errorWidget: (context, url, error) => _buildErrorWidget(),
          ),
        ),
      ),
    );
  }

  Widget _buildTwoMedia(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Row(
        children: [
          Expanded(
            child: _buildMediaItem(context, 0),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: _buildMediaItem(context, 1),
          ),
        ],
      ),
    );
  }

  Widget _buildThreeMedia(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: _buildMediaItem(context, 0),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: _buildMediaItem(context, 1),
                ),
                const SizedBox(height: 2),
                Expanded(
                  child: _buildMediaItem(context, 2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFourMedia(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildMediaItem(context, 0)),
                const SizedBox(width: 2),
                Expanded(child: _buildMediaItem(context, 1)),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildMediaItem(context, 2)),
                const SizedBox(width: 2),
                Expanded(child: _buildMediaItem(context, 3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoreMedia(BuildContext context) {
    final remainingCount = mediaUrls.length - 3;
    
    return SizedBox(
      height: 200,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildMediaItem(context, 0)),
                const SizedBox(width: 2),
                Expanded(child: _buildMediaItem(context, 1)),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildMediaItem(context, 2)),
                const SizedBox(width: 2),
                Expanded(
                  child: Stack(
                    children: [
                      _buildMediaItem(context, 3),
                      // Overlay for more items
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.photo_library_rounded,
                                color: Colors.white,
                                size: 32,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '+$remainingCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaItem(BuildContext context, int index) {
    if (index >= mediaUrls.length) return const SizedBox.shrink();
    
    return GestureDetector(
      onTap: () => _openMediaViewer(context, index),
      child: Hero(
        tag: _getHeroTag(index),
        child: CachedNetworkImage(
          imageUrl: mediaUrls[index],
          fit: BoxFit.cover,
          placeholder: (context, url) => _buildPlaceholder(),
          errorWidget: (context, url, error) => _buildErrorWidget(),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: CircularProgressIndicator(
          valueColor: const AlwaysStoppedAnimation<Color>(PulseColors.primary),
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      color: Colors.grey[100],
      child: const Center(
        child: Icon(
          Icons.broken_image_rounded,
          color: Colors.grey,
          size: 32,
        ),
      ),
    );
  }

  String _getHeroTag(int index) {
    return heroTagPrefix != null 
        ? '${heroTagPrefix}_$index'
        : 'media_grid_$index';
  }

  void _openMediaViewer(BuildContext context, int initialIndex) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondaryAnimation) => MediaViewer(
          mediaUrls: mediaUrls,
          initialIndex: initialIndex,
          messageType: messageType,
          heroTag: heroTagPrefix,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }
}