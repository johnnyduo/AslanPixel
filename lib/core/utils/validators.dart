/// Form field validators — all return null when the value is valid,
/// or a Thai/English error string when invalid.
class Validators {
  const Validators._();

  /// Validates an email address.
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'กรุณากรอกอีเมล';
    }
    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'รูปแบบอีเมลไม่ถูกต้อง';
    }
    return null;
  }

  /// Validates a password — minimum 8 characters, at least 1 digit.
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'กรุณากรอกรหัสผ่าน';
    }
    if (value.length < 8) {
      return 'รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร';
    }
    if (!RegExp(r'\d').hasMatch(value)) {
      return 'รหัสผ่านต้องมีตัวเลขอย่างน้อย 1 ตัว';
    }
    return null;
  }

  /// Validates a display name — 2–30 characters.
  static String? validateDisplayName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'กรุณากรอกชื่อที่แสดง';
    }
    final trimmed = value.trim();
    if (trimmed.length < 2) {
      return 'ชื่อต้องมีอย่างน้อย 2 ตัวอักษร';
    }
    if (trimmed.length > 30) {
      return 'ชื่อต้องไม่เกิน 30 ตัวอักษร';
    }
    return null;
  }

  /// Validates a coin amount — must be a positive integer not exceeding [maxCoins].
  static String? validateCoinAmount(String? value, int maxCoins) {
    if (value == null || value.trim().isEmpty) {
      return 'กรุณากรอกจำนวนเหรียญ';
    }
    final parsed = int.tryParse(value.trim());
    if (parsed == null) {
      return 'กรุณากรอกตัวเลขจำนวนเต็ม';
    }
    if (parsed <= 0) {
      return 'จำนวนเหรียญต้องมากกว่า 0';
    }
    if (parsed > maxCoins) {
      return 'เหรียญไม่เพียงพอ (สูงสุด $maxCoins)';
    }
    return null;
  }
}
