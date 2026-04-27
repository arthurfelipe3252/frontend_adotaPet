import 'package:flutter/material.dart';

import 'package:adota_pet/core/theme/app_theme.dart';

enum PrimaryButtonVariant { primary, sage }

class PrimaryButton extends StatelessWidget {
  final String label;
  final IconData? trailingIcon;
  final bool isLoading;
  final bool fullWidth;
  final PrimaryButtonVariant variant;
  final VoidCallback? onPressed;

  const PrimaryButton({
    super.key,
    required this.label,
    this.trailingIcon,
    this.isLoading = false,
    this.fullWidth = true,
    this.variant = PrimaryButtonVariant.primary,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final color = variant == PrimaryButtonVariant.sage
        ? AppTheme.sage
        : AppTheme.primary;

    final button = ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: color),
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label),
                if (trailingIcon != null) ...[
                  const SizedBox(width: 8),
                  Icon(trailingIcon, size: 18),
                ],
              ],
            ),
    );

    if (fullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}
