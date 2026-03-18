import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class PredictionEntryModel extends Equatable {
  const PredictionEntryModel({
    required this.entryId,
    required this.eventId,
    required this.uid,
    required this.selectedOptionId,
    required this.coinStaked,
    required this.enteredAt,
    this.result,
    required this.rewardGranted,
  });

  final String entryId;
  final String eventId;
  final String uid;
  final String selectedOptionId;
  final int coinStaked;
  final DateTime enteredAt;

  /// null while open, 'win' | 'loss' when settled
  final String? result;
  final int rewardGranted;

  factory PredictionEntryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PredictionEntryModel(
      entryId: doc.id,
      eventId: data['eventId'] as String,
      uid: data['uid'] as String,
      selectedOptionId: data['selectedOptionId'] as String,
      coinStaked: (data['coinStaked'] as num).toInt(),
      enteredAt: (data['enteredAt'] as Timestamp).toDate(),
      result: data['result'] as String?,
      rewardGranted: (data['rewardGranted'] as num? ?? 0).toInt(),
    );
  }

  Map<String, dynamic> toMap() => {
        'entryId': entryId,
        'eventId': eventId,
        'uid': uid,
        'selectedOptionId': selectedOptionId,
        'coinStaked': coinStaked,
        'enteredAt': Timestamp.fromDate(enteredAt),
        'result': result,
        'rewardGranted': rewardGranted,
      };

  @override
  List<Object?> get props => [
        entryId,
        eventId,
        uid,
        selectedOptionId,
        coinStaked,
        enteredAt,
        result,
        rewardGranted,
      ];
}
