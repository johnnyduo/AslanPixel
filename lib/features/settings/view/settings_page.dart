import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:aslan_pixel/main.dart';

// ── Palette ──────────────────────────────────────────────────────────────────
const _kNavy = Color(0xFF0A1628);
const _kSurface = Color(0xFF0F2040);
const _kBorder = Color(0xFF1E3050);
const _kNeonGreen = Color(0xFF00F5A0);
const _kTextPrimary = Color(0xFFE8F4F8);
const _kTextSecondary = Color(0xFF6B8AAB);
const _kErrorRed = Color(0xFFFF4D4F);

/// App settings page — theme switcher, language picker, sign-out, etc.
///
/// Route: [SettingsPage.routeName]
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  static const routeName = '/settings';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kNavy,
      appBar: AppBar(
        backgroundColor: _kNavy,
        foregroundColor: _kTextPrimary,
        elevation: 0,
        title: const Text(
          'ตั้งค่า',
          style: TextStyle(
            color: _kTextPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(color: _kBorder, height: 1),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: const [
          _SectionHeader(label: 'รูปลักษณ์'),
          _ThemeRow(),
          _LanguageRow(),
          SizedBox(height: 8),
          _SectionHeader(label: 'บัญชี'),
          _SignOutRow(),
          SizedBox(height: 8),
          _SectionHeader(label: 'ข้อมูล'),
          _PrivacyPolicyRow(),
          _VersionRow(),
          SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── _SectionHeader ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Text(
        label,
        style: const TextStyle(
          color: _kTextSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ── _ThemeRow ─────────────────────────────────────────────────────────────────

class _ThemeRow extends StatelessWidget {
  const _ThemeRow();

  @override
  Widget build(BuildContext context) {
    final appState = MyApp.of(context);
    final currentMode = appState?.themeMode ?? ThemeMode.dark;

    return _SettingsTile(
      icon: Icons.brightness_6_outlined,
      iconColor: _kNeonGreen,
      label: 'ธีม',
      trailing: _ThemeSegmentedButton(
        current: currentMode,
        onChanged: (mode) => appState?.changeTheme(mode),
      ),
    );
  }
}

class _ThemeSegmentedButton extends StatelessWidget {
  const _ThemeSegmentedButton({
    required this.current,
    required this.onChanged,
  });

  final ThemeMode current;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<ThemeMode>(
      segments: const [
        ButtonSegment<ThemeMode>(
          value: ThemeMode.dark,
          icon: Icon(Icons.dark_mode, size: 16),
          label: Text('มืด', style: TextStyle(fontSize: 11)),
        ),
        ButtonSegment<ThemeMode>(
          value: ThemeMode.light,
          icon: Icon(Icons.light_mode, size: 16),
          label: Text('สว่าง', style: TextStyle(fontSize: 11)),
        ),
      ],
      selected: {current},
      onSelectionChanged: (set) {
        if (set.isNotEmpty) onChanged(set.first);
      },
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return _kNeonGreen;
          return _kSurface;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return _kNavy;
          return _kTextSecondary;
        }),
        side: WidgetStateProperty.all(
          const BorderSide(color: _kBorder),
        ),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

// ── _LanguageRow ──────────────────────────────────────────────────────────────

class _LanguageRow extends StatelessWidget {
  const _LanguageRow();

  @override
  Widget build(BuildContext context) {
    final appState = MyApp.of(context);
    // Infer current locale from context; fallback to Thai.
    final locale = Localizations.localeOf(context);
    final currentCode = locale.languageCode;

    return _SettingsTile(
      icon: Icons.language_outlined,
      iconColor: const Color(0xFF4FC3F7),
      label: 'ภาษา',
      trailing: _LanguageSegmentedButton(
        currentCode: currentCode,
        onChanged: (code) => appState?.changeLanguage(Locale(code)),
      ),
    );
  }
}

class _LanguageSegmentedButton extends StatelessWidget {
  const _LanguageSegmentedButton({
    required this.currentCode,
    required this.onChanged,
  });

  final String currentCode;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment<String>(
          value: 'th',
          label: Text('ไทย', style: TextStyle(fontSize: 11)),
        ),
        ButtonSegment<String>(
          value: 'en',
          label: Text('English', style: TextStyle(fontSize: 11)),
        ),
      ],
      selected: {currentCode},
      onSelectionChanged: (set) {
        if (set.isNotEmpty) onChanged(set.first);
      },
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return _kNeonGreen;
          return _kSurface;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return _kNavy;
          return _kTextSecondary;
        }),
        side: WidgetStateProperty.all(
          const BorderSide(color: _kBorder),
        ),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

// ── _SignOutRow ───────────────────────────────────────────────────────────────

class _SignOutRow extends StatelessWidget {
  const _SignOutRow();

  Future<void> _signOut(BuildContext context) async {
    Navigator.of(context).popUntil((route) => route.isFirst);
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsTile(
      icon: Icons.logout,
      iconColor: _kErrorRed,
      label: 'ออกจากระบบ',
      labelColor: _kErrorRed,
      onTap: () => _signOut(context),
    );
  }
}

// ── _PrivacyPolicyRow ─────────────────────────────────────────────────────────

class _PrivacyPolicyRow extends StatelessWidget {
  const _PrivacyPolicyRow();

  @override
  Widget build(BuildContext context) {
    return const _SettingsTile(
      icon: Icons.shield_outlined,
      iconColor: Color(0xFF7B2FFF),
      label: 'นโยบายความเป็นส่วนตัว',
      trailing: Icon(
        Icons.chevron_right,
        color: _kTextSecondary,
        size: 20,
      ),
    );
  }
}

// ── _VersionRow ───────────────────────────────────────────────────────────────

class _VersionRow extends StatelessWidget {
  const _VersionRow();

  @override
  Widget build(BuildContext context) {
    return const _SettingsTile(
      icon: Icons.info_outline,
      iconColor: _kTextSecondary,
      label: 'เวอร์ชัน',
      trailing: Text(
        '1.0.0',
        style: TextStyle(
          color: _kTextSecondary,
          fontSize: 13,
        ),
      ),
    );
  }
}

// ── _SettingsTile ─────────────────────────────────────────────────────────────

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.labelColor = _kTextPrimary,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final Color labelColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      splashColor: _kNeonGreen.withValues(alpha: 0.05),
      highlightColor: _kNeonGreen.withValues(alpha: 0.03),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: _kBorder, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: labelColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
