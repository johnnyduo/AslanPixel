/// The operational status of a single agent inside the pixel world.
enum AgentStatus {
  /// Agent is idle in the room, awaiting a mission.
  idle,

  /// Agent is actively executing a mission.
  working,

  /// Agent has finished a mission and is returning to base.
  returning,

  /// Agent has just completed a successful mission and is celebrating.
  celebrating,

  /// Agent encountered an error / failed mission.
  fail,
}

extension AgentStatusLabel on AgentStatus {
  String get label {
    switch (this) {
      case AgentStatus.idle:
        return 'Idle';
      case AgentStatus.working:
        return 'Working';
      case AgentStatus.returning:
        return 'Returning';
      case AgentStatus.celebrating:
        return 'Celebrating';
      case AgentStatus.fail:
        return 'Failed';
    }
  }
}
