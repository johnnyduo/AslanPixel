import 'package:aslan_pixel/features/home/data/models/ranking_entry_model.dart';

/// Abstract contract for leaderboard data operations.
abstract class RankingRepository {
  /// Emits the top [limit] entries for [period] ordered by score descending.
  ///
  /// [period] is typically 'weekly' or 'alltime'.
  Stream<List<RankingEntryModel>> watchLeaderboard(
    String period, {
    int limit = 20,
  });

  /// Fetches the ranking entry for [uid] in [period], or null if absent.
  Future<RankingEntryModel?> getMyRank(String uid, String period);
}
