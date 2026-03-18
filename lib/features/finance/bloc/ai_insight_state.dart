import 'package:equatable/equatable.dart';
import 'package:aslan_pixel/features/finance/data/models/ai_insight_model.dart';

abstract class AiInsightState extends Equatable {
  const AiInsightState();

  @override
  List<Object?> get props => [];
}

class AiInsightInitial extends AiInsightState {
  const AiInsightInitial();
}

class AiInsightLoading extends AiInsightState {
  const AiInsightLoading();
}

class AiInsightLoaded extends AiInsightState {
  const AiInsightLoaded(this.insights);

  final List<AiInsightModel> insights;

  @override
  List<Object?> get props => [insights];
}

class AiInsightError extends AiInsightState {
  const AiInsightError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
