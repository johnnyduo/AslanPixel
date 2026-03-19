import 'package:flutter_test/flutter_test.dart';
import 'package:aslan_pixel/features/home/game/npc_quotes.dart';

void main() {
  const List<String> expectedNpcKeys = [
    'npc_banker',
    'npc_trader',
    'npc_champion',
    'npc_merchant',
    'npc_sysbot',
    'npc_pixelcat',
    'npc_analyst_senior',
    'npc_hacker',
    'npc_oracle',
    'npc_intern',
  ];

  group('kNpcQuotes map', () {
    test('has all 10 NPC keys', () {
      expect(kNpcQuotes.keys.toSet(), equals(expectedNpcKeys.toSet()));
      expect(kNpcQuotes.length, equals(10));
    });

    test('each NPC has at least 30 quotes', () {
      for (final key in expectedNpcKeys) {
        final quotes = kNpcQuotes[key];
        expect(quotes, isNotNull, reason: 'Key "$key" is missing from kNpcQuotes');
        expect(
          quotes!.length,
          greaterThanOrEqualTo(30),
          reason: '"$key" has only ${quotes.length} quotes (expected >= 30)',
        );
      }
    });

    test('each NPC has at least 30 non-empty TH quotes', () {
      for (final key in expectedNpcKeys) {
        final quotes = kNpcQuotes[key]!;
        final nonEmptyTh = quotes.where((q) => q.th.isNotEmpty).toList();
        expect(
          nonEmptyTh.length,
          greaterThanOrEqualTo(30),
          reason:
              '"$key" has only ${nonEmptyTh.length} non-empty TH quotes (expected >= 30)',
        );
      }
    });

    test('each NPC has at least 30 non-empty EN quotes', () {
      for (final key in expectedNpcKeys) {
        final quotes = kNpcQuotes[key]!;
        final nonEmptyEn = quotes.where((q) => q.en.isNotEmpty).toList();
        expect(
          nonEmptyEn.length,
          greaterThanOrEqualTo(30),
          reason:
              '"$key" has only ${nonEmptyEn.length} non-empty EN quotes (expected >= 30)',
        );
      }
    });

    test('no quote has an empty th string', () {
      for (final key in expectedNpcKeys) {
        final quotes = kNpcQuotes[key]!;
        for (var i = 0; i < quotes.length; i++) {
          expect(
            quotes[i].th.isNotEmpty,
            isTrue,
            reason: '"$key" index $i has an empty th string',
          );
        }
      }
    });

    test('no quote has an empty en string', () {
      for (final key in expectedNpcKeys) {
        final quotes = kNpcQuotes[key]!;
        for (var i = 0; i < quotes.length; i++) {
          expect(
            quotes[i].en.isNotEmpty,
            isTrue,
            reason: '"$key" index $i has an empty en string',
          );
        }
      }
    });

    test('all 10 NPCs quote lists are non-overlapping (separate list instances)', () {
      final lists = expectedNpcKeys.map((k) => kNpcQuotes[k]!).toList();
      for (var i = 0; i < lists.length; i++) {
        for (var j = i + 1; j < lists.length; j++) {
          expect(
            identical(lists[i], lists[j]),
            isFalse,
            reason:
                '"${expectedNpcKeys[i]}" and "${expectedNpcKeys[j]}" share the same list instance',
          );
        }
      }
    });
  });

  group('NpcQuotes.textOf', () {
    const testQuote = NpcQuote(th: 'ทดสอบภาษาไทย', en: 'English test text');

    tearDown(() {
      // Reset to default after each test.
      NpcQuotes.useEnglish = false;
    });

    test('returns quote.th when useEnglish is false', () {
      NpcQuotes.useEnglish = false;
      expect(NpcQuotes.textOf(testQuote), equals(testQuote.th));
    });

    test('returns quote.en when useEnglish is true', () {
      NpcQuotes.useEnglish = true;
      expect(NpcQuotes.textOf(testQuote), equals(testQuote.en));
    });
  });
}
