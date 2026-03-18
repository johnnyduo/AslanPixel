import 'package:cloud_firestore/cloud_firestore.dart';

/// A single user notification record.
///
/// [type] values: `quest_complete`, `prediction_settled`, `agent_returned`,
/// `social`, `system`.
class NotificationModel {
  const NotificationModel({
    required this.notifId,
    required this.type,
    required this.title,
    required this.titleTh,
    required this.body,
    required this.bodyTh,
    required this.isRead,
    required this.createdAt,
  });

  final String notifId;
  final String type;
  final String title;
  final String titleTh;
  final String body;
  final String bodyTh;
  final bool isRead;
  final DateTime createdAt;

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return NotificationModel(
      notifId: doc.id,
      type: data['type'] as String? ?? 'system',
      title: data['title'] as String? ?? '',
      titleTh: data['titleTh'] as String? ?? '',
      body: data['body'] as String? ?? '',
      bodyTh: data['bodyTh'] as String? ?? '',
      isRead: data['isRead'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'notifId': notifId,
        'type': type,
        'title': title,
        'titleTh': titleTh,
        'body': body,
        'bodyTh': bodyTh,
        'isRead': isRead,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  NotificationModel copyWith({
    String? notifId,
    String? type,
    String? title,
    String? titleTh,
    String? body,
    String? bodyTh,
    bool? isRead,
    DateTime? createdAt,
  }) =>
      NotificationModel(
        notifId: notifId ?? this.notifId,
        type: type ?? this.type,
        title: title ?? this.title,
        titleTh: titleTh ?? this.titleTh,
        body: body ?? this.body,
        bodyTh: bodyTh ?? this.bodyTh,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt ?? this.createdAt,
      );
}
