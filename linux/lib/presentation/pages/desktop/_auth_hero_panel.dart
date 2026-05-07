import 'package:flutter/material.dart';

import 'package:adota_pet/core/theme/app_theme.dart';
import 'package:adota_pet/presentation/widgets/app_logo.dart';

/// Painel lateral compartilhado pelas telas de autenticação no desktop.
class AuthHeroPanel extends StatelessWidget {
  const AuthHeroPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary, AppTheme.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(56),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppLogo(size: 80, onDarkBackground: true),
                const SizedBox(height: 36),
                Text(
                  'Conectando vidas,\ntransformando histórias.',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Painel de gestão para protetores e ONGs '
                  'cadastrarem pets, gerenciarem solicitações '
                  'e acompanharem adoções.',
                  style: TextStyle(
                    color: Color(0xE6FFFFFF),
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                _HeroBullet(
                  icon: Icons.pets_rounded,
                  text: 'Cadastre e gerencie seus pets em um só lugar',
                ),
                _HeroBullet(
                  icon: Icons.assignment_turned_in_rounded,
                  text: 'Acompanhe solicitações de adoção em tempo real',
                ),
                _HeroBullet(
                  icon: Icons.event_available_rounded,
                  text: 'Organize feiras e eventos de adoção',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroBullet extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HeroBullet({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xF2FFFFFF),
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
