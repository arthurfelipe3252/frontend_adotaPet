import 'package:flutter/material.dart';

import 'package:adota_pet/core/theme/app_theme.dart';

class PfPjToggle extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const PfPjToggle({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEDE6DA),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: _Option(
              label: 'Pessoa Física',
              icon: Icons.person_rounded,
              selected: selected == 'protetor',
              onTap: () => onChanged('protetor'),
            ),
          ),
          Expanded(
            child: _Option(
              label: 'Pessoa Jurídica',
              icon: Icons.business_rounded,
              selected: selected == 'ong',
              onTap: () => onChanged('ong'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Option extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _Option({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: selected ? AppTheme.foreground : AppTheme.mutedForeground,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: selected
                    ? AppTheme.foreground
                    : AppTheme.mutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
