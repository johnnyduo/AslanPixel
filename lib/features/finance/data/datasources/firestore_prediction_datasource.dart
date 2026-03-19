import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aslan_pixel/features/finance/data/models/prediction_entry_model.dart';
import 'package:aslan_pixel/features/finance/data/models/prediction_event_model.dart';
import 'package:aslan_pixel/features/finance/data/repositories/prediction_repository.dart';

class FirestorePredictionDatasource implements PredictionRepository {
  FirestorePredictionDatasource({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  // ---------------------------------------------------------------------------
  // Collections
  // ---------------------------------------------------------------------------

  CollectionReference<Map<String, dynamic>> get _events =>
      _db.collection('predictionEvents');

  CollectionReference<Map<String, dynamic>> _userEntries(String uid) =>
      _db.collection('userEntries').doc(uid).collection('entries');

  // ---------------------------------------------------------------------------
  // watchOpenEvents
  // ---------------------------------------------------------------------------

  @override
  Stream<List<PredictionEventModel>> watchOpenEvents() {
    return _events
        .where('status', isEqualTo: 'open')
        .orderBy('settlementAt')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => PredictionEventModel.fromFirestore(doc))
              .toList(),
        );
  }

  // ---------------------------------------------------------------------------
  // getEvent
  // ---------------------------------------------------------------------------

  @override
  Future<PredictionEventModel?> getEvent(String eventId) async {
    final doc = await _events.doc(eventId).get();
    if (!doc.exists) return null;
    return PredictionEventModel.fromFirestore(doc);
  }

  // ---------------------------------------------------------------------------
  // enterPrediction
  // ---------------------------------------------------------------------------

  @override
  Future<void> enterPrediction({
    required String eventId,
    required String uid,
    required String selectedOptionId,
    required int coinStaked,
  }) async {
    final eventRef = _events.doc(eventId);
    final economyRef =
        _db.collection('users').doc(uid).collection('economy').doc('balance');
    final txLogRef = _db
        .collection('users')
        .doc(uid)
        .collection('economy')
        .doc('balance')
        .collection('transactions')
        .doc();
    final entryId = _db.collection('_').doc().id; // generate unique ID

    final userEntryRef = _userEntries(uid).doc(entryId);

    await _db.runTransaction((txn) async {
      // (a) Verify event is still open
      final eventSnap = await txn.get(eventRef);
      if (!eventSnap.exists) {
        throw Exception('Event not found: $eventId');
      }
      final status = (eventSnap.data()!['status'] as String?) ?? '';
      if (status != 'open') {
        throw Exception('Event is no longer open for entries.');
      }

      // (b) Deduct coins from the canonical economy balance document
      final economySnap = await txn.get(economyRef);
      final currentCoins = economySnap.exists
          ? ((economySnap.data()?['coins'] as num?)?.toInt() ?? 0)
          : 0;
      if (currentCoins < coinStaked) {
        throw Exception('Insufficient coins. Have $currentCoins, need $coinStaked.');
      }
      txn.set(
        economyRef,
        {
          'coins': FieldValue.increment(-coinStaked),
          'lastUpdated': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      // (b2) Log the transaction
      txn.set(txLogRef, {
        'type': 'debit',
        'amount': coinStaked,
        'reason': 'prediction_entry:$eventId',
        'timestamp': FieldValue.serverTimestamp(),
      });

      // (c) Write the user entry document
      final now = DateTime.now();
      final entryData = PredictionEntryModel(
        entryId: entryId,
        eventId: eventId,
        uid: uid,
        selectedOptionId: selectedOptionId,
        coinStaked: coinStaked,
        enteredAt: now,
        rewardGranted: 0,
      ).toMap();

      txn.set(userEntryRef, entryData);
    });
  }

  // ---------------------------------------------------------------------------
  // watchMyEntries
  // ---------------------------------------------------------------------------

  @override
  Stream<List<PredictionEntryModel>> watchMyEntries(String uid) {
    return _userEntries(uid)
        .orderBy('enteredAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => PredictionEntryModel.fromFirestore(doc))
              .toList(),
        );
  }

  // ---------------------------------------------------------------------------
  // loadVotes
  // ---------------------------------------------------------------------------

  @override
  Future<({int bullCount, int bearCount, String? myVote})> loadVotes({
    required String eventId,
    required String uid,
  }) async {
    final snap = await _events.doc(eventId).collection('votes').get();
    int bull = 0;
    int bear = 0;
    String? mine;
    for (final doc in snap.docs) {
      final side = doc.data()['side'] as String?;
      if (side == 'bull') bull++;
      if (side == 'bear') bear++;
      if (doc.id == uid) mine = side;
    }
    return (bullCount: bull, bearCount: bear, myVote: mine);
  }

  // ---------------------------------------------------------------------------
  // castVote
  // ---------------------------------------------------------------------------

  @override
  Future<void> castVote({
    required String eventId,
    required String uid,
    required String side,
  }) async {
    await _events.doc(eventId).collection('votes').doc(uid).set({
      'uid': uid,
      'side': side,
      'votedAt': FieldValue.serverTimestamp(),
    });
  }
}
