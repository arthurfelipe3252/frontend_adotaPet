import 'package:flutter/material.dart';

class OrgLayout extends StatelessWidget {
  final Widget child;
  final String? title;
  final int currentIndex;

  const OrgLayout({
    super.key,
    required this.child,
    this.title,
    this.currentIndex = 1,
  });

  static const _navItems = [
    _NavItem(
      icon: Icons.bar_chart_rounded,
      label: 'Painel',
      route: '/org/dashboard',
    ),
    _NavItem(icon: Icons.pets_rounded, label: 'Meus Pets', route: '/org/pets'),
    _NavItem(
      icon: Icons.assignment_rounded,
      label: 'Solicitações',
      route: '/org/requests',
    ),
    _NavItem(
      icon: Icons.calendar_month_rounded,
      label: 'Feiras',
      route: '/org/events',
    ),
    _NavItem(
      icon: Icons.person_rounded,
      label: 'Perfil',
      route: '/org/profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3F0),
      appBar: title != null
          ? PreferredSize(
              preferredSize: const Size.fromHeight(64),
              child: Container(
                color: Colors.white,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Painel da ONG',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey[500],
                                letterSpacing: 0.3,
                              ),
                            ),
                            Text(
                              title!,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () => Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/login',
                            (_) => false,
                          ),
                          child: const Text(
                            'Sair',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFE53935),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          : null,
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFEEEAE6), width: 1)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_navItems.length, (i) {
                final item = _navItems[i];
                final isActive = i == currentIndex;
                return GestureDetector(
                  onTap: () {
                    if (!isActive) {
                      Navigator.pushReplacementNamed(context, item.route);
                    }
                  },
                  child: Container(
                    color: Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item.icon,
                          size: 20,
                          color: isActive
                              ? const Color(0xFFCC6633)
                              : const Color(0xFF9E9E9E),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: isActive
                                ? const Color(0xFFCC6633)
                                : const Color(0xFF9E9E9E),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
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
