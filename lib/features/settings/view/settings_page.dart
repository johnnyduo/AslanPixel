import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:aslan_pixel/features/settings/view/account_deletion_page.dart';
import 'package:aslan_pixel/features/settings/view/legal_page.dart';
import 'package:aslan_pixel/features/settings/view/notification_settings_page.dart';
import 'package:aslan_pixel/main.dart';
import 'package:aslan_pixel/shared/widgets/pixel_icon.dart';

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
        children: [
          const _SectionHeader(label: 'รูปลักษณ์'),
          const _ThemeRow(),
          const _LanguageRow(),
          const SizedBox(height: 8),
          const _SectionHeader(label: 'การแจ้งเตือน'),
          _SettingsTile(
            icon: Icons.notifications_outlined,
            iconColor: _kNeonGreen,
            iconWidget: const PixelIcon(PixelIcon.bell, size: 18, color: _kNeonGreen),
            label: 'ตั้งค่าการแจ้งเตือน',
            trailing: const Icon(
              Icons.chevron_right,
              color: _kTextSecondary,
              size: 20,
            ),
            onTap: () => Navigator.of(context)
                .pushNamed(NotificationSettingsPage.routeName),
          ),
          const SizedBox(height: 8),
          const _SectionHeader(label: 'บัญชี'),
          const _GuestUpgradeRow(),
          const _SignOutRow(),
          const _DeleteAccountRow(),
          const SizedBox(height: 8),
          const _SectionHeader(label: 'กฎหมายและข้อมูล'),
          const _PrivacyPolicyRow(),
          const _TermsOfServiceRow(),
          const _VersionRow(),
          const SizedBox(height: 32),
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

// ── _GuestUpgradeRow ─────────────────────────────────────────────────────────

/// Shows "อัปเกรดบัญชี" only if the current user is anonymous (guest).
/// Taps open a bottom sheet to collect email + password for linking.
class _GuestUpgradeRow extends StatelessWidget {
  const _GuestUpgradeRow();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || !user.isAnonymous) {
      return const SizedBox.shrink();
    }
    return _SettingsTile(
      icon: Icons.upgrade_rounded,
      iconColor: _kNeonGreen,
      label: 'อัปเกรดบัญชี',
      trailing: const Icon(
        Icons.chevron_right,
        color: _kTextSecondary,
        size: 20,
      ),
      onTap: () => _showUpgradeSheet(context),
    );
  }

  void _showUpgradeSheet(BuildContext context) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'อัปเกรดบัญชีผู้เยี่ยมชม',
                style: TextStyle(
                  color: _kTextPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'เชื่อมต่ออีเมลและรหัสผ่านเพื่อรักษาข้อมูลทั้งหมดของคุณ',
                style: TextStyle(color: _kTextSecondary, fontSize: 13),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: _kTextPrimary),
                decoration: InputDecoration(
                  hintText: 'อีเมล',
                  hintStyle: const TextStyle(color: _kTextSecondary),
                  filled: true,
                  fillColor: _kNavy,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: _kBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: _kBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: _kNeonGreen, width: 1.5),
                  ),
                  prefixIcon: const Icon(Icons.alternate_email_rounded,
                      color: _kTextSecondary, size: 20),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                obscureText: true,
                style: const TextStyle(color: _kTextPrimary),
                decoration: InputDecoration(
                  hintText: 'รหัสผ่าน (อย่างน้อย 8 ตัวอักษร)',
                  hintStyle: const TextStyle(color: _kTextSecondary),
                  filled: true,
                  fillColor: _kNavy,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: _kBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: _kBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: _kNeonGreen, width: 1.5),
                  ),
                  prefixIcon: const Icon(Icons.lock_outline_rounded,
                      color: _kTextSecondary, size: 20),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _linkAccount(
                  context,
                  emailController.text.trim(),
                  passwordController.text.trim(),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kNeonGreen,
                  foregroundColor: _kNavy,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'อัปเกรดบัญชี',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _linkAccount(
      BuildContext context, String email, String password) async {
    if (email.isEmpty ||
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      _showSnackBar(context, 'กรุณากรอกอีเมลให้ถูกต้อง', isError: true);
      return;
    }
    if (password.length < 8) {
      _showSnackBar(context, 'รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร',
          isError: true);
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || !user.isAnonymous) return;

      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      await user.linkWithCredential(credential);

      // Update Firestore user doc with new email and provider.
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'email': email,
        'provider': 'email',
        'lastLoginAt': FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        Navigator.of(context).pop(); // close sheet
        _showSnackBar(context, 'อัปเกรดบัญชีสำเร็จ!');
      }
    } on FirebaseAuthException catch (e) {
      if (context.mounted) {
        final msg = e.code == 'email-already-in-use'
            ? 'อีเมลนี้ถูกใช้งานแล้ว'
            : e.code == 'credential-already-in-use'
                ? 'ข้อมูลรับรองนี้ถูกใช้กับบัญชีอื่นแล้ว'
                : 'เกิดข้อผิดพลาด กรุณาลองใหม่';
        _showSnackBar(context, msg, isError: true);
      }
    } catch (_) {
      if (context.mounted) {
        _showSnackBar(context, 'เกิดข้อผิดพลาด กรุณาลองใหม่', isError: true);
      }
    }
  }

  void _showSnackBar(BuildContext context, String message,
      {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? _kErrorRed : _kNeonGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
    return _SettingsTile(
      icon: Icons.shield_outlined,
      iconColor: const Color(0xFF7B2FFF),
      iconWidget: const PixelIcon(PixelIcon.shield, size: 18, color: Color(0xFF7B2FFF)),
      label: 'นโยบายความเป็นส่วนตัว',
      trailing: const Icon(
        Icons.chevron_right,
        color: _kTextSecondary,
        size: 20,
      ),
      onTap: () => Navigator.of(context)
          .pushNamed(LegalPage.privacyPolicyRouteName),
    );
  }
}

