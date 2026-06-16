import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:adota_pet/core/platform/file_download.dart';
import 'package:adota_pet/core/theme/app_dimens.dart';
import 'package:adota_pet/core/theme/app_status_colors.dart';
import 'package:adota_pet/core/theme/app_theme.dart';
import 'package:adota_pet/domain/entities/dashboard_data.dart';
import 'package:adota_pet/presentation/viewmodels/reports_viewmodel.dart';
import 'package:adota_pet/presentation/widgets/donut_chart_widget.dart';
import 'package:adota_pet/presentation/widgets/dual_line_chart_widget.dart';
import 'package:adota_pet/presentation/widgets/line_chart_widget.dart';
import 'package:adota_pet/presentation/widgets/section_card.dart';
import 'package:adota_pet/presentation/widgets/state_views.dart';
import 'package:adota_pet/presentation/widgets/status_pill.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportsViewModel>().load();
    });
  }

  Future<void> _download(Uint8List bytes, String filename, String mime) async {
    if (kIsWeb) {
      // Conditional import (web usa dart:html; nativo usa stub) — mantém o
      // `flutter build apk` funcionando. Respeita filename/mime (XLSX e CSV).
      downloadBytes(bytes, filename: filename, mimeType: mime);
    }
  }

  Future<void> _downloadXlsx() async {
    final vm = context.read<ReportsViewModel>();
    final bytes = await vm.buildXlsx();
    if (bytes == null) { _showExportError(vm.exportError); return; }
    await _download(
      bytes,
      'adotapet_relatorio.xlsx',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
  }

  Future<void> _downloadCsv() async {
    final vm = context.read<ReportsViewModel>();
    final bytes = await vm.buildCsv();
    if (bytes == null) { _showExportError(vm.exportError); return; }
    await _download(bytes, 'adotapet_relatorio.csv', 'text/csv;charset=utf-8');
  }

  void _showExportError(String? msg) {
    if (!mounted || msg == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppTheme.destructive),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReportsViewModel>();

    return ColoredBox(
      color: AppTheme.background,
      child: _buildBody(context, vm),
    );
  }

  Widget _buildBody(BuildContext context, ReportsViewModel vm) {
    if (vm.isLoading && vm.data == null) {
      return const LoadingView(message: 'Carregando relatórios...');
    }
    if (vm.error != null && vm.data == null) {
      return ErrorStateView(message: vm.error!, onRetry: vm.load);
    }
    final data = vm.data;
    if (data == null) return const LoadingView();

    return RefreshIndicator(
      onRefresh: vm.load,
      color: AppTheme.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: AppSpacing.contentMaxWidth),
            child: LayoutBuilder(builder: (context, c) {
              final wide = c.maxWidth >= 900;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ReportsHeader(
                    period: vm.period,
                    isExporting: vm.isExporting,
                    onPeriodChanged: vm.setPeriod,
                    onExportXlsx: _downloadXlsx,
                    onExportCsv: _downloadCsv,
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // ── KPI chips ────────────────────────────────────────────
                  _KpiStrip(kpis: data.kpis),
                  const SizedBox(height: AppSpacing.xl),

                  // ── Gráfico duplo: adoções + solicitações ─────────────────
                  SectionCard(
                    title: 'Evolução Mensal',
                    subtitle:
                        'Adoções concluídas vs solicitações recebidas — ${vm.period.label}',
                    icon: Icons.show_chart_rounded,
                    child: DualLineChartWidget(
                      adoptions: data.adoptionsTimeline,
                      requests: data.requestsTimeline,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ── Linha 2: adoções individuais + solicitações individuais
                  _twoCol(
                    wide,
                    SectionCard(
                      title: 'Adoções por Mês',
                      icon: Icons.volunteer_activism_rounded,
                      child: LineChartWidget(
                        points: data.adoptionsTimeline,
                        color: AppTheme.sage,
                      ),
                    ),
                    SectionCard(
                      title: 'Solicitações por Mês',
                      icon: Icons.inbox_rounded,
                      child: LineChartWidget(
                        points: data.requestsTimeline,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ── Linha 3: funil (donut) + top pets tabela ─────────────
                  _twoCol(
                    wide,
                    SectionCard(
                      title: 'Funil de Adoção',
                      subtitle: 'Distribuição por etapa',
                      icon: Icons.filter_alt_rounded,
                      child: DonutChartWidget(funnel: data.funnel),
                    ),
                    SectionCard(
                      title: 'Top Pets Mais Solicitados',
                      icon: Icons.emoji_events_rounded,
                      child: _TopPetsTable(pets: data.topPets),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ── Linha 4: pets parados + métricas de chat ─────────────
                  _twoCol(
                    wide,
                    SectionCard(
                      title: 'Pets Parados no Catálogo',
                      subtitle: 'Sem solicitações recentes (≥ 30 dias)',
                      icon: Icons.warning_amber_rounded,
                      child: _StalePetsTable(pets: data.stalePets),
                    ),
                    SectionCard(
                      title: 'Engajamento',
                      subtitle: 'Resumo de conversas e mensagens',
                      icon: Icons.chat_bubble_outline_rounded,
                      child: _EngagementPanel(kpis: data.kpis),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _twoCol(bool wide, Widget a, Widget b) {
    if (!wide) {
      return Column(
          children: [a, const SizedBox(height: AppSpacing.lg), b]);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: a),
        const SizedBox(width: AppSpacing.lg),
        Expanded(child: b),
      ],
    );
  }
}

// ── Header ─────────────────────────────────────────────────────────────────

class _ReportsHeader extends StatelessWidget {
  final ReportsPeriod period;
  final bool isExporting;
  final Future<void> Function(ReportsPeriod) onPeriodChanged;
  final VoidCallback onExportXlsx;
  final VoidCallback onExportCsv;

  const _ReportsHeader({
    required this.period,
    required this.isExporting,
    required this.onPeriodChanged,
    required this.onExportXlsx,
    required this.onExportCsv,
  });

  @override
  Widget build(BuildContext context) {
    final titulo = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Relatórios & Análises',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 4),
        const Text(
          'Acompanhe o desempenho da sua operação de adoção.',
          style:
              TextStyle(color: AppTheme.mutedForeground, fontSize: 14),
        ),
      ],
    );

    final actions = Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _PeriodSelector(current: period, onChange: onPeriodChanged),
        _ExportMenuButton(
          isExporting: isExporting,
          onXlsx: onExportXlsx,
          onCsv: onExportCsv,
        ),
      ],
    );

    return LayoutBuilder(builder: (_, c) {
      if (c.maxWidth < 700) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [titulo, const SizedBox(height: 16), actions],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: titulo),
          actions,
        ],
      );
    });
  }
}

class _ExportMenuButton extends StatelessWidget {
  final bool isExporting;
  final VoidCallback onXlsx;
  final VoidCallback onCsv;

  const _ExportMenuButton({
    required this.isExporting,
    required this.onXlsx,
    required this.onCsv,
  });

  @override
  Widget build(BuildContext context) {
    final buttonStyle = FilledButton.styleFrom(
      backgroundColor: AppTheme.sage,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );

    if (isExporting) {
      return FilledButton.icon(
        onPressed: null,
        style: buttonStyle,
        icon: const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        ),
        label: const Text('Gerando...'),
      );
    }

    return MenuAnchor(
      builder: (context, controller, _) => FilledButton.icon(
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
        style: buttonStyle,
        icon: const Icon(Icons.download_rounded, size: 18),
        label: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Exportar'),
            SizedBox(width: 4),
            Icon(Icons.arrow_drop_down_rounded, size: 18),
          ],
        ),
      ),
      menuChildren: [
        MenuItemButton(
          leadingIcon: const Icon(Icons.table_chart_outlined,
              size: 18, color: AppTheme.sage),
          onPressed: onXlsx,
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Excel (.xlsx)',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
                Text('6 abas com todos os dados',
                    style: TextStyle(
                        fontSize: 11, color: AppTheme.mutedForeground)),
              ],
            ),
          ),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.text_snippet_outlined,
              size: 18, color: AppTheme.primary),
          onPressed: onCsv,
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('CSV (.csv)',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
                Text('Arquivo único com seções',
                    style: TextStyle(
                        fontSize: 11, color: AppTheme.mutedForeground)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  final ReportsPeriod current;
  final Future<void> Function(ReportsPeriod) onChange;

  const _PeriodSelector({required this.current, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ReportsPeriod>(
          value: current,
          borderRadius: BorderRadius.circular(14),
          style: const TextStyle(
            color: AppTheme.foreground,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          items: ReportsPeriod.values
              .map(
                (p) => DropdownMenuItem(
                  value: p,
                  child: Text(p.label),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) onChange(v);
          },
        ),
      ),
    );
  }
}

// ── KPI strip ──────────────────────────────────────────────────────────────

class _KpiStrip extends StatelessWidget {
  final DashboardKpis kpis;
  const _KpiStrip({required this.kpis});

  @override
  Widget build(BuildContext context) {
    final items = <({IconData icon, String value, String label, Color color})>[
      (
        icon: Icons.pets_rounded,
        value: '${kpis.petsDisponivel}',
        label: 'Disponíveis',
        color: AppStatusColors.petDisponivel,
      ),
      (
        icon: Icons.hourglass_bottom_rounded,
        value: '${kpis.petsEmProcesso}',
        label: 'Em processo',
        color: AppStatusColors.petEmProcesso,
      ),
      (
        icon: Icons.favorite_rounded,
        value: '${kpis.petsAdotadoTotal}',
        label: 'Adotados (total)',
        color: AppStatusColors.petAdotado,
      ),
      (
        icon: Icons.inbox_rounded,
        value: '${kpis.solicitacoesPendentes}',
        label: 'Pendentes',
        color: AppTheme.accent,
      ),
      (
        icon: Icons.trending_up_rounded,
        value: kpis.taxaConversaoPct == null
            ? '—'
            : '${kpis.taxaConversaoPct!.toStringAsFixed(1)}%',
        label: 'Conversão',
        color: AppTheme.sage,
      ),
      (
        icon: Icons.schedule_rounded,
        value: kpis.tempoMedioAdocaoDias == null
            ? '—'
            : '${kpis.tempoMedioAdocaoDias!.round()} dias',
        label: 'Tempo médio',
        color: AppTheme.primary,
      ),
    ];

    return LayoutBuilder(builder: (_, c) {
      final cols = c.maxWidth >= 1000
          ? 6
          : c.maxWidth >= 760
              ? 4
              : c.maxWidth >= 500
                  ? 3
                  : 2;
      const gap = AppSpacing.lg;
      final itemW = (c.maxWidth - gap * (cols - 1)) / cols;

      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: items
            .map(
              (it) => SizedBox(
                width: itemW,
                child: _KpiChip(
                  icon: it.icon,
                  value: it.value,
                  label: it.label,
                  color: it.color,
                ),
              ),
            )
            .toList(),
      );
    });
  }
}

class _KpiChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _KpiChip({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    color: AppTheme.foreground,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.mutedForeground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Top Pets Table ─────────────────────────────────────────────────────────

class _TopPetsTable extends StatelessWidget {
  final List<TopPet> pets;
  const _TopPetsTable({required this.pets});

  @override
  Widget build(BuildContext context) {
    if (pets.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'Ainda não há solicitações para ranquear.',
            style: TextStyle(color: AppTheme.mutedForeground),
          ),
        ),
      );
    }

    return Column(
      children: [
        // Cabeçalho
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: const [
              SizedBox(width: 32),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Pet',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.mutedForeground,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              SizedBox(
                width: 80,
                child: Text(
                  'Pedidos',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.mutedForeground,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        ...pets.asMap().entries.map((e) {
          final i = e.key;
          final p = e.value;
          return _TopPetRow(rank: i + 1, pet: p, total: pets.first.totalRequests);
        }),
      ],
    );
  }
}

class _TopPetRow extends StatelessWidget {
  final int rank;
  final TopPet pet;
  final int total;

  const _TopPetRow({
    required this.rank,
    required this.pet,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : pet.totalRequests / total;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Rank badge
          SizedBox(
            width: 32,
            child: Center(
              child: Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: rank == 1
                      ? const Color(0xFFFFD700).withOpacity(0.15)
                      : AppTheme.primary.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$rank',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: rank == 1
                        ? const Color(0xFFB8860B)
                        : AppTheme.primary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  pet.nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      pet.especieLabel,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppTheme.mutedForeground,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      height: 3,
                      width: 80 * pct,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          StatusPill(
            label:
                '${pet.totalRequests} ${pet.totalRequests == 1 ? 'pedido' : 'pedidos'}',
            color: AppTheme.primary,
            icon: Icons.favorite_rounded,
          ),
        ],
      ),
    );
  }
}

// ── Stale Pets Table ───────────────────────────────────────────────────────

class _StalePetsTable extends StatelessWidget {
  final List<StalePet> pets;
  const _StalePetsTable({required this.pets});

  @override
  Widget build(BuildContext context) {
    if (pets.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'Nenhum pet parado — bom trabalho! 🎉',
            style: TextStyle(color: AppTheme.mutedForeground),
          ),
        ),
      );
    }

    return Column(
      children: pets
          .map(
            (p) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppTheme.destructive.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.schedule_rounded,
                      size: 16,
                      color: AppTheme.destructive,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          p.nome,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          p.especieLabel,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                  StatusPill(
                    label: '${p.diasNoCatalogo} dias',
                    color: p.diasNoCatalogo >= 180
                        ? AppTheme.destructive
                        : AppTheme.accent,
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

// ── Engagement Panel ───────────────────────────────────────────────────────

class _EngagementPanel extends StatelessWidget {
  final DashboardKpis kpis;
  const _EngagementPanel({required this.kpis});

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        icon: Icons.chat_rounded,
        label: 'Conversas ativas',
        value: '${kpis.conversasAtivas}',
        color: AppTheme.primary,
      ),
      (
        icon: Icons.mark_chat_unread_rounded,
        label: 'Mensagens não lidas',
        value: '${kpis.mensagensNaoLidas}',
        color: kpis.mensagensNaoLidas > 0
            ? AppTheme.destructive
            : AppTheme.mutedForeground,
      ),
      (
        icon: Icons.checklist_rounded,
        label: 'Adoções no mês',
        value: '${kpis.petsAdotadoMesAtual}',
        color: AppTheme.sage,
      ),
    ];

    return Column(
      children: items.map((it) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: it.color.withOpacity(0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: it.color.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Icon(it.icon, color: it.color, size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  it.label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.foreground,
                  ),
                ),
              ),
              Text(
                it.value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: it.color,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}