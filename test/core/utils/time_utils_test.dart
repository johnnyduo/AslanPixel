import 'package:aslan_pixel/core/utils/time_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TimeUtils', () {
    // ── timeAgoTh ───────────────────────────────────────────────────────────
    group('timeAgoTh', () {
      test('returns "เมื่อกี้" for less than 60 seconds ago', () {
        final dt = DateTime.now().subtract(const Duration(seconds: 30));
        expect(TimeUtils.timeAgoTh(dt), 'เมื่อกี้');
      });

      test('returns "เมื่อกี้" for just now (0 seconds)', () {
        final dt = DateTime.now();
        expect(TimeUtils.timeAgoTh(dt), 'เมื่อกี้');
      });

      test('returns minutes ago for 5 minutes', () {
        final dt = DateTime.now().subtract(const Duration(minutes: 5));
        expect(TimeUtils.timeAgoTh(dt), '5 นาทีที่แล้ว');
      });

      test('returns minutes ago for 1 minute', () {
        final dt = DateTime.now().subtract(const Duration(minutes: 1));
        expect(TimeUtils.timeAgoTh(dt), '1 นาทีที่แล้ว');
      });

      test('returns minutes ago for 59 minutes', () {
        final dt = DateTime.now().subtract(const Duration(minutes: 59));
        expect(TimeUtils.timeAgoTh(dt), '59 นาทีที่แล้ว');
      });

      test('returns hours ago for 3 hours', () {
        final dt = DateTime.now().subtract(const Duration(hours: 3));
        expect(TimeUtils.timeAgoTh(dt), '3 ชั่วโมงที่แล้ว');
      });

      test('returns hours ago for 1 hour', () {
        final dt = DateTime.now().subtract(const Duration(hours: 1));
        expect(TimeUtils.timeAgoTh(dt), '1 ชั่วโมงที่แล้ว');
      });

      test('returns hours ago for 23 hours', () {
        final dt = DateTime.now().subtract(const Duration(hours: 23));
        expect(TimeUtils.timeAgoTh(dt), '23 ชั่วโมงที่แล้ว');
      });

      test('returns days ago for 2 days', () {
        final dt = DateTime.now().subtract(const Duration(days: 2));
        expect(TimeUtils.timeAgoTh(dt), '2 วันที่แล้ว');
      });

      test('returns days ago for 6 days', () {
        final dt = DateTime.now().subtract(const Duration(days: 6));
        expect(TimeUtils.timeAgoTh(dt), '6 วันที่แล้ว');
      });

      test('returns DD/MM/YYYY for 10 days ago', () {
        final dt = DateTime.now().subtract(const Duration(days: 10));
        final d = dt.day.toString().padLeft(2, '0');
        final m = dt.month.toString().padLeft(2, '0');
        final y = dt.year.toString();
        expect(TimeUtils.timeAgoTh(dt), '$d/$m/$y');
      });

      test('returns DD/MM/YYYY for 30 days ago', () {
        final dt = DateTime.now().subtract(const Duration(days: 30));
        final d = dt.day.toString().padLeft(2, '0');
        final m = dt.month.toString().padLeft(2, '0');
        final y = dt.year.toString();
        expect(TimeUtils.timeAgoTh(dt), '$d/$m/$y');
      });

      test('formats specific date correctly', () {
        // Use a date far enough in the past to trigger DD/MM/YYYY
        final dt = DateTime(2025, 3, 15);
        expect(TimeUtils.timeAgoTh(dt), '15/03/2025');
      });
    });

    // ── countdownTh ─────────────────────────────────────────────────────────
    group('countdownTh', () {
      test('returns "หมดเวลาแล้ว" for past datetime', () {
        final past = DateTime.now().subtract(const Duration(hours: 1));
        expect(TimeUtils.countdownTh(past), 'หมดเวลาแล้ว');
      });

      test('returns hours and minutes for 2h 30m in the future', () {
        // Add extra seconds to absorb time elapsed between now() calls
        final future =
            DateTime.now().add(const Duration(hours: 2, minutes: 30, seconds: 30));
        expect(TimeUtils.countdownTh(future), 'เหลือ 2 ชั่วโมง 30 นาที');
      });

      test('returns only minutes when less than 1 hour', () {
        final future =
            DateTime.now().add(const Duration(minutes: 45, seconds: 30));
        expect(TimeUtils.countdownTh(future), 'เหลือ 45 นาที');
      });

      test('returns hours with 0 minutes when exact hours', () {
        final future =
            DateTime.now().add(const Duration(hours: 3, seconds: 30));
        expect(TimeUtils.countdownTh(future), 'เหลือ 3 ชั่วโมง 0 นาที');
      });

      test('returns 0 minutes for just-now future', () {
        // A few seconds in the future — 0 hours, 0 minutes remainder
        final future = DateTime.now().add(const Duration(seconds: 10));
        expect(TimeUtils.countdownTh(future), 'เหลือ 0 นาที');
      });
    });
  });
}
