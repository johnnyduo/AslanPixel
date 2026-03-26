import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:aslan_pixel/features/home/bloc/room_bloc.dart';
import 'package:aslan_pixel/features/home/bloc/room_event.dart';
import 'package:aslan_pixel/features/home/bloc/room_state.dart';
import 'package:aslan_pixel/features/home/data/models/room_item_model.dart';
import 'package:aslan_pixel/features/home/data/repositories/room_repository.dart';
import 'package:aslan_pixel/features/home/data/room_theme_shop.dart';

// ── Mock ─────────────────────────────────────────────────────────────────────

class MockRoomRepository extends Mock implements RoomRepository {}

class FakeRoomModel extends Fake implements RoomModel {}

class FakeRoomItem extends Fake implements RoomItem {}

// ── Helpers ──────────────────────────────────────────────────────────────────

const _kUid = 'test_uid';

void main() {
  setUpAll(() {
    registerFallbackValue(FakeRoomModel());
    registerFallbackValue(FakeRoomItem());
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Room Theme Catalog tests
  // ══════════════════════════════════════════════════════════════════════════

  group('kRoomThemes catalog', () {
    test('contains exactly 12 themes (matching PNG files)', () {
      expect(kRoomThemes.length, equals(12));
    });

    test('starter theme is free (price == 0)', () {
      final starter =
          kRoomThemes.firstWhere((t) => t.themeId == 'starter');
      expect(starter.price, equals(0));
      expect(starter.unlockLevel, equals(1));
    });

    test('all themes have valid previewAsset paths', () {
      for (final theme in kRoomThemes) {
        expect(
          theme.previewAsset,
          startsWith('assets/sprites/room_backgrounds/'),
          reason: '${theme.themeId} preview path must be under room_backgrounds',
        );
        expect(
          theme.previewAsset,
          endsWith('.png'),
          reason: '${theme.themeId} preview must be a PNG',
        );
      }
    });

    test('all themes have non-empty backgroundAsset', () {
      for (final theme in kRoomThemes) {
        expect(theme.backgroundAsset, isNotEmpty,
            reason: '${theme.themeId} backgroundAsset must not be empty');
        expect(theme.backgroundAsset, endsWith('.png'),
            reason: '${theme.themeId} backgroundAsset must end with .png');
      }
    });

    test('unlock levels are in non-decreasing order', () {
      for (var i = 1; i < kRoomThemes.length; i++) {
        expect(
          kRoomThemes[i].unlockLevel,
          greaterThanOrEqualTo(kRoomThemes[i - 1].unlockLevel),
          reason:
              '${kRoomThemes[i].themeId} (Lv ${kRoomThemes[i].unlockLevel}) '
              'should be >= ${kRoomThemes[i - 1].themeId} '
              '(Lv ${kRoomThemes[i - 1].unlockLevel})',
        );
      }
    });

    test('no duplicate themeIds', () {
      final ids = kRoomThemes.map((t) => t.themeId).toList();
      expect(ids.toSet().length, equals(ids.length),
          reason: 'All themeIds must be unique');
    });

    test('all themes have non-empty names and emoji', () {
      for (final theme in kRoomThemes) {
        expect(theme.nameTh, isNotEmpty);
        expect(theme.nameEn, isNotEmpty);
        expect(theme.descriptionTh, isNotEmpty);
        expect(theme.emoji, isNotEmpty);
      }
    });

    test('prices are non-negative', () {
      for (final theme in kRoomThemes) {
        expect(theme.price, greaterThanOrEqualTo(0),
            reason: '${theme.themeId} price must be >= 0');
      }
    });

    test('all 12 expected theme IDs are present', () {
      final expectedIds = {
        'starter',
        'office',
        'penthouse',
        'wallstreet_bull',
        'wallstreet_bear',
        'wallstreet_crypto',
        'wallstreet_floor',
        'wallstreet_hedge_fund',
        'wallstreet_news',
        'wallstreet_penthouse_nyc',
        'wallstreet_rooftop',
        'wallstreet_vault',
      };
      final actualIds = kRoomThemes.map((t) => t.themeId).toSet();
      expect(actualIds, equals(expectedIds));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // RoomBloc theme purchase/change tests
  // ══════════════════════════════════════════════════════════════════════════

  group('RoomBloc — theme purchase', () {
    late MockRoomRepository repo;

    setUp(() {
      repo = MockRoomRepository();
    });

    RoomBloc build() => RoomBloc(repository: repo);

    blocTest<RoomBloc, RoomState>(
      'emits RoomThemePurchaseSuccess on successful purchase',
      build: build,
      setUp: () {
        when(() => repo.purchaseTheme(
              uid: _kUid,
              themeId: 'office',
              price: 300,
            )).thenAnswer((_) async {});
      },
      act: (bloc) => bloc.add(const RoomThemePurchaseRequested(
        themeId: 'office',
        uid: _kUid,
        price: 300,
      )),
      expect: () => [
        isA<RoomThemePurchaseSuccess>()
            .having((s) => s.themeId, 'themeId', 'office'),
      ],
      verify: (_) {
        verify(() => repo.purchaseTheme(
              uid: _kUid,
              themeId: 'office',
              price: 300,
            )).called(1);
      },
    );

    blocTest<RoomBloc, RoomState>(
      'emits RoomThemePurchaseFailure when purchase throws',
      build: build,
      setUp: () {
        when(() => repo.purchaseTheme(
              uid: _kUid,
              themeId: 'penthouse',
              price: 1000,
            )).thenThrow(Exception('InsufficientCoins'));
      },
      act: (bloc) => bloc.add(const RoomThemePurchaseRequested(
        themeId: 'penthouse',
        uid: _kUid,
        price: 1000,
      )),
      expect: () => [isA<RoomThemePurchaseFailure>()],
    );
  });

  group('RoomBloc — theme change', () {
    late MockRoomRepository repo;

    setUp(() {
      repo = MockRoomRepository();
    });

    RoomBloc build() => RoomBloc(repository: repo);

    blocTest<RoomBloc, RoomState>(
      'emits RoomThemeChangeSuccess on successful change',
      build: build,
      setUp: () {
        when(() => repo.setActiveTheme(uid: _kUid, themeId: 'office'))
            .thenAnswer((_) async {});
      },
      act: (bloc) => bloc.add(const RoomThemeChanged(
        themeId: 'office',
        uid: _kUid,
      )),
      expect: () => [
        isA<RoomThemeChangeSuccess>()
            .having((s) => s.themeId, 'themeId', 'office'),
      ],
    );

    blocTest<RoomBloc, RoomState>(
      'emits RoomError when setActiveTheme throws (theme not owned)',
      build: build,
      setUp: () {
        when(() => repo.setActiveTheme(uid: _kUid, themeId: 'vault'))
            .thenThrow(StateError('not owned'));
      },
      act: (bloc) => bloc.add(const RoomThemeChanged(
        themeId: 'vault',
        uid: _kUid,
      )),
      expect: () => [isA<RoomError>()],
    );
  });
}
