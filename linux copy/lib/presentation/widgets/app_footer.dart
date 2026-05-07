import 'package:flutter/material.dart';

import 'package:adota_pet/core/theme/app_theme.dart';

class AppFooter extends StatelessWidget {
  const AppFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
      decoration: const BoxDecoration(
        color: Color(0xF2FAF6F1),
        border: Border(top: BorderSide(color: AppTheme.border, width: 1)),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 24,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: const [
          Text(
            '© 2026 AdotaPet · Conectando vidas, transformando histórias.',
            style: TextStyle(color: AppTheme.mutedForeground, fontSize: 13),
          ),
          _FooterLink(label: 'Termos'),
          _FooterLink(label: 'Privacidade'),
          _FooterLink(label: 'Contato'),
        ],
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  final String label;

  const _FooterLink({required this.label});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {},
        child: Text(
          label,
          style: const TextStyle(
            color: AppTheme.primary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }
}
