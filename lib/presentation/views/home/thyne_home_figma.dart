import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:carousel_slider/carousel_slider.dart' as carousel;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';

import '../viewmodels/auth_provider.dart';
import '../viewmodels/cart_provider.dart';
import '../viewmodels/product_provider.dart';
import '../viewmodels/wishlist_provider.dart';
import '../../../theme/thyne_theme.dart';

class ThyneHomeFigma extends StatefulWidget {
  const ThyneHomeFigma({Key? key}) : super(key: key);

  @override
  State<ThyneHomeFigma> createState() => _ThyneHomeFigmaState();
}

class _ThyneHomeFigmaState extends State<ThyneHomeFigma> {
  String selectedFilter = 'all';
  int currentCarouselIndex = 0;

  // Sample banner data
  final List<Map<String, String>> banners = [
    {
      'image': 'https://images.unsplash.com/photo-1515562141207-7a88fb7ce338?w=800',
      'title': 'Begin Your Bridal\nJourney',
      'subtitle': 'Exquisite bridal jewelry with Khazana\nAcross India & Middle East',
      'cta': 'EXPLORE BRIDAL',
    },
    {
      'image': 'https://images.unsplash.com/photo-1535632066927-ab7c9ab60908?w=800',
      'title': 'Luxury Collection',
      'subtitle': 'Discover our premium range',
      'cta': 'SHOP NOW',
    },
    {
      'image': 'https://images.unsplash.com/photo-1611652022419-a9419f74343d?w=800',
      'title': 'New Arrivals',
      'subtitle': 'Latest designs just for you',
      'cta': 'VIEW COLLECTION',
    },
  ];

  final List<String> filters = ['all', 'women', 'men', 'inclusive'];

  final List<Map<String, dynamic>> categories = [
    {'name': 'Rings', 'image': 'https://images.unsplash.com/photo-1605100804763-247f67b3557e?w=200'},
    {'name': 'Necklaces', 'image': 'https://images.unsplash.com/photo-1599643478518-a784e5dc4c8f?w=200'},
    {'name': 'Earrings', 'image': 'https://images.unsplash.com/photo-1535632787350-4e68ef0ac584?w=200'},
    {'name': 'Bracelets', 'image': 'https://images.unsplash.com/photo-1611591437281-460bfbe1220a?w=200'},
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F5),
      body: Stack(
        children: [
          Column(
            children: [
              // App Bar
              _buildAppBar(),
              // Filter Pills
              _buildFilterPills(),
              // Main Content
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hero Carousel
                      _buildHeroCarousel(),
                      const SizedBox(height: 32),
                      // Shop by Category
                      _buildShopByCategory(),
                      const SizedBox(height: 100), // Space for bottom nav
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Bottom Navigation
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomNavigation(),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Top Row
              Row(
                children: [
                  // Logo
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F0F0),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        CupertinoIcons.sparkles,
                        size: 20,
                        color: const Color(0xFF094010),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'THYNE',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                  const Spacer(),
                  // User Avatar
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE8E8E8), Color(0xFFD0D0D0)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        'U',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A1A1A),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Location and Icons Row
              Row(
                children: [
                  Icon(
                    CupertinoIcons.location,
                    size: 14,
                    color: const Color(0xFF666666),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'deliver to ',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF666666),
                    ),
                  ),
                  Text(
                    'Sector 2',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                  const Spacer(),
                  _buildIconButton(CupertinoIcons.gift),
                  const SizedBox(width: 16),
                  _buildIconButton(CupertinoIcons.heart),
                  const SizedBox(width: 16),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _buildIconButton(CupertinoIcons.bag),
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A1A),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon) {
    return Icon(
      icon,
      size: 20,
      color: const Color(0xFF1A1A1A),
    );
  }

  Widget _buildFilterPills() {
    return Container(
      height: 48,
      margin: const EdgeInsets.only(top: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = selectedFilter == filter;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => selectedFilter = filter),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF094010).withOpacity(0.1)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF094010)
                        : const Color(0xFFE5E5E5),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    filter,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected
                          ? const Color(0xFF094010)
                          : const Color(0xFF666666),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeroCarousel() {
    return Container(
      height: 420,
      child: Stack(
        children: [
          carousel.CarouselSlider(
            options: carousel.CarouselOptions(
              height: 420,
              viewportFraction: 1.0,
              autoPlay: true,
              autoPlayInterval: const Duration(seconds: 5),
              onPageChanged: (index, reason) {
                setState(() {
                  currentCarouselIndex = index;
                });
              },
            ),
            items: banners.map((banner) {
              return Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(banner['image']!),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        banner['title']!,
                        style: GoogleFonts.inter(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        banner['subtitle']!,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF094010),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              banner['cta']!,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              CupertinoIcons.arrow_right,
                              size: 16,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          // Carousel Indicators
          Positioned(
            bottom: 80,
            left: 24,
            child: Row(
              children: List.generate(
                banners.length,
                (index) => Container(
                  width: index == currentCarouselIndex ? 24 : 8,
                  height: 4,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: index == currentCarouselIndex
                        ? Colors.white
                        : Colors.white.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
          // Page Counter
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${currentCarouselIndex + 1} / ${banners.length}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShopByCategory() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Shop by Category',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return Container(
                  width: 100,
                  margin: const EdgeInsets.only(right: 12),
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: NetworkImage(category['image']),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        category['name'],
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFF1A1A1A),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(CupertinoIcons.bag, 'Shop', true),
              _buildNavItem(CupertinoIcons.person_2, 'Community', false),
              _buildNavItem(CupertinoIcons.star, 'Rewards', false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive) {
    return Expanded(
      child: Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 22,
              color: isActive ? const Color(0xFF094010) : const Color(0xFF999999),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? const Color(0xFF094010) : const Color(0xFF999999),
              ),
            ),
          ],
        ),
      ),
    );
  }
}