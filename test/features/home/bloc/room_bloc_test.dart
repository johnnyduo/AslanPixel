import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:aslan_pixel/features/home/bloc/room_bloc.dart';
import 'package:aslan_pixel/features/home/bloc/room_event.dart';
import 'package:aslan_pixel/features/home/bloc/room_state.dart';
import 'package:aslan_pixel/features/home/data/models/room_item_model.dart';
import 'package:aslan_pixel/features/home/data/repositories/room_repository.dart';

// ── Mock ─────────────────────────────────────────────────────────────────────

class MockRoomRepository extends Mock implements RoomRepository {}

// ── Fallback fakes ────────────────────────────────────────────────────────────

class FakeRoomModel extends Fake implements RoomModel {}
class FakeRoomItem extends Fake implements RoomItem {}

// ── Helpers ──────────────────────────────────────────────────────────────────

RoomModel _starterRoom({String uid = 'uid_01'}) => RoomModel(
      uid: uid,
      layoutVersion: 1,
      items: const [
        RoomItem(
          itemId: 'desk_01',
          type: RoomItemType.furniture,
          assetKey: 'desk_01',
          slotX: 3,
          slotY: 2,
          isUnlocked: true,
        ),
      ],
      updatedAt: DateTime(2026, 3, 18),
    );

const _kUid = 'uid_01';

