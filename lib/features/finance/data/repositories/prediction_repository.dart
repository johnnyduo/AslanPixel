import 'package:aslan_pixel/features/finance/data/models/prediction_entry_model.dart';
import 'package:aslan_pixel/features/finance/data/models/prediction_event_model.dart';

abstract class PredictionRepository {
  /// Live stream of all events with status == 'open', ordered by settlementAt.
  Stream<List<PredictionEventModel>> watchOpenEvents();

  /// Fetch a single event by ID.
  Future<PredictionEventModel?> getEvent(String eventId);

  /// Enter a prediction: deducts coins, writes entry documents atomically.
  Future<void> enterPrediction({
    required String eventId,
    required String uid,
    required String selectedOptionId,
    required int coinStaked,
  });

  /// Live stream of the current user's prediction entries.
  Stream<List<PredictionEntryModel>> watchMyEntries(String uid);

  /// Load vote counts and the current user's vote for a prediction event.
  Future<({int bullCount, int bearCount, String? myVote})> loadVotes({
    required String eventId,
    required String uid,
  });

  /// Cast a bull/bear vote for a prediction event.
  Future<void> castVote({
    required String eventId,
    required String uid,
    required String side,
  });
}
