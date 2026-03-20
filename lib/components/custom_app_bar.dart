import 'package:flutter/material.dart';
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

  final double height = 36;

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    final showBack = showBackButton && canPop && leading == null;

    final titleWidget =
        this.titleWidget ??
        (title != null
            ? Text(title!, style: Theme.of(context).appBarTheme.titleTextStyle)
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
                        icon: const Icon(LucideIcons.chevronLeft),
                        small: true,
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
