import 'package:flutter/material.dart';

import 'package:adota_pet/core/theme/app_theme.dart';

/// Cores e rótulos semânticos de status, centralizados para evitar o hardcode
/// que estava espalhado pelas telas (pets e solicitações de adoção).
///
/// Antes desta classe, cada tela definia o próprio `Color(0xFF...)` para o
/// mesmo status — fonte de inconsistência visual. Use sempre estes helpers.
class AppStatusColors {
  AppStatusColors._();

  // ── Pets ────────────────────────────────────────────────────────────────
  static const Color petDisponivel = AppTheme.sage;
  static const Color petEmProcesso = AppTheme.accent;
  static const Color petAdotado = AppTheme.primary;

  static Color pet(String status) {
    switch (status) {
      case 'disponivel':
        return petDisponivel;
      case 'em_processo':
        return petEmProcesso;
      case 'adotado':
        return petAdotado;
      default:
        return AppTheme.mutedForeground;
    }
  }

  // ── Solicitações de adoção ────────────────────────────────────────────────
  static const Color requestReceived = AppTheme.accent;
  static const Color requestInAnalysis = AppTheme.primary;
  static const Color requestApproved = AppTheme.sage;
  static const Color requestRejected = AppTheme.destructive;

  static Color request(String status) {
    switch (status) {
      case 'received':
        return requestReceived;
      case 'in_analysis':
        return requestInAnalysis;
      case 'approved':
        return requestApproved;
      case 'rejected':
        return requestRejected;
      default:
        return AppTheme.mutedForeground;
    }
  }

  static String requestLabel(String status) {
    switch (status) {
      case 'received':
        return 'Recebida';
      case 'in_analysis':
        return 'Em análise';
      case 'approved':
        return 'Aprovada';
      case 'rejected':
        return 'Rejeitada';
      default:
        return status;
    }
  }
}
