import 'package:flutter/material.dart';

import 'package:adota_pet/core/theme/app_theme.dart';

/// Diálogo de confirmação themed, para ações destrutivas ou que pedem
/// dupla-checagem. Retorna `true` se o usuário confirmou. Substitui os
/// `AlertDialog` montados ad-hoc em cada tela.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirmar',
  String cancelLabel = 'Cancelar',
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      title: Text(title, style: Theme.of(ctx).textTheme.titleMedium),
      content: Text(
        message,
        style: const TextStyle(color: AppTheme.foreground, height: 1.4),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(
            cancelLabel,
            style: const TextStyle(color: AppTheme.mutedForeground),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(
            confirmLabel,
            style: TextStyle(
              color: destructive ? AppTheme.destructive : AppTheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
  return result ?? false;
}
