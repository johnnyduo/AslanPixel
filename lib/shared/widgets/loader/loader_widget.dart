import 'package:flutter/material.dart';

import 'package:aslan_pixel/core/config/app_colors.dart';
import 'package:aslan_pixel/shared/widgets/style.dart';

/// Simple centered loading indicator using the primary neon green color.
class LoaderWidget extends StatelessWidget {
  final String? message;

  const LoaderWidget({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
              strokeWidth: 3,
            ),
          ),
          if (message != null && message!.isNotEmpty) ...[
            spacerH(h: 16),
            Text(
              message!,
              style: styleWithColor(
                color: colors.textSecondary,
                size: AppFontSize.body.toInt(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Full-screen loading overlay — renders over the current screen content.
class LoaderOverlay extends StatelessWidget {
  final String? message;

  const LoaderOverlay({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Material(
      type: MaterialType.transparency,
      child: Container(
        color: colors.background.withValues(alpha: 0.7),
        child: LoaderWidget(message: message),
      ),
    );
  }
}

/// Small inline loader — for use inside cards or list items.
class LoaderInline extends StatelessWidget {
  final double size;

  const LoaderInline({super.key, this.size = 20});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
        strokeWidth: 2,
      ),
    );
  }
}
