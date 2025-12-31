import 'dart:convert';
import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  // Notification channels
  static const String orderChannel = 'order_notifications';
  static const String promotionalChannel = 'promotional_notifications';
  static const String behavioralChannel = 'behavioral_notifications';

  Future<void> initialize() async {
    try {
      // Initialize local notifications
      await _initializeLocalNotifications();

      debugPrint('Notification service initialized successfully');
    } catch (e) {
      debugPrint('Notification service initialization failed: $e');
    }
  }

  Future<void> _requestPermission() async {
    if (!kIsWeb && Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleNotificationTap,
    );

    // Create notification channels for Android
    if (!kIsWeb && Platform.isAndroid) {
      await _createNotificationChannels();
    }

    // Request permissions
    await _requestPermission();
  }

  Future<void> _createNotificationChannels() async {
    const orderChannelAndroid = AndroidNotificationChannel(
      orderChannel,
      'Order Updates',
      description: 'Notifications about your orders',
      importance: Importance.high,
    );

    const promotionalChannelAndroid = AndroidNotificationChannel(
      promotionalChannel,
      'Promotions & Offers',
      description: 'Special deals and promotional offers',
      importance: Importance.defaultImportance,
    );

    const behavioralChannelAndroid = AndroidNotificationChannel(
      behavioralChannel,
      'Reminders & Alerts',
      description: 'Cart reminders and stock alerts',
      importance: Importance.defaultImportance,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(orderChannelAndroid);

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(promotionalChannelAndroid);

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(behavioralChannelAndroid);
  }

  // Handle notification tap
  void _handleNotificationTap(NotificationResponse response) {
    if (response.payload != null) {
      final data = json.decode(response.payload!);
      _navigateToScreen(data);
    }
  }

  String _getChannelId(String? type) {
    switch (type) {
      case 'order':
        return orderChannel;
      case 'promotional':
        return promotionalChannel;
      case 'behavioral':
        return behavioralChannel;
      default:
        return orderChannel;
    }
  }

  void _navigateToScreen(Map<String, dynamic> data) {
    final type = data['type'];
    final targetId = data['targetId'];

    switch (type) {
      case 'order':
        // Navigate to order details
        // Navigator.pushNamed(context, '/order/$targetId');
        break;
      case 'product':
        // Navigate to product details
        // Navigator.pushNamed(context, '/product/$targetId');
        break;
      case 'promotion':
        // Navigate to promotions
        // Navigator.pushNamed(context, '/promotions');
        break;
      case 'cart':
        // Navigate to cart
        // Navigator.pushNamed(context, '/cart');
        break;
    }
  }

  // Send different types of notifications

  // Transactional Notifications
  Future<void> sendOrderPlacedNotification(String orderId) async {
    await _sendLocalNotification(
      title: 'Order Confirmed! 🎉',
      body: 'Your order #$orderId has been placed successfully. We\'ll notify you when it ships.',
      data: {'type': 'order', 'targetId': orderId},
      channel: orderChannel,
    );
  }

  Future<void> sendOrderShippedNotification(String orderId, String trackingNumber) async {
    await _sendLocalNotification(
      title: 'Order Shipped! 📦',
      body: 'Your order #$orderId is on its way. Track it with: $trackingNumber',
      data: {'type': 'order', 'targetId': orderId},
      channel: orderChannel,
    );
  }

  Future<void> sendOrderDeliveredNotification(String orderId) async {
    await _sendLocalNotification(
      title: 'Order Delivered! ✅',
      body: 'Your order #$orderId has been delivered. Enjoy your purchase!',
      data: {'type': 'order', 'targetId': orderId},
      channel: orderChannel,
    );
  }

  Future<void> sendOrderCancelledNotification(String orderId) async {
    await _sendLocalNotification(
      title: 'Order Cancelled',
      body: 'Your order #$orderId has been cancelled. Refund will be processed within 3-5 days.',
      data: {'type': 'order', 'targetId': orderId},
      channel: orderChannel,
    );
  }

  // Promotional Notifications
  Future<void> sendFlashSaleNotification(String saleTitle, int discountPercent) async {
    await _sendLocalNotification(
      title: '⚡ Flash Sale Alert!',
      body: '$saleTitle - Get $discountPercent% OFF! Limited time only.',
      data: {'type': 'promotion', 'targetId': 'flash_sale'},
      channel: promotionalChannel,
    );
  }

  Future<void> sendCouponReminderNotification(String couponCode, int daysLeft) async {
    await _sendLocalNotification(
      title: 'Coupon Expiring Soon! ⏰',
      body: 'Your coupon $couponCode expires in $daysLeft days. Use it before it\'s gone!',
      data: {'type': 'promotion', 'targetId': couponCode},
      channel: promotionalChannel,
    );
  }

  Future<void> sendSeasonalOfferNotification(String season, int discount) async {
    await _sendLocalNotification(
      title: '$season Sale Now Live! 🎊',
      body: 'Celebrate with up to $discount% OFF on selected items.',
      data: {'type': 'promotion', 'targetId': 'seasonal'},
      channel: promotionalChannel,
    );
  }

  // Behavioral Notifications
  Future<void> sendAbandonedCartNotification(int itemCount, double totalAmount) async {
    await _sendLocalNotification(
      title: 'Items Still in Your Cart 🛒',
      body: 'You have $itemCount items worth \$$totalAmount waiting. Complete your purchase now!',
      data: {'type': 'cart', 'targetId': 'cart'},
      channel: behavioralChannel,
    );
  }

  Future<void> sendBackInStockNotification(String productName, String productId) async {
    await _sendLocalNotification(
      title: 'Back in Stock! 🎯',
      body: '$productName is now available. Get it before it sells out again!',
      data: {'type': 'product', 'targetId': productId},
      channel: behavioralChannel,
    );
  }

  Future<void> sendLoyaltyPointsNotification(int points, String tier) async {
    await _sendLocalNotification(
      title: 'You Earned Points! 🌟',
      body: '+$points loyalty points added. You\'re now a $tier member!',
      data: {'type': 'loyalty', 'targetId': 'rewards'},
      channel: behavioralChannel,
    );
  }

  Future<void> sendStreakBonusNotification(int streak, int bonusPoints) async {
    await _sendLocalNotification(
      title: 'Login Streak Bonus! 🔥',
      body: '$streak day streak! You earned $bonusPoints bonus points.',
      data: {'type': 'loyalty', 'targetId': 'rewards'},
      channel: behavioralChannel,
    );
  }

  // Helper method to send local notifications
  Future<void> _sendLocalNotification({
    required String title,
    required String body,
    required Map<String, dynamic> data,
    required String channel,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channel,
      channel,
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: json.encode(data),
    );
  }

  // Update notification preferences
  Future<void> updateNotificationPreferences({
    bool orderUpdates = true,
    bool promotions = true,
    bool reminders = true,
    bool loyaltyRewards = true,
    bool backInStock = true,
    bool flashSales = true,
  }) async {
    try {
      // Save preferences securely
      await _storage.write(key: 'notifications_order_updates', value: orderUpdates.toString());
      await _storage.write(key: 'notifications_promotions', value: promotions.toString());
      await _storage.write(key: 'notifications_reminders', value: reminders.toString());
      await _storage.write(key: 'notifications_loyalty_rewards', value: loyaltyRewards.toString());
      await _storage.write(key: 'notifications_back_in_stock', value: backInStock.toString());
      await _storage.write(key: 'notifications_flash_sales', value: flashSales.toString());

      // Sync with backend
      await _syncPreferencesWithBackend({
        'orderUpdates': orderUpdates,
        'promotions': promotions,
        'reminders': reminders,
        'loyaltyRewards': loyaltyRewards,
        'backInStock': backInStock,
        'flashSales': flashSales,
      });
    } catch (e) {
      debugPrint('Error updating notification preferences: $e');
    }
  }

  // Get notification preferences
  Future<Map<String, bool>> getNotificationPreferences() async {
    try {
      return {
        'orderUpdates': (await _storage.read(key: 'notifications_order_updates')) == 'true',
        'promotions': (await _storage.read(key: 'notifications_promotions')) == 'true',
        'reminders': (await _storage.read(key: 'notifications_reminders')) == 'true',
        'loyaltyRewards': (await _storage.read(key: 'notifications_loyalty_rewards')) == 'true',
        'backInStock': (await _storage.read(key: 'notifications_back_in_stock')) == 'true',
        'flashSales': (await _storage.read(key: 'notifications_flash_sales')) == 'true',
      };
    } catch (e) {
      debugPrint('Error getting notification preferences: $e');
      return {
        'orderUpdates': true,
        'promotions': true,
        'reminders': true,
        'loyaltyRewards': true,
        'backInStock': true,
        'flashSales': true,
      };
    }
  }

  // Sync notification preferences with backend
  Future<void> _syncPreferencesWithBackend(Map<String, bool> preferences) async {
    try {
      await ApiService.updateNotificationPreferences(preferences: preferences);
      debugPrint('Notification preferences synced with backend successfully');
    } catch (e) {
      debugPrint('Error syncing notification preferences with backend: $e');
    }
  }

  // Get user notifications from backend
  Future<List<Map<String, dynamic>>> getUserNotifications({
    int page = 1,
    int limit = 20,
    bool unreadOnly = false,
  }) async {
    try {
      final response = await ApiService.getUserNotifications(
        page: page,
        limit: limit,
        unreadOnly: unreadOnly,
      );
      return List<Map<String, dynamic>>.from(response['data']['notifications'] ?? []);
    } catch (e) {
      debugPrint('Error fetching user notifications: $e');
      return [];
    }
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await ApiService.markNotificationAsRead(notificationId: notificationId);
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  // Mark all notifications as read
  Future<void> markAllNotificationsAsRead() async {
    try {
      await ApiService.markAllNotificationsAsRead();
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }
}