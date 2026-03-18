import 'package:flutter/widgets.dart';

/// Minimal stub [AppLocalizations] for Aslan Pixel.
///
/// This provides all user-facing strings for Phase 1 screens.
/// Full intl codegen will replace this after `flutter pub get` and
/// `flutter gen-l10n` are run with the proper flutter_localizations setup.
class AppLocalizations {
  final Locale locale;

  const AppLocalizations(this.locale);

  /// Returns the [AppLocalizations] for the given [context].
  /// Falls back to English if not found in the widget tree.
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        const AppLocalizations(Locale('en'));
  }

  /// The localization delegate used by [MaterialApp] / [WidgetsApp].
  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// Supported locales for this app.
  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('th'),
  ];

  bool get _isThai => locale.languageCode == 'th';

  // ── Strings ─────────────────────────────────────────────────────────────

  String get appName => 'Aslan Pixel';

  String get signIn => _isThai ? 'เข้าสู่ระบบ' : 'Sign In';

  String get signUp => _isThai ? 'สมัครสมาชิก' : 'Sign Up';

  String get email => _isThai ? 'อีเมล' : 'Email';

  String get password => _isThai ? 'รหัสผ่าน' : 'Password';

  String get forgotPassword => _isThai ? 'ลืมรหัสผ่าน?' : 'Forgot Password?';

  String get continueWithGoogle =>
      _isThai ? 'ดำเนินการต่อด้วย Google' : 'Continue with Google';

  String get continueWithApple =>
      _isThai ? 'ดำเนินการต่อด้วย Apple' : 'Continue with Apple';

  String get orSignInWithEmail =>
      _isThai ? 'หรือเข้าสู่ระบบด้วยอีเมล' : 'Or sign in with email';

  String get home => _isThai ? 'หน้าหลัก' : 'Home';

  String get world => _isThai ? 'โลก' : 'World';

  String get feed => _isThai ? 'ฟีด' : 'Feed';

  String get finance => _isThai ? 'การเงิน' : 'Finance';

  String get profile => _isThai ? 'โปรไฟล์' : 'Profile';

  String get loading => _isThai ? 'กำลังโหลด...' : 'Loading...';

  String get error => _isThai ? 'เกิดข้อผิดพลาด' : 'An error occurred';

  String get retry => _isThai ? 'ลองใหม่' : 'Retry';

  String get cancel => _isThai ? 'ยกเลิก' : 'Cancel';

  String get confirm => _isThai ? 'ยืนยัน' : 'Confirm';

  String get save => _isThai ? 'บันทึก' : 'Save';

  String get disclaimer =>
      _isThai
          ? 'ข้อมูลเพื่อการศึกษา ไม่ใช่คำแนะนำทางการเงิน'
          : 'For educational purposes only, not financial advice';
}

// ── Delegate ────────────────────────────────────────────────────────────────

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['en', 'th'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
