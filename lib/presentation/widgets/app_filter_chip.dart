import 'package:flutter/material.dart';

import 'package:adota_pet/core/theme/app_theme.dart';

/// Chip de filtro selecionável das barras de filtro do painel.
/// Selecionado = preenchido `primary`; caso contrário, `surface` + borda.
class AppFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const AppFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      backgroundColor: AppTheme.surface,
      selectedColor: AppTheme.primary,
      side: BorderSide(color: selected ? AppTheme.primary : AppTheme.border),
      labelStyle: TextStyle(
        color: selected ? Colors.white : AppTheme.foreground,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
      shape: const StadiumBorder(),
    );
  }
}
