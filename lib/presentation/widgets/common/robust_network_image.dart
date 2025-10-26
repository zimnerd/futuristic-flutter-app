import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';

/// A robust image widget that gracefully handles network failures,
/// 404 errors, and provides fallback placeholder images.
/// Now supports blurhash for progressive image loading.
class RobustNetworkImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;
  final String? fallbackAsset;
  final String? blurhash; // Blurhash string for progressive loading

  const RobustNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
    this.fallbackAsset,
    this.blurhash,
  });

  @override
  Widget build(BuildContext context) {
    // If no URL provided, show error widget immediately
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildErrorWidget(context);
    }

    Widget imageWidget = CachedNetworkImage(
      imageUrl: imageUrl!,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => _buildPlaceholder(context),
      errorWidget: (context, url, error) => _buildErrorWidget(context),
      errorListener: (error) {
        // Log 404 and other errors silently instead of throwing exceptions
        debugPrint('Image failed to load: $imageUrl - Error: $error');
      },
    );

    // Apply border radius if specified
    if (borderRadius != null) {
      imageWidget = ClipRRect(borderRadius: borderRadius!, child: imageWidget);
    }

    return imageWidget;
  }

  Widget _buildPlaceholder(BuildContext context) {
    // If custom placeholder provided, use it
    if (placeholder != null) {
      return placeholder!;
    }

    // If blurhash provided, show blurred placeholder
    if (blurhash != null && blurhash!.isNotEmpty) {
      return Stack(
        fit: StackFit.expand,
        children: [
          BlurHash(hash: blurhash!, imageFit: fit),
          // Small loading indicator over blurhash
          Center(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Default placeholder with loading indicator
    return Container(
      width: width,
      height: height,
      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).colorScheme.outline,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    if (errorWidget != null) {
      return errorWidget!;
    }

    // Try to use fallback asset if provided
    if (fallbackAsset != null) {
      return Image.asset(
        fallbackAsset!,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) =>
            _buildDefaultErrorWidget(context),
      );
    }

    return _buildDefaultErrorWidget(context);
  }

  Widget _buildDefaultErrorWidget(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[100],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported_outlined,
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            size: (width != null && width! < 100) ? 24 : 48,
          ),
          if (width == null || width! >= 100) ...[
            const SizedBox(height: 8),
            Text(
              'Image unavailable',
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// Specialized version for profile photos with gender-specific avatars
class ProfileNetworkImage extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final String? userGender; // 'male', 'female', or null for neutral
  final BorderRadius? borderRadius;

  const ProfileNetworkImage({
    super.key,
    required this.imageUrl,
    this.size = 50,
    this.userGender,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return RobustNetworkImage(
      imageUrl: imageUrl,
      width: size,
      height: size,
      borderRadius: borderRadius ?? BorderRadius.circular(size / 2),
      errorWidget: Builder(
        builder: (context) => _buildAvatarErrorWidget(context),
      ),
    );
  }

  Widget _buildAvatarErrorWidget(BuildContext context) {
    IconData avatarIcon;
    Color avatarColor;

    switch (userGender?.toLowerCase()) {
      case 'male':
        avatarIcon = Icons.person;
        avatarColor = Colors.blue[300]!;
        break;
      case 'female':
        avatarIcon = Icons.person;
        avatarColor = Colors.pink[300]!;
        break;
      default:
        avatarIcon = Icons.person;
        avatarColor = Theme.of(
          context,
        ).colorScheme.outline.withValues(alpha: 0.2);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: borderRadius ?? BorderRadius.circular(size / 2),
      ),
      child: Icon(avatarIcon, color: avatarColor, size: size * 0.6),
    );
  }
}

/// Specialized version for event images with event-specific placeholder
class EventNetworkImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final String? eventCategory;
  final BorderRadius? borderRadius;

  const EventNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.eventCategory,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return RobustNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      borderRadius: borderRadius,
      errorWidget: Builder(
        builder: (context) => _buildEventErrorWidget(context),
      ),
    );
  }

  Widget _buildEventErrorWidget(BuildContext context) {
    IconData eventIcon;
    Color eventColor;

    switch (eventCategory?.toLowerCase()) {
      case 'sports':
        eventIcon = Icons.sports_basketball;
        eventColor = Colors.orange[400]!;
        break;
      case 'entertainment':
        eventIcon = Icons.movie;
        eventColor = Colors.purple[400]!;
        break;
      case 'food':
        eventIcon = Icons.restaurant;
        eventColor = Colors.red[400]!;
        break;
      case 'art':
      case 'arts':
        eventIcon = Icons.palette;
        eventColor = Colors.pink[400]!;
        break;
      case 'educational':
        eventIcon = Icons.school;
        eventColor = Colors.blue[400]!;
        break;
      case 'networking':
        eventIcon = Icons.people;
        eventColor = Colors.green[400]!;
        break;
      case 'outdoor':
        eventIcon = Icons.nature;
        eventColor = Colors.green[600]!;
        break;
      default:
        eventIcon = Icons.event;
        eventColor = Theme.of(
          context,
        ).colorScheme.outline.withValues(alpha: 0.2);
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.fromRGBO(
              (eventColor.r * 255.0).round() & 0xff,
              (eventColor.g * 255.0).round() & 0xff,
              (eventColor.b * 255.0).round() & 0xff,
              0.3,
            ),
            Color.fromRGBO(
              (eventColor.r * 255.0).round() & 0xff,
              (eventColor.g * 255.0).round() & 0xff,
              (eventColor.b * 255.0).round() & 0xff,
              0.1,
            ),
          ],
        ),
        borderRadius: borderRadius,
      ),
      child: Center(
        child: Icon(
          eventIcon,
          color: eventColor,
          size: (width != null && width! < 100) ? 40 : 80,
        ),
      ),
    );
  }
}
