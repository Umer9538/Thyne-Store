import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Widget for displaying a live preview of customized jewelry
/// Uses layered image compositing for metal/stone visualization
class CustomizationPreviewWidget extends StatelessWidget {
  final String? baseImageUrl;
  final String? selectedMetal;
  final String? selectedPlatingColor;
  final Map<String, String>? stoneSelections; // stone name -> color
  final Map<String, String>? stoneShapes; // stone name -> shape
  final Map<String, String>? metalPreviewImages; // metal -> image URL
  final Map<String, Map<String, String>>? stonePreviewImages; // stone -> color -> URL
  final double width;
  final double height;
  final bool showLabels;

  const CustomizationPreviewWidget({
    super.key,
    required this.baseImageUrl,
    this.selectedMetal,
    this.selectedPlatingColor,
    this.stoneSelections,
    this.stoneShapes,
    this.metalPreviewImages,
    this.stonePreviewImages,
    this.width = 300,
    this.height = 300,
    this.showLabels = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Base/background layer
            _buildBaseLayer(),

            // Metal layer with color tinting
            _buildMetalLayer(),

            // Stone overlays
            if (stoneSelections != null && stoneSelections!.isNotEmpty)
              ..._buildStoneOverlays(),

            // Selection labels overlay
            if (showLabels) _buildLabelsOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildBaseLayer() {
    if (baseImageUrl == null || baseImageUrl!.isEmpty) {
      return Container(
        color: Colors.grey[100],
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.image_outlined, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 8),
              Text(
                'Preview',
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: baseImageUrl!,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: Colors.grey[100],
        child: const Center(child: CircularProgressIndicator()),
      ),
      errorWidget: (context, url, error) => Container(
        color: Colors.grey[100],
        child: Icon(Icons.error_outline, color: Colors.grey[400]),
      ),
    );
  }

  Widget _buildMetalLayer() {
    // Get metal-specific preview image if available
    final metalImageUrl = metalPreviewImages?[selectedMetal];

    if (metalImageUrl != null && metalImageUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: metalImageUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => const SizedBox.shrink(),
        errorWidget: (context, url, error) => const SizedBox.shrink(),
      );
    }

    // Apply color filter based on metal/plating selection
    final metalColor = _getMetalColor(selectedMetal, selectedPlatingColor);
    if (metalColor != null && baseImageUrl != null) {
      return ColorFiltered(
        colorFilter: ColorFilter.mode(
          metalColor.withAlpha(50),
          BlendMode.overlay,
        ),
        child: CachedNetworkImage(
          imageUrl: baseImageUrl!,
          fit: BoxFit.cover,
          placeholder: (context, url) => const SizedBox.shrink(),
          errorWidget: (context, url, error) => const SizedBox.shrink(),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  List<Widget> _buildStoneOverlays() {
    final overlays = <Widget>[];

    if (stoneSelections == null) return overlays;

    for (final entry in stoneSelections!.entries) {
      final stoneName = entry.key;
      final stoneColor = entry.value;

      // Try to get stone-specific preview image
      final stoneImageUrl = stonePreviewImages?[stoneName]?[stoneColor];

      if (stoneImageUrl != null && stoneImageUrl.isNotEmpty) {
        overlays.add(
          Positioned.fill(
            child: CachedNetworkImage(
              imageUrl: stoneImageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => const SizedBox.shrink(),
              errorWidget: (context, url, error) => const SizedBox.shrink(),
            ),
          ),
        );
      } else {
        // Apply a subtle color overlay to represent the stone
        final color = _getStoneColorFromName(stoneColor);
        if (color != null) {
          overlays.add(
            Positioned(
              bottom: height * 0.3,
              left: width * 0.3,
              right: width * 0.3,
              height: height * 0.2,
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      color.withAlpha(100),
                      color.withAlpha(30),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
          );
        }
      }
    }

    return overlays;
  }

  Widget _buildLabelsOverlay() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withAlpha(180),
              Colors.transparent,
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (selectedMetal != null)
              _buildLabelChip(
                Icons.brightness_4_outlined,
                selectedMetal!,
              ),
            if (selectedPlatingColor != null)
              _buildLabelChip(
                Icons.palette_outlined,
                selectedPlatingColor!,
              ),
            if (stoneSelections != null && stoneSelections!.isNotEmpty)
              ...stoneSelections!.entries.map((e) => _buildLabelChip(
                    Icons.diamond_outlined,
                    '${e.key}: ${e.value}',
                  )),
          ],
        ),
      ),
    );
  }

  Widget _buildLabelChip(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white70),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color? _getMetalColor(String? metal, String? plating) {
    // First check plating color
    if (plating != null) {
      switch (plating.toLowerCase()) {
        case 'rose gold':
        case 'rose':
          return const Color(0xFFB76E79);
        case 'yellow gold':
        case 'yellow':
        case 'gold':
          return const Color(0xFFD4AF37);
        case 'white gold':
        case 'white':
        case 'silver':
        case 'platinum':
          return const Color(0xFFE8E8E8);
        case 'black':
        case 'gunmetal':
          return const Color(0xFF2D2D2D);
      }
    }

    // Check metal type
    if (metal != null) {
      final lowerMetal = metal.toLowerCase();
      if (lowerMetal.contains('rose')) {
        return const Color(0xFFB76E79);
      } else if (lowerMetal.contains('yellow') || lowerMetal.contains('gold')) {
        return const Color(0xFFD4AF37);
      } else if (lowerMetal.contains('white') ||
          lowerMetal.contains('silver') ||
          lowerMetal.contains('platinum')) {
        return const Color(0xFFE8E8E8);
      }
    }

    return null;
  }

  Color? _getStoneColorFromName(String colorName) {
    switch (colorName.toLowerCase()) {
      // Diamonds
      case 'diamond':
      case 'white diamond':
      case 'clear':
        return const Color(0xFFF0F0F0);
      case 'champagne diamond':
        return const Color(0xFFF5DEB3);
      case 'black diamond':
        return const Color(0xFF1A1A1A);
      case 'blue diamond':
        return const Color(0xFF6495ED);
      case 'pink diamond':
        return const Color(0xFFFFB6C1);
      case 'yellow diamond':
        return const Color(0xFFFFD700);

      // Precious stones
      case 'ruby':
      case 'red':
        return const Color(0xFFE0115F);
      case 'emerald':
      case 'green':
        return const Color(0xFF50C878);
      case 'blue sapphire':
      case 'sapphire':
      case 'blue':
        return const Color(0xFF0F52BA);
      case 'pink sapphire':
        return const Color(0xFFFF69B4);
      case 'yellow sapphire':
        return const Color(0xFFFFD700);
      case 'white sapphire':
        return const Color(0xFFF0F8FF);

      // Semi-precious
      case 'amethyst':
      case 'purple':
        return const Color(0xFF9966CC);
      case 'citrine':
      case 'orange':
        return const Color(0xFFFFA500);
      case 'topaz':
        return const Color(0xFF1E90FF);
      case 'aquamarine':
        return const Color(0xFF7FFFD4);
      case 'garnet':
        return const Color(0xFF722F37);
      case 'peridot':
        return const Color(0xFF9ACD32);
      case 'tanzanite':
        return const Color(0xFF4B0082);
      case 'opal':
        return const Color(0xFFA8C3BC);
      case 'turquoise':
        return const Color(0xFF40E0D0);
      case 'morganite':
        return const Color(0xFFEDC9AF);

      // Lab-created
      case 'lab diamond':
      case 'moissanite':
      case 'cz':
      case 'cubic zirconia':
        return const Color(0xFFF5F5F5);

      default:
        return Colors.grey[300];
    }
  }
}

/// Compact preview for product cards and lists
class CompactPreviewWidget extends StatelessWidget {
  final String? imageUrl;
  final String? metalType;
  final String? stoneColor;
  final double size;

