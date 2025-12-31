import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/core.dart';
import 'loading_widgets.dart';

/// A network image widget with placeholder, error handling, and caching.
class AppNetworkImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;
  final Color? backgroundColor;
  final bool showLoadingIndicator;

  const AppNetworkImage({
    super.key,
    this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = 0.0,
    this.placeholder,
    this.errorWidget,
    this.backgroundColor,
    this.showLoadingIndicator = true,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildErrorWidget(context);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: CachedNetworkImage(
        imageUrl: imageUrl!,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => _buildPlaceholder(context),
        errorWidget: (context, url, error) => _buildErrorWidget(context),
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    if (placeholder != null) return placeholder!;

    return Container(
      width: width,
      height: height,
      color: backgroundColor ?? Colors.grey[200],
      child: showLoadingIndicator
          ? const Center(
              child: AppLoadingSpinner(size: 24),
            )
          : null,
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    if (errorWidget != null) return errorWidget!;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.grey[200],
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Icon(
        Icons.image_not_supported_outlined,
        color: Colors.grey[400],
        size: _getIconSize(),
      ),
    );
  }

  double _getIconSize() {
    if (width != null && height != null) {
      final minDimension = width! < height! ? width! : height!;
      return (minDimension * 0.3).clamp(20.0, 48.0);
    }
    return 32.0;
  }
}

/// A circular avatar image with placeholder.
class AppAvatarImage extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final String? fallbackText;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData fallbackIcon;

  const AppAvatarImage({
    super.key,
    this.imageUrl,
    this.radius = 24.0,
    this.fallbackText,
    this.backgroundColor,
    this.textColor,
    this.fallbackIcon = Icons.person,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = backgroundColor ?? theme.colorScheme.primary.withValues(alpha: 0.1);
    final fgColor = textColor ?? theme.colorScheme.primary;

    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildFallback(bgColor, fgColor);
    }

    return CachedNetworkImage(
      imageUrl: imageUrl!,
      imageBuilder: (context, imageProvider) => CircleAvatar(
        radius: radius,
        backgroundImage: imageProvider,
      ),
      placeholder: (context, url) => CircleAvatar(
        radius: radius,
        backgroundColor: bgColor,
        child: const AppLoadingSpinner(size: 20),
      ),
      errorWidget: (context, url, error) => _buildFallback(bgColor, fgColor),
    );
  }

  Widget _buildFallback(Color bgColor, Color fgColor) {
    if (fallbackText != null && fallbackText!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: bgColor,
        child: Text(
          fallbackText![0].toUpperCase(),
          style: TextStyle(
            fontSize: radius * 0.8,
            fontWeight: FontWeight.bold,
            color: fgColor,
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: bgColor,
      child: Icon(
        fallbackIcon,
        size: radius * 0.8,
        color: fgColor,
      ),
    );
  }
}

/// A product image with zoom capability.
class AppProductImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final double borderRadius;
  final bool enableZoom;
  final VoidCallback? onTap;
  final Widget? badge;

  const AppProductImage({
    super.key,
    this.imageUrl,
    this.width,
    this.height,
    this.borderRadius = 8.0,
    this.enableZoom = false,
    this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    Widget image = AppNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      borderRadius: borderRadius,
      fit: BoxFit.cover,
      errorWidget: _buildProductPlaceholder(),
    );

    if (badge != null) {
      image = Stack(
        children: [
          image,
          Positioned(
            top: 8,
            left: 8,
            child: badge!,
          ),
        ],
      );
    }

    if (onTap != null) {
      image = GestureDetector(
        onTap: onTap,
        child: image,
      );
    }

    if (enableZoom) {
      image = GestureDetector(
        onTap: () => _showZoomDialog(context),
        child: image,
      );
    }

    return image;
  }

  Widget _buildProductPlaceholder() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.diamond_outlined,
            size: 40,
            color: Colors.grey[400],
          ),
          AppDimensions.verticalSpace8,
          Text(
            'No Image',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _showZoomDialog(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: AppDimensions.paddingAll16,
        child: Stack(
          children: [
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                icon: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Image gallery widget for multiple images.
class AppImageGallery extends StatefulWidget {
  final List<String> imageUrls;
  final double height;
  final double borderRadius;
  final bool showIndicator;
  final bool autoPlay;
  final Duration autoPlayDuration;

  const AppImageGallery({
    super.key,
    required this.imageUrls,
    this.height = 300.0,
    this.borderRadius = 12.0,
    this.showIndicator = true,
    this.autoPlay = false,
    this.autoPlayDuration = const Duration(seconds: 3),
  });

  @override
  State<AppImageGallery> createState() => _AppImageGalleryState();
}

class _AppImageGalleryState extends State<AppImageGallery> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrls.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: const AppNetworkImage(),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: widget.height,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.imageUrls.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                return AppProductImage(
                  imageUrl: widget.imageUrls[index],
                  enableZoom: true,
                );
              },
            ),
          ),
        ),
        if (widget.showIndicator && widget.imageUrls.length > 1) ...[
          AppDimensions.verticalSpace12,
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.imageUrls.length,
              (index) => AnimatedContainer(
                duration: AppDimensions.animationFast,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentIndex == index ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentIndex == index
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey[300],
                  borderRadius: AppDimensions.borderRadiusCircular,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Badge widget for product images.
class ImageBadge extends StatelessWidget {
  final String text;
  final Color? backgroundColor;
  final Color? textColor;

  const ImageBadge({
    super.key,
    required this.text,
    this.backgroundColor,
    this.textColor,
  });

  const ImageBadge.sale({super.key})
      : text = 'SALE',
        backgroundColor = Colors.red,
        textColor = Colors.white;

  const ImageBadge.newArrival({super.key})
      : text = 'NEW',
        backgroundColor = Colors.green,
        textColor = Colors.white;

  const ImageBadge.outOfStock({super.key})
      : text = 'OUT OF STOCK',
        backgroundColor = Colors.grey,
        textColor = Colors.white;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor ?? Theme.of(context).colorScheme.primary,
        borderRadius: AppDimensions.borderRadius4,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: textColor ?? Colors.white,
        ),
      ),
    );
  }
}
