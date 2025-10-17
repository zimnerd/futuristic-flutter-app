import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import '../../../core/theme/pulse_design_system.dart';
import '../../../core/utils/haptic_feedback_utils.dart';

/// Fullscreen Photo Preview with Zoom
///
/// Displays photos in fullscreen with:
/// - Pinch to zoom
/// - Swipe between photos
/// - Page indicator
/// - Close button
/// - Share button (optional)
/// - Report button (optional)
///
/// Usage:
/// ```dart
/// Navigator.push(
///   context,
///   MaterialPageRoute(
///     builder: (_) => PhotoPreviewScreen(
///       images: ['url1', 'url2', 'url3'],
///       initialIndex: 0,
///     ),
///   ),
/// );
/// ```
class PhotoPreviewScreen extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  final bool showShare;
  final bool showReport;
  final VoidCallback? onShare;
  final VoidCallback? onReport;

  const PhotoPreviewScreen({
    super.key,
    required this.images,
    this.initialIndex = 0,
    this.showShare = false,
    this.showReport = false,
    this.onShare,
    this.onReport,
  });

  @override
  State<PhotoPreviewScreen> createState() => _PhotoPreviewScreenState();
}

class _PhotoPreviewScreenState extends State<PhotoPreviewScreen> {
  late PageController _pageController;
  late int _currentIndex;
  bool _showUI = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);

    // Hide UI after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _showUI = false);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _toggleUI() {
    setState(() => _showUI = !_showUI);
    PulseHaptics.light();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Stack(
          children: [
            // Photo Gallery
            GestureDetector(
              onTap: _toggleUI,
              child: PhotoViewGallery.builder(
                scrollPhysics: const BouncingScrollPhysics(),
                builder: (BuildContext context, int index) {
                  return PhotoViewGalleryPageOptions(
                    imageProvider: NetworkImage(widget.images[index]),
                    initialScale: PhotoViewComputedScale.contained,
                    minScale: PhotoViewComputedScale.contained,
                    maxScale: PhotoViewComputedScale.covered * 3,
                    heroAttributes: PhotoViewHeroAttributes(
                      tag: widget.images[index],
                    ),
                  );
                },
                itemCount: widget.images.length,
                loadingBuilder: (context, event) => Center(
                  child: CircularProgressIndicator(
                    value: event == null
                        ? 0
                        : event.cumulativeBytesLoaded /
                            (event.expectedTotalBytes ?? 1),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      PulseColors.primary,
                    ),
                  ),
                ),
                backgroundDecoration: const BoxDecoration(
                  color: Colors.black,
                ),
                pageController: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                  PulseHaptics.light();
                },
              ),
            ),

            // Top Bar
            AnimatedOpacity(
              opacity: _showUI ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: SafeArea(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.5),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Close button
                      IconButton(
                        onPressed: () {
                          PulseHaptics.light();
                          Navigator.pop(context);
                        },
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),

                      // Page indicator
                      if (widget.images.length > 1)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_currentIndex + 1}/${widget.images.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                      // Actions
                      Row(
                        children: [
                          if (widget.showShare)
                            IconButton(
                              onPressed: () {
                                PulseHaptics.medium();
                                widget.onShare?.call();
                              },
                              icon: const Icon(
                                Icons.share,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          if (widget.showReport)
                            IconButton(
                              onPressed: () {
                                PulseHaptics.medium();
                                widget.onReport?.call();
                              },
                              icon: const Icon(
                                Icons.flag,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom indicators (dots)
            if (widget.images.length > 1)
              AnimatedOpacity(
                opacity: _showUI ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(
                          widget.images.length,
                          (index) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _currentIndex == index
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.4),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
