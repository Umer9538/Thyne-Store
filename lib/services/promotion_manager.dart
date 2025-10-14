import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/event_promotion.dart';
import '../services/api_service.dart';
import '../widgets/event_promotion_popup.dart';

class PromotionManager {
  static const String _shownPromotionsKey = 'shown_promotions';
  static const String _lastShownDateKey = 'last_shown_date';
  
  // Cache for active promotions
  static List<EventPromotion>? _cachedPromotions;
  static DateTime? _cacheTime;
  static const Duration _cacheDuration = Duration(minutes: 5);
  
  static Future<void> checkAndShowPromotions(BuildContext context) async {
    try {
      final response = await ApiService.getPopupPromotions();
      
      if (response['success'] == true && response['data'] != null) {
        final promotions = (response['data'] as List)
            .map((json) => EventPromotion.fromJson(json))
            .where((p) => p.isLive && p.showAsPopup)
            .toList();

        if (promotions.isEmpty) return;

        // Get shown promotions
        final shownPromotions = await _getShownPromotions();
        final lastShownDate = await _getLastShownDate();
        
        // Filter promotions based on frequency
        final promos = _filterPromotionsByFrequency(
          promotions,
          shownPromotions,
          lastShownDate,
        );

        if (promos.isNotEmpty && context.mounted) {
          // Show the first eligible promotion
          final promotion = promos.first;
          await _showPromotion(context, promotion);
        }
      }
    } catch (e) {
      debugPrint('Error checking promotions: $e');
    }
  }

  static List<EventPromotion> _filterPromotionsByFrequency(
    List<EventPromotion> promotions,
    Set<String> shownPromotions,
    DateTime? lastShownDate,
  ) {
    final now = DateTime.now();
    
    return promotions.where((promo) {
      switch (promo.popupFrequency) {
        case 'once':
          // Show only if never shown before
          return !shownPromotions.contains(promo.id);
          
        case 'daily':
          // Show if not shown today
          if (lastShownDate == null) return true;
          return !_isSameDay(now, lastShownDate);
          
        case 'session':
          // Show every session (always true for first check)
          return true;
          
        default:
          return false;
      }
    }).toList();
  }

  static bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  static Future<void> _showPromotion(
    BuildContext context,
    EventPromotion promotion,
  ) async {
    // Wait a bit before showing popup (better UX)
    await Future.delayed(const Duration(seconds: 1));
    
    if (!context.mounted) return;

    await showEventPromotionPopup(
      context: context,
      promotion: promotion,
      onShopNow: () {
        // Navigate to products page with promotion filter
        if (context.mounted) {
          if (promotion.applicableTo == 'category' && 
              promotion.categories.isNotEmpty) {
            Navigator.pushNamed(
              context,
              '/products',
              arguments: {'category': promotion.categories.first},
            );
          } else {
            Navigator.pushNamed(context, '/products');
          }
        }
      },
    );

    // Mark as shown
    await _markPromotionAsShown(promotion.id);
  }

  static Future<Set<String>> _getShownPromotions() async {
    final prefs = await SharedPreferences.getInstance();
    final shown = prefs.getStringList(_shownPromotionsKey) ?? [];
    return Set.from(shown);
  }

  static Future<DateTime?> _getLastShownDate() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_lastShownDateKey);
    if (timestamp == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  static Future<void> _markPromotionAsShown(String promotionId) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Add to shown promotions
    final shown = await _getShownPromotions();
    shown.add(promotionId);
    await prefs.setStringList(_shownPromotionsKey, shown.toList());
    
    // Update last shown date
    await prefs.setInt(
      _lastShownDateKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  static Future<void> clearShownPromotions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_shownPromotionsKey);
    await prefs.remove(_lastShownDateKey);
  }

  static Future<List<EventPromotion>> getActivePromotions() async {
    // Return cached data if available and not expired
    if (_cachedPromotions != null && 
        _cacheTime != null && 
        DateTime.now().difference(_cacheTime!) < _cacheDuration) {
      return _cachedPromotions!;
    }
    
    try {
      final response = await ApiService.getActivePromotions();
      
      if (response['success'] == true && response['data'] != null) {
        final promotions = (response['data'] as List)
            .map((json) => EventPromotion.fromJson(json))
            .where((p) => p.isLive)
            .toList();
        
        // Update cache
        _cachedPromotions = promotions;
        _cacheTime = DateTime.now();
        
        return promotions;
      }
    } catch (e) {
      debugPrint('Error getting active promotions: $e');
    }
    return _cachedPromotions ?? [];
  }
  
  // Clear the cache manually if needed
  static void clearCache() {
    _cachedPromotions = null;
    _cacheTime = null;
  }

  // Check if a product has an active promotion
  static Future<EventPromotion?> getPromotionForProduct(String productId) async {
    final promotions = await getActivePromotions();
    
    for (var promo in promotions) {
      if (promo.applicableTo == 'all') {
        return promo;
      }
      if (promo.applicableTo == 'product' && 
          promo.productIds.contains(productId)) {
        return promo;
      }
    }
    
    return null;
  }

  // Check if a category has an active promotion
  static Future<EventPromotion?> getPromotionForCategory(String category) async {
    final promotions = await getActivePromotions();
    
    for (var promo in promotions) {
      if (promo.applicableTo == 'all') {
        return promo;
      }
      if (promo.applicableTo == 'category' && 
          promo.categories.contains(category)) {
        return promo;
      }
    }
    
    return null;
  }
}

