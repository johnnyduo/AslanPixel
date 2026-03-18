import 'package:aslan_pixel/features/world/data/models/plaza_presence_model.dart';

/// Abstract interface for Public Plaza presence operations.
abstract class PlazaRepository {
  /// Returns a real-time stream of up to [limit] active presences.
  Stream<List<PlazaPresenceModel>> watchPresence({int limit = 50});

  /// Creates or updates the current user's presence record.
  Future<void> updateMyPresence({
    required String uid,
    required double x,
    required double y,
    String? avatarId,
    String? displayName,
  });

  /// Deletes the current user's presence record (called on disconnect/close).
  Future<void> removeMyPresence(String uid);
}
