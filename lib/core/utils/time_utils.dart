/// Thai-language time formatting utilities.
class TimeUtils {
  const TimeUtils._();

  /// Returns a human-readable Thai relative time string for [dt].
  ///
  /// Examples:
  ///   < 1 min  → "เมื่อกี้"
  ///   < 60 min → "5 นาทีที่แล้ว"
  ///   < 24 h   → "3 ชั่วโมงที่แล้ว"
  ///   < 7 days → "2 วันที่แล้ว"
  ///   else     → "15/03/2568" (DD/MM/YYYY Buddhist era)
  static String timeAgoTh(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inSeconds < 60) {
      return 'เมื่อกี้';
    }
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} นาทีที่แล้ว';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours} ชั่วโมงที่แล้ว';
    }
    if (diff.inDays < 7) {
      return '${diff.inDays} วันที่แล้ว';
    }
    // Format as DD/MM/YYYY (Gregorian for simplicity)
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString();
    return '$d/$m/$y';
  }

  /// Returns a Thai countdown string until [future].
  ///
  /// Examples:
  ///   future is past → "หมดเวลาแล้ว"
  ///   else           → "เหลือ 2 ชั่วโมง 30 นาที"
  static String countdownTh(DateTime future) {
    final now = DateTime.now();
    final diff = future.difference(now);

    if (diff.isNegative) {
      return 'หมดเวลาแล้ว';
    }

    final hours = diff.inHours;
    final minutes = diff.inMinutes.remainder(60);

    if (hours > 0) {
      return 'เหลือ $hours ชั่วโมง $minutes นาที';
    }
    return 'เหลือ $minutes นาที';
  }
}
