import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:aslan_pixel/core/config/env_config.dart';
import 'package:aslan_pixel/core/enums/agent_type.dart';
import 'package:aslan_pixel/data/services/ai_service.dart';

/// Concrete [AIService] implementation backed by the Google Generative AI SDK.
///
/// Two Gemini models are used:
///   • `gemini-2.0-flash-lite` — short text & agent dialogue (cost-optimised)
///   • `gemini-2.0-flash`      — market summaries & deep analysis
///
/// Deep analysis is routed to Flash for MVP.
/// TODO: Phase production — route to Claude Sonnet via Anthropic API.
class GeminiAiService implements AIService {
  GeminiAiService() {
    final apiKey = EnvConfig.geminiApiKey;
    _flashLite = GenerativeModel(
      model: 'gemini-2.0-flash-lite',
      apiKey: apiKey,
    );
    _flash = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: apiKey,
    );
  }

  late final GenerativeModel _flashLite;
  late final GenerativeModel _flash;

  // ---------------------------------------------------------------------------
  // generateShortText
  // ---------------------------------------------------------------------------

  @override
  Future<String> generateShortText({
    required String prompt,
    int maxTokens = 200,
  }) async {
    try {
      final response = await _flashLite.generateContent([
        Content.text(prompt),
      ]);
      return response.text ?? '';
    } catch (e) {
      debugPrint('[GeminiAiService] generateShortText error: $e');
      return '';
    }
  }

  // ---------------------------------------------------------------------------
  // generateMarketSummary
  // ---------------------------------------------------------------------------

  @override
  Future<String> generateMarketSummary({
    required String symbols,
    required String context,
    int maxTokens = 500,
  }) async {
    final prompt = '''
สรุปภาวะตลาดสั้นๆ ในภาษาไทย (ไม่เกิน 3 ประโยค) สำหรับ: $symbols
บริบท: $context
หมายเหตุ: ข้อมูลนี้เพื่อการศึกษาเท่านั้น ไม่ใช่คำแนะนำการลงทุน''';
    try {
      final response = await _flash.generateContent([Content.text(prompt)]);
      return response.text ?? '';
    } catch (e) {
      debugPrint('[GeminiAiService] generateMarketSummary error: $e');
      return '';
    }
  }

  // ---------------------------------------------------------------------------
  // generateDeepAnalysis
  // ---------------------------------------------------------------------------

  @override
  Future<String> generateDeepAnalysis({
    required String prompt,
    int maxTokens = 1000,
  }) async {
    // Deep analysis also uses Flash for MVP — Claude Sonnet via API key needed in production.
    // TODO: Phase production — route to Claude Sonnet via Anthropic API.
    try {
      final response = await _flash.generateContent([Content.text(prompt)]);
      return response.text ?? '';
    } catch (e) {
      debugPrint('[GeminiAiService] generateDeepAnalysis error: $e');
      return '';
    }
  }

  // ---------------------------------------------------------------------------
  // generateAgentDialogue
  // ---------------------------------------------------------------------------

  @override
  Future<String> generateAgentDialogue({
    required AgentType agentType,
    required String agentStatus,
    required String context,
  }) async {
    final agentName = agentType.displayName;
    final prompt = '''
สร้างบทพูดสั้นๆ (ไม่เกิน 60 ตัวอักษร) ในภาษาไทยสำหรับ Agent "$agentName"
สถานะ: $agentStatus
บริบท: $context
ใช้ emoji 1 ตัวสูงสุด ให้ดูน่ารักและมีเสน่ห์''';
    try {
      final response = await _flashLite.generateContent([Content.text(prompt)]);
      return response.text?.trim() ?? '$agentName พร้อมทำงาน!';
    } catch (e) {
      return '$agentName พร้อมทำงาน!';
    }
  }
}
