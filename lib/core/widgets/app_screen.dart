import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Keeps content below the status bar / notch.
///
/// When [embeddedInShell] is true, the parent shell already provides top
/// insets — skip nested [Scaffold] and [SafeArea] to avoid double padding.
class AppScreen extends StatelessWidget {
  const AppScreen({
    super.key,
    required this.body,
    this.appBar,
    this.backgroundColor = AppColors.background,
    this.embeddedInShell = false,
    this.safeBottom = true,
  });

  final Widget body;
  final PreferredSizeWidget? appBar;
  final Color backgroundColor;
  final bool embeddedInShell;
  final bool safeBottom;

  @override
  Widget build(BuildContext context) {
    if (embeddedInShell) {
      return ColoredBox(color: backgroundColor, child: body);
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: appBar,
      body: SafeArea(
        bottom: safeBottom,
        child: body,
      ),
    );
  }
}
