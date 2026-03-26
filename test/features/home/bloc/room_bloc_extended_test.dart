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

class FakeRoomModel extends Fake implements RoomModel {}

class FakeRoomItem extends Fake implements RoomItem {}

// ── Helpers ──────────────────────────────────────────────────────────────────

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

  // ══════════════════════════════════════════════════════════════════════════
  // FriendRoomVisitRequested
  // ══════════════════════════════════════════════════════════════════════════

  group('FriendRoomVisitRequested', () {
    const friendUid = 'friend_uid_01';
    final friendItems = const [
      RoomItem(
        itemId: 'plant_02',
        type: RoomItemType.plant,
        assetKey: 'plant_02',
        slotX: 2,
        slotY: 3,
        isUnlocked: true,
      ),
    ];

    blocTest<RoomBloc, RoomState>(
      'emits [RoomLoading, FriendRoomLoaded] on success',
      build: build,
      setUp: () {
        when(() => repo.getFriendRoom(friendUid))
            .thenAnswer((_) async => friendItems);
      },
      act: (bloc) => bloc.add(const FriendRoomVisitRequested(friendUid)),
      expect: () => [
        isA<RoomLoading>(),
        isA<FriendRoomLoaded>()
            .having((s) => s.friendUid, 'friendUid', friendUid)
            .having((s) => s.items.length, 'items count', 1)
            .having((s) => s.items.first.itemId, 'first item', 'plant_02'),
      ],
      verify: (_) =>
          verify(() => repo.getFriendRoom(friendUid)).called(1),
    );

    blocTest<RoomBloc, RoomState>(
      'emits [RoomLoading, FriendRoomLoaded] with empty items when friend has no room',
      build: build,
      setUp: () {
        when(() => repo.getFriendRoom(friendUid))
            .thenAnswer((_) async => <RoomItem>[]);
      },
      act: (bloc) => bloc.add(const FriendRoomVisitRequested(friendUid)),
      expect: () => [
        isA<RoomLoading>(),
        isA<FriendRoomLoaded>()
            .having((s) => s.items, 'items', isEmpty),
      ],
    );

    blocTest<RoomBloc, RoomState>(
      'emits [RoomLoading, RoomError] when getFriendRoom throws',
      build: build,
      setUp: () {
        when(() => repo.getFriendRoom(friendUid))
            .thenThrow(Exception('user not found'));
      },
      act: (bloc) => bloc.add(const FriendRoomVisitRequested(friendUid)),
      expect: () => [
        isA<RoomLoading>(),
        isA<RoomError>(),
      ],
    );
  });

  // ══════════════════════════════════════════════════════════════════════════
  // RoomThemePurchaseRequested
  // ══════════════════════════════════════════════════════════════════════════

  group('RoomThemePurchaseRequested', () {
    blocTest<RoomBloc, RoomState>(
      'emits RoomThemePurchaseSuccess on successful purchase',
      build: build,
      setUp: () {
        when(() => repo.purchaseTheme(
              uid: any(named: 'uid'),
              themeId: any(named: 'themeId'),
              price: any(named: 'price'),
            )).thenAnswer((_) async {});
      },
      act: (bloc) => bloc.add(const RoomThemePurchaseRequested(
        themeId: 'wallstreet_floor',
        uid: _kUid,
        price: 500,
      )),
      expect: () => [
        isA<RoomThemePurchaseSuccess>()
            .having((s) => s.themeId, 'themeId', 'wallstreet_floor'),
      ],
      verify: (_) => verify(() => repo.purchaseTheme(
            uid: _kUid,
            themeId: 'wallstreet_floor',
            price: 500,
          )).called(1),
    );

    blocTest<RoomBloc, RoomState>(
      'emits RoomThemePurchaseFailure when purchase throws',
      build: build,
      setUp: () {
        when(() => repo.purchaseTheme(
              uid: any(named: 'uid'),
              themeId: any(named: 'themeId'),
              price: any(named: 'price'),
            )).thenThrow(Exception('Insufficient coins'));
      },
      act: (bloc) => bloc.add(const RoomThemePurchaseRequested(
        themeId: 'wallstreet_vault',
        uid: _kUid,
        price: 1000,
      )),
      expect: () => [
        isA<RoomThemePurchaseFailure>(),
      ],
    );

    blocTest<RoomBloc, RoomState>(
      'emits RoomThemePurchaseFailure when theme already owned',
      build: build,
      setUp: () {
        when(() => repo.purchaseTheme(
              uid: any(named: 'uid'),
              themeId: any(named: 'themeId'),
              price: any(named: 'price'),
            )).thenThrow(StateError('Theme already owned'));
      },
      act: (bloc) => bloc.add(const RoomThemePurchaseRequested(
        themeId: 'starter',
        uid: _kUid,
        price: 0,
      )),
      expect: () => [
        isA<RoomThemePurchaseFailure>(),
      ],
    );
  });

  // ══════════════════════════════════════════════════════════════════════════
  // RoomThemeChanged
  // ══════════════════════════════════════════════════════════════════════════

  group('RoomThemeChanged', () {
    blocTest<RoomBloc, RoomState>(
      'emits RoomThemeChangeSuccess on success',
      build: build,
      setUp: () {
        when(() => repo.setActiveTheme(
              uid: any(named: 'uid'),
              themeId: any(named: 'themeId'),
            )).thenAnswer((_) async {});
      },
      act: (bloc) => bloc.add(const RoomThemeChanged(
        themeId: 'wallstreet_bull',
        uid: _kUid,
      )),
      expect: () => [
        isA<RoomThemeChangeSuccess>()
            .having((s) => s.themeId, 'themeId', 'wallstreet_bull'),
      ],
      verify: (_) => verify(() => repo.setActiveTheme(
            uid: _kUid,
            themeId: 'wallstreet_bull',
          )).called(1),
    );

    blocTest<RoomBloc, RoomState>(
      'emits RoomError when setActiveTheme throws',
      build: build,
      setUp: () {
        when(() => repo.setActiveTheme(
              uid: any(named: 'uid'),
              themeId: any(named: 'themeId'),
            )).thenThrow(StateError('Theme not owned'));
      },
      act: (bloc) => bloc.add(const RoomThemeChanged(
        themeId: 'wallstreet_vault',
        uid: _kUid,
      )),
      expect: () => [
        isA<RoomError>(),
      ],
    );
  });

  // ══════════════════════════════════════════════════════════════════════════
  // State equality
  // ══════════════════════════════════════════════════════════════════════════

  group('RoomState types', () {
    test('FriendRoomLoaded stores friendUid and items', () {
      const items = [
        RoomItem(
          itemId: 'desk_01',
          type: RoomItemType.furniture,
          assetKey: 'desk_01',
          slotX: 3,
          slotY: 2,
          isUnlocked: true,
        ),
      ];
      const state = FriendRoomLoaded('friend_01', items);
      expect(state.friendUid, 'friend_01');
      expect(state.items.length, 1);
    });

    test('RoomThemePurchaseSuccess stores themeId', () {
      const state = RoomThemePurchaseSuccess('wallstreet_floor');
      expect(state.themeId, 'wallstreet_floor');
    });

    test('RoomThemeChangeSuccess stores themeId', () {
      const state = RoomThemeChangeSuccess('penthouse');
      expect(state.themeId, 'penthouse');
    });

    test('RoomThemePurchaseFailure stores message', () {
      const state = RoomThemePurchaseFailure('Not enough coins');
      expect(state.message, 'Not enough coins');
    });
  });
}
