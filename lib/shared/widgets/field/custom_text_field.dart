import 'package:flutter/material.dart';

import 'package:aslan_pixel/core/config/app_colors.dart';
import 'package:aslan_pixel/shared/widgets/style.dart';

/// Standard text input field for Aslan Pixel screens.
///
/// Colors are resolved from [AppColors.of(context)] so the field
/// automatically adapts to light and dark themes.
class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String? hint;
  final TextInputType keyboardType;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final bool isEnable;
  final bool obscureText;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final int? maxLines;

  const CustomTextField({
    super.key,
    required this.controller,
    this.hint,
    this.keyboardType = TextInputType.text,
    this.suffixIcon,
    this.prefixIcon,
    this.isEnable = true,
    this.obscureText = false,
    this.validator,
    this.onChanged,
    this.textInputAction,
    this.focusNode,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      enabled: isEnable,
      obscureText: obscureText,
      validator: validator,
      onChanged: onChanged,
      textInputAction: textInputAction,
      focusNode: focusNode,
      maxLines: obscureText ? 1 : maxLines,
      style: styleWithColor(
        color: isEnable ? colors.textPrimary : colors.textDisabled,
      ),
      cursorColor: colors.primary,
      decoration: InputDecoration(
        filled: true,
        fillColor: isEnable ? colors.inputBackground : colors.backgroundSecondary,
        hintText: hint,
        hintStyle: styleWithColor(color: colors.textTertiary),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: colors.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: colors.inputBorder),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: colors.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: colors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: colors.error, width: 1.5),
        ),
        suffixIcon: suffixIcon,
        prefixIcon: prefixIcon,
      ),
    );
  }
}
