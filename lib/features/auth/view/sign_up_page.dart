import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:sizer/sizer.dart';

import 'package:aslan_pixel/core/config/app_colors.dart';

/// Sign-up page — creates a new Firebase Auth account with email + password
/// then initialises a Firestore user document.
///
/// Intentionally uses a lightweight local state machine rather than the full
/// [AuthBloc] to keep the registration path simple; the resulting [User] is
/// still surfaced through [FirebaseAuth.authStateChanges] so [AuthBloc]
/// will pick it up automatically.
class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  static const routeName = '/signup';

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── Validation + submission ──────────────────────────────────────────────────

  Future<void> _submit() async {
    final displayName = _displayNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (displayName.isEmpty) {
      _showError('กรุณากรอกชื่อแสดง');
      return;
    }
    if (email.isEmpty ||
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      _showError('กรุณากรอกอีเมลให้ถูกต้อง');
      return;
    }
    if (password.length < 8) {
      _showError('รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร');
      return;
    }

    setState(() => _isLoading = true);
    TextInput.finishAutofillContext();

    try {
      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update Firebase Auth profile with the chosen display name.
      await credential.user?.updateDisplayName(displayName);

      if (!mounted) return;
      // Navigate to home — authStateChanges will propagate the new user.
      Navigator.of(context)
          .pushNamedAndRemoveUntil('/home', (route) => false);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _showError(_mapFirebaseError(e.code));
    } catch (e) {
      if (!mounted) return;
      _showError('เกิดข้อผิดพลาด กรุณาลองใหม่');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.of(context).error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
  }

  String _mapFirebaseError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'อีเมลนี้ถูกใช้งานแล้ว';
      case 'invalid-email':
        return 'รูปแบบอีเมลไม่ถูกต้อง';
      case 'weak-password':
        return 'รหัสผ่านไม่ปลอดภัยพอ กรุณาใช้อย่างน้อย 8 ตัวอักษร';
      case 'network-request-failed':
        return 'ไม่มีการเชื่อมต่ออินเทอร์เน็ต';
      default:
        return 'เกิดข้อผิดพลาด กรุณาลองใหม่';
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: colors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: colors.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'สมัครสมาชิก',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding:
                  EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header text
                  Text(
                    'สร้างบัญชีใหม่',
                    style: TextStyle(
                      color: colors.primary,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    'กรอกข้อมูลเพื่อเริ่มต้นใช้งาน Aslan Pixel',
                    style: TextStyle(
                        color: colors.textSecondary, fontSize: 11.sp),
                  ),
                  SizedBox(height: 3.h),

                  // Display name
                  _buildTextField(
                    controller: _displayNameController,
                    hint: 'ชื่อแสดง',
                    icon: Icons.person_outline_rounded,
                    autofillHints: const [AutofillHints.name],
                    colors: colors,
                    enabled: !_isLoading,
                  ),
                  SizedBox(height: 1.5.h),

                  // Email
                  AutofillGroup(
                    child: Column(
                      children: [
                        _buildTextField(
                          controller: _emailController,
                          hint: 'อีเมล',
                          icon: Icons.alternate_email_rounded,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [
                            AutofillHints.newUsername,
                            AutofillHints.email,
                          ],
                          colors: colors,
                          enabled: !_isLoading,
                        ),
                        SizedBox(height: 1.5.h),
                        _buildTextField(
                          controller: _passwordController,
                          hint: 'รหัสผ่าน (อย่างน้อย 8 ตัวอักษร)',
                          icon: Icons.lock_outline_rounded,
                          obscureText: _obscurePassword,
                          autofillHints: const [AutofillHints.newPassword],
                          colors: colors,
                          enabled: !_isLoading,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: colors.textDisabled,
                              size: 20,
                            ),
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 3.h),

                  // Submit button
                  _buildSignUpButton(colors),
                  SizedBox(height: 2.5.h),

                  // Back to sign in
                  _buildSignInLink(colors),
                  SizedBox(
                      height:
                          MediaQuery.of(context).padding.bottom + 1.h),
                ],
              ),
            ),
          ),
          if (_isLoading) _buildLoadingOverlay(colors),
        ],
      ),
    );
  }

  // ── Sub-widgets ───────────────────────────────────────────────────────────────

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required AppColorScheme colors,
    TextInputType? keyboardType,
    bool obscureText = false,
    List<String>? autofillHints,
    Widget? suffixIcon,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      autofillHints: autofillHints,
      enabled: enabled,
      style: TextStyle(color: colors.textPrimary, fontSize: 13.sp),
      cursorColor: colors.primary,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: colors.textDisabled, fontSize: 11.sp),
        filled: true,
        fillColor: colors.inputBackground,
        prefixIcon: Icon(icon, color: colors.textDisabled, size: 20),
        suffixIcon: suffixIcon,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colors.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colors.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colors.borderSubtle),
        ),
      ),
    );
  }

  Widget _buildSignUpButton(AppColorScheme colors) {
    return SizedBox(
      height: 6.h,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.textOnPrimary,
          disabledBackgroundColor: colors.primary.withAlpha(80),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          'สมัครสมาชิก',
          style: TextStyle(
            color: colors.textOnPrimary,
            fontSize: 13.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSignInLink(AppColorScheme colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'มีบัญชีอยู่แล้ว? ',
          style: TextStyle(color: colors.textSecondary, fontSize: 11.sp),
        ),
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Text(
            'เข้าสู่ระบบ',
            style: TextStyle(
              color: colors.primary,
              fontSize: 11.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingOverlay(AppColorScheme colors) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: LoadingAnimationWidget.staggeredDotsWave(
          color: colors.primary,
          size: 48,
        ),
      ),
    );
  }
}
