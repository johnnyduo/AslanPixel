import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:aslan_pixel/core/config/app_colors.dart';
import 'package:aslan_pixel/shared/widgets/notification_bell.dart';
import 'package:aslan_pixel/shared/widgets/style.dart';

/// Standard AppBar for Aslan Pixel screens.
///
/// Uses [AppColors.of(context)] for appBarBackground and appBarForeground,
/// supporting both light and dark themes automatically.
class PixelAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget> actions;
  final bool showBackButton;
  final VoidCallback? onBack;
  final bool centerTitle;

  /// When provided, a [NotificationBell] is appended to [actions].
  final String? uid;

  const PixelAppBar({
    super.key,
    required this.title,
    this.actions = const [],
    this.showBackButton = true,
    this.onBack,
    this.centerTitle = false,
    this.uid,
  }) : assert(actions.length <= 3, 'Max 3 action icons allowed');

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 24);

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final paddingTop = MediaQuery.of(context).padding.top;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: (isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
          .copyWith(statusBarColor: Colors.transparent),
      child: Container(
        padding: EdgeInsets.only(top: paddingTop),
        color: colors.appBarBackground,
        child: SizedBox(
          height: kToolbarHeight,
          child: Row(
            children: [
              if (showBackButton)
                GestureDetector(
                  onTap:
                      onBack ??
                      () {
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        }
                      },
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: colors.appBarForeground,
                      size: 20,
                    ),
                  ),
                )
              else
                spacerW(w: 20),
              Expanded(
                child: Container(
                  alignment:
                      centerTitle ? Alignment.center : Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: 8, right: 8),
                  child: titleText(
                    title,
                    color: colors.appBarForeground,
                    fontSize: 20,
                    maxLine: 1,
                    isLimit: true,
                    isBold: true,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...actions.map(
                    (w) => Padding(
                      padding: const EdgeInsets.only(right: 4.0),
                      child: w,
                    ),
                  ),
                  if (uid != null) NotificationBell(uid: uid!),
                ],
              ),
              spacerW(w: 4),
            ],
          ),
        ),
      ),
    );
  }
}

/// AppBar variant with a bottom border divider line.
class PixelAppBarWithBorder extends PixelAppBar {
  const PixelAppBarWithBorder({
    super.key,
    required super.title,
    super.actions,
    super.showBackButton,
    super.onBack,
    super.centerTitle,
    super.uid,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: colors.appBarBorder, width: 0.5),
        ),
      ),
      child: super.build(context),
    );
  }
}
