import 'package:contextchat/theme.dart';
import 'package:flutter/material.dart';

class PopupMenuItemWidget<T> {
  final T value;
  final String label;
  final Widget? icon;

  const PopupMenuItemWidget({
    required this.value,
    required this.label,
    this.icon,
  });
}

class PopupMenuWidget<T> extends StatefulWidget {
  final List<PopupMenuItemWidget<T>> items;
  final T? value;
  final ValueChanged<T>? onSelected;
  final Widget? child;
  final String? tooltip;
  final bool enabled;

  const PopupMenuWidget({
    super.key,
    required this.items,
    this.value,
    this.onSelected,
    this.child,
    this.tooltip,
    this.enabled = true,
  });

  @override
  State<PopupMenuWidget<T>> createState() => _PopupMenuWidgetState<T>();
}

class _PopupMenuWidgetState<T> extends State<PopupMenuWidget<T>> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isMenuOpen = false;

  void _toggleMenu() {
    if (_isMenuOpen) {
      _hideMenu();
    } else {
      _showMenu();
    }
  }

  void _showMenu() {
    if (_isMenuOpen) return;
    setState(() => _isMenuOpen = true);
    _updateOverlay();
  }

  void _hideMenu() {
    if (!_isMenuOpen) return;
    setState(() => _isMenuOpen = false);
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _updateOverlay() {
    final theme = Theme.of(context);
    final shadowColor = theme.brightness == Brightness.light
        ? Colors.black.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.2);
    final menuBackground = theme.cardColor.withValues(alpha: 1.0);

    _overlayEntry?.remove();

    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final screenPadding = mediaQuery.padding;

    const menuMinWidth = 160.0;
    const menuVerticalOffset = 8.0;
    const minSpaceThreshold = 120.0;

    final triggerTop = renderBox.localToGlobal(Offset.zero).dy;
    final triggerBottom = triggerTop + size.height;
    final spaceBelow = screenHeight - screenPadding.bottom - triggerBottom;
    final spaceAbove = triggerTop - screenPadding.top;
    final showAbove = spaceBelow < minSpaceThreshold && spaceAbove > spaceBelow;

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _hideMenu,
              child: Container(color: Colors.transparent),
            ),
          ),
          Positioned(
            width: menuMinWidth > size.width ? menuMinWidth : size.width,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: showAbove
                  ? Offset(0, -(size.height + menuVerticalOffset))
                  : Offset(0, size.height + menuVerticalOffset),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    color: menuBackground,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    border: Border.all(color: theme.dividerColor),
                    boxShadow: [
                      BoxShadow(
                        color: shadowColor,
                        blurRadius: 60,
                        offset: const Offset(0, 16),
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 300),
                    child: IntrinsicWidth(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: widget.items.asMap().entries.map((entry) {
                          final index = entry.key;
                          final item = entry.value;
                          final isFirst = index == 0;
                          final isLast = index == widget.items.length - 1;
                          final isSelected = item.value == widget.value;
                          return _MenuItemWidget(
                            item: item,
                            isSelected: isSelected,
                            isFirst: isFirst,
                            isLast: isLast,
                            onTap: () {
                              _hideMenu();
                              widget.onSelected?.call(item.value);
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  @override
  void dispose() {
    _hideMenu();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: widget.enabled ? _toggleMenu : null,
        child: widget.child ?? _DefaultMenuButton(isMenuOpen: _isMenuOpen),
      ),
    );
  }
}

class _HoverableMenuItem extends StatefulWidget {
  final Widget child;
  final bool isFirst;
  final bool isLast;

  const _HoverableMenuItem({
    required this.child,
    required this.isFirst,
    required this.isLast,
  });

  @override
  State<_HoverableMenuItem> createState() => _HoverableMenuItemState();
}

class _HoverableMenuItemState extends State<_HoverableMenuItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hoverColor = theme.colorScheme.onSurface.withValues(alpha: 0.06);

    final borderRadius = BorderRadius.only(
      topLeft: widget.isFirst
          ? const Radius.circular(AppTheme.radiusMedium)
          : Radius.zero,
      bottomLeft: widget.isLast
          ? const Radius.circular(AppTheme.radiusMedium)
          : Radius.zero,
      topRight: widget.isFirst
          ? const Radius.circular(AppTheme.radiusMedium)
          : Radius.zero,
      bottomRight: widget.isLast
          ? const Radius.circular(AppTheme.radiusMedium)
          : Radius.zero,
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        decoration: BoxDecoration(
          color: _isHovered ? hoverColor : Colors.transparent,
          borderRadius: borderRadius,
        ),
        child: widget.child,
      ),
    );
  }
}

class _MenuItemWidget extends StatelessWidget {
  final PopupMenuItemWidget item;
  final bool isSelected;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onTap;

  const _MenuItemWidget({
    required this.item,
    required this.isSelected,
    required this.isFirst,
    required this.isLast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _HoverableMenuItem(
      isFirst: isFirst,
      isLast: isLast,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          width: double.infinity,
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              if (item.icon != null) ...[
                IconTheme(
                  data: IconThemeData(
                    size: 18,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                  ),
                  child: item.icon!,
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 8),
                Icon(Icons.check, size: 16, color: theme.colorScheme.primary),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DefaultMenuButton extends StatelessWidget {
  final bool isMenuOpen;

  const _DefaultMenuButton({this.isMenuOpen = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shadowColor = theme.brightness == Brightness.light
        ? Colors.black.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.2);
    final menuBackground = theme.cardColor.withValues(alpha: 1.0);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: menuBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: isMenuOpen ? 60 : 10,
            offset: isMenuOpen ? const Offset(0, 16) : const Offset(0, 4),
            spreadRadius: isMenuOpen ? 8 : 0,
          ),
        ],
      ),
      child: IconTheme(
        data: IconThemeData(
          size: 20,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
        ),
        child: const Icon(Icons.more_horiz),
      ),
    );
  }
}
