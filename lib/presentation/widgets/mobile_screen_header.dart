import 'package:flutter/material.dart';

import 'package:adota_pet/core/theme/app_theme.dart';

/// Cabeçalho padrão das telas mobile (no corpo, sem AppBar): selo de ícone +
/// título (Quicksand) + subtítulo opcional, com um `trailing` opcional à
/// direita. Dá identidade às telas que antes tinham só o nome numa AppBar.
class MobileScreenHeader extends StatelessWidget {
  /// Selo de ícone padrão (usado quando [leading] não é informado).
  final IconData? icon;

  /// Leading customizado (ex.: avatar). Quando presente, substitui o selo.
  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  const MobileScreenHeader({
    super.key,
    this.icon,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(16, 10, 16, 10),
  }) : assert(icon != null || leading != null,
            'Informe um icon ou um leading');

  @override
  Widget build(BuildContext context) {
    final lead = leading ??
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppTheme.primary, size: 24),
        );

    return Padding(
      padding: padding,
      child: Row(
        children: [
          lead,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.mutedForeground,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 12),
            trailing!,
          ],
        ],
      ),
    );
  }
}
