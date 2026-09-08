import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

enum AppButtonVariant { primary, secondary, outlined, text }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.expand = false,
    this.icon,
    this.semanticLabel,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final bool expand;
  final IconData? icon;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? const SizedBox(
            width: AppSpacing.iconMd,
            height: AppSpacing.iconMd,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: AppSpacing.iconSm),
                const SizedBox(width: AppSpacing.xs),
              ],
              Text(label),
            ],
          );

    final button = switch (variant) {
      AppButtonVariant.primary => ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          child: child,
        ),
      AppButtonVariant.secondary => FilledButton.tonal(
          onPressed: isLoading ? null : onPressed,
          child: child,
        ),
      AppButtonVariant.outlined => OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          child: child,
        ),
      AppButtonVariant.text => TextButton(
          onPressed: isLoading ? null : onPressed,
          child: child,
        ),
    };

    final labeled = Semantics(
      button: true,
      label: semanticLabel ?? label,
      enabled: !isLoading && onPressed != null,
      excludeSemantics: true,
      child: button,
    );

    if (!expand) return labeled;
    return SizedBox(width: double.infinity, child: labeled);
  }
}
