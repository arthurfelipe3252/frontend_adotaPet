import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:adota_pet/core/theme/app_dimens.dart';
import 'package:adota_pet/core/theme/app_theme.dart';
import 'package:adota_pet/domain/entities/usuario.dart';
import 'package:adota_pet/presentation/viewmodels/auth_viewmodel.dart';
import 'package:adota_pet/presentation/widgets/app_logo.dart';

/// Shell do painel da ONG: sidebar lateral fixa (padrão web) + área de
/// conteúdo. Substitui o antigo `OrgLayout` (bottom-nav mobile com cores fora
/// do tema). É montado uma única vez pela `ShellRoute`, então a sidebar
/// persiste entre as telas sem reconstruir.
///
/// Responsivo: sidebar expandida em telas largas; em telas estreitas vira um
/// `Drawer` acionado por um botão de menu no topo.
class OrgShell extends StatelessWidget {
  final Widget child;
  const OrgShell({super.key, required this.child});

  static const List<_NavItem> _items = [
    _NavItem(icon: Icons.dashboard_rounded, label: 'Painel', route: '/home'),
    _NavItem(icon: Icons.pets_rounded, label: 'Meus Pets', route: '/pets'),
    _NavItem(
      icon: Icons.assignment_rounded,
      label: 'Solicitações',
      route: '/adoptions',
    ),
    _NavItem(
      icon: Icons.chat_rounded,
      label: 'Chat',
      route: '/chat',
    ),
    _NavItem(
      icon: Icons.settings_rounded,
      label: 'Configurações',
      route: '/settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final expanded = width >= AppSpacing.sidebarExpandBreakpoint;
    final location = GoRouterState.of(context).uri.path;

    if (expanded) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: Row(
          children: [
            _Sidebar(location: location),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppLogo(size: 28),
            const SizedBox(width: 10),
            Text('AdotaPet', style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ),
      drawer: Drawer(
        backgroundColor: AppTheme.surface,
        child: _Sidebar(location: location, inDrawer: true),
      ),
      body: child,
    );
  }
}

class _Sidebar extends StatelessWidget {
  final String location;
  final bool inDrawer;

  const _Sidebar({required this.location, this.inDrawer = false});

  bool _isActive(String route) {
    if (route == '/home') return location == '/home';
    return location == route || location.startsWith('$route/');
  }

  void _go(BuildContext context, String route) {
    if (inDrawer) Navigator.of(context).pop();
    if (!_isActive(route)) context.go(route);
  }

  Future<void> _logout(BuildContext context) async {
    if (inDrawer) Navigator.of(context).pop();
    await context.read<AuthViewModel>().logout();
    if (context.mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthViewModel>().session?.usuario;

    return Container(
      width: AppSpacing.sidebarWidth,
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(right: BorderSide(color: AppTheme.border)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Row(
                children: [
                  const AppLogo(size: 38),
                  const SizedBox(width: 12),
                  Text(
                    'AdotaPet',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            const SizedBox(height: 12),
            ...OrgShell._items.map(
              (item) => _SidebarTile(
                item: item,
                active: _isActive(item.route),
                onTap: () => _go(context, item.route),
              ),
            ),
            const Spacer(),
            const Divider(height: 1),
            _UserFooter(
              usuario: usuario,
              onLogout: () => _logout(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarTile extends StatelessWidget {
  final _NavItem item;
  final bool active;
  final VoidCallback onTap;

  const _SidebarTile({
    required this.item,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: active ? AppTheme.primary.withOpacity(0.12) : null,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  size: 22,
                  color: active ? AppTheme.primary : AppTheme.mutedForeground,
                ),
                const SizedBox(width: 12),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                    color: active ? AppTheme.primary : AppTheme.foreground,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UserFooter extends StatelessWidget {
  final Usuario? usuario;
  final VoidCallback onLogout;

  const _UserFooter({required this.usuario, required this.onLogout});

  String get _tipoLabel {
    if (usuario == null) return '';
    return usuario!.isOng ? 'ONG' : 'Protetor';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.primary.withOpacity(0.15),
                child: const Icon(
                  Icons.person_rounded,
                  size: 20,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      usuario?.nome ?? '—',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppTheme.foreground,
                      ),
                    ),
                    Text(
                      _tipoLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onLogout,
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Sair'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.destructive,
                side: const BorderSide(color: AppTheme.border),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final String route;
  const _NavItem({
    required this.icon,
    required this.label,
    required this.route,
  });
}
