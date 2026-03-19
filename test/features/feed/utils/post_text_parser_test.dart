import 'package:aslan_pixel/features/feed/utils/post_text_parser.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Colour constants matching the source file.
  const neonGreen = Color(0xFF00F5A0);
  const cyan = Color(0xFF00D9FF);
  const textWhite70 = Color(0xB3E8F4F8);

  group('buildRichPostText', () {
    test('plain text returns TextSpan with white70 color', () {
      final span = buildRichPostText('Hello world');
      // May be a direct TextSpan or wrapped in children depending on engine
      if (span.children != null && span.children!.isNotEmpty) {
        // All children should be plain white70
        for (final child in span.children!.cast<TextSpan>()) {
          expect(child.style?.color, textWhite70);
        }
        final combinedText =
            span.children!.cast<TextSpan>().map((s) => s.text).join();
        expect(combinedText, 'Hello world');
      } else {
        expect(span.text, 'Hello world');
        expect(span.style?.color, textWhite70);
      }
    });

    test('empty string returns single TextSpan', () {
      final span = buildRichPostText('');
      expect(span.children, isNull);
      expect(span.text, '');
      expect(span.style?.color, textWhite70);
    });

    test('hashtag is neon-green and bold', () {
      final span = buildRichPostText('#hashtag');
      // Single token → wrapped in children list
      expect(span.children, isNotNull);
      expect(span.children!.length, 1);
      final child = span.children!.first as TextSpan;
      expect(child.text, '#hashtag');
      expect(child.style?.color, neonGreen);
      expect(child.style?.fontWeight, FontWeight.bold);
    });

    test('mention is cyan and normal weight', () {
      final span = buildRichPostText('@mention');
      expect(span.children, isNotNull);
      expect(span.children!.length, 1);
      final child = span.children!.first as TextSpan;
      expect(child.text, '@mention');
      expect(child.style?.color, cyan);
      expect(child.style?.fontWeight, FontWeight.normal);
    });

    test('mixed text produces correct spans', () {
      final span = buildRichPostText('Hello #crypto @trader world');
      expect(span.children, isNotNull);
      final children = span.children!.cast<TextSpan>();
      expect(children.length, 5);

      // 'Hello '
      expect(children[0].text, 'Hello ');
      expect(children[0].style?.color, textWhite70);

      // '#crypto'
      expect(children[1].text, '#crypto');
      expect(children[1].style?.color, neonGreen);
      expect(children[1].style?.fontWeight, FontWeight.bold);

      // ' '
      expect(children[2].text, ' ');
      expect(children[2].style?.color, textWhite70);

      // '@trader'
      expect(children[3].text, '@trader');
      expect(children[3].style?.color, cyan);
      expect(children[3].style?.fontWeight, FontWeight.normal);

      // ' world'
      expect(children[4].text, ' world');
      expect(children[4].style?.color, textWhite70);
    });

    test('multiple hashtags are correctly parsed', () {
      final span = buildRichPostText('#btc #eth');
      expect(span.children, isNotNull);
      final children = span.children!.cast<TextSpan>();
      expect(children.length, 3);

      expect(children[0].text, '#btc');
      expect(children[0].style?.color, neonGreen);
      expect(children[0].style?.fontWeight, FontWeight.bold);

      expect(children[1].text, ' ');
      expect(children[1].style?.color, textWhite70);

      expect(children[2].text, '#eth');
      expect(children[2].style?.color, neonGreen);
      expect(children[2].style?.fontWeight, FontWeight.bold);
    });

    test('text ending with hashtag has no trailing plain span', () {
      final span = buildRichPostText('check #this');
      expect(span.children, isNotNull);
      final children = span.children!.cast<TextSpan>();
      expect(children.length, 2);
      expect(children[0].text, 'check ');
      expect(children[1].text, '#this');
    });

    test('text starting with mention has no leading plain span', () {
      final span = buildRichPostText('@user hello');
      expect(span.children, isNotNull);
      final children = span.children!.cast<TextSpan>();
      expect(children.length, 2);
      expect(children[0].text, '@user');
      expect(children[0].style?.color, cyan);
      expect(children[1].text, ' hello');
      expect(children[1].style?.color, textWhite70);
    });
  });
}
