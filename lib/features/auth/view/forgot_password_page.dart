import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import 'package:aslan_pixel/core/config/app_colors.dart';

/// Forgot-password page — sends a Firebase password-reset email.
///
/// Route: [ForgotPasswordPage.routeName]
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  static const routeName = '/forgot-password';

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showError('กรุณากรอกอีเมล');
      return;
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      _showError('รูปแบบอีเมลไม่ถูกต้อง');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _emailSent = true;
      });
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError(_mapFirebaseError(e.code));
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError('เกิดข้อผิดพลาด กรุณาลองใหม่');
    }
  }

  String _mapFirebaseError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'ไม่พบบัญชีที่ใช้อีเมลนี้';
      case 'invalid-email':
        return 'รูปแบบอีเมลไม่ถูกต้อง';
      case 'too-many-requests':
        return 'คำขอมากเกินไป กรุณารอสักครู่';
      default:
        return 'เกิดข้อผิดพลาด กรุณาลองใหม่';
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
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
          'ลืมรหัสผ่าน',
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
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
          child: _emailSent ? _buildSuccessView(colors) : _buildFormView(colors),
        ),
      ),
    );
  }

  Widget _buildFormView(AppColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          Icons.lock_reset_rounded,
          color: colors.primary,
          size: 56,
        ),
        SizedBox(height: 2.h),
        Text(
          'รีเซ็ตรหัสผ่าน',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 1.h),
        Text(
          'กรอกอีเมลของคุณ เราจะส่งลิงก์สำหรับตั้งรหัสผ่านใหม่',
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 12.sp,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 3.h),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          enabled: !_isLoading,
          style: TextStyle(color: colors.textPrimary, fontSize: 15.sp),
          cursorColor: colors.primary,
          decoration: InputDecoration(
            hintText: 'อีเมล',
            hintStyle: TextStyle(color: colors.textDisabled, fontSize: 15.sp),
            filled: true,
            fillColor: colors.inputBackground,
            prefixIcon: Icon(
              Icons.alternate_email_rounded,
              color: colors.textDisabled,
              size: 20,
            ),
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
        ),
        SizedBox(height: 2.5.h),
        SizedBox(
          height: 6.h,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.textOnPrimary,
              disabledBackgroundColor: colors.primary.withValues(alpha: 0.3),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: _isLoading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: colors.textOnPrimary,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(
                    'ส่งลิงก์รีเซ็ต',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessView(AppColorScheme colors) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.mark_email_read_rounded,
          color: colors.primary,
          size: 72,
        ),
        SizedBox(height: 2.h),
        Text(
          'ส่งอีเมลเรียบร้อยแล้ว!',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 1.h),
        Text(
          'กรุณาตรวจสอบกล่องจดหมายของคุณ\nและคลิกลิงก์เพื่อตั้งรหัสผ่านใหม่',
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 12.sp,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 3.h),
        SizedBox(
          height: 6.h,
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.primary,
              side: BorderSide(color: colors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'กลับไปหน้าเข้าสู่ระบบ',
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
