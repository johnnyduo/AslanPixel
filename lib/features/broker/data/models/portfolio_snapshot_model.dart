import 'package:equatable/equatable.dart';

// ---------------------------------------------------------------------------
// PositionModel
// ---------------------------------------------------------------------------

class PositionModel extends Equatable {
  const PositionModel({
    required this.symbol,
    required this.qty,
    required this.avgCost,
    required this.currentPrice,
    required this.unrealizedPnl,
  });

  final String symbol;
  final double qty;
  final double avgCost;
  final double currentPrice;
  final double unrealizedPnl;

  factory PositionModel.fromMap(Map<String, dynamic> map) {
    return PositionModel(
      symbol: map['symbol'] as String,
      qty: (map['qty'] as num).toDouble(),
      avgCost: (map['avgCost'] as num).toDouble(),
      currentPrice: (map['currentPrice'] as num).toDouble(),
      unrealizedPnl: (map['unrealizedPnl'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
        'symbol': symbol,
        'qty': qty,
        'avgCost': avgCost,
        'currentPrice': currentPrice,
        'unrealizedPnl': unrealizedPnl,
      };

  @override
  List<Object?> get props => [symbol, qty, avgCost, currentPrice, unrealizedPnl];
}

// ---------------------------------------------------------------------------
// PortfolioSnapshotModel
// ---------------------------------------------------------------------------

class PortfolioSnapshotModel extends Equatable {
  const PortfolioSnapshotModel({
    required this.totalValue,
    required this.dailyPnl,
    required this.dailyPnlPercent,
    required this.positions,
    required this.snapshotAt,
  });

  final double totalValue;
  final double dailyPnl;
  final double dailyPnlPercent;
  final List<PositionModel> positions;
  final DateTime snapshotAt;

  factory PortfolioSnapshotModel.fromMap(Map<String, dynamic> map) {
    return PortfolioSnapshotModel(
      totalValue: (map['totalValue'] as num).toDouble(),
      dailyPnl: (map['dailyPnl'] as num).toDouble(),
      dailyPnlPercent: (map['dailyPnlPercent'] as num).toDouble(),
      positions: (map['positions'] as List<dynamic>)
          .map((e) => PositionModel.fromMap(e as Map<String, dynamic>))
          .toList(),
      snapshotAt: DateTime.parse(map['snapshotAt'] as String),
    );
  }

  Map<String, dynamic> toMap() => {
        'totalValue': totalValue,
        'dailyPnl': dailyPnl,
        'dailyPnlPercent': dailyPnlPercent,
        'positions': positions.map((p) => p.toMap()).toList(),
        'snapshotAt': snapshotAt.toIso8601String(),
      };

  @override
  List<Object?> get props => [
        totalValue,
        dailyPnl,
        dailyPnlPercent,
        positions,
        snapshotAt,
      ];
}
