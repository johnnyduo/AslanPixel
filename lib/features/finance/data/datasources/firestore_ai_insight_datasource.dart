import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aslan_pixel/features/finance/data/models/ai_insight_model.dart';
import 'package:aslan_pixel/features/finance/data/repositories/ai_insight_repository.dart';

/// Firestore-backed implementation of [AiInsightRepository].
///
/// Document path: `aiInsights/{uid}/{insightId}`
class FirestoreAiInsightDatasource implements AiInsightRepository {
  FirestoreAiInsightDatasource({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  // ---------------------------------------------------------------------------
  // Collection reference
  // ---------------------------------------------------------------------------

  CollectionReference<Map<String, dynamic>> _insightsRef(String uid) =>
      _db.collection('aiInsights').doc(uid).collection('insights');

  // ---------------------------------------------------------------------------
  // getLatestInsight
  // ---------------------------------------------------------------------------

  @override
  Future<AiInsightModel?> getLatestInsight(String uid, String type) async {
    final snap = await _insightsRef(uid)
        .where('type', isEqualTo: type)
        .orderBy('generatedAt', descending: true)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;

    final model = AiInsightModel.fromFirestore(snap.docs.first);
    if (model.isExpired) return null;
    return model;
  }

  // ---------------------------------------------------------------------------
  // saveInsight
  // ---------------------------------------------------------------------------

  @override
  Future<void> saveInsight(AiInsightModel insight) async {
    await _insightsRef(insight.uid)
        .doc(insight.insightId)
        .set(insight.toMap());
  }

  // ---------------------------------------------------------------------------
  // watchInsights
  // ---------------------------------------------------------------------------

  @override
  Stream<List<AiInsightModel>> watchInsights(String uid) {
    return _insightsRef(uid)
        .orderBy('generatedAt', descending: true)
        .limit(10)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => AiInsightModel.fromFirestore(doc))
              .toList(),
        );
  }
}
