/// The 4 agent types available in Aslan Pixel.
enum AgentType { analyst, scout, risk, social }

extension AgentTypeValue on AgentType {
  String get value {
    switch (this) {
      case AgentType.analyst:
        return 'analyst';
      case AgentType.scout:
        return 'scout';
      case AgentType.risk:
        return 'risk';
      case AgentType.social:
        return 'social';
    }
  }

  String get displayName {
    switch (this) {
      case AgentType.analyst:
        return 'Analyst';
      case AgentType.scout:
        return 'Scout';
      case AgentType.risk:
        return 'Risk';
      case AgentType.social:
        return 'Social';
    }
  }

  static AgentType fromString(String? value) {
    switch (value) {
      case 'scout':
        return AgentType.scout;
      case 'risk':
        return AgentType.risk;
      case 'social':
        return AgentType.social;
      default:
        return AgentType.analyst;
    }
  }
}
