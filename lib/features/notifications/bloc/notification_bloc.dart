import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:aslan_pixel/features/notifications/data/models/notification_model.dart';
import 'package:aslan_pixel/features/notifications/data/repositories/notification_repository.dart';

part 'notification_event.dart';
part 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  NotificationBloc({required NotificationRepository repository})
      : _repository = repository,
        super(const NotificationInitial()) {
    on<NotificationWatchStarted>(_onWatchStarted);
    on<NotificationMarkedRead>(_onMarkedRead);
    on<NotificationAllMarkedRead>(_onAllMarkedRead);
  }

  final NotificationRepository _repository;
  String? _watchedUid;

  Future<void> _onWatchStarted(
    NotificationWatchStarted event,
    Emitter<NotificationState> emit,
  ) async {
    if (_watchedUid == event.uid) return;

    _watchedUid = event.uid;
    emit(const NotificationLoading());

    await emit.forEach<List<NotificationModel>>(
      _repository.watchNotifications(event.uid),
      onData: (notifications) {
        final unread = notifications.where((n) => !n.isRead).length;
        return NotificationLoaded(notifications, unread);
      },
      onError: (error, _) => NotificationError(error.toString()),
    );
  }

  Future<void> _onMarkedRead(
    NotificationMarkedRead event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await _repository.markAsRead(event.uid, event.notifId);
    } catch (e) {
      emit(NotificationError(e.toString()));
    }
  }

  Future<void> _onAllMarkedRead(
    NotificationAllMarkedRead event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await _repository.markAllAsRead(event.uid);
    } catch (e) {
      emit(NotificationError(e.toString()));
    }
  }
}
