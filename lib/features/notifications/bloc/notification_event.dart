part of 'notification_bloc.dart';

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object?> get props => [];
}

class NotificationWatchStarted extends NotificationEvent {
  const NotificationWatchStarted(this.uid);

  final String uid;

  @override
  List<Object?> get props => [uid];
}

class NotificationMarkedRead extends NotificationEvent {
  const NotificationMarkedRead({
    required this.notifId,
    required this.uid,
  });

  final String notifId;
  final String uid;

  @override
  List<Object?> get props => [notifId, uid];
}

class NotificationAllMarkedRead extends NotificationEvent {
  const NotificationAllMarkedRead(this.uid);

  final String uid;

  @override
  List<Object?> get props => [uid];
}
