import 'package:flutter/material.dart';

import 'package:adota_pet/core/theme/app_theme.dart';

/// Card de seção padrão do mobile: superfície clara, raio 16, borda suave e
/// cabeçalho opcional (ícone + título). É a versão "app" (raio 16) do
/// `SectionCard` do painel (raio 28) — usada pelas telas mobile (Perfil etc.).
class MobileSectionCard extends StatelessWidget {
  final String? title;
  final IconData? icon;
  final EdgeInsetsGeometry padding;
  final Widget child;

  const MobileSectionCard({
    super.key,
    this.title,
    this.icon,
    this.padding = const EdgeInsets.all(16),
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null) ...[
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: AppTheme.primary),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    title!,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.foreground,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
          ],
          child,
        ],
      ),
    );
  }
}
