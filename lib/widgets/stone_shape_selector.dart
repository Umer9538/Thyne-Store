import 'package:flutter/material.dart';

/// Widget for selecting stone cut/shape
class StoneShapeSelector extends StatelessWidget {
  final List<String> availableShapes;
  final String? selectedShape;
  final ValueChanged<String> onShapeSelected;
  final Map<String, double>? priceModifiers;
  final bool showPriceModifiers;

  const StoneShapeSelector({
    super.key,
    required this.availableShapes,
    required this.selectedShape,
    required this.onShapeSelected,
    this.priceModifiers,
    this.showPriceModifiers = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              const Icon(Icons.hexagon_outlined, size: 18, color: Color(0xFF666666)),
              const SizedBox(width: 8),
              Text(
                'Select Shape',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              if (selectedShape != null) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    selectedShape!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFD4AF37),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            childAspectRatio: 0.85,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: availableShapes.length,
          itemBuilder: (context, index) {
            final shape = availableShapes[index];
            final isSelected = shape == selectedShape;
            final priceModifier = priceModifiers?[shape];

            return _ShapeButton(
              shape: shape,
              isSelected: isSelected,
              priceModifier: priceModifier,
              showPriceModifier: showPriceModifiers && priceModifier != null && priceModifier != 0,
              onTap: () => onShapeSelected(shape),
            );
          },
        ),
      ],
    );
  }
}

class _ShapeButton extends StatelessWidget {
  final String shape;
  final bool isSelected;
  final double? priceModifier;
  final bool showPriceModifier;
  final VoidCallback onTap;

