import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:aslan_pixel/features/notifications/bloc/notification_bloc.dart';
import 'package:aslan_pixel/features/notifications/data/models/notification_model.dart';
import '../../mocks/mock_repositories.dart';
import '../../mocks/test_fixtures.dart';

void main() {
  late MockNotificationRepository repo;

  setUp(() {
    repo = MockNotificationRepository();
  });

  NotificationBloc build() => NotificationBloc(repository: repo);

  group('NotificationBloc — initial state', () {
    test('initial state is NotificationInitial', () {
      expect(build().state, isA<NotificationInitial>());
    });
  });

  // ── NotificationWatchStarted ───────────────────────────────────────────────

  group('NotificationWatchStarted', () {
    blocTest<NotificationBloc, NotificationState>(
      'emits [Loading, Loaded] with notifications from stream',
      build: build,
      setUp: () {
        when(() => repo.watchNotifications('uid_01'))
            .thenAnswer((_) => Stream.value([kNotification()]));
      },
      act: (bloc) => bloc.add(const NotificationWatchStarted('uid_01')),
      expect: () => [
        isA<NotificationLoading>(),
        isA<NotificationLoaded>()
            .having((s) => s.notifications.length, 'count', 1),
      ],
      verify: (_) =>
          verify(() => repo.watchNotifications('uid_01')).called(1),
    );

    blocTest<NotificationBloc, NotificationState>(
      'emits [Loading, Loaded] with empty list when no notifications',
      build: build,
      setUp: () {
        when(() => repo.watchNotifications(any()))
            .thenAnswer((_) => Stream.value(<NotificationModel>[]));
      },
      act: (bloc) => bloc.add(const NotificationWatchStarted('uid_01')),
      expect: () => [
        isA<NotificationLoading>(),
        isA<NotificationLoaded>()
            .having((s) => s.notifications, 'notifications', isEmpty),
      ],
    );

    blocTest<NotificationBloc, NotificationState>(
      'emits [Loading, Error] when stream throws',
      build: build,
      setUp: () {
        when(() => repo.watchNotifications(any()))
            .thenAnswer((_) => Stream.error(Exception('Firestore error')));
      },
      act: (bloc) => bloc.add(const NotificationWatchStarted('uid_01')),
      expect: () => [isA<NotificationLoading>(), isA<NotificationError>()],
    );

    blocTest<NotificationBloc, NotificationState>(
      'unreadCount is correct on mixed read/unread',
      build: build,
      setUp: () {
        when(() => repo.watchNotifications(any())).thenAnswer(
          (_) => Stream.value([
            kNotification(isRead: false),
            kNotification(isRead: false),
            kNotification(isRead: true),
          ]),
        );
      },
      act: (bloc) => bloc.add(const NotificationWatchStarted('uid_01')),
      expect: () => [
        isA<NotificationLoading>(),
        isA<NotificationLoaded>()
            .having((s) => s.unreadCount, 'unreadCount', 2),
      ],
    );

    blocTest<NotificationBloc, NotificationState>(
      'unreadCount is 0 when all notifications are read',
      build: build,
      setUp: () {
        when(() => repo.watchNotifications(any())).thenAnswer(
          (_) => Stream.value([
            kNotification(isRead: true),
            kNotification(isRead: true),
          ]),
        );
      },
      act: (bloc) => bloc.add(const NotificationWatchStarted('uid_01')),
      expect: () => [
        isA<NotificationLoading>(),
        isA<NotificationLoaded>()
            .having((s) => s.unreadCount, 'unreadCount', 0),
      ],
    );

    blocTest<NotificationBloc, NotificationState>(
      'second call with same uid does not re-subscribe',
      build: build,
      setUp: () {
        when(() => repo.watchNotifications(any()))
            .thenAnswer((_) => Stream.value([kNotification()]));
      },
      act: (bloc) async {
        bloc.add(const NotificationWatchStarted('uid_01'));
        await Future.delayed(Duration.zero);
        bloc.add(const NotificationWatchStarted('uid_01'));
      },
      verify: (_) =>
          verify(() => repo.watchNotifications('uid_01')).called(1),
    );
  });

  // ── NotificationMarkedRead ─────────────────────────────────────────────────

  group('NotificationMarkedRead', () {
    blocTest<NotificationBloc, NotificationState>(
      'calls repository markAsRead with correct args',
      build: build,
      setUp: () {
        when(() => repo.watchNotifications(any()))
            .thenAnswer((_) => Stream.value([kNotification()]));
        when(() => repo.markAsRead(any(), any()))
            .thenAnswer((_) async {});
      },
      act: (bloc) async {
        bloc.add(const NotificationWatchStarted('uid_01'));
        await Future.delayed(Duration.zero);
        bloc.add(NotificationMarkedRead(
          notifId: kNotification().notifId,
          uid: 'uid_01',
        ));
      },
      verify: (_) => verify(
        () => repo.markAsRead('uid_01', kNotification().notifId),
      ).called(1),
    );

    blocTest<NotificationBloc, NotificationState>(
      'emits NotificationError when markAsRead throws',
      build: build,
      setUp: () {
        when(() => repo.watchNotifications(any()))
            .thenAnswer((_) => Stream.value([kNotification()]));
        when(() => repo.markAsRead(any(), any()))
            .thenThrow(Exception('mark read failed'));
      },
      act: (bloc) async {
        bloc.add(const NotificationWatchStarted('uid_01'));
        await Future.delayed(Duration.zero);
        bloc.add(NotificationMarkedRead(
          notifId: kNotification().notifId,
          uid: 'uid_01',
        ));
      },
      expect: () => [
        isA<NotificationLoading>(),
        isA<NotificationLoaded>(),
        isA<NotificationError>(),
      ],
    );
  });

  // ── NotificationAllMarkedRead ──────────────────────────────────────────────

  group('NotificationAllMarkedRead', () {
    blocTest<NotificationBloc, NotificationState>(
      'calls repository markAllAsRead with correct uid',
      build: build,
      setUp: () {
        when(() => repo.watchNotifications(any())).thenAnswer(
          (_) => Stream.value([
            kNotification(isRead: false),
            kNotification(isRead: false),
          ]),
        );
        when(() => repo.markAllAsRead(any())).thenAnswer((_) async {});
      },
      act: (bloc) async {
        bloc.add(const NotificationWatchStarted('uid_01'));
        await Future.delayed(Duration.zero);
        bloc.add(const NotificationAllMarkedRead('uid_01'));
      },
      verify: (_) =>
          verify(() => repo.markAllAsRead('uid_01')).called(1),
    );

    blocTest<NotificationBloc, NotificationState>(
      'emits NotificationError when markAllAsRead throws',
      build: build,
      setUp: () {
        when(() => repo.watchNotifications(any()))
            .thenAnswer((_) => Stream.value([kNotification()]));
        when(() => repo.markAllAsRead(any()))
            .thenThrow(Exception('mark all failed'));
      },
      act: (bloc) async {
        bloc.add(const NotificationWatchStarted('uid_01'));
        await Future.delayed(Duration.zero);
        bloc.add(const NotificationAllMarkedRead('uid_01'));
      },
      expect: () => [
        isA<NotificationLoading>(),
        isA<NotificationLoaded>(),
        isA<NotificationError>(),
      ],
    );
  });

  // ── State equality ─────────────────────────────────────────────────────────

  group('State equality', () {
    test('NotificationInitial == NotificationInitial', () {
      expect(const NotificationInitial(), equals(const NotificationInitial()));
    });

    test('NotificationLoading == NotificationLoading', () {
      expect(const NotificationLoading(), equals(const NotificationLoading()));
    });

    test('NotificationLoaded with same reference has same props', () {
      final notif = kNotification();
      final s1 = NotificationLoaded([notif], 1);
      final s2 = NotificationLoaded([notif], 1);
      expect(s1.notifications, equals(s2.notifications));
      expect(s1.unreadCount, equals(s2.unreadCount));
    });

    test('NotificationError with same message are equal', () {
      expect(
        const NotificationError('error'),
        equals(const NotificationError('error')),
      );
    });
  });
}
