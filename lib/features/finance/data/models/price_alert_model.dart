/// A simple price alert that fires when a simulated ticker crosses a threshold.
class PriceAlertModel {
  const PriceAlertModel({
    required this.symbol,
    required this.targetPrice,
    required this.direction, // 'above' | 'below'
    required this.createdAt,
    this.triggered = false,
  });
  final String symbol;
  final double targetPrice;
  final String direction;
  final DateTime createdAt;
  final bool triggered;

  PriceAlertModel copyWith({bool? triggered}) => PriceAlertModel(
        symbol: symbol,
        targetPrice: targetPrice,
        direction: direction,
        createdAt: createdAt,
        triggered: triggered ?? this.triggered,
      );

  /// Returns true if the alert should fire based on current price.
  bool shouldTrigger(double currentPrice) {
    if (triggered) return false;
    return direction == 'above'
        ? currentPrice >= targetPrice
        : currentPrice <= targetPrice;
  }
}
