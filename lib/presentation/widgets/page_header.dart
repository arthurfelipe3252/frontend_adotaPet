import 'package:flutter/material.dart';

import 'package:adota_pet/core/theme/app_theme.dart';

/// Cabeçalho padrão de uma tela do painel: título (+ subtítulo opcional) e
/// ações à direita. Como o shell não tem AppBar com título, é aqui que cada
/// tela apresenta seu título contextual. Responsivo: empilha as ações em
/// telas estreitas.
class PageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final Widget? leading;

  const PageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final titulo = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: const TextStyle(
              color: AppTheme.mutedForeground,
              fontSize: 14,
            ),
          ),
        ],
      ],
    );

    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth >= 640;
        final leftBlock = leading == null
            ? titulo
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  leading!,
                  const SizedBox(width: 12),
                  Flexible(child: titulo),
                ],
              );

        if (!wide || actions.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              leftBlock,
              if (actions.isNotEmpty) ...[
                const SizedBox(height: 16),
                Wrap(spacing: 12, runSpacing: 12, children: actions),
              ],
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: leftBlock),
            const SizedBox(width: 16),
            Wrap(spacing: 12, runSpacing: 12, children: actions),
          ],
        );
      },
    );
  }
}
