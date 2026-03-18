import 'package:flutter/material.dart';

// ── Colour constants ──────────────────────────────────────────────────────────
const Color _neonGreen = Color(0xFF00F5A0);
const Color _cyan = Color(0xFF00D9FF);
const Color _textWhite70 = Color(0xB3E8F4F8); // E8F4F8 at ~70% opacity

/// Parses a post body string and returns a styled [TextSpan] tree.
///
/// Rules applied in one pass (regex alternation keeps ordering):
/// - `#hashtag` → neon-green, bold
/// - `@mention` → cyan, normal weight
/// - Everything else → white-70
TextSpan buildRichPostText(String text) {
  // Matches either a hashtag token or a mention token.
  final pattern = RegExp(r'(#\w+|@\w+)');
  final spans = <TextSpan>[];

  int cursor = 0;
  for (final match in pattern.allMatches(text)) {
    // Plain text segment before this token.
    if (match.start > cursor) {
      spans.add(
        TextSpan(
          text: text.substring(cursor, match.start),
          style: const TextStyle(color: _textWhite70),
        ),
      );
    }

    final token = match.group(0)!;
    final isHashtag = token.startsWith('#');
    spans.add(
      TextSpan(
        text: token,
        style: TextStyle(
          color: isHashtag ? _neonGreen : _cyan,
          fontWeight: isHashtag ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );

    cursor = match.end;
  }

  // Remaining plain text after the last token.
  if (cursor < text.length) {
    spans.add(
      TextSpan(
        text: text.substring(cursor),
        style: const TextStyle(color: _textWhite70),
      ),
    );
  }

  // If there were no tokens at all just return plain text in one span.
  if (spans.isEmpty) {
    return TextSpan(
      text: text,
      style: const TextStyle(color: _textWhite70),
    );
  }

  return TextSpan(children: spans);
}
