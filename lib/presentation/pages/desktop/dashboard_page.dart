import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:adota_pet/core/theme/app_dimens.dart';
import 'package:adota_pet/core/theme/app_status_colors.dart';
import 'package:adota_pet/core/theme/app_theme.dart';
import 'package:adota_pet/domain/entities/dashboard_data.dart';
import 'package:adota_pet/presentation/viewmodels/auth_viewmodel.dart';
import 'package:adota_pet/presentation/viewmodels/dashboard_viewmodel.dart';
import 'package:adota_pet/presentation/widgets/dashboard_stat_card.dart';
import 'package:adota_pet/presentation/widgets/mini_bar_chart.dart';
import 'package:adota_pet/presentation/widgets/primary_button.dart';
import 'package:adota_pet/presentation/widgets/section_card.dart';
import 'package:adota_pet/presentation/widgets/state_views.dart';
import 'package:adota_pet/presentation/widgets/status_pill.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardViewModel>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DashboardViewModel>();

    return ColoredBox(
      color: AppTheme.background,
      child: _buildBody(context, vm),
    );
  }

  Widget _buildBody(BuildContext context, DashboardViewModel vm) {
    if (vm.isLoading && vm.data == null) {
      return const LoadingView(message: 'Carregando seu painel...');
    }
    if (vm.error != null && vm.data == null) {
      return ErrorStateView(message: vm.error!, onRetry: vm.load);
    }
    final data = vm.data;
    if (data == null) return const LoadingView();

    final nome = context.read<AuthViewModel>().session?.usuario.nome ?? '';

    return RefreshIndicator(
      onRefresh: vm.load,
      color: AppTheme.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSpacing.contentMaxWidth,
            ),
            child: LayoutBuilder(
              builder: (context, c) {
                final wide = c.maxWidth >= 900;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Header(nome: nome, wide: wide),
                    const SizedBox(height: AppSpacing.xl),
                    _KpiGrid(kpis: data.kpis, maxWidth: c.maxWidth),
                    const SizedBox(height: AppSpacing.xl),
                    _twoCol(
                      wide,
                      SectionCard(
                        title: 'Adoções concluídas',
                        subtitle: 'Por mês',
                        icon: Icons.volunteer_activism_rounded,
                        child: MiniBarChart(
                          points: data.adoptionsTimeline,
                          color: AppTheme.sage,
                        ),
                      ),
                      SectionCard(
                        title: 'Solicitações recebidas',
                        subtitle: 'Por mês',
                        icon: Icons.inbox_rounded,
                        child: MiniBarChart(
                          points: data.requestsTimeline,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SectionCard(
                      title: 'Funil de solicitações',
                      subtitle: 'Distribuição por status no período',
                      icon: Icons.filter_alt_rounded,
                      child: _FunnelBars(funnel: data.funnel),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _twoCol(
                      wide,
                      SectionCard(
                        title: 'Pets mais procurados',
                        icon: Icons.trending_up_rounded,
                        child: _TopPetsList(pets: data.topPets),
                      ),
                      SectionCard(
                        title: 'Pets parados',
                        subtitle: 'Sem solicitações recentes',
                        icon: Icons.warning_amber_rounded,
                        child: _StalePetsList(pets: data.stalePets),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// Dispõe dois cards lado a lado em telas largas e empilhados em estreitas.
  Widget _twoCol(bool wide, Widget a, Widget b) {
    if (!wide) {
      return Column(
        children: [a, const SizedBox(height: AppSpacing.lg), b],
      );
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

class _Header extends StatelessWidget {
  final String nome;
  final bool wide;

  const _Header({required this.nome, required this.wide});

  @override
  Widget build(BuildContext context) {
    final titulo = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          nome.isEmpty ? 'Olá 🐾' : 'Olá, ${nome.split(' ').first} 🐾',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 4),
        const Text(
          'Aqui está o resumo da sua operação de adoção.',
          style: TextStyle(color: AppTheme.mutedForeground, fontSize: 14),
        ),
      ],
    );

    final acoes = Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        OutlinedButton.icon(
          onPressed: () => context.go('/adoptions'),
          icon: const Icon(Icons.assignment_rounded, size: 18),
          label: const Text('Ver solicitações'),
        ),
        PrimaryButton(
          label: 'Cadastrar pet',
          trailingIcon: Icons.add_rounded,
          fullWidth: false,
          onPressed: () => context.go('/pets/new'),
        ),
      ],
    );

    if (!wide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [titulo, const SizedBox(height: 16), acoes],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: titulo),
        acoes,
      ],
    );
  }
}

class _KpiGrid extends StatelessWidget {
  final DashboardKpis kpis;
  final double maxWidth;

  const _KpiGrid({required this.kpis, required this.maxWidth});

  @override
  Widget build(BuildContext context) {
    final cards = <Widget>[
      DashboardStatCard(
        icon: Icons.pets_rounded,
        value: '${kpis.petsDisponivel}',
        label: 'Pets disponíveis',
        color: AppStatusColors.petDisponivel,
      ),
      DashboardStatCard(
        icon: Icons.hourglass_bottom_rounded,
        value: '${kpis.petsEmProcesso}',
        label: 'Em processo',
        color: AppStatusColors.petEmProcesso,
      ),
      DashboardStatCard(
        icon: Icons.favorite_rounded,
        value: '${kpis.petsAdotadoMesAtual}',
        label: 'Adotados no mês',
        color: AppStatusColors.petAdotado,
      ),
      DashboardStatCard(
        icon: Icons.inbox_rounded,
        value: '${kpis.solicitacoesPendentes}',
        label: 'Solicitações pendentes',
        color: AppTheme.accent,
      ),
      DashboardStatCard(
        icon: Icons.trending_up_rounded,
        value: _fmtPct(kpis.taxaConversaoPct),
        label: 'Taxa de conversão',
        color: AppTheme.sage,
      ),
      DashboardStatCard(
        icon: Icons.schedule_rounded,
        value: _fmtDias(kpis.tempoMedioAdocaoDias),
        label: 'Tempo médio de adoção',
        color: AppTheme.primary,
      ),
    ];

    final cols = maxWidth >= 1000
        ? 4
        : maxWidth >= 680
        ? 3
        : maxWidth >= 440
        ? 2
        : 1;
    const gap = AppSpacing.lg;
    final itemW = (maxWidth - gap * (cols - 1)) / cols;

    return Wrap(
      spacing: gap,
      runSpacing: gap,
      children: [
        for (final card in cards) SizedBox(width: itemW, child: card),
      ],
    );
  }

  String _fmtPct(double? v) {
    if (v == null) return '—';
    final s = (v % 1 == 0) ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
    return '${s.replaceAll('.', ',')}%';
  }

  String _fmtDias(double? v) {
    if (v == null) return '—';
    final d = v.round();
    return '$d ${d == 1 ? 'dia' : 'dias'}';
  }
}

class _FunnelBars extends StatelessWidget {
  final AdoptionFunnel funnel;

  const _FunnelBars({required this.funnel});

  @override
  Widget build(BuildContext context) {
    final rows = <(String, int, Color)>[
      ('Recebidas', funnel.received, AppStatusColors.requestReceived),
      ('Em análise', funnel.inAnalysis, AppStatusColors.requestInAnalysis),
      ('Aprovadas', funnel.approved, AppStatusColors.requestApproved),
      ('Rejeitadas', funnel.rejected, AppStatusColors.requestRejected),
    ];
    final maxV = rows.map((r) => r.$2).fold<int>(0, (a, b) => a > b ? a : b);
    final safeMax = maxV == 0 ? 1 : maxV;

    return Column(
      children: [
        for (final r in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 92,
                  child: Text(
                    r.$1,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.foreground,
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppTheme.border.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: (r.$2 / safeMax).clamp(
                          r.$2 > 0 ? 0.04 : 0.0,
                          1.0,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: r.$3,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 28,
                  child: Text(
                    '${r.$2}',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.foreground,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _TopPetsList extends StatelessWidget {
  final List<TopPet> pets;

  const _TopPetsList({required this.pets});

  @override
  Widget build(BuildContext context) {
    if (pets.isEmpty) {
      return const _EmptyHint(text: 'Ainda não há solicitações para ranquear.');
    }
    return Column(
      children: [
        for (var i = 0; i < pets.length; i++)
          _PetRow(
            onTap: () => context.go('/pets/${pets[i].petId}'),
            leading: _RankBadge(position: i + 1),
            title: pets[i].nome,
            subtitle: pets[i].especieLabel,
            trailing: StatusPill(
              label:
                  '${pets[i].totalRequests} '
                  '${pets[i].totalRequests == 1 ? 'pedido' : 'pedidos'}',
              color: AppTheme.primary,
              icon: Icons.favorite_rounded,
            ),
          ),
      ],
    );
  }
}

class _StalePetsList extends StatelessWidget {
  final List<StalePet> pets;

  const _StalePetsList({required this.pets});

  @override
  Widget build(BuildContext context) {
    if (pets.isEmpty) {
      return const _EmptyHint(
        text: 'Nenhum pet parado — bom trabalho! 🎉',
      );
    }
    return Column(
      children: [
        for (final p in pets)
          _PetRow(
            onTap: () => context.go('/pets/${p.id}'),
            leading: const Icon(
              Icons.schedule_rounded,
              color: AppTheme.mutedForeground,
            ),
            title: p.nome,
            subtitle: p.especieLabel,
            trailing: StatusPill(
              label: '${p.diasNoCatalogo} dias',
              color: AppTheme.destructive,
            ),
          ),
      ],
    );
  }
}

class _PetRow extends StatelessWidget {
  final Widget leading;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback onTap;

  const _PetRow({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            SizedBox(width: 32, child: Center(child: leading)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                      color: AppTheme.foreground,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppTheme.mutedForeground,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            trailing,
          ],
        ),
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  final int position;
  const _RankBadge({required this.position});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.12),
        shape: BoxShape.circle,
      ),
      child: Text(
        '$position',
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 13,
          color: AppTheme.primary,
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String text;
  const _EmptyHint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppTheme.mutedForeground),
        ),
      ),
    );
  }
}
