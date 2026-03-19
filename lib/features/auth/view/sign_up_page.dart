import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:sizer/sizer.dart';

import 'package:aslan_pixel/core/config/app_colors.dart';
import 'package:aslan_pixel/features/auth/bloc/auth_bloc.dart';
import 'package:aslan_pixel/features/settings/view/legal_page.dart';

/// Sign-up page — creates a new Firebase Auth account with email + password
/// then initialises a Firestore user document and sends email verification.
///
/// Uses [AuthBloc] so the resulting [UserModel] is handled consistently
/// across all auth flows (Firestore sync, economy init, FCM token).
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
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreedToTerms = false;

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ── Validation + submission ──────────────────────────────────────────────────

  void _submit() {
    final displayName = _displayNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

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
    if (password != confirmPassword) {
      _showError('รหัสผ่านไม่ตรงกัน');
      return;
    }
    if (!_agreedToTerms) {
      _showError('กรุณายอมรับข้อกำหนดการใช้งานและนโยบายความเป็นส่วนตัว');
      return;
    }

    TextInput.finishAutofillContext();
    context.read<AuthBloc>().add(
          AuthSignUpWithEmailRequested(
            email: email,
            password: password,
            displayName: displayName,
          ),
        );
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

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.of(context).primary,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
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

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthSuccess) {
          _showSuccess('ตรวจสอบอีเมลของคุณเพื่อยืนยันบัญชี');
          Navigator.of(context)
              .pushNamedAndRemoveUntil('/home', (route) => false);
        } else if (state is AuthFailure) {
          _showError(state.message);
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;

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
                        enabled: !isLoading,
                      ),
                      SizedBox(height: 1.5.h),

                      // Email + Password + Confirm Password
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
                              enabled: !isLoading,
                            ),
                            SizedBox(height: 1.5.h),
                            _buildTextField(
                              controller: _passwordController,
                              hint: 'รหัสผ่าน (อย่างน้อย 8 ตัวอักษร)',
                              icon: Icons.lock_outline_rounded,
                              obscureText: _obscurePassword,
                              autofillHints: const [AutofillHints.newPassword],
                              colors: colors,
                              enabled: !isLoading,
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
                            SizedBox(height: 1.5.h),
                            _buildTextField(
                              controller: _confirmPasswordController,
                              hint: 'ยืนยันรหัสผ่าน',
                              icon: Icons.lock_outline_rounded,
                              obscureText: _obscureConfirmPassword,
                              colors: colors,
                              enabled: !isLoading,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: colors.textDisabled,
                                  size: 20,
                                ),
                                onPressed: () => setState(() =>
                                    _obscureConfirmPassword =
                                        !_obscureConfirmPassword),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 2.h),

                      // Terms & Privacy checkbox
                      _buildTermsCheckbox(colors),
                      SizedBox(height: 2.h),

                      // Submit button
                      _buildSignUpButton(colors, isLoading),
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
              if (isLoading) _buildLoadingOverlay(colors),
            ],
          ),
        );
      },
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

  Widget _buildTermsCheckbox(AppColorScheme colors) {
    return GestureDetector(
      onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: _agreedToTerms,
              onChanged: (v) =>
                  setState(() => _agreedToTerms = v ?? false),
              activeColor: colors.primary,
              checkColor: colors.textOnPrimary,
              side: BorderSide(color: colors.textDisabled),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 11.sp,
                  height: 1.4,
                ),
                children: [
                  const TextSpan(text: 'ฉันยอมรับ '),
                  TextSpan(
                    text: 'ข้อกำหนดการใช้งาน',
                    style: TextStyle(
                      color: colors.primary,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => Navigator.of(context)
                          .pushNamed(LegalPage.termsOfServiceRouteName),
                  ),
                  const TextSpan(text: ' และ '),
                  TextSpan(
                    text: 'นโยบายความเป็นส่วนตัว',
                    style: TextStyle(
                      color: colors.primary,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => Navigator.of(context)
                          .pushNamed(LegalPage.privacyPolicyRouteName),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignUpButton(AppColorScheme colors, bool isLoading) {
    return SizedBox(
      height: 6.h,
      child: ElevatedButton(
        onPressed: isLoading ? null : _submit,
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
