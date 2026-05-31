import 'package:flutter/material.dart';

import 'package:adota_pet/core/theme/app_theme.dart';
import 'package:adota_pet/domain/entities/dashboard_data.dart';

/// Gráfico de barras mensal simples (sem dependência externa) para as séries
/// temporais do dashboard. Cada barra é um mês; a altura é proporcional ao
/// maior valor da série.
class MiniBarChart extends StatelessWidget {
  final List<TimelinePoint> points;
  final Color color;

  const MiniBarChart({
    super.key,
    required this.points,
    this.color = AppTheme.primary,
  });

  static const _meses = [
    'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
    'jul', 'ago', 'set', 'out', 'nov', 'dez',
  ];

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(
          child: Text(
            'Sem dados no período',
            style: TextStyle(color: AppTheme.mutedForeground),
          ),
        ),
      );
    }

    final maxCount = points
        .map((p) => p.count)
        .fold<int>(0, (a, b) => a > b ? a : b);
    final safeMax = maxCount == 0 ? 1 : maxCount;

    return SizedBox(
      height: 180,
      child: LayoutBuilder(
        builder: (context, c) {
          const labelArea = 44.0;
          final chartH = (c.maxHeight - labelArea).clamp(0.0, double.infinity);
          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final p in points)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          p.count > 0 ? '${p.count}' : '',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.foreground,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          height: (chartH * (p.count / safeMax)).clamp(
                            p.count > 0 ? 3.0 : 0.0,
                            chartH,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.85),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _meses[p.monthStart.month - 1],
                          style: const TextStyle(
                            fontSize: 9,
                            color: AppTheme.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
