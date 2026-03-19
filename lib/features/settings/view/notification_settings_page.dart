import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:aslan_pixel/core/config/app_colors.dart';

/// Per-type notification settings page.
///
/// Reads/writes toggle values to Firestore:
///   `users/{uid}/settings/notifications`
///
/// Route: [NotificationSettingsPage.routeName]
class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  static const routeName = '/notification-settings';

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  static const _kTypes = <_NotifType>[
    _NotifType(key: 'quest_ready', label: 'เควสพร้อมรับรางวัล', icon: Icons.emoji_events_outlined),
    _NotifType(key: 'idle_reward', label: 'รางวัลจาก Agent', icon: Icons.card_giftcard_outlined),
    _NotifType(key: 'prediction_settled', label: 'ผลการทำนาย', icon: Icons.analytics_outlined),
    _NotifType(key: 'friend_visit', label: 'เพื่อนเยี่ยมห้อง', icon: Icons.person_pin_outlined),
    _NotifType(key: 'market_alert', label: 'แจ้งเตือนตลาด', icon: Icons.trending_up_outlined),
  ];

  final _firestore = FirebaseFirestore.instance;
  late final String _uid;

  Map<String, bool> _toggles = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    if (_uid.isEmpty) {
      setState(() => _loading = false);
      return;
    }
    try {
      final doc = await _firestore
          .collection('users')
          .doc(_uid)
          .collection('settings')
          .doc('notifications')
          .get();

      final data = doc.data() ?? {};
      final loaded = <String, bool>{};
      for (final t in _kTypes) {
        loaded[t.key] = data[t.key] as bool? ?? true;
      }
      if (!mounted) return;
      setState(() {
        _toggles = loaded;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _updateToggle(String key, bool value) async {
    setState(() => _toggles[key] = value);

    if (_uid.isEmpty) return;
    try {
      await _firestore
          .collection('users')
          .doc(_uid)
          .collection('settings')
          .doc('notifications')
          .set({key: value}, SetOptions(merge: true));
    } catch (_) {
      // Revert on failure
      if (!mounted) return;
      setState(() => _toggles[key] = !value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: colors.scaffoldBackground,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        title: Text(
          'การแจ้งเตือน',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(color: colors.border, height: 1),
        ),
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(color: colors.primary),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: _kTypes.length,
              separatorBuilder: (_, __) =>
                  Divider(color: colors.border, height: 1, indent: 64),
              itemBuilder: (context, index) {
                final t = _kTypes[index];
                final enabled = _toggles[t.key] ?? true;
                return SwitchListTile(
                  activeColor: colors.primary,
                  inactiveTrackColor: colors.surface,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  secondary: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(t.icon, color: colors.primary, size: 20),
                  ),
                  title: Text(
                    t.label,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  value: enabled,
                  onChanged: (v) => _updateToggle(t.key, v),
                );
              },
            ),
    );
  }
}

class _NotifType {
  const _NotifType({
    required this.key,
    required this.label,
    required this.icon,
  });

  final String key;
  final String label;
  final IconData icon;
}
