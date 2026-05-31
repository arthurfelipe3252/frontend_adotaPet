import 'package:flutter/widgets.dart';

/// Tokens de espaçamento derivados dos valores recorrentes do design language
/// do login/registro. Preferir estes no lugar de números mágicos soltos.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// Largura máxima do conteúdo nas telas do painel (centralizado).
  static const double contentMaxWidth = 1200;

  /// Largura da sidebar fixa do painel.
  static const double sidebarWidth = 248;

  /// Breakpoint a partir do qual a sidebar fica expandida (vs. rail/drawer).
  static const double sidebarExpandBreakpoint = 1024;
}

/// Raios de borda padronizados (inputs, cards, pills).
class AppRadius {
  AppRadius._();

  static const double field = 20;
  static const double card = 28;
  static const double pill = 999;

  static const Radius fieldRadius = Radius.circular(field);
  static const Radius cardRadius = Radius.circular(card);
  static const BorderRadius fieldBorder = BorderRadius.all(fieldRadius);
  static const BorderRadius cardBorder = BorderRadius.all(cardRadius);
}
