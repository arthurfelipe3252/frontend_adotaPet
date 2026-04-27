import 'package:flutter/material.dart';

import 'package:adota_pet/core/theme/app_theme.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool onDarkBackground;

  const AppLogo({super.key, this.size = 64, this.onDarkBackground = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: onDarkBackground
            ? null
            : const LinearGradient(
                colors: [AppTheme.primary, AppTheme.accent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        color: onDarkBackground ? const Color(0x33FFFFFF) : null,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Center(
        child: Text('🐾', style: TextStyle(fontSize: size * 0.55)),
      ),
    );
  }
}
