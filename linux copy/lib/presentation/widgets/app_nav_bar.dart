import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:adota_pet/core/theme/app_theme.dart';
import 'package:adota_pet/presentation/widgets/app_logo.dart';

class AppNavBar extends StatelessWidget {
  final bool showLoginAction;

  const AppNavBar({super.key, this.showLoginAction = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: const BoxDecoration(
        // background com leve translucidez pra deixar os símbolos atrás
        // aparecerem sutilmente sob o header.
        color: Color(0xF2FAF6F1),
        border: Border(bottom: BorderSide(color: AppTheme.border, width: 1)),
      ),
      child: Row(
        children: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => context.go('/login'),
              behavior: HitTestBehavior.opaque,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AppLogo(size: 36),
                  const SizedBox(width: 12),
                  Text(
                    'AdotaPet',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.foreground,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          if (showLoginAction)
            Row(
              children: [
                const Text(
                  'Já tem uma conta?',
                  style: TextStyle(
                    color: AppTheme.mutedForeground,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Entrar',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded, size: 16),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
