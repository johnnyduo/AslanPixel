import 'package:equatable/equatable.dart';

abstract class AiInsightEvent extends Equatable {
  const AiInsightEvent();

  @override
  List<Object?> get props => [];
}

/// Request a fresh or cached insight of [type] for [uid] using [context].
class AiInsightRequested extends AiInsightEvent {
  const AiInsightRequested({
    required this.uid,
    required this.type,
    required this.context,
  });

  final String uid;
  final String type;
  final String context;

  @override
  List<Object?> get props => [uid, type, context];
}

/// Start watching all insights for [uid] in real-time.
class AiInsightWatchStarted extends AiInsightEvent {
  const AiInsightWatchStarted(this.uid);

  final String uid;

  @override
  List<Object?> get props => [uid];
}
