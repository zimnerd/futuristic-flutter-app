import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import '../../../domain/entities/message.dart';

/// Full-screen image viewer with gesture navigation and caption support
class ChatImageViewer extends StatefulWidget {
  final List<MediaAttachment> images;
  final int initialIndex;
  final String? heroTag;

  const ChatImageViewer({
    super.key,
    required this.images,
    this.initialIndex = 0,
    this.heroTag,
  });

  @override
  State<ChatImageViewer> createState() => _ChatImageViewerState();
}

class _ChatImageViewerState extends State<ChatImageViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          '${_currentIndex + 1} / ${widget.images.length}',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _saveImage(context),
            tooltip: 'Save to gallery',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareImage(context),
            tooltip: 'Share',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Image gallery
          PhotoViewGallery.builder(
            pageController: _pageController,
            itemCount: widget.images.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            builder: (context, index) {
              final image = widget.images[index];
              final imageUrl = image.url;

              return PhotoViewGalleryPageOptions(
                imageProvider: CachedNetworkImageProvider(imageUrl),
                heroAttributes: widget.heroTag != null
                    ? PhotoViewHeroAttributes(tag: '${widget.heroTag}_$index')
                    : null,
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 2.0,
                initialScale: PhotoViewComputedScale.contained,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.broken_image,
                          color: Colors.white54,
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load image',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
            loadingBuilder: (context, event) {
              return Center(
                child: CircularProgressIndicator(
                  value: event == null
                      ? null
                      : event.cumulativeBytesLoaded / event.expectedTotalBytes!,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              );
            },
            backgroundDecoration: const BoxDecoration(color: Colors.black),
          ),

          // Caption overlay (bottom)
          if (widget.images[_currentIndex].caption != null &&
              widget.images[_currentIndex].caption!.isNotEmpty)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildCaptionOverlay(widget.images[_currentIndex].caption!),
            ),

          // Image counter dots (if multiple images)
          if (widget.images.length > 1)
            Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: _buildImageIndicators(),
            ),
        ],
      ),
    );
  }

  Widget _buildCaptionOverlay(String caption) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withValues(alpha: 0.8),
            Colors.black.withValues(alpha: 0.0),
          ],
        ),
      ),
      child: SafeArea(
        child: Text(
          caption,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildImageIndicators() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            widget.images.length,
            (index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: index == _currentIndex ? 8 : 6,
              height: index == _currentIndex ? 8 : 6,
              decoration: BoxDecoration(
                color: index == _currentIndex
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _saveImage(BuildContext context) {
    // TODO: Implement save to gallery functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Save to gallery - Coming soon'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _shareImage(BuildContext context) {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share image - Coming soon'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