void main() {
  setUpAll(() {
    registerFallbackValue(FakeRoomModel());
    registerFallbackValue(FakeRoomItem());
  });

  late MockRoomRepository repo;

  setUp(() {
    repo = MockRoomRepository();
  });

  RoomBloc build() => RoomBloc(repository: repo);

  // ── Initial state ─────────────────────────────────────────────────────────

  group('RoomBloc initial state', () {
    test('starts as RoomInitial', () {
      expect(build().state, isA<RoomInitial>());
    });
  });

  // ── RoomLoadRequested ─────────────────────────────────────────────────────

  group('RoomLoadRequested', () {
    blocTest<RoomBloc, RoomState>(
      'emits [RoomLoading, RoomLoaded] when room exists',
      build: build,
      setUp: () {
        when(() => repo.getRoom(_kUid))
            .thenAnswer((_) async => _starterRoom());
        when(() => repo.watchRoom(_kUid))
            .thenAnswer((_) => Stream.value(_starterRoom()));
      },
      act: (bloc) => bloc.add(const RoomLoadRequested(_kUid)),
      expect: () => [
        isA<RoomLoading>(),
        isA<RoomLoaded>()
            .having((s) => s.room.uid, 'uid', _kUid)
            .having((s) => s.room.items.length, 'items count', 1),
      ],
    );

    blocTest<RoomBloc, RoomState>(
      'creates starter room when getRoom returns null then streams loaded state',
      build: build,
      setUp: () {
        when(() => repo.getRoom(_kUid)).thenAnswer((_) async => null);
        when(() => repo.saveRoom(_kUid, any())).thenAnswer((_) async {});
        when(() => repo.watchRoom(_kUid))
            .thenAnswer((_) => Stream.value(_starterRoom()));
      },
      act: (bloc) => bloc.add(const RoomLoadRequested(_kUid)),
      expect: () => [
        isA<RoomLoading>(),
        isA<RoomLoaded>(),
      ],
      verify: (_) {
        verify(() => repo.getRoom(_kUid)).called(1);
        verify(() => repo.saveRoom(_kUid, any())).called(1);
      },
    );

    blocTest<RoomBloc, RoomState>(
      'emits RoomLoading when stream emits null (equal states are deduplicated)',
      build: build,
      setUp: () {
        when(() => repo.getRoom(_kUid))
            .thenAnswer((_) async => _starterRoom());
        when(() => repo.watchRoom(_kUid))
            .thenAnswer((_) => Stream.value(null));
      },
      act: (bloc) => bloc.add(const RoomLoadRequested(_kUid)),
      // RoomLoading is const — emitting an equal state is a no-op in BLoC,
      // so only one RoomLoading is recorded even though two are attempted.
      expect: () => [isA<RoomLoading>()],
    );

    blocTest<RoomBloc, RoomState>(
      'emits RoomError when stream throws',
      build: build,
      setUp: () {
        when(() => repo.getRoom(_kUid))
            .thenAnswer((_) async => _starterRoom());
        when(() => repo.watchRoom(_kUid))
            .thenAnswer((_) => Stream.error(Exception('Firestore error')));
      },
      act: (bloc) => bloc.add(const RoomLoadRequested(_kUid)),
      expect: () => [isA<RoomLoading>(), isA<RoomError>()],
    );
  });

  // ── RoomItemPlaced ────────────────────────────────────────────────────────

  group('RoomItemPlaced', () {
    const newItem = RoomItem(
      itemId: 'plant_01',
      type: RoomItemType.plant,
      assetKey: 'plant_01',
      slotX: 1,
      slotY: 1,
      isUnlocked: true,
    );

    blocTest<RoomBloc, RoomState>(
      'calls repository placeItem with correct args',
      build: build,
      setUp: () {
        when(() => repo.getRoom(_kUid))
            .thenAnswer((_) async => _starterRoom());
        when(() => repo.watchRoom(_kUid))
            .thenAnswer((_) => Stream.value(_starterRoom()));
        when(() => repo.placeItem(_kUid, any())).thenAnswer((_) async {});
      },
      act: (bloc) async {
        bloc.add(const RoomLoadRequested(_kUid));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const RoomItemPlaced(uid: _kUid, item: newItem));
      },
      verify: (_) => verify(() => repo.placeItem(_kUid, newItem)).called(1),
    );

    blocTest<RoomBloc, RoomState>(
      'emits RoomError when placeItem throws',
      build: build,
      setUp: () {
        when(() => repo.getRoom(_kUid))
            .thenAnswer((_) async => _starterRoom());
        when(() => repo.watchRoom(_kUid))
            .thenAnswer((_) => Stream.value(_starterRoom()));
        when(() => repo.placeItem(_kUid, any()))
            .thenThrow(StateError('slot occupied'));
      },
      act: (bloc) async {
        bloc.add(const RoomLoadRequested(_kUid));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const RoomItemPlaced(uid: _kUid, item: newItem));
      },
      expect: () => [
        isA<RoomLoading>(),
        isA<RoomLoaded>(),
        isA<RoomError>(),
      ],
    );
  });

  // ── RoomItemRemoved ───────────────────────────────────────────────────────

  group('RoomItemRemoved', () {
    blocTest<RoomBloc, RoomState>(
      'calls repository removeItem with correct args',
      build: build,
      setUp: () {
        when(() => repo.getRoom(_kUid))
            .thenAnswer((_) async => _starterRoom());
        when(() => repo.watchRoom(_kUid))
            .thenAnswer((_) => Stream.value(_starterRoom()));
        when(() => repo.removeItem(_kUid, 'desk_01'))
            .thenAnswer((_) async {});
      },
      act: (bloc) async {
        bloc.add(const RoomLoadRequested(_kUid));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const RoomItemRemoved(uid: _kUid, itemId: 'desk_01'));
      },
      verify: (_) =>
          verify(() => repo.removeItem(_kUid, 'desk_01')).called(1),
    );

    blocTest<RoomBloc, RoomState>(
      'emits RoomError when removeItem throws',
      build: build,
      setUp: () {
        when(() => repo.getRoom(_kUid))
            .thenAnswer((_) async => _starterRoom());
        when(() => repo.watchRoom(_kUid))
            .thenAnswer((_) => Stream.value(_starterRoom()));
        when(() => repo.removeItem(any(), any()))
            .thenThrow(Exception('remove failed'));
      },
      act: (bloc) async {
        bloc.add(const RoomLoadRequested(_kUid));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const RoomItemRemoved(uid: _kUid, itemId: 'desk_01'));
      },
      expect: () => [
        isA<RoomLoading>(),
        isA<RoomLoaded>(),
        isA<RoomError>(),
      ],
    );
  });

  // ── RoomItemUnlocked ──────────────────────────────────────────────────────

  group('RoomItemUnlocked', () {
    blocTest<RoomBloc, RoomState>(
      'places new item when it does not exist in loaded room',
      build: build,
      setUp: () {
        when(() => repo.getRoom(_kUid))
            .thenAnswer((_) async => _starterRoom());
        when(() => repo.watchRoom(_kUid))
            .thenAnswer((_) => Stream.value(_starterRoom()));
        when(() => repo.placeItem(_kUid, any())).thenAnswer((_) async {});
      },
      act: (bloc) async {
        bloc.add(const RoomLoadRequested(_kUid));
        await Future<void>.delayed(Duration.zero);
        // 'crystal_ball_01' does not exist in _starterRoom
        bloc.add(const RoomItemUnlocked(uid: _kUid, itemId: 'crystal_ball_01'));
        await Future<void>.delayed(Duration.zero);
      },
      verify: (_) => verify(() => repo.placeItem(_kUid, any())).called(1),
    );

    blocTest<RoomBloc, RoomState>(
      'unlocks item when it exists but is locked',
      build: build,
      setUp: () {
        // Room with a locked item
        final roomWithLocked = RoomModel(
          uid: _kUid,
          layoutVersion: 1,
          items: const [
            RoomItem(
              itemId: 'chest_01',
              type: RoomItemType.chest,
              assetKey: 'chest_01',
              slotX: 1,
              slotY: 5,
              isUnlocked: false,
            ),
          ],
          updatedAt: DateTime(2026, 3, 18),
        );
        when(() => repo.getRoom(_kUid))
            .thenAnswer((_) async => roomWithLocked);
        when(() => repo.watchRoom(_kUid))
            .thenAnswer((_) => Stream.value(roomWithLocked));
        when(() => repo.unlockItem(_kUid, 'chest_01'))
            .thenAnswer((_) async {});
      },
      act: (bloc) async {
        bloc.add(const RoomLoadRequested(_kUid));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const RoomItemUnlocked(uid: _kUid, itemId: 'chest_01'));
        await Future<void>.delayed(Duration.zero);
      },
      verify: (_) =>
          verify(() => repo.unlockItem(_kUid, 'chest_01')).called(1),
    );

    blocTest<RoomBloc, RoomState>(
      'does nothing when item is already unlocked',
      build: build,
      setUp: () {
        when(() => repo.getRoom(_kUid))
            .thenAnswer((_) async => _starterRoom());
        when(() => repo.watchRoom(_kUid))
            .thenAnswer((_) => Stream.value(_starterRoom()));
      },
      act: (bloc) async {
        bloc.add(const RoomLoadRequested(_kUid));
        await Future<void>.delayed(Duration.zero);
        // 'desk_01' is already unlocked in _starterRoom
        bloc.add(const RoomItemUnlocked(uid: _kUid, itemId: 'desk_01'));
        await Future<void>.delayed(Duration.zero);
      },
      verify: (_) {
        verifyNever(() => repo.placeItem(any(), any()));
        verifyNever(() => repo.unlockItem(any(), any()));
      },
    );

    blocTest<RoomBloc, RoomState>(
      'does nothing when room is not loaded',
      build: build,
      act: (bloc) =>
          bloc.add(const RoomItemUnlocked(uid: _kUid, itemId: 'desk_01')),
      expect: () => [],
    );
  });
}
