import 'package:aslan_pixel/features/finance/data/models/ai_insight_model.dart';

/// Abstract repository for persisting and retrieving [AiInsightModel] records.
abstract class AiInsightRepository {
  /// Returns the most recent non-expired insight for [uid] of the given [type],
  /// or `null` if none exists.
  Future<AiInsightModel?> getLatestInsight(String uid, String type);

  /// Persists [insight] to the backing store.
  Future<void> saveInsight(AiInsightModel insight);

  /// Streams the latest 10 insights for [uid], ordered by [generatedAt] desc.
  Stream<List<AiInsightModel>> watchInsights(String uid);
}
