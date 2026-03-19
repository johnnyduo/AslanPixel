import 'package:aslan_pixel/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validators', () {
    // ── validateEmail ─────────────────────────────────────────────────────────
    group('validateEmail', () {
      test('returns error when null', () {
        expect(
          Validators.validateEmail(null),
          'กรุณากรอกอีเมล',
        );
      });

      test('returns error when empty string', () {
        expect(
          Validators.validateEmail(''),
          'กรุณากรอกอีเมล',
        );
      });

      test('returns error when whitespace only', () {
        expect(
          Validators.validateEmail('   '),
          'กรุณากรอกอีเมล',
        );
      });

      test('returns format error for invalid email', () {
        expect(
          Validators.validateEmail('invalid'),
          'รูปแบบอีเมลไม่ถูกต้อง',
        );
      });

      test('returns format error for email without domain', () {
        expect(
          Validators.validateEmail('user@'),
          'รูปแบบอีเมลไม่ถูกต้อง',
        );
      });

      test('returns null for valid email', () {
        expect(Validators.validateEmail('test@example.com'), isNull);
      });

      test('returns null for email with plus tag and .co.th TLD', () {
        expect(Validators.validateEmail('user+tag@domain.co.th'), isNull);
      });

      test('returns null for email with dots and hyphens', () {
        expect(Validators.validateEmail('first.last@sub-domain.org'), isNull);
      });
    });

    // ── validatePassword ──────────────────────────────────────────────────────
    group('validatePassword', () {
      test('returns error when null', () {
        expect(
          Validators.validatePassword(null),
          'กรุณากรอกรหัสผ่าน',
        );
      });

      test('returns error when empty', () {
        expect(
          Validators.validatePassword(''),
          'กรุณากรอกรหัสผ่าน',
        );
      });

      test('returns length error when fewer than 8 characters', () {
        expect(
          Validators.validatePassword('short1'),
          'รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร',
        );
      });

      test('returns digit error when no digits present', () {
        expect(
          Validators.validatePassword('nodigitshere'),
          'รหัสผ่านต้องมีตัวเลขอย่างน้อย 1 ตัว',
        );
      });

      test('returns null for valid password with digit', () {
        expect(Validators.validatePassword('password1'), isNull);
      });

      test('returns null for long password with multiple digits', () {
        expect(Validators.validatePassword('securePass123'), isNull);
      });
    });

    // ── validateDisplayName ───────────────────────────────────────────────────
    group('validateDisplayName', () {
      test('returns error when null', () {
        expect(
          Validators.validateDisplayName(null),
          'กรุณากรอกชื่อที่แสดง',
        );
      });

      test('returns error when empty', () {
        expect(
          Validators.validateDisplayName(''),
          'กรุณากรอกชื่อที่แสดง',
        );
      });

      test('returns error when whitespace only', () {
        expect(
          Validators.validateDisplayName('   '),
          'กรุณากรอกชื่อที่แสดง',
        );
      });

      test('returns min-length error for single character', () {
        expect(
          Validators.validateDisplayName('A'),
          'ชื่อต้องมีอย่างน้อย 2 ตัวอักษร',
        );
      });

      test('returns max-length error for 31-char string', () {
        final longName = 'A' * 31;
        expect(
          Validators.validateDisplayName(longName),
          'ชื่อต้องไม่เกิน 30 ตัวอักษร',
        );
      });

      test('returns null for valid Thai name', () {
        expect(Validators.validateDisplayName('สมชาย'), isNull);
      });

      test('returns null for exactly 2 characters', () {
        expect(Validators.validateDisplayName('AB'), isNull);
      });

      test('returns null for exactly 30 characters', () {
        final name30 = 'A' * 30;
        expect(Validators.validateDisplayName(name30), isNull);
      });
    });

    // ── validateCoinAmount ────────────────────────────────────────────────────
    group('validateCoinAmount', () {
      test('returns error when null', () {
        expect(
          Validators.validateCoinAmount(null, 500),
          'กรุณากรอกจำนวนเหรียญ',
        );
      });

      test('returns error when empty', () {
        expect(
          Validators.validateCoinAmount('', 500),
          'กรุณากรอกจำนวนเหรียญ',
        );
      });

      test('returns parse error for non-numeric input', () {
        expect(
          Validators.validateCoinAmount('abc', 500),
          'กรุณากรอกตัวเลขจำนวนเต็ม',
        );
      });

      test('returns error for zero', () {
        expect(
          Validators.validateCoinAmount('0', 500),
          'จำนวนเหรียญต้องมากกว่า 0',
        );
      });

      test('returns error for negative number', () {
        expect(
          Validators.validateCoinAmount('-5', 500),
          'จำนวนเหรียญต้องมากกว่า 0',
        );
      });

      test('returns insufficient error when exceeding maxCoins', () {
        expect(
          Validators.validateCoinAmount('999', 500),
          'เหรียญไม่เพียงพอ (สูงสุด 500)',
        );
      });

      test('returns null for valid amount within limit', () {
        expect(Validators.validateCoinAmount('100', 500), isNull);
      });

      test('returns null for amount equal to maxCoins', () {
        expect(Validators.validateCoinAmount('500', 500), isNull);
      });
    });
  });
}
