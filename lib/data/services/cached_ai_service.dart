import 'package:aslan_pixel/core/enums/agent_type.dart';
import 'package:aslan_pixel/data/services/ai_service.dart';

/// Decorator that wraps an [AIService] with in-memory TTL caching.
///
/// Cache key = method name + first 50 characters of the primary prompt.
/// Default [ttl] is 30 minutes; individual methods may override this.
class CachedAiService implements AIService {
  CachedAiService(this._inner, {this.ttl = const Duration(minutes: 30)});

  final AIService _inner;
  final Duration ttl;
  final Map<String, _CacheEntry> _cache = {};

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _key(String method, String prompt) =>
      '$method:${prompt.length > 50 ? prompt.substring(0, 50) : prompt}';

  String? _get(String key) {
    final entry = _cache[key];
    if (entry == null) return null;
    if (DateTime.now().isAfter(entry.expiresAt)) {
      _cache.remove(key);
      return null;
    }
    return entry.value;
  }

  void _put(String key, String value, Duration entryTtl) {
    _cache[key] = _CacheEntry(
      value: value,
      expiresAt: DateTime.now().add(entryTtl),
    );
  }

  // ---------------------------------------------------------------------------
  // generateShortText — TTL 30 min
  // ---------------------------------------------------------------------------

  @override
  Future<String> generateShortText({
    required String prompt,
    int maxTokens = 200,
  }) async {
    final key = _key('generateShortText', prompt);
    final cached = _get(key);
    if (cached != null) return cached;
    final result = await _inner.generateShortText(
      prompt: prompt,
      maxTokens: maxTokens,
    );
    if (result.isNotEmpty) _put(key, result, ttl);
    return result;
  }

  // ---------------------------------------------------------------------------
  // generateMarketSummary — TTL 30 min
  // ---------------------------------------------------------------------------

  @override
  Future<String> generateMarketSummary({
    required String symbols,
    required String context,
    int maxTokens = 500,
  }) async {
    final key = _key('generateMarketSummary', '$symbols:$context');
    final cached = _get(key);
    if (cached != null) return cached;
    final result = await _inner.generateMarketSummary(
      symbols: symbols,
      context: context,
      maxTokens: maxTokens,
    );
    if (result.isNotEmpty) _put(key, result, ttl);
    return result;
  }

  // ---------------------------------------------------------------------------
  // generateDeepAnalysis — TTL 60 min
  // ---------------------------------------------------------------------------

  @override
  Future<String> generateDeepAnalysis({
    required String prompt,
    int maxTokens = 1000,
  }) async {
    final key = _key('generateDeepAnalysis', prompt);
    final cached = _get(key);
    if (cached != null) return cached;
    final result = await _inner.generateDeepAnalysis(
      prompt: prompt,
      maxTokens: maxTokens,
    );
    if (result.isNotEmpty) _put(key, result, const Duration(minutes: 60));
    return result;
  }

  // ---------------------------------------------------------------------------
  // generateAgentDialogue — TTL 5 min
  // ---------------------------------------------------------------------------

  @override
  Future<String> generateAgentDialogue({
    required AgentType agentType,
    required String agentStatus,
    required String context,
  }) async {
    final key =
        _key('generateAgentDialogue', '${agentType.value}:$agentStatus:$context');
    final cached = _get(key);
    if (cached != null) return cached;
    final result = await _inner.generateAgentDialogue(
      agentType: agentType,
      agentStatus: agentStatus,
      context: context,
    );
    if (result.isNotEmpty) _put(key, result, const Duration(minutes: 5));
    return result;
  }
}

// ---------------------------------------------------------------------------
// Internal cache entry
// ---------------------------------------------------------------------------

class _CacheEntry {
  const _CacheEntry({required this.value, required this.expiresAt});

  final String value;
  final DateTime expiresAt;
}