  const _ShapeButton({
    required this.shape,
    required this.isSelected,
    required this.priceModifier,
    required this.showPriceModifier,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD4AF37).withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFFD4AF37) : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFD4AF37).withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Shape icon
            SizedBox(
              height: 32,
              width: 32,
              child: CustomPaint(
                painter: _ShapeIconPainter(
                  shape: shape,
                  color: isSelected ? const Color(0xFFD4AF37) : Colors.grey[600]!,
                ),
              ),
            ),
            const SizedBox(height: 4),
            // Shape name
            Text(
              _getShortName(shape),
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? const Color(0xFFD4AF37) : Colors.grey[700],
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            // Price modifier
            if (showPriceModifier && priceModifier != null) ...[
              const SizedBox(height: 2),
              Text(
                priceModifier! >= 0 ? '+₹${priceModifier!.toInt()}' : '-₹${priceModifier!.abs().toInt()}',
                style: TextStyle(
                  fontSize: 9,
                  color: priceModifier! >= 0 ? Colors.orange[700] : Colors.green[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getShortName(String shape) {
    // Abbreviate long names
    switch (shape) {
      case 'Princess':
        return 'Princess';
      case 'Marquise':
        return 'Marquise';
      case 'Baguette':
        return 'Baguette';
      case 'Trillion':
        return 'Trillion';
      default:
        return shape;
    }
  }
}

/// Custom painter for shape icons
class _ShapeIconPainter extends CustomPainter {
  final String shape;
  final Color color;

  _ShapeIconPainter({required this.shape, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final fillPaint = Paint()
      ..color = color.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.4;

    switch (shape.toLowerCase()) {
      case 'round':
        canvas.drawCircle(center, radius, fillPaint);
        canvas.drawCircle(center, radius, paint);
        break;

      case 'oval':
        final rect = Rect.fromCenter(center: center, width: radius * 2, height: radius * 1.4);
        canvas.drawOval(rect, fillPaint);
        canvas.drawOval(rect, paint);
        break;

      case 'pear':
        final path = _createPearPath(center, radius);
        canvas.drawPath(path, fillPaint);
        canvas.drawPath(path, paint);
        break;

      case 'princess':
      case 'cushion':
        final rect = Rect.fromCenter(center: center, width: radius * 1.8, height: radius * 1.8);
        final rRect = RRect.fromRectAndRadius(rect, Radius.circular(shape.toLowerCase() == 'cushion' ? 6 : 2));
        canvas.drawRRect(rRect, fillPaint);
        canvas.drawRRect(rRect, paint);
        break;

      case 'emerald':
      case 'radiant':
      case 'asscher':
        final rect = Rect.fromCenter(center: center, width: radius * 1.6, height: radius * 2);
        final rRect = RRect.fromRectAndRadius(rect, const Radius.circular(3));
        canvas.drawRRect(rRect, fillPaint);
        canvas.drawRRect(rRect, paint);
        break;

      case 'marquise':
        final path = _createMarquisePath(center, radius);
        canvas.drawPath(path, fillPaint);
        canvas.drawPath(path, paint);
        break;

      case 'heart':
        final path = _createHeartPath(center, radius);
        canvas.drawPath(path, fillPaint);
        canvas.drawPath(path, paint);
        break;

      case 'baguette':
        final rect = Rect.fromCenter(center: center, width: radius * 0.8, height: radius * 2.2);
        canvas.drawRect(rect, fillPaint);
        canvas.drawRect(rect, paint);
        break;

      case 'trillion':
        final path = _createTrianglePath(center, radius);
        canvas.drawPath(path, fillPaint);
        canvas.drawPath(path, paint);
        break;

      default:
        // Default hexagon for unknown shapes
        final path = _createHexagonPath(center, radius);
        canvas.drawPath(path, fillPaint);
        canvas.drawPath(path, paint);
    }
  }

  Path _createPearPath(Offset center, double radius) {
    final path = Path();
    path.moveTo(center.dx, center.dy - radius * 1.2);
    path.quadraticBezierTo(
      center.dx + radius * 1.2,
      center.dy - radius * 0.3,
      center.dx,
      center.dy + radius,
    );
    path.quadraticBezierTo(
      center.dx - radius * 1.2,
      center.dy - radius * 0.3,
      center.dx,
      center.dy - radius * 1.2,
    );
    path.close();
    return path;
  }

  Path _createMarquisePath(Offset center, double radius) {
    final path = Path();
    path.moveTo(center.dx, center.dy - radius * 1.3);
    path.quadraticBezierTo(
      center.dx + radius,
      center.dy,
      center.dx,
      center.dy + radius * 1.3,
    );
    path.quadraticBezierTo(
      center.dx - radius,
      center.dy,
      center.dx,
      center.dy - radius * 1.3,
    );
    path.close();
    return path;
  }

  Path _createHeartPath(Offset center, double radius) {
    final path = Path();
    path.moveTo(center.dx, center.dy + radius * 0.8);
    path.cubicTo(
      center.dx - radius * 1.5,
      center.dy - radius * 0.2,
      center.dx - radius * 0.8,
      center.dy - radius * 1.2,
      center.dx,
      center.dy - radius * 0.5,
    );
    path.cubicTo(
      center.dx + radius * 0.8,
      center.dy - radius * 1.2,
      center.dx + radius * 1.5,
      center.dy - radius * 0.2,
      center.dx,
      center.dy + radius * 0.8,
    );
    path.close();
    return path;
  }

  Path _createTrianglePath(Offset center, double radius) {
    final path = Path();
    path.moveTo(center.dx, center.dy - radius);
    path.lineTo(center.dx + radius, center.dy + radius * 0.8);
    path.lineTo(center.dx - radius, center.dy + radius * 0.8);
    path.close();
    return path;
  }

  Path _createHexagonPath(Offset center, double radius) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60 - 90) * 3.14159 / 180;
      final x = center.dx + radius * 0.9 * (angle == -1.5708 ? 1 : (i == 0 ? 1 : 1)) * (i == 0 ? 0 : (i < 3 ? 1 : -1)) * 0.866;
      final y = center.dy + radius * 0.9 * (i == 0 || i == 3 ? -1 : (i < 3 ? 0.5 : 0.5)) * (i == 0 ? 1 : (i == 3 ? 1 : (i < 3 ? 1 : 1)));

      // Simplified hexagon
      final angle2 = (i * 60 - 90) * 3.14159 / 180;
      final px = center.dx + radius * 0.9 * (angle2).cos();
      final py = center.dy + radius * 0.9 * (angle2).sin();

      if (i == 0) {
        path.moveTo(px, py);
      } else {
        path.lineTo(px, py);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _ShapeIconPainter oldDelegate) {
    return oldDelegate.shape != shape || oldDelegate.color != color;
  }
}

extension on double {
  double cos() => _cos(this);
  double sin() => _sin(this);
}

double _cos(double radians) {
  return (radians == 0) ? 1 :
         (radians == 1.5708) ? 0 :
         (radians == 3.14159) ? -1 :
         (radians == -1.5708) ? 0 :
         (radians > 0 && radians < 1.5708) ? 0.866 :
         (radians > 1.5708) ? -0.866 :
         (radians < -1.5708) ? -0.866 : 0.866;
}

double _sin(double radians) {
  return (radians == 0) ? 0 :
         (radians == 1.5708) ? 1 :
         (radians == 3.14159) ? 0 :
         (radians == -1.5708) ? -1 :
         (radians > 0 && radians < 1.5708) ? 0.5 :
         (radians > 1.5708) ? 0.5 :
         (radians < -1.5708) ? 0.5 : -0.5;
}
