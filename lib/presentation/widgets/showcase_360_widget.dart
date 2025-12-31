import 'package:flutter/material.dart';
import 'package:thyne_jewls/data/models/homepage.dart';
import 'package:thyne_jewls/data/models/product.dart';
import 'package:thyne_jewls/presentation/views/product/product_detail_screen.dart';
import 'package:video_player/video_player.dart';

class Showcase360Widget extends StatefulWidget {
  final Showcase360 showcase;
  final Product? product;

  const Showcase360Widget({
    super.key,
    required this.showcase,
    this.product,
  });

  @override
  State<Showcase360Widget> createState() => _Showcase360WidgetState();
}

class _Showcase360WidgetState extends State<Showcase360Widget> {
  int _currentImageIndex = 0;
  double _dragStartX = 0;
  double _scale = 1.0;
  bool _showVideo = false;
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    if (widget.showcase.videoUrl.isNotEmpty) {
      _initializeVideoPlayer();
    }
  }

  Future<void> _initializeVideoPlayer() async {
    try {
      _videoController = VideoPlayerController.network(widget.showcase.videoUrl);
      await _videoController!.initialize();
      _videoController!.setLooping(true);
      if (mounted) setState(() {});
    } catch (e) {
      // Video initialization failed, continue without video
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  void _onHorizontalDragStart(DragStartDetails details) {
    _dragStartX = details.localPosition.dx;
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (widget.showcase.images360.isEmpty) return;

    final dx = details.localPosition.dx - _dragStartX;
    final sensitivity = 20.0;

    if (dx.abs() > sensitivity) {
      setState(() {
        if (dx > 0) {
          // Drag right - rotate forward
          _currentImageIndex = (_currentImageIndex + 1) % widget.showcase.images360.length;
        } else {
          // Drag left - rotate backward
          _currentImageIndex = (_currentImageIndex - 1 + widget.showcase.images360.length) % widget.showcase.images360.length;
        }
        _dragStartX = details.localPosition.dx;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showcase.isLive || widget.showcase.images360.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.rotate_right,
                    color: Colors.purple.shade700,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.showcase.title,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      if (widget.showcase.description.isNotEmpty)
                        Text(
                          widget.showcase.description,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 360° View or Video
          GestureDetector(
            onTap: () {
              if (widget.product != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductDetailScreen(product: widget.product!),
                  ),
                );
              }
            },
            onHorizontalDragStart: _showVideo ? null : _onHorizontalDragStart,
            onHorizontalDragUpdate: _showVideo ? null : _onHorizontalDragUpdate,
            child: Container(
              height: 350,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 360° Images
                  if (!_showVideo)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Transform.scale(
                        scale: _scale,
                        child: Image.network(
                          widget.showcase.images360[_currentImageIndex],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Icon(
                                Icons.image_not_supported,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                  // Video Player
                  if (_showVideo && _videoController != null && _videoController!.value.isInitialized)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AspectRatio(
                        aspectRatio: _videoController!.value.aspectRatio,
                        child: VideoPlayer(_videoController!),
                      ),
                    ),

                  // Controls Overlay
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Rotation indicator
                        if (!_showVideo)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.swipe,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Drag to rotate • ${_currentImageIndex + 1}/${widget.showcase.images360.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Zoom controls
                        if (!_showVideo)
                          Row(
                            children: [
                              _buildControlButton(
                                Icons.zoom_out,
                                () {
                                  setState(() {
                                    _scale = (_scale - 0.2).clamp(0.5, 3.0);
                                  });
                                },
                              ),
                              const SizedBox(width: 8),
                              _buildControlButton(
                                Icons.zoom_in,
                                () {
                                  setState(() {
                                    _scale = (_scale + 0.2).clamp(0.5, 3.0);
                                  });
                                },
                              ),
                            ],
                          ),

                        // Video toggle
                        if (widget.showcase.videoUrl.isNotEmpty && _videoController != null)
                          _buildControlButton(
                            _showVideo ? Icons.image : Icons.play_circle,
                            () {
                              setState(() {
                                _showVideo = !_showVideo;
                                if (_showVideo) {
                                  _videoController?.play();
                                } else {
                                  _videoController?.pause();
                                }
                              });
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // View Product Button
          if (widget.product != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductDetailScreen(product: widget.product!),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'View Product Details',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildControlButton(IconData icon, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 20),
        onPressed: onPressed,
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(),
      ),
    );
  }
}
