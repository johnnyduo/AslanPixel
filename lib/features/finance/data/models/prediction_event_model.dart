import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

// ---------------------------------------------------------------------------
// PredictionOption
// ---------------------------------------------------------------------------

class PredictionOption extends Equatable {
  const PredictionOption({
    required this.optionId,
    required this.label,
    required this.labelTh,
  });

  final String optionId;
  final String label;
  final String labelTh;

  factory PredictionOption.fromMap(Map<String, dynamic> map) {
    return PredictionOption(
      optionId: map['optionId'] as String,
      label: map['label'] as String,
      labelTh: map['labelTh'] as String,
    );
  }

  Map<String, dynamic> toMap() => {
        'optionId': optionId,
        'label': label,
        'labelTh': labelTh,
      };

  @override
  List<Object?> get props => [optionId, label, labelTh];
}

// ---------------------------------------------------------------------------
// PredictionEventModel
// ---------------------------------------------------------------------------

class PredictionEventModel extends Equatable {
  const PredictionEventModel({
    required this.eventId,
    required this.symbol,
    required this.title,
    required this.titleTh,
    required this.options,
    required this.coinCost,
    required this.settlementAt,
    required this.settlementRule,
    required this.status,
    this.context,
    required this.createdAt,
  });

  final String eventId;
  final String symbol;
  final String title;
  final String titleTh;
  final List<PredictionOption> options;
  final int coinCost;
  final DateTime settlementAt;

  /// 'above' | 'below' | 'exact'
  final String settlementRule;

  /// 'open' | 'closed' | 'settled'
  final String status;

  final String? context;
  final DateTime createdAt;

  factory PredictionEventModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PredictionEventModel(
      eventId: doc.id,
      symbol: data['symbol'] as String,
      title: data['title'] as String,
      titleTh: data['titleTh'] as String,
      options: (data['options'] as List<dynamic>)
          .map((e) => PredictionOption.fromMap(e as Map<String, dynamic>))
          .toList(),
      coinCost: (data['coinCost'] as num).toInt(),
      settlementAt: (data['settlementAt'] as Timestamp).toDate(),
      settlementRule: data['settlementRule'] as String,
      status: data['status'] as String,
      context: data['context'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'eventId': eventId,
        'symbol': symbol,
        'title': title,
        'titleTh': titleTh,
        'options': options.map((o) => o.toMap()).toList(),
        'coinCost': coinCost,
        'settlementAt': Timestamp.fromDate(settlementAt),
        'settlementRule': settlementRule,
        'status': status,
        'context': context,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  PredictionEventModel copyWith({
    String? eventId,
    String? symbol,
    String? title,
    String? titleTh,
    List<PredictionOption>? options,
    int? coinCost,
    DateTime? settlementAt,
    String? settlementRule,
    String? status,
    String? context,
    DateTime? createdAt,
  }) {
    return PredictionEventModel(
      eventId: eventId ?? this.eventId,
      symbol: symbol ?? this.symbol,
      title: title ?? this.title,
      titleTh: titleTh ?? this.titleTh,
      options: options ?? this.options,
      coinCost: coinCost ?? this.coinCost,
      settlementAt: settlementAt ?? this.settlementAt,
      settlementRule: settlementRule ?? this.settlementRule,
      status: status ?? this.status,
      context: context ?? this.context,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        eventId,
        symbol,
        title,
        titleTh,
        options,
        coinCost,
        settlementAt,
        settlementRule,
        status,
        context,
        createdAt,
      ];
}
