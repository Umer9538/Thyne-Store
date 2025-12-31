import 'package:flutter/foundation.dart';
import '../../data/models/loyalty.dart';
import '../../data/services/api_service.dart';

class LoyaltyProvider extends ChangeNotifier {
  LoyaltyProgram? _loyaltyProgram;
  bool _isLoading = false;

  LoyaltyProgram? get loyaltyProgram => _loyaltyProgram;
  bool get isLoading => _isLoading;

  /// Load loyalty program for the current user
  Future<void> loadLoyaltyProgram(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.getLoyaltyProgram();
      if (response['success'] == true && response['data'] != null) {
        _loyaltyProgram = LoyaltyProgram.fromJson(response['data']);
      } else {
        debugPrint('Failed to load loyalty program from API: ${response['error'] ?? 'No data'}');
        _loyaltyProgram = null;
      }
    } catch (e, stackTrace) {
      debugPrint('Error loading loyalty program: $e');
      debugPrint('Stack trace: $stackTrace');
      _loyaltyProgram = null;
      // Don't rethrow - just log and continue
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Trigger daily login check
  Future<void> checkDailyLogin() async {
    try {
      final response = await ApiService.checkDailyLogin();

      if (response['success'] == true) {
        // Reload loyalty program to get updated credits and streak
        if (_loyaltyProgram != null) {
          await loadLoyaltyProgram(_loyaltyProgram!.userId);
        }
      }
    } catch (e) {
      debugPrint('Error checking daily login: $e');
      rethrow;
    }
  }

  /// Get credit transaction history
  Future<List<CreditTransaction>> getCreditHistory({int limit = 20, int offset = 0}) async {
    try {
      final response = await ApiService.getCreditHistory(limit: limit, offset: offset);

      if (response['success'] == true && response['data'] != null) {
        final transactions = response['data'] as List;
        return transactions.map((t) => CreditTransaction.fromJson(t)).toList();
      }

      return [];
    } catch (e) {
      debugPrint('Error getting credit history: $e');
      return [];
    }
  }

  /// Get available redemption options
  Future<List<RedemptionOption>> getRedemptionOptions() async {
    try {
      final response = await ApiService.getRedemptionOptions();

      if (response['success'] == true && response['data'] != null) {
        final options = response['data'] as List;
        return options.map((o) => RedemptionOption.fromJson(o)).toList();
      }

      return [];
    } catch (e) {
      debugPrint('Error getting redemption options: $e');
      return [];
    }
  }

  /// Redeem credits for a reward
  Future<void> redeemCredits(String redemptionId) async {
    try {
      final response = await ApiService.redeemCredits(redemptionId: redemptionId);

      if (response['success'] == true) {
        // Reload loyalty program to get updated credits
        if (_loyaltyProgram != null) {
          await loadLoyaltyProgram(_loyaltyProgram!.userId);
        }
      } else {
        throw Exception(response['error'] ?? 'Failed to redeem credits');
      }
    } catch (e) {
      debugPrint('Error redeeming credits: $e');
      rethrow;
    }
  }

  /// Get tier information for all tiers
  Future<List<TierInfo>> getTierInfo() async {
    try {
      final response = await ApiService.getLoyaltyTiers();

      if (response['success'] == true && response['data'] != null) {
        final tiers = response['data'] as List;
        return tiers.map((t) => TierInfo.fromJson(t)).toList();
      }

      return [];
    } catch (e) {
      debugPrint('Error getting tier info: $e');
      return [];
    }
  }

  /// Refresh loyalty program data
  Future<void> refresh() async {
    if (_loyaltyProgram != null) {
      await loadLoyaltyProgram(_loyaltyProgram!.userId);
    }
  }
}
