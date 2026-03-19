import 'package:flutter_test/flutter_test.dart';

import 'package:aslan_pixel/core/utils/app_version_service.dart';

void main() {
  group('AppVersionService.compareVersions', () {
    test('equal versions return 0', () {
      expect(AppVersionService.compareVersions('1.0.0', '1.0.0'), 0);
      expect(AppVersionService.compareVersions('2.3.4', '2.3.4'), 0);
    });

    test('returns negative when v1 < v2 (major)', () {
      expect(
        AppVersionService.compareVersions('1.0.0', '2.0.0'),
        isNegative,
      );
    });

    test('returns negative when v1 < v2 (minor)', () {
      expect(
        AppVersionService.compareVersions('1.2.0', '1.3.0'),
        isNegative,
      );
    });

    test('returns negative when v1 < v2 (patch)', () {
      expect(
        AppVersionService.compareVersions('1.0.1', '1.0.2'),
        isNegative,
      );
    });

    test('returns positive when v1 > v2 (major)', () {
      expect(
        AppVersionService.compareVersions('3.0.0', '2.0.0'),
        isPositive,
      );
    });

    test('returns positive when v1 > v2 (minor)', () {
      expect(
        AppVersionService.compareVersions('1.5.0', '1.4.0'),
        isPositive,
      );
    });

    test('returns positive when v1 > v2 (patch)', () {
      expect(
        AppVersionService.compareVersions('1.0.3', '1.0.1'),
        isPositive,
      );
    });

    test('handles shorter version strings', () {
      expect(
        AppVersionService.compareVersions('1.0', '1.0.0'),
        0,
      );
      expect(
        AppVersionService.compareVersions('1', '1.0.0'),
        0,
      );
    });

    test('handles longer version strings (only first 3 parts matter)', () {
      expect(
        AppVersionService.compareVersions('1.0.0.1', '1.0.0.2'),
        0,
      );
    });

    test('multi-digit version numbers', () {
      expect(
        AppVersionService.compareVersions('1.10.0', '1.9.0'),
        isPositive,
      );
      expect(
        AppVersionService.compareVersions('1.0.99', '1.1.0'),
        isNegative,
      );
    });
  });
}
