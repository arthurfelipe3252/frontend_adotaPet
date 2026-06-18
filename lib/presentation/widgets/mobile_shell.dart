import 'package:flutter/material.dart';

import 'package:adota_pet/core/theme/app_theme.dart';
import 'package:adota_pet/presentation/pages/mobile/catalog_page.dart';
import 'package:adota_pet/presentation/pages/mobile/chat_page.dart';
import 'package:adota_pet/presentation/pages/mobile/home_page.dart';
import 'package:adota_pet/presentation/pages/mobile/profile_page.dart';
import 'package:adota_pet/presentation/widgets/mobile_screen_header.dart';
import 'package:adota_pet/presentation/widgets/mobile_shell_scope.dart';

/// Shell de navegação do app do adotante (mobile): bottom-nav fixa de 5 abas
/// com `IndexedStack` preservando o estado de cada aba.
///
/// Início, Match e Perfil são placeholders por enquanto; Catálogo e Conversas
/// já usam as telas implementadas. As telas que ainda serão refatoradas
/// continuam intactas — aqui só montamos a estrutura de navegação.
class MobileShell extends StatefulWidget {
  /// Aba inicial (0 = Início). Permite abrir o shell direto numa aba.
  final int initialIndex;

  const MobileShell({super.key, this.initialIndex = 0});

  @override
  State<MobileShell> createState() => _MobileShellState();
}

class _MobileShellState extends State<MobileShell> {
  late int _index = widget.initialIndex;

  void _select(int i) {
    if (i != _index) setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    // IndexedStack mantém todas as abas vivas (estado/scroll preservados).
    final tabs = <Widget>[
      const HomePage(),
      const CatalogPage(embedded: true),
      const _ComingSoonTab(
        icon: Icons.favorite_rounded,
        title: 'Match',
        message: 'O match de pets por afinidade está a caminho.',
      ),
      const ChatPage(),
      const ProfilePage(),
    ];

    final scaffold = Scaffold(
      backgroundColor: AppTheme.background,
      body: IndexedStack(index: _index, children: tabs),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppTheme.border)),
        ),
        child: BottomNavigationBar(
          currentIndex: _index,
          onTap: _select,
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppTheme.surface,
          selectedItemColor: AppTheme.primary,
          unselectedItemColor: AppTheme.mutedForeground,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Início',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.pets_outlined),
              activeIcon: Icon(Icons.pets_rounded),
              label: 'Catálogo',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite_border_rounded),
              activeIcon: Icon(Icons.favorite_rounded),
              label: 'Match',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline_rounded),
              activeIcon: Icon(Icons.chat_bubble_rounded),
              label: 'Conversas',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );

    return MobileShellScope(
      currentIndex: _index,
      goTo: _select,
      child: scaffold,
    );
  }
}

/// Placeholder padrão para as abas ainda não implementadas (Match).
class _ComingSoonTab extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _ComingSoonTab({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            MobileScreenHeader(icon: icon, title: title, subtitle: 'Em breve'),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon,
                          size: 56, color: AppTheme.primary.withOpacity(0.4)),
                      const SizedBox(height: 16),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.mutedForeground,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
