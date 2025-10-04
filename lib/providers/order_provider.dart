import 'package:flutter/foundation.dart';
import '../models/order.dart';
import '../models/cart.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class OrderProvider extends ChangeNotifier {
  final List<Order> _orders = [];
  bool _isLoading = false;
  Order? _currentOrder;

  List<Order> get orders => _orders;
  bool get isLoading => _isLoading;
  Order? get currentOrder => _currentOrder;

  Future<void> placeOrder({
    required String userId,
    required List<CartItem> items,
    required Address shippingAddress,
    required String paymentMethod,
    required double subtotal,
    required double tax,
    required double shipping,
    required double discount,
    required double total,
  }) async {
    _setLoading(true);

    try {
      // Prepare order data
      final orderData = {
        'items': items.map((item) => {
          'productId': item.product.id,
          'quantity': item.quantity,
          'price': item.product.price,
          'name': item.product.name,
          'image': item.product.images.isNotEmpty ? item.product.images.first : '',
        }).toList(),
        'shippingAddress': {
          'street': shippingAddress.street,
          'city': shippingAddress.city,
          'state': shippingAddress.state,
          'zipCode': shippingAddress.zipCode,
          'country': shippingAddress.country,
        },
        'paymentMethod': paymentMethod,
      };

      final response = await ApiService.createOrder(orderData: orderData);
      
      if (response['success'] == true) {
        final orderJson = response['data'];
        final order = Order.fromJson(orderJson);
        
        _orders.insert(0, order);
        _currentOrder = order;
        notifyListeners();
      } else {
        throw Exception(response['error'] ?? 'Failed to place order');
      }
    } catch (e) {
      debugPrint('Error placing order: $e');
      throw Exception('Failed to place order: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadOrders(String userId) async {
    _setLoading(true);

    try {
      final response = await ApiService.getOrders();
      
      if (response['success'] == true) {
        final ordersData = response['data']['orders'] as List;
        _orders.clear();
        
        for (final orderJson in ordersData) {
          final order = Order.fromJson(orderJson);
          _orders.add(order);
        }
        
        notifyListeners();
      } else {
        throw Exception(response['error'] ?? 'Failed to load orders');
      }
    } catch (e) {
      debugPrint('Error loading orders: $e');
      // Keep existing orders if API fails
    } finally {
      _setLoading(false);
    }
  }

  Order? getOrderById(String orderId) {
    try {
      return _orders.firstWhere((order) => order.id == orderId);
    } catch (e) {
      return null;
    }
  }

  Order? getOrderByOrderNumber(String orderNumber) {
    try {
      return _orders.firstWhere((order) => order.orderNumber != null && order.orderNumber == orderNumber);
    } catch (e) {
      return null;
    }
  }

  Future<Order?> searchOrderByNumber(String orderNumber) async {
    _setLoading(true);

    try {
      // Always search via API first to get the most up-to-date data from MongoDB
      debugPrint('Searching for order number: $orderNumber');
      final response = await ApiService.searchOrderByNumber(orderNumber: orderNumber);
      debugPrint('API response: $response');
      
      if (response['success'] == true && response['data'] != null) {
        final orderJson = response['data'];
        debugPrint('Order JSON: $orderJson');
        
        try {
          final order = Order.fromJson(orderJson);
          debugPrint('Successfully parsed order: ${order.id}');
          
          // Add to local cache if not already present
          if (!_orders.any((o) => o.id == order.id)) {
            _orders.insert(0, order);
            notifyListeners();
          }
          
          return order;
        } catch (parseError) {
          debugPrint('Error parsing order JSON: $parseError');
          debugPrint('Problematic JSON: $orderJson');
          throw parseError;
        }
      } else {
        debugPrint('API search failed or returned no data: ${response['error']}');
        // If API fails, check local cache as fallback
        final cachedOrder = getOrderByOrderNumber(orderNumber);
        return cachedOrder;
      }
    } catch (e) {
      debugPrint('Error searching order by number: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      
      // If API fails, try local cache as fallback
      try {
        final cachedOrder = getOrderByOrderNumber(orderNumber);
        debugPrint('Found in local cache: ${cachedOrder?.id}');
        return cachedOrder;
      } catch (localError) {
        debugPrint('Local search also failed: $localError');
        return null;
      }
    } finally {
      _setLoading(false);
    }
  }

  List<Order> searchOrdersLocally(String query) {
    if (query.isEmpty) return _orders;
    
    final lowerQuery = query.toLowerCase();
    return _orders.where((order) {
      // Check order number (with null safety)
      final orderNumberMatch = order.orderNumber != null && 
          order.orderNumber!.toLowerCase().contains(lowerQuery);
      
      // Check order ID
      final orderIdMatch = order.id.toLowerCase().contains(lowerQuery);
      
      // Check product names
      final productNameMatch = order.items.any((item) => 
          item.product.name.toLowerCase().contains(lowerQuery));
      
      return orderNumberMatch || orderIdMatch || productNameMatch;
    }).toList();
  }

  Future<void> cancelOrder(String orderId, {String? reason}) async {
    _setLoading(true);

    try {
      final response = await ApiService.cancelOrder(orderId: orderId);
      
      if (response['success'] == true) {
        final index = _orders.indexWhere((order) => order.id == orderId);
        if (index >= 0) {
          // Create a new order with cancelled status
          final oldOrder = _orders[index];
          final cancelledOrder = Order(
            id: oldOrder.id,
            orderNumber: oldOrder.orderNumber,
            userId: oldOrder.userId,
            items: oldOrder.items,
            shippingAddress: oldOrder.shippingAddress,
            paymentMethod: oldOrder.paymentMethod,
            status: OrderStatus.cancelled,
            subtotal: oldOrder.subtotal,
            tax: oldOrder.tax,
            shipping: oldOrder.shipping,
            discount: oldOrder.discount,
            total: oldOrder.total,
            createdAt: oldOrder.createdAt,
            trackingNumber: oldOrder.trackingNumber,
            cancellationReason: reason,
          );

          _orders[index] = cancelledOrder;
          notifyListeners();
        }
      } else {
        throw Exception(response['error'] ?? 'Failed to cancel order');
      }
    } catch (e) {
      debugPrint('Error cancelling order: $e');
      throw Exception('Failed to cancel order: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> returnOrder(String orderId, String reason) async {
    _setLoading(true);

    try {
      final response = await ApiService.returnOrder(orderId: orderId, reason: reason);
      
      if (response['success'] == true) {
        final index = _orders.indexWhere((order) => order.id == orderId);
        if (index >= 0) {
          final oldOrder = _orders[index];
          final returnedOrder = Order(
            id: oldOrder.id,
            orderNumber: oldOrder.orderNumber,
            userId: oldOrder.userId,
            items: oldOrder.items,
            shippingAddress: oldOrder.shippingAddress,
            paymentMethod: oldOrder.paymentMethod,
            status: OrderStatus.returnRequested,
            subtotal: oldOrder.subtotal,
            tax: oldOrder.tax,
            shipping: oldOrder.shipping,
            discount: oldOrder.discount,
            total: oldOrder.total,
            createdAt: oldOrder.createdAt,
            trackingNumber: oldOrder.trackingNumber,
            returnReason: reason,
          );

          _orders[index] = returnedOrder;
          notifyListeners();
        }
      } else {
        throw Exception(response['error'] ?? 'Failed to return order');
      }
    } catch (e) {
      debugPrint('Error returning order: $e');
      throw Exception('Failed to return order: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refundOrder(String orderId, String reason) async {
    _setLoading(true);

    try {
      final response = await ApiService.refundOrder(orderId: orderId, reason: reason);
      
      if (response['success'] == true) {
        final index = _orders.indexWhere((order) => order.id == orderId);
        if (index >= 0) {
          final oldOrder = _orders[index];
          final refundedOrder = Order(
            id: oldOrder.id,
            orderNumber: oldOrder.orderNumber,
            userId: oldOrder.userId,
            items: oldOrder.items,
            shippingAddress: oldOrder.shippingAddress,
            paymentMethod: oldOrder.paymentMethod,
            status: OrderStatus.refunded,
            subtotal: oldOrder.subtotal,
            tax: oldOrder.tax,
            shipping: oldOrder.shipping,
            discount: oldOrder.discount,
            total: oldOrder.total,
            createdAt: oldOrder.createdAt,
            trackingNumber: oldOrder.trackingNumber,
            returnReason: reason,
            refundStatus: 'processed',
            refundAmount: oldOrder.total,
            refundedAt: DateTime.now(),
          );

          _orders[index] = refundedOrder;
          notifyListeners();
        }
      } else {
        throw Exception(response['error'] ?? 'Failed to refund order');
      }
    } catch (e) {
      debugPrint('Error refunding order: $e');
      throw Exception('Failed to refund order: $e');
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearCurrentOrder() {
    _currentOrder = null;
    notifyListeners();
  }
}