  const CompactPreviewWidget({
    super.key,
    this.imageUrl,
    this.metalType,
    this.stoneColor,
    this.size = 60,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: imageUrl != null
            ? CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (context, url, error) => Icon(
                  Icons.image_not_supported_outlined,
                  color: Colors.grey[400],
                  size: size * 0.4,
                ),
              )
            : Icon(
                Icons.diamond_outlined,
                color: Colors.grey[400],
                size: size * 0.4,
              ),
      ),
    );
  }
}

/// Preview carousel for showing multiple customization variations
class PreviewCarousel extends StatefulWidget {
  final List<String> imageUrls;
  final String? selectedMetal;
  final Map<String, String>? stoneSelections;
  final double height;

  const PreviewCarousel({
    super.key,
    required this.imageUrls,
    this.selectedMetal,
    this.stoneSelections,
    this.height = 300,
  });

  @override
  State<PreviewCarousel> createState() => _PreviewCarouselState();
}

class _PreviewCarouselState extends State<PreviewCarousel> {
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
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.image_outlined, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 8),
              Text(
                'No preview images',
                style: TextStyle(color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: widget.height,
      child: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.imageUrls.length,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: CustomizationPreviewWidget(
                    baseImageUrl: widget.imageUrls[index],
                    selectedMetal: widget.selectedMetal,
                    stoneSelections: widget.stoneSelections,
                    showLabels: index == _currentIndex,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                );
              },
            ),
          ),
          if (widget.imageUrls.length > 1) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.imageUrls.length,
                (index) => GestureDetector(
                  onTap: () {
                    _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index == _currentIndex
                          ? const Color(0xFFD4AF37)
                          : Colors.grey[300],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
