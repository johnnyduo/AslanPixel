import 'package:aslan_pixel/features/inventory/data/models/economy_model.dart';

/// Abstract contract for economy persistence.
abstract class EconomyRepository {
  /// Emits the live economy balance for [uid].
  Stream<EconomyModel> watchEconomy(String uid);

  /// Adds [amount] coins, logging the [reason].
  Future<void> addCoins(String uid, int amount, String reason);

  /// Deducts [amount] coins after checking sufficient balance.
  /// Throws [InsufficientCoinsException] if balance < amount.
  Future<void> deductCoins(String uid, int amount, String reason);

  /// Adds [amount] XP.
  Future<void> addXp(String uid, int amount);
}

/// Thrown when a deduction would result in a negative balance.
class InsufficientCoinsException implements Exception {
  const InsufficientCoinsException(this.available, this.required_);

  final int available;
  final int required_;

  @override
  String toString() =>
      'InsufficientCoinsException: need $required_ but only $available available';
}
