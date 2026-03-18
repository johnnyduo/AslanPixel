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
