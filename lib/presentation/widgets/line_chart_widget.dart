// ignore_for_file: unnecessary_underscores

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:adota_pet/core/theme/app_theme.dart';
import 'package:adota_pet/domain/entities/dashboard_data.dart';

/// Gráfico de linha suavizado para séries temporais mensais.
/// Usa fl_chart; exibe tooltip ao tocar/hover com valor e mês.
class LineChartWidget extends StatefulWidget {
  final List<TimelinePoint> points;
  final Color color;
  final double height;

  const LineChartWidget({
    super.key,
    required this.points,
    this.color = AppTheme.primary,
    this.height = 220,
  });

  @override
  State<LineChartWidget> createState() => _LineChartWidgetState();
}

class _LineChartWidgetState extends State<LineChartWidget> {
  static const _meses = [
    'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
    'jul', 'ago', 'set', 'out', 'nov', 'dez',
  ];

  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    if (widget.points.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: const Center(
          child: Text(
            'Sem dados no período',
            style: TextStyle(color: AppTheme.mutedForeground),
          ),
        ),
      );
    }

    final maxY = widget.points
        .map((p) => p.count.toDouble())
        .fold<double>(0, (a, b) => a > b ? a : b);
    final double safeMax = maxY < 1 ? 4.0 : (maxY * 1.25).ceilToDouble();

    final spots = widget.points
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.count.toDouble()))
        .toList();

    return SizedBox(
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
            horizontalInterval: (safeMax / 4).clamp(1, double.infinity),
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
                interval: (safeMax / 4).clamp(1, double.infinity),
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
                interval: _bottomInterval(widget.points.length),
                getTitlesWidget: (v, _) {
                  final idx = v.toInt();
                  if (idx < 0 || idx >= widget.points.length) {
                    return const SizedBox.shrink();
                  }
                  final m = widget.points[idx].monthStart;
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
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          lineTouchData: LineTouchData(
            handleBuiltInTouches: true,
            touchCallback: (event, response) {
              setState(() {
                _touchedIndex =
                    response?.lineBarSpots?.firstOrNull?.spotIndex;
              });
            },
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => AppTheme.foreground,
              getTooltipItems: (spots) => spots.map((s) {
                final idx = s.spotIndex;
                final p = widget.points[idx];
                final m = p.monthStart;
                return LineTooltipItem(
                  '${_meses[m.month - 1]}/${m.year}\n',
                  const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  children: [
                    TextSpan(
                      text: '${p.count}',
                      style: TextStyle(
                        color: widget.color,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.35,
              color: widget.color,
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, _, __, idx) {
                  final touched = idx == _touchedIndex;
                  return FlDotCirclePainter(
                    radius: touched ? 5 : 3,
                    color: touched ? widget.color : Colors.white,
                    strokeWidth: 2,
                    strokeColor: widget.color,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    widget.color.withOpacity(0.2),
                    widget.color.withOpacity(0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _bottomInterval(int count) {
    if (count <= 6) return 1;
    if (count <= 12) return 2;
    return 4;
  }
}