// ── _TermsOfServiceRow ────────────────────────────────────────────────────────

class _TermsOfServiceRow extends StatelessWidget {
  const _TermsOfServiceRow();

  @override
  Widget build(BuildContext context) {
    return _SettingsTile(
      icon: Icons.description_outlined,
      iconColor: const Color(0xFF4FC3F7),
      label: 'ข้อกำหนดการใช้งาน',
      trailing: const Icon(
        Icons.chevron_right,
        color: _kTextSecondary,
        size: 20,
      ),
      onTap: () => Navigator.of(context)
          .pushNamed(LegalPage.termsOfServiceRouteName),
    );
  }
}

// ── _DeleteAccountRow ─────────────────────────────────────────────────────────

class _DeleteAccountRow extends StatelessWidget {
  const _DeleteAccountRow();

  @override
  Widget build(BuildContext context) {
    return _SettingsTile(
      icon: Icons.person_remove_outlined,
      iconColor: _kErrorRed,
      label: 'ลบบัญชี',
      labelColor: _kErrorRed,
      trailing: const Icon(
        Icons.chevron_right,
        color: _kTextSecondary,
        size: 20,
      ),
      onTap: () => Navigator.of(context)
          .pushNamed(AccountDeletionPage.routeName),
    );
  }
}

// ── _VersionRow ───────────────────────────────────────────────────────────────

class _VersionRow extends StatelessWidget {
  const _VersionRow();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final version = snapshot.hasData
            ? '${snapshot.data!.version}+${snapshot.data!.buildNumber}'
            : '...';
        return _SettingsTile(
          icon: Icons.info_outline,
          iconColor: _kTextSecondary,
          label: 'เวอร์ชัน',
          trailing: Text(
            version,
            style: const TextStyle(
              color: _kTextSecondary,
              fontSize: 13,
            ),
          ),
        );
      },
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
    this.iconWidget,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final Color labelColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  /// Optional custom widget to display instead of [Icon]. When provided,
  /// [icon] is ignored (but still required for API compat).
  final Widget? iconWidget;

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
              child: Center(
                child: iconWidget ?? Icon(icon, color: iconColor, size: 18),
              ),
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
