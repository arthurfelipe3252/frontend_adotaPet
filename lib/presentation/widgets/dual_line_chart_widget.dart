// ignore_for_file: unnecessary_underscores

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:adota_pet/core/theme/app_theme.dart';
import 'package:adota_pet/domain/entities/dashboard_data.dart';

/// Gráfico de linhas duplo: adoções (verde) e solicitações (laranja) no
/// mesmo eixo de tempo. Facilita comparar o volume de entrada vs. saída.
class DualLineChartWidget extends StatefulWidget {
  final List<TimelinePoint> adoptions;
  final List<TimelinePoint> requests;
  final double height;

  const DualLineChartWidget({
    super.key,
    required this.adoptions,
    required this.requests,
    this.height = 240,
  });

  @override
  State<DualLineChartWidget> createState() => _DualLineChartWidgetState();
}

class _DualLineChartWidgetState extends State<DualLineChartWidget> {
  static const _meses = [
    'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
    'jul', 'ago', 'set', 'out', 'nov', 'dez',
  ];

  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final allPoints = [...widget.adoptions, ...widget.requests];
    if (allPoints.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: const Center(
          child: Text('Sem dados no período',
              style: TextStyle(color: AppTheme.mutedForeground)),
        ),
      );
    }

    final maxY = allPoints
        .map((p) => p.count.toDouble())
        .fold<double>(0, (a, b) => a > b ? a : b);
    final double safeMax = maxY < 1 ? 4.0 : (maxY * 1.3).ceilToDouble();
    final double yInterval = (safeMax / 4).clamp(1.0, double.infinity);

    final adoptSpots = widget.adoptions
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.count.toDouble()))
        .toList();

    final reqSpots = widget.requests
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.count.toDouble()))
        .toList();

    final pts = widget.adoptions.isNotEmpty
        ? widget.adoptions
        : widget.requests;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Legenda
        Row(
          children: [
            _LegendDot(color: AppTheme.sage, label: 'Adoções'),
            const SizedBox(width: 16),
            _LegendDot(color: AppTheme.primary, label: 'Solicitações'),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: widget.height,
          child: LineChart(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
            LineChartData(
              minY: 0,
              maxY: safeMax,
              clipData: const FlClipData.all(),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: yInterval,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: AppTheme.border.withOpacity(0.6),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    interval: yInterval,
                    getTitlesWidget: (v, _) => Text(
                      v == 0 ? '' : v.toInt().toString(),
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppTheme.mutedForeground,
                      ),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    interval: pts.length <= 6
                        ? 1.0
                        : pts.length <= 12
                            ? 2.0
                            : 4.0,
                    getTitlesWidget: (v, _) {
                      final idx = v.toInt();
                      if (idx < 0 || idx >= pts.length) {
                        return const SizedBox.shrink();
                      }
                      final m = pts[idx].monthStart;
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          _meses[m.month - 1],
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppTheme.mutedForeground,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
              ),
              lineTouchData: LineTouchData(
                handleBuiltInTouches: true,
                touchCallback: (_, response) {
                  setState(() {
                    _touchedIndex =
                        response?.lineBarSpots?.firstOrNull?.spotIndex;
                  });
                },
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => AppTheme.foreground,
                  getTooltipItems: (spots) {
                    return spots.map((s) {
                      final isAdoption = s.barIndex == 0;
                      final label = isAdoption ? 'Adoções' : 'Solicitações';
                      final color =
                          isAdoption ? AppTheme.sage : AppTheme.primary;
                      final idx = s.spotIndex;
                      final source = isAdoption ? widget.adoptions : widget.requests;
                      final m = idx < source.length
                          ? source[idx].monthStart
                          : null;
                      return LineTooltipItem(
                        m != null
                            ? '${_meses[m.month - 1]}/${m.year}\n'
                            : '',
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                        children: [
                          TextSpan(
                            text: '$label: ${s.y.toInt()}',
                            style: TextStyle(
                              color: color,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      );
                    }).toList();
                  },
                ),
              ),
              lineBarsData: [
                _buildBar(adoptSpots, AppTheme.sage),
                _buildBar(reqSpots, AppTheme.primary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  LineChartBarData _buildBar(List<FlSpot> spots, Color color) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      curveSmoothness: 0.35,
      color: color,
      barWidth: 2.5,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, _, __, idx) {
          final touched = idx == _touchedIndex;
          return FlDotCirclePainter(
            radius: touched ? 5 : 3,
            color: touched ? color : Colors.white,
            strokeWidth: 2,
            strokeColor: color,
          );
        },
      ),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.15),
            color.withOpacity(0.0),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.mutedForeground,
          ),
        ),
      ],
    );
  }
}