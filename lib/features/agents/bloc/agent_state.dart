part of 'agent_bloc.dart';

abstract class AgentState extends Equatable {
  const AgentState();

  @override
  List<Object?> get props => [];
}

class AgentInitial extends AgentState {
  const AgentInitial();
}

class AgentLoading extends AgentState {
  const AgentLoading();
}

class AgentLoaded extends AgentState {
  const AgentLoaded(this.agents);

  final List<AgentModel> agents;

  @override
  List<Object?> get props => [agents];
}

class AgentError extends AgentState {
  const AgentError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class AgentLevelUpSuccess extends AgentState {
  const AgentLevelUpSuccess(this.agentId);

  final String agentId;

  @override
  List<Object?> get props => [agentId];
}

class AgentPurchaseSuccess extends AgentState {
  const AgentPurchaseSuccess(this.agentType);

  final AgentType agentType;

  @override
  List<Object?> get props => [agentType];
}

class AgentPurchaseError extends AgentState {
  const AgentPurchaseError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
