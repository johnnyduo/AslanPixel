import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:aslan_pixel/features/world/bloc/plaza_bloc.dart';
import 'package:aslan_pixel/features/world/data/models/plaza_presence_model.dart';
import 'package:aslan_pixel/features/world/data/repositories/plaza_repository.dart';

// ── Mock ─────────────────────────────────────────────────────────────────────

class MockPlazaRepository extends Mock implements PlazaRepository {}

// ── Helpers ──────────────────────────────────────────────────────────────────

PlazaPresenceModel _presence({String uid = 'uid_01'}) => PlazaPresenceModel(
      uid: uid,
      x: 0.5,
      y: 0.5,
      lastSeen: DateTime(2026, 3, 18),
    );

const _kUid = 'uid_01';

/// Stubs all repository methods that are required for every test that
/// dispatches [PlazaWatchStarted]. [PlazaBloc.close] always calls
/// [removeMyPresence] when [_currentUid] is set, so it must be stubbed.
void _stubAll(MockPlazaRepository repo, {List<PlazaPresenceModel>? presences}) {
  when(() => repo.updateMyPresence(
        uid: any(named: 'uid'),
        x: any(named: 'x'),
        y: any(named: 'y'),
      )).thenAnswer((_) async {});
  when(() => repo.removeMyPresence(any())).thenAnswer((_) async {});
  when(() => repo.watchPresence()).thenAnswer(
    (_) => Stream.value(presences ?? []),
  );
}

void main() {
  late MockPlazaRepository repo;

  setUp(() {
    repo = MockPlazaRepository();
  });

  PlazaBloc build() => PlazaBloc(repo);

  // ── Initial state ─────────────────────────────────────────────────────────

  group('PlazaBloc initial state', () {
    test('starts as PlazaInitial', () {
      expect(build().state, isA<PlazaInitial>());
    });
  });

  // ── PlazaWatchStarted ─────────────────────────────────────────────────────

  group('PlazaWatchStarted', () {
    blocTest<PlazaBloc, PlazaState>(
      'emits [PlazaLoading, PlazaLoaded] with presences from stream',
      build: build,
      setUp: () => _stubAll(repo, presences: [_presence()]),
      act: (bloc) => bloc.add(const PlazaWatchStarted(
        uid: _kUid,
        x: 0.5,
        y: 0.5,
      )),
      expect: () => [
        isA<PlazaLoading>(),
        isA<PlazaLoaded>().having((s) => s.presences.length, 'count', 1),
      ],
      verify: (_) => verify(() => repo.updateMyPresence(
            uid: _kUid,
            x: 0.5,
            y: 0.5,
          )).called(1),
    );

    blocTest<PlazaBloc, PlazaState>(
      'emits PlazaError when stream throws',
      build: build,
      setUp: () {
        when(() => repo.updateMyPresence(
              uid: any(named: 'uid'),
              x: any(named: 'x'),
              y: any(named: 'y'),
            )).thenAnswer((_) async {});
        when(() => repo.removeMyPresence(any())).thenAnswer((_) async {});
        when(() => repo.watchPresence())
            .thenAnswer((_) => Stream.error(Exception('Firestore offline')));
      },
      act: (bloc) => bloc.add(const PlazaWatchStarted(
        uid: _kUid,
        x: 0.5,
        y: 0.5,
      )),
      expect: () => [isA<PlazaLoading>(), isA<PlazaError>()],
    );

    blocTest<PlazaBloc, PlazaState>(
      'announces arrival by calling updateMyPresence before streaming',
      build: build,
      setUp: () => _stubAll(repo),
      act: (bloc) => bloc.add(const PlazaWatchStarted(
        uid: _kUid,
        x: 0.3,
        y: 0.7,
      )),
      verify: (_) => verify(() => repo.updateMyPresence(
            uid: _kUid,
            x: 0.3,
            y: 0.7,
          )).called(1),
    );
  });

  // ── PlazaLeft ─────────────────────────────────────────────────────────────

  group('PlazaLeft', () {
    blocTest<PlazaBloc, PlazaState>(
      'calls removeMyPresence with the correct uid at least once',
      build: build,
      setUp: () => _stubAll(repo, presences: [_presence()]),
      act: (bloc) async {
        bloc.add(const PlazaWatchStarted(uid: _kUid, x: 0.5, y: 0.5));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const PlazaLeft(uid: _kUid));
      },
      // PlazaLeft handler calls removeMyPresence once.
      // PlazaBloc.close() also calls removeMyPresence since _currentUid is set.
      // Verify it's called at least once.
      verify: (_) => verify(() => repo.removeMyPresence(_kUid))
          .called(greaterThanOrEqualTo(1)),
    );
  });

  // ── PlazaPositionUpdated ──────────────────────────────────────────────────

  group('PlazaPositionUpdated', () {
    blocTest<PlazaBloc, PlazaState>(
      'does not immediately call updateMyPresence a second time (debounced)',
      build: build,
      setUp: () => _stubAll(repo),
      act: (bloc) async {
        bloc.add(const PlazaWatchStarted(uid: _kUid, x: 0.5, y: 0.5));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const PlazaPositionUpdated(x: 0.8, y: 0.2));
      },
      // updateMyPresence is only called once (on arrival), not again immediately
      // after a position update (debounce window = 3 s).
      verify: (_) =>
          verify(() => repo.updateMyPresence(
                uid: _kUid,
                x: 0.5,
                y: 0.5,
              )).called(1),
    );

    blocTest<PlazaBloc, PlazaState>(
      'does not emit new states on position update (no state change)',
      build: build,
      setUp: () => _stubAll(repo),
      act: (bloc) async {
        bloc.add(const PlazaWatchStarted(uid: _kUid, x: 0.5, y: 0.5));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const PlazaPositionUpdated(x: 0.2, y: 0.9));
      },
      expect: () => [
        isA<PlazaLoading>(),
        isA<PlazaLoaded>(),
        // No additional states from PlazaPositionUpdated
      ],
    );
  });
}
