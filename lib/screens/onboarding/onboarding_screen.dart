import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      icon: Icons.auto_awesome,
      iconColor: const Color(0xFF8B9A7D),
      title: 'Commerce',
      description: 'Premium jewelry & accessories',
      backgroundColor: const Color(0xFFC5C9BA),
    ),
    OnboardingPage(
      icon: Icons.people_outline,
      iconColor: const Color(0xFF8B7D7D),
      title: 'Community',
      description: 'Connect with style enthusiasts',
      backgroundColor: const Color(0xFFC5BCB8),
    ),
    OnboardingPage(
      icon: Icons.palette_outlined,
      iconColor: const Color(0xFF4A5C6A),
      title: 'Create',
      description: 'Design your unique pieces',
      backgroundColor: const Color(0xFFB8BEC9),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      body: SafeArea(
        child: Column(
          children: [
            // Logo and Title
            Padding(
              padding: const EdgeInsets.only(top: 60, bottom: 40),
              child: Column(
                children: [
                  // Logo
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF3D1F1F), width: 2),
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/thyne.svg',
                        width: 80,
                        height: 80,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Title
                  const Text(
                    'thyne',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3D1F1F),
                      fontFamily: 'Georgia',
                      letterSpacing: 2,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Subtitle
                  const Text(
                    'etched by you',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),

            // PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index]);
                },
              ),
            ),

            // Page Indicators
            Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentPage == index
                          ? const Color(0xFF3D1F1F)
                          : Colors.grey.shade400,
                    ),
                  ),
                ),
              ),
            ),

            // Get Started Button (only on last page)
            if (_currentPage == _pages.length - 1)
              Padding(
                padding: const EdgeInsets.only(bottom: 40, left: 40, right: 40),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _completeOnboarding,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3D1F1F),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Get Started',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              )
            else
              const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 40),
              decoration: BoxDecoration(
                color: page.backgroundColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: page.backgroundColor.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      page.icon,
                      size: 40,
                      color: page.iconColor,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Title
                  Text(
                    page.title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Description
                  Text(
                    page.description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingPage {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final Color backgroundColor;

  OnboardingPage({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.backgroundColor,
  });
}

// Custom painter for the Thyne logo
class ThyneLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF3D1F1F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw outer circle
    canvas.drawCircle(center, radius, paint);

    // Draw cross lines
    canvas.drawLine(
      Offset(center.dx, 0),
      Offset(center.dx, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(0, center.dy),
      Offset(size.width, center.dy),
      paint,
    );

    // Draw inner circles in each quadrant
    final innerRadius = radius / 3;
    final offset = radius / 2;

    // Top-left
    canvas.drawCircle(
      Offset(center.dx - offset, center.dy - offset),
      innerRadius,
      paint,
    );

    // Top-right
    canvas.drawCircle(
      Offset(center.dx + offset, center.dy - offset),
      innerRadius,
      paint,
    );

    // Bottom-left
    canvas.drawCircle(
      Offset(center.dx - offset, center.dy + offset),
      innerRadius,
      paint,
    );

    // Bottom-right
    canvas.drawCircle(
      Offset(center.dx + offset, center.dy + offset),
      innerRadius,
      paint,
    );

    // Draw center circle
    canvas.drawCircle(center, innerRadius / 2, paint);

    // Draw decorative leaves in each quadrant
    final leafPaint = Paint()
      ..color = const Color(0xFF3D1F1F)
      ..style = PaintingStyle.fill;

    // Simple leaf shapes
    _drawLeaf(canvas, leafPaint, center.dx - offset, center.dy - offset, innerRadius);
    _drawLeaf(canvas, leafPaint, center.dx + offset, center.dy - offset, innerRadius);
    _drawLeaf(canvas, leafPaint, center.dx - offset, center.dy + offset, innerRadius);
    _drawLeaf(canvas, leafPaint, center.dx + offset, center.dy + offset, innerRadius);
  }

  void _drawLeaf(Canvas canvas, Paint paint, double cx, double cy, double radius) {
    final path = Path();
    path.moveTo(cx, cy - radius / 3);
    path.quadraticBezierTo(
      cx + radius / 4,
      cy - radius / 6,
      cx + radius / 6,
      cy,
    );
    path.quadraticBezierTo(
      cx + radius / 8,
      cy + radius / 8,
      cx,
      cy,
    );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
