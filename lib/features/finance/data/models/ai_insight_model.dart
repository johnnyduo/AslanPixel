import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Model for an AI-generated insight stored in Firestore.
///
/// [type] values: `market_summary` | `portfolio_explanation` |
///                `prediction_context` | `agent_tip`
class AiInsightModel extends Equatable {
  const AiInsightModel({
    required this.insightId,
    required this.uid,
    required this.type,
    required this.content,
    required this.contentTh,
    required this.modelUsed,
    required this.generatedAt,
    required this.expiresAt,
  });

  final String insightId;
  final String uid;

  /// One of: market_summary, portfolio_explanation, prediction_context, agent_tip
  final String type;

  final String content;
  final String contentTh;
  final String modelUsed;
  final DateTime generatedAt;
  final DateTime expiresAt;

  // ---------------------------------------------------------------------------
  // Computed
  // ---------------------------------------------------------------------------

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  // ---------------------------------------------------------------------------
  // Firestore
  // ---------------------------------------------------------------------------

  factory AiInsightModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AiInsightModel(
      insightId: doc.id,
      uid: data['uid'] as String? ?? '',
      type: data['type'] as String? ?? '',
      content: data['content'] as String? ?? '',
      contentTh: data['contentTh'] as String? ?? '',
      modelUsed: data['modelUsed'] as String? ?? '',
      generatedAt: (data['generatedAt'] as Timestamp).toDate(),
      expiresAt: (data['expiresAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'insightId': insightId,
        'uid': uid,
        'type': type,
        'content': content,
        'contentTh': contentTh,
        'modelUsed': modelUsed,
        'generatedAt': Timestamp.fromDate(generatedAt),
        'expiresAt': Timestamp.fromDate(expiresAt),
      };

  // ---------------------------------------------------------------------------
  // copyWith
  // ---------------------------------------------------------------------------

  AiInsightModel copyWith({
    String? insightId,
    String? uid,
    String? type,
    String? content,
    String? contentTh,
    String? modelUsed,
    DateTime? generatedAt,
    DateTime? expiresAt,
  }) {
    return AiInsightModel(
      insightId: insightId ?? this.insightId,
      uid: uid ?? this.uid,
      type: type ?? this.type,
      content: content ?? this.content,
      contentTh: contentTh ?? this.contentTh,
      modelUsed: modelUsed ?? this.modelUsed,
      generatedAt: generatedAt ?? this.generatedAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  // ---------------------------------------------------------------------------
  // Equatable
  // ---------------------------------------------------------------------------

  @override
  List<Object?> get props => [
        insightId,
        uid,
        type,
        content,
        contentTh,
        modelUsed,
        generatedAt,
        expiresAt,
      ];
}
