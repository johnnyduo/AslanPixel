import 'package:aslan_pixel/core/enums/agent_type.dart';

/// Abstract AI service used across Aslan Pixel features.
///
/// Three tiers of model quality are exposed:
///   • Flash-Lite  — cheap, high-volume short text
///   • Flash       — balanced market/summary generation
///   • Deep        — high-quality reasoning (Claude Sonnet in production)
abstract class AIService {
  /// Generate short text (quest dialogue, NPC flavour, feed captions).
  /// Uses Gemini Flash-Lite (cheap, high volume).
  Future<String> generateShortText({
    required String prompt,
    int maxTokens = 200,
  });

  /// Generate market summary or prediction context.
  /// Uses Gemini Flash (balanced).
  Future<String> generateMarketSummary({
    required String symbols,
    required String context,
    int maxTokens = 500,
  });

  /// Generate deep portfolio explanation or post-trade analysis.
  /// Uses Claude Sonnet (reasoning quality).
  Future<String> generateDeepAnalysis({
    required String prompt,
    int maxTokens = 1000,
  });

  /// Generate agent dialogue line for a given state.
  Future<String> generateAgentDialogue({
    required AgentType agentType,
    required String agentStatus,
    required String context,
  });
}
