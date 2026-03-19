import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Centralised Firebase Analytics wrapper for Aslan Pixel.
///
/// All custom event names follow snake_case and stay under the
/// 40-character Firebase limit. Parameter values are kept short to
/// avoid truncation (max 100 chars).
///
/// All log methods are fire-and-forget safe — they swallow errors so
/// analytics failures never crash the app or break unit tests.
class AnalyticsService {
  AnalyticsService._();

  static FirebaseAnalytics? _analytics;

  static FirebaseAnalytics get _instance {
    _analytics ??= FirebaseAnalytics.instance;
    return _analytics!;
  }

  /// Navigation observer — attach to MaterialApp / GoRouter.
  static FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _instance);

  /// Safe wrapper — swallows errors so analytics never crashes the app.
  static Future<void> _log(String name, Map<String, Object>? params) async {
    try {
      await _instance.logEvent(name: name, parameters: params);
    } catch (e) {
      debugPrint('[Analytics] $name failed: $e');
    }
  }

  // ── Onboarding ──────────────────────────────────────────────────────────

  static Future<void> logOnboardingComplete({
    required String avatarId,
    required String marketFocus,
    required String riskStyle,
  }) =>
      _log('onboarding_complete', {
        'avatar_id': avatarId,
        'market_focus': marketFocus,
        'risk_style': riskStyle,
      });

  // ── Quests ──────────────────────────────────────────────────────────────

  static Future<void> logQuestComplete({
    required String questId,
    required String actionType,
  }) =>
      _log('quest_complete', {
        'quest_id': questId,
        'action_type': actionType,
      });

  // ── Predictions ─────────────────────────────────────────────────────────

  static Future<void> logPredictionEntered({
    required String eventId,
    required String optionId,
    required int coinStaked,
  }) =>
      _log('prediction_entered', {
        'event_id': eventId,
        'option_id': optionId,
        'coin_staked': coinStaked,
      });

  // ── Broker ──────────────────────────────────────────────────────────────

  static Future<void> logBrokerConnected({
    required String connectorId,
  }) =>
      _log('broker_connected', {'connector_id': connectorId});

  static Future<void> logOrderSubmitted({
    required String symbol,
    required String side,
    required double lots,
  }) =>
      _log('order_submitted', {
        'symbol': symbol,
        'side': side,
        'lots': lots,
      });

  // ── Agents ──────────────────────────────────────────────────────────────

  static Future<void> logAgentTaskStarted({
    required String agentType,
    required String taskType,
    required String tier,
  }) =>
      _log('agent_task_started', {
        'agent_type': agentType,
        'task_type': taskType,
        'tier': tier,
      });

  // ── Pixel Art ───────────────────────────────────────────────────────────

  static Future<void> logPixelArtExported({
    required String canvasId,
  }) =>
      _log('pixel_art_exported', {'canvas_id': canvasId});
}
