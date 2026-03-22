import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'icon_button.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;

  const CustomAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.showBackButton = true,
    this.onBackPressed,
    this.actions,
    this.leading,
    this.centerTitle = false,
  });

  final double height = 48;

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canPop = Navigator.of(context).canPop();
    final showBack = showBackButton && canPop && leading == null;

    final titleWidget =
        this.titleWidget ??
        (title != null
            ? Text(
                title!,
                style: TextStyle(
                  color:
                      theme.appBarTheme.foregroundColor ??
                      theme.colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              )
            : null);

    return AppBar(
      leading: showBack ? null : leading,
      leadingWidth: showBack ? 0 : null,
      title: showBack ? null : titleWidget,
      centerTitle: showBack ? false : centerTitle,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      actions: actions,
      systemOverlayStyle: theme.brightness == Brightness.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: theme.dividerColor),
      ),
      flexibleSpace: showBack
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: SizedBox(
                  height: height,
                  child: Row(
                    children: [
                      IconButtonWidget(
                        onPressed:
                            onBackPressed ?? () => Navigator.maybePop(context),
                        icon: const Icon(LucideIcons.chevronLeft, size: 24),
                      ),
                      if (titleWidget != null) Flexible(child: titleWidget),
                    ],
                  ),
                ),
              ),
            )
          : null,
    );
  }
}
