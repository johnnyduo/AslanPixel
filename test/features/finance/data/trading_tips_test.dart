import 'package:aslan_pixel/features/finance/data/trading_tips.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TradingTips', () {
    test('kTradingTips has 30 tips', () {
      expect(kTradingTips.length, 30);
    });

    test('all tips have non-empty textTh, textEn, author', () {
      for (var i = 0; i < kTradingTips.length; i++) {
        final tip = kTradingTips[i];
        expect(tip.textTh.isNotEmpty, isTrue,
            reason: 'Tip $i has empty textTh');
        expect(tip.textEn.isNotEmpty, isTrue,
            reason: 'Tip $i has empty textEn');
        expect(tip.author.isNotEmpty, isTrue,
            reason: 'Tip $i has empty author');
      }
    });

    test('no duplicate tips', () {
      final englishTexts = kTradingTips.map((t) => t.textEn).toSet();
      expect(englishTexts.length, kTradingTips.length,
          reason: 'Found duplicate English texts');

      final thaiTexts = kTradingTips.map((t) => t.textTh).toSet();
      expect(thaiTexts.length, kTradingTips.length,
          reason: 'Found duplicate Thai texts');
    });
  });
}
