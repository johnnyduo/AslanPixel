import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Checks the running app version against the minimum version defined in
/// Firebase Remote Config and shows a blocking update dialog when needed.
class AppVersionService {
  const AppVersionService._();

  /// Checks if the current app version meets the minimum required version
  /// from Firebase Remote Config.
  ///
  /// Returns `true` if an update is required.
  static Future<bool> isUpdateRequired() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final remoteConfig = FirebaseRemoteConfig.instance;
      final minVersion = remoteConfig.getString('min_app_version');

      if (minVersion.isEmpty) return false;
      return compareVersions(currentVersion, minVersion) < 0;
    } catch (_) {
      return false;
    }
  }

  /// Compares two semantic version strings.
  /// Returns negative if [v1] < [v2], 0 if equal, positive if [v1] > [v2].
  @visibleForTesting
  static int compareVersions(String v1, String v2) {
    final parts1 = v1.split('.').map(int.tryParse).toList();
    final parts2 = v2.split('.').map(int.tryParse).toList();

    for (var i = 0; i < 3; i++) {
      final p1 = i < parts1.length ? (parts1[i] ?? 0) : 0;
      final p2 = i < parts2.length ? (parts2[i] ?? 0) : 0;
      if (p1 != p2) return p1.compareTo(p2);
    }
    return 0;
  }

  /// Shows a blocking update dialog that cannot be dismissed.
  static Future<void> showUpdateDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F2040),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF00F5A0), width: 1),
        ),
        title: const Text(
          'อัปเดตแอป',
          style: TextStyle(
            color: Color(0xFFE8F4F8),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'กรุณาอัปเดตแอปเป็นเวอร์ชันล่าสุดเพื่อใช้งานต่อ',
          style: TextStyle(color: Color(0xB3E8F4F8)),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00F5A0),
              foregroundColor: const Color(0xFF0A1628),
            ),
            onPressed: () {
              // TODO: Open app store URL
            },
            child: const Text('อัปเดต'),
          ),
        ],
      ),
    );
  }
}
