import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:sizer/sizer.dart';

import 'package:aslan_pixel/core/config/app_colors.dart';
import 'package:aslan_pixel/features/auth/bloc/auth_bloc.dart';
import 'package:aslan_pixel/features/auth/view/forgot_password_page.dart';
import 'sign_up_page.dart';

/// Full-screen sign-in page.
///
/// Layout (top → bottom):
///   • Logo area — pixel-art "ASLAN PIXEL" wordmark + Thai subtitle
///   • Email + Password fields
///   • Sign In button
///   • OR divider
///   • Google sign-in button
///   • Apple sign-in button (iOS-only)
///   • "ยังไม่มีบัญชี? สมัครสมาชิก" link
///
/// All business logic lives in [AuthBloc]; this widget is pure UI.
class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  static const routeName = '/signin';

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── Validation ──────────────────────────────────────────────────────────────

  void _submitEmail() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty) {
      _showError('กรุณากรอกอีเมล');
      return;
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      _showError('รูปแบบอีเมลไม่ถูกต้อง');
      return;
    }
    if (password.isEmpty) {
      _showError('กรุณากรอกรหัสผ่าน');
      return;
    }
    if (password.length < 8) {
      _showError('รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร');
      return;
    }

    TextInput.finishAutofillContext();
    context.read<AuthBloc>().add(
          AuthSignInWithEmailRequested(email: email, password: password),
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
          body: Stack(
            children: [
              _buildHeaderBackground(colors),
              SafeArea(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    children: [
                      _buildLogoSection(colors),
                      _buildFormCard(colors, isLoading),
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

  // ── Header background ────────────────────────────────────────────────────────

  Widget _buildHeaderBackground(AppColorScheme colors) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: 32.h,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colors.primary.withAlpha(25),
              colors.scaffoldBackground,
            ],
          ),
        ),
        child: CustomPaint(painter: _PixelGridPainter(colors.primary)),
      ),
    );
  }

  // ── Logo section ─────────────────────────────────────────────────────────────

  Widget _buildLogoSection(AppColorScheme colors) {
    return Padding(
      padding: EdgeInsets.only(top: 6.h, bottom: 2.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PixelLogo(primaryColor: colors.primary),
          SizedBox(height: 1.5.h),
          Text(
            'ASLAN PIXEL',
            style: TextStyle(
              color: colors.primary,
              fontSize: 20.sp,
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
              shadows: [
                Shadow(
                  color: colors.primary.withAlpha(130),
                  blurRadius: 14,
                ),
              ],
            ),
          ),
          SizedBox(height: 0.8.h),
          Text(
            'ตลาดการเงิน · โลกพิกเซล · โปรไฟล์นักลงทุน',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 9.sp,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── Form card ────────────────────────────────────────────────────────────────

  Widget _buildFormCard(AppColorScheme colors, bool isLoading) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 5.w),
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'เข้าสู่ระบบ',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 15.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 2.h),

          // Email
          AutofillGroup(
            child: Column(
              children: [
                _buildTextField(
                  controller: _emailController,
                  hint: 'อีเมล',
                  icon: Icons.alternate_email_rounded,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  colors: colors,
                  enabled: !isLoading,
                ),
                SizedBox(height: 1.5.h),
                _buildTextField(
                  controller: _passwordController,
                  hint: 'รหัสผ่าน',
                  icon: Icons.lock_outline_rounded,
                  obscureText: _obscurePassword,
                  autofillHints: const [AutofillHints.password],
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
              ],
            ),
          ),
          SizedBox(height: 0.8.h),

          // Forgot password link
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () => Navigator.of(context)
                  .pushNamed(ForgotPasswordPage.routeName),
              child: Text(
                'ลืมรหัสผ่าน?',
                style: TextStyle(
                  color: colors.primary,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          SizedBox(height: 1.5.h),

          // Sign In
          _buildPrimaryButton(
            label: 'เข้าสู่ระบบ',
            onPressed: isLoading ? null : _submitEmail,
            colors: colors,
          ),
          SizedBox(height: 2.5.h),

          // OR divider
          _buildOrDivider(colors),
          SizedBox(height: 2.h),

          // Google
          _buildSocialButton(
            label: 'เข้าสู่ระบบด้วย Google',
            iconWidget: const _GoogleIcon(),
            onPressed: isLoading
                ? null
                : () => context
                    .read<AuthBloc>()
                    .add(const AuthSignInWithGoogleRequested()),
            colors: colors,
          ),

          // Apple (iOS only)
          if (!kIsWeb && Platform.isIOS) ...[
            SizedBox(height: 1.2.h),
            _buildSocialButton(
              label: 'เข้าสู่ระบบด้วย Apple',
              iconWidget: const Icon(Icons.apple, color: Colors.white, size: 22),
              onPressed: isLoading
                  ? null
                  : () => context
                      .read<AuthBloc>()
                      .add(const AuthSignInWithAppleRequested()),
              colors: colors,
            ),
          ],

          SizedBox(height: 3.h),
          _buildSignUpLink(colors),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 0.5.h),
        ],
      ),
    );
  }

  // ── Reusable sub-widgets ──────────────────────────────────────────────────────

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
      style: TextStyle(color: colors.textPrimary, fontSize: 15.sp),
      cursorColor: colors.primary,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: colors.textDisabled, fontSize: 15.sp),
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

  Widget _buildPrimaryButton({
    required String label,
    required VoidCallback? onPressed,
    required AppColorScheme colors,
  }) {
    return SizedBox(
      height: 6.h,
      child: ElevatedButton(
        onPressed: onPressed,
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
          label,
          style: TextStyle(
            color: colors.textOnPrimary,
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }

  Widget _buildOrDivider(AppColorScheme colors) {
    return Row(
      children: [
        Expanded(child: Divider(color: colors.divider, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'หรือ',
            style: TextStyle(color: colors.textDisabled, fontSize: 13.sp),
          ),
        ),
        Expanded(child: Divider(color: colors.divider, thickness: 1)),
      ],
    );
  }

  Widget _buildSocialButton({
    required String label,
    required Widget iconWidget,
    required VoidCallback? onPressed,
    required AppColorScheme colors,
  }) {
    return SizedBox(
      height: 6.h,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.textPrimary,
          backgroundColor: colors.surfaceElevated,
          side: BorderSide(color: colors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            iconWidget,
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(color: colors.textPrimary, fontSize: 15.sp),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignUpLink(AppColorScheme colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'ยังไม่มีบัญชี? ',
          style: TextStyle(color: colors.textSecondary, fontSize: 14.sp),
        ),
        GestureDetector(
          onTap: () => Navigator.of(context).pushNamed(SignUpPage.routeName),
          child: Text(
            'สมัครสมาชิก',
            style: TextStyle(
              color: colors.primary,
              fontSize: 14.sp,
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

// ── Pixel logo ────────────────────────────────────────────────────────────────

/// 5×5 pixel-art diamond logo — rendered via [CustomPaint], no asset needed.
class _PixelLogo extends StatelessWidget {
  const _PixelLogo({required this.primaryColor});
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 56,
      child: CustomPaint(painter: _PixelLogoPainter(primaryColor)),
    );
  }
}

class _PixelLogoPainter extends CustomPainter {
  _PixelLogoPainter(this.color);
  final Color color;

  static const _map = [
    [0, 1, 1, 1, 0],
    [1, 1, 0, 1, 1],
    [1, 0, 1, 0, 1],
    [1, 1, 0, 1, 1],
    [0, 1, 1, 1, 0],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final cellW = size.width / 5;
    final cellH = size.height / 5;
    final glowPaint = Paint()
      ..color = color.withAlpha(55)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    final fillPaint = Paint()..color = color;

    for (var row = 0; row < 5; row++) {
      for (var col = 0; col < 5; col++) {
        if (_map[row][col] == 1) {
          final rect = RRect.fromRectAndRadius(
            Rect.fromLTWH(col * cellW + 1, row * cellH + 1, cellW - 2,
                cellH - 2),
            const Radius.circular(1.5),
          );
          canvas.drawRRect(rect, glowPaint);
          canvas.drawRRect(rect, fillPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_PixelLogoPainter old) => old.color != color;
}

/// Subtle dot-grid overlay drawn over the header gradient.
class _PixelGridPainter extends CustomPainter {
  _PixelGridPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withAlpha(18)
      ..strokeWidth = 0.5;
    const step = 20.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_PixelGridPainter old) => old.color != color;
}

/// Simple 'G' mark on a white circle — no SVG asset required.
class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: const Text(
        'G',
        style: TextStyle(
          color: Color(0xFF4285F4),
          fontSize: 14,
          fontWeight: FontWeight.bold,
          height: 1,
        ),
      ),
    );
  }
}
