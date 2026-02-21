import 'package:flutter/material.dart';

class MarkMeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final VoidCallback? onBackPressed;
  final bool isLoading;
  final List<Widget>? actions;
  final bool showBackButton;

  const MarkMeAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.onBackPressed,
    this.isLoading = false,
    this.actions,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF2563EB),
      automaticallyImplyLeading: false,
      leading: showBackButton
          ? IconButton(
              onPressed: isLoading
                  ? null
                  : (onBackPressed ?? () => Navigator.of(context).pop()),
              icon: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(51), // 0.2
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            )
          : null,
      title: titleWidget ??
          Text(
            title ?? '',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
          ),
      centerTitle: true,
      elevation: 0,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
