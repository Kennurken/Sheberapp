import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Primary button with loading state (spinner replaces label).
class SheberButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool expanded;

  const SheberButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.expanded = true,
  });

  @override
  Widget build(BuildContext context) {
    final busy = isLoading || onPressed == null;
    final child = isLoading
        ? SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          )
        : Text(label);

    final btn = FilledButton(
      onPressed: busy ? null : onPressed,
      style: FilledButton.styleFrom(
        minimumSize: expanded ? const Size.fromHeight(48) : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SheberTokens.radiusMd),
        ),
      ),
      child: child,
    );

    return expanded ? SizedBox(width: double.infinity, child: btn) : btn;
  }
}
