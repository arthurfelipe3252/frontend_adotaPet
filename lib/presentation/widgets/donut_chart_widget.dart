import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:adota_pet/core/theme/app_theme.dart';
import 'package:adota_pet/domain/entities/dashboard_data.dart';

/// Gráfico de rosca (donut) para o funil de adoções.
/// Mostra as 4 etapas com legenda lateral e tooltip de porcentagem.
class DonutChartWidget extends StatefulWidget {
  final AdoptionFunnel funnel;
  final double size;

  const DonutChartWidget({
    super.key,
    required this.funnel,
    this.size = 200,
  });

  @override
  State<DonutChartWidget> createState() => _DonutChartWidgetState();
}

class _DonutChartWidgetState extends State<DonutChartWidget> {
  int? _touchedIndex;

  static const _labels = ['Recebidas', 'Em análise', 'Aprovadas', 'Rejeitadas'];
  static const _colors = [
    Color(0xFFEFA63B), // accent – amber
    Color(0xFFD2693A), // primary – terra
    Color(0xFF7AAD83), // sage – verde
    Color(0xFFD93939), // destructive – vermelho
  ];

  @override
  Widget build(BuildContext context) {
    final f = widget.funnel;
    final values = [
      f.received.toDouble(),
      f.inAnalysis.toDouble(),
      f.approved.toDouble(),
      f.rejected.toDouble(),
    ];
    final total = values.fold(0.0, (a, b) => a + b);

    if (total == 0) {
      return SizedBox(
        height: widget.size,
        child: const Center(
          child: Text(
            'Sem solicitações no período',
            style: TextStyle(color: AppTheme.mutedForeground),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth >= 480;
        final chart = SizedBox(
          width: widget.size,
          height: widget.size,
          child: PieChart(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  setState(() {
                    _touchedIndex =
                        response?.touchedSection?.touchedSectionIndex;
                  });
                },
              ),
              sectionsSpace: 3,
              centerSpaceRadius: widget.size * 0.27,
              sections: List.generate(4, (i) {
                final touched = i == _touchedIndex;
                final pct = values[i] / total * 100;
                return PieChartSectionData(
                  value: values[i],
                  color: _colors[i],
                  radius: touched ? widget.size * 0.28 : widget.size * 0.24,
                  title: touched
                      ? '${pct.toStringAsFixed(1)}%'
                      : values[i] > 0
                          ? '${values[i].toInt()}'
                          : '',
                  titleStyle: TextStyle(
                    fontSize: touched ? 13 : 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  badgePositionPercentageOffset: 0.6,
                );
              }),
            ),
          ),
        );

        final legend = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(4, (i) {
            final v = values[i].toInt();
            final pct = (v / total * 100).toStringAsFixed(1);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _colors[i],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _labels[i],
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.foreground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$v ($pct%)',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.mutedForeground,
                    ),
                  ),
                ],
              ),
            );
          }),
        );

        if (!wide) {
          return Column(
            children: [
              Center(child: chart),
              const SizedBox(height: 16),
              legend,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            chart,
            const SizedBox(width: 24),
            Expanded(child: legend),
          ],
        );
      },
    );
  }
}