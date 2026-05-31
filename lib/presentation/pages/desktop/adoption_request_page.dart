import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:adota_pet/core/theme/app_dimens.dart';
import 'package:adota_pet/core/theme/app_status_colors.dart';
import 'package:adota_pet/core/theme/app_theme.dart';
import 'package:adota_pet/domain/entities/adoption_request.dart';
import 'package:adota_pet/domain/entities/pet.dart';
import 'package:adota_pet/presentation/viewmodels/adoption_request_viewmodel.dart';
import 'package:adota_pet/presentation/viewmodels/pet_viewmodel.dart';
import 'package:adota_pet/presentation/widgets/app_filter_chip.dart';
import 'package:adota_pet/presentation/widgets/dashboard_stat_card.dart';
import 'package:adota_pet/presentation/widgets/page_header.dart';
import 'package:adota_pet/presentation/widgets/primary_button.dart';
import 'package:adota_pet/presentation/widgets/state_views.dart';
import 'package:adota_pet/presentation/widgets/status_pill.dart';

class AdoptionRequestPage extends StatefulWidget {
  const AdoptionRequestPage({super.key});

  @override
  State<AdoptionRequestPage> createState() => _AdoptionRequestPageState();
}

class _AdoptionRequestPageState extends State<AdoptionRequestPage> {
  String _filtroStatus = 'todos';

  static const _filtros = [
    ('todos', 'Todas'),
    ('received', 'Recebidas'),
    ('in_analysis', 'Em análise'),
    ('approved', 'Aprovadas'),
    ('rejected', 'Rejeitadas'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdoptionRequestViewmodel>().loadAll();
      final petVm = context.read<PetViewModel>();
      if (petVm.pets.isEmpty) petVm.loadPets();
    });
  }

  String _petNome(List<Pet> pets, String petId) {
    for (final p in pets) {
      if (p.id == petId) return p.nome;
    }
    final short = petId.length > 8 ? petId.substring(0, 8) : petId;
    return 'Pet #$short';
  }

  void _abrirModal(String requestId, String petNome) {
    showDialog(
      context: context,
      builder: (_) =>
          _AdoptionDetailModal(requestId: requestId, petNome: petNome),
    );
  }

  /// Marca a solicitação como "em análise" e abre o modal de detalhes.
  Future<void> _analisarEAbrir(String requestId, String petNome) async {
    await context
        .read<AdoptionRequestViewmodel>()
        .updateStatus(requestId, 'in_analysis');
    if (mounted) _abrirModal(requestId, petNome);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdoptionRequestViewmodel>();
    final pets = context.watch<PetViewModel>().pets;

    final filtradas = _filtroStatus == 'todos'
        ? vm.requests
        : vm.requests.where((r) => r.status == _filtroStatus).toList();

    return ColoredBox(
      color: AppTheme.background,
      child: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: vm.loadAll,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSpacing.contentMaxWidth,
            ),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.xl,
                    AppSpacing.xl,
                    AppSpacing.lg,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const PageHeader(
                          title: 'Solicitações de adoção',
                          subtitle:
                              'Acompanhe e responda aos pedidos recebidos pela sua organização.',
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        _Contadores(requests: vm.requests),
                        const SizedBox(height: AppSpacing.lg),
                        _Filtros(
                          filtros: _filtros,
                          selecionado: _filtroStatus,
                          onSelect: (s) => setState(() => _filtroStatus = s),
                        ),
                      ],
                    ),
                  ),
                ),
                _buildSliverBody(vm, pets, filtradas),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSliverBody(
    AdoptionRequestViewmodel vm,
    List<Pet> pets,
    List<AdoptionRequest> filtradas,
  ) {
    if (vm.isLoading && vm.requests.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: LoadingView(),
      );
    }
    if (vm.error != null && vm.requests.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: ErrorStateView(message: vm.error!, onRetry: vm.loadAll),
      );
    }
    if (filtradas.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: EmptyState(
          icon: Icons.inbox_rounded,
          title: 'Nenhuma solicitação encontrada',
          message: 'As solicitações de adoção aparecerão aqui.',
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        0,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, i) {
            final r = filtradas[i];
            final petNome = _petNome(pets, r.petId);
            return _AdoptionCard(
              request: r,
              petNome: petNome,
              onOpen: () => _abrirModal(r.id, petNome),
              onAnalisar: () => _analisarEAbrir(r.id, petNome),
            );
          },
          childCount: filtradas.length,
        ),
      ),
    );
  }
}

class _Contadores extends StatelessWidget {
  final List<AdoptionRequest> requests;
  const _Contadores({required this.requests});

  int _count(String s) => requests.where((r) => r.status == s).length;

  @override
  Widget build(BuildContext context) {
    final cards = <Widget>[
      DashboardStatCard(
        icon: Icons.inbox_rounded,
        value: '${_count('received')}',
        label: 'Recebidas',
        color: AppStatusColors.requestReceived,
      ),
      DashboardStatCard(
        icon: Icons.search_rounded,
        value: '${_count('in_analysis')}',
        label: 'Em análise',
        color: AppStatusColors.requestInAnalysis,
      ),
      DashboardStatCard(
        icon: Icons.check_circle_rounded,
        value: '${_count('approved')}',
        label: 'Aprovadas',
        color: AppStatusColors.requestApproved,
      ),
      DashboardStatCard(
        icon: Icons.cancel_rounded,
        value: '${_count('rejected')}',
        label: 'Rejeitadas',
        color: AppStatusColors.requestRejected,
      ),
    ];

    return LayoutBuilder(
      builder: (context, c) {
        final cols = c.maxWidth >= 760
            ? 4
            : c.maxWidth >= 380
            ? 2
            : 1;
        const gap = AppSpacing.md;
        final w = (c.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final card in cards) SizedBox(width: w, child: card),
          ],
        );
      },
    );
  }
}

class _Filtros extends StatelessWidget {
  final List<(String, String)> filtros;
  final String selecionado;
  final ValueChanged<String> onSelect;

  const _Filtros({
    required this.filtros,
    required this.selecionado,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final f in filtros)
          AppFilterChip(
            label: f.$2,
            selected: selecionado == f.$1,
            onTap: () => onSelect(f.$1),
          ),
      ],
    );
  }
}

/// Card-resumo de uma solicitação. O card inteiro é clicável e abre o modal de
/// detalhes; o botão "Analisar" (só em Recebidas) marca como em análise e
/// também abre o modal. As decisões (aceitar/rejeitar) ficam no modal.
class _AdoptionCard extends StatelessWidget {
  final AdoptionRequest request;
  final String petNome;
  final VoidCallback onOpen;
  final VoidCallback onAnalisar;

  const _AdoptionCard({
    required this.request,
    required this.petNome,
    required this.onOpen,
    required this.onAnalisar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _PetAvatar(),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      request.adopterNome ?? 'Adotante',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                    Text(
                                      'Interesse em $petNome',
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        color: AppTheme.mutedForeground,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              StatusPill(
                                label: AppStatusColors.requestLabel(
                                  request.status,
                                ),
                                color: AppStatusColors.request(request.status),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              _PreTriageBadge(status: request.preTriageStatus),
                              if (request.matchScore != null)
                                _MatchScoreChip(score: request.matchScore!),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        _formatData(request.createdAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.mutedForeground,
                        ),
                      ),
                    ),
                    if (request.status == 'received')
                      _ActionBtn(
                        label: 'Analisar',
                        icon: Icons.search_rounded,
                        color: AppStatusColors.requestInAnalysis,
                        onTap: onAnalisar,
                      )
                    else
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Ver detalhes',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary,
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                            color: AppTheme.primary,
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Modal de detalhes da solicitação. Reativo ao viewmodel (reflete o status
/// atual). Mostra os botões Aceitar/Rejeitar apenas enquanto a solicitação
/// está pendente (received/in_analysis); finalizada abre em leitura.
class _AdoptionDetailModal extends StatefulWidget {
  final String requestId;
  final String petNome;

  const _AdoptionDetailModal({required this.requestId, required this.petNome});

  @override
  State<_AdoptionDetailModal> createState() => _AdoptionDetailModalState();
}

class _AdoptionDetailModalState extends State<_AdoptionDetailModal> {
  /// `null` = ocioso; senão o status em curso ('approved'/'rejected').
  String? _busyAction;

  Future<void> _decidir(String status) async {
    setState(() => _busyAction = status);
    final vm = context.read<AdoptionRequestViewmodel>();
    await vm.updateStatus(widget.requestId, status);
    if (!mounted) return;
    // Só fecha se a ação realmente persistiu (o vm exibe toast em erro).
    final atualizada = vm.requests
        .where((r) => r.id == widget.requestId)
        .toList();
    final ok = atualizada.isNotEmpty && atualizada.first.status == status;
    if (ok) {
      Navigator.of(context).pop();
    } else {
      setState(() => _busyAction = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdoptionRequestViewmodel>();
    AdoptionRequest? request;
    for (final r in vm.requests) {
      if (r.id == widget.requestId) {
        request = r;
        break;
      }
    }

    final media = MediaQuery.sizeOf(context);
    final maxHeight = media.height * 0.85;
    // Em telas estreitas, reduz a margem do diálogo para dar mais largura útil.
    final inset = media.width < 480 ? 16.0 : 40.0;

    return Dialog(
      backgroundColor: AppTheme.surface,
      insetPadding: EdgeInsets.symmetric(horizontal: inset, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 520, maxHeight: maxHeight),
        child: request == null
            ? _naoEncontrada()
            : _conteudo(request),
      ),
    );
  }

  Widget _naoEncontrada() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Solicitação não encontrada.'),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Widget _conteudo(AdoptionRequest request) {
    final pendente =
        request.status == 'received' || request.status == 'in_analysis';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Cabeçalho ──────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 8, 16),
          child: Row(
            children: [
              const _PetAvatar(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      request.adopterNome ?? 'Adotante',
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Interesse em ${widget.petNome}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppTheme.mutedForeground,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                color: AppTheme.mutedForeground,
                tooltip: 'Fechar',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // ── Corpo ──────────────────────────────────────────────────────────
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    StatusPill(
                      label: AppStatusColors.requestLabel(request.status),
                      color: AppStatusColors.request(request.status),
                    ),
                    _PreTriageBadge(status: request.preTriageStatus),
                    if (request.matchScore != null)
                      _MatchScoreChip(score: request.matchScore!),
                  ],
                ),
                if (request.mensagem != null &&
                    request.mensagem!.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const _SectionLabel('Mensagem do adotante'),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Text(
                      request.mensagem!,
                      style: const TextStyle(
                        fontSize: 13.5,
                        height: 1.5,
                        color: AppTheme.foreground,
                      ),
                    ),
                  ),
                ],
                if (request.matchAnswers != null) ...[
                  const SizedBox(height: 20),
                  const _SectionLabel('Questionário de match'),
                  const SizedBox(height: 10),
                  _QuestionarioDetalhado(answers: request.matchAnswers!),
                ],
                const SizedBox(height: 20),
                const _SectionLabel('Enviada em'),
                const SizedBox(height: 6),
                Text(
                  _formatDataHora(request.createdAt),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.foreground,
                  ),
                ),
              ],
            ),
          ),
        ),
        // ── Rodapé ─────────────────────────────────────────────────────────
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(16),
          child: pendente ? _acoes() : _statusFinal(request.status),
        ),
      ],
    );
  }

  Widget _acoes() {
    final rejeitar = OutlinedButton.icon(
      onPressed: _busyAction == null ? () => _decidir('rejected') : null,
      icon: _busyAction == 'rejected'
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: AppTheme.destructive,
              ),
            )
          : const Icon(Icons.close_rounded, size: 18),
      label: const Text('Rejeitar'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.destructive,
        side: const BorderSide(color: AppTheme.destructive),
        minimumSize: const Size(0, 52),
      ),
    );
    final aceitar = PrimaryButton(
      label: 'Aceitar',
      trailingIcon: Icons.check_rounded,
      variant: PrimaryButtonVariant.sage,
      isLoading: _busyAction == 'approved',
      onPressed: _busyAction == null ? () => _decidir('approved') : null,
    );

    return LayoutBuilder(
      builder: (context, c) {
        // Telas estreitas: empilha (ação primária no topo) para os botões não
        // ficarem apertados nem estourarem o texto.
        if (c.maxWidth < 340) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              aceitar,
              const SizedBox(height: 10),
              SizedBox(width: double.infinity, child: rejeitar),
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: rejeitar),
            const SizedBox(width: 12),
            Expanded(child: aceitar),
          ],
        );
      },
    );
  }

  Widget _statusFinal(String status) {
    final aprovada = status == 'approved';
    return Row(
      children: [
        Icon(
          aprovada ? Icons.check_circle_rounded : Icons.cancel_rounded,
          color: AppStatusColors.request(status),
          size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            aprovada
                ? 'Esta solicitação já foi aprovada.'
                : 'Esta solicitação foi rejeitada.',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.mutedForeground,
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppTheme.mutedForeground,
        letterSpacing: 0.3,
      ),
    );
  }
}

class _PetAvatar extends StatelessWidget {
  const _PetAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withOpacity(0.3),
            AppTheme.accent.withOpacity(0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(Icons.pets_rounded, color: AppTheme.primary, size: 24),
    );
  }
}

class _PreTriageBadge extends StatelessWidget {
  final String status;
  const _PreTriageBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (Color color, String label) = switch (status) {
      'qualified' => (AppTheme.sage, '✓ Qualificado'),
      'review' => (AppTheme.accent, '⏳ Em revisão'),
      'disqualified' => (AppTheme.destructive, '✗ Desqualificado'),
      _ => (AppTheme.mutedForeground, status),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _MatchScoreChip extends StatelessWidget {
  final double score;
  const _MatchScoreChip({required this.score});

  @override
  Widget build(BuildContext context) {
    final color = score >= 70
        ? AppTheme.sage
        : score >= 50
        ? AppTheme.accent
        : AppTheme.destructive;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: 12, color: color),
          const SizedBox(width: 3),
          Text(
            '${score.toStringAsFixed(0)}% match',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Lista detalhada do questionário de match (label + valor), usada no modal.
class _QuestionarioDetalhado extends StatelessWidget {
  final Map<String, dynamic> answers;
  const _QuestionarioDetalhado({required this.answers});

  String _moradia() {
    switch (answers['tipoMoradia']) {
      case 'casa_com_quintal':
        return 'Casa com quintal';
      case 'casa_sem_quintal':
        return 'Casa sem quintal';
      case 'apartamento':
        return 'Apartamento';
      default:
        return '—';
    }
  }

  String _simNao(dynamic v) => v == true ? 'Sim' : 'Não';

  @override
  Widget build(BuildContext context) {
    final horas = answers['horasDisponiveisDia'];
    final itens = <(IconData, String, String)>[
      (Icons.home_outlined, 'Moradia', _moradia()),
      (
        Icons.schedule_rounded,
        'Disponibilidade',
        horas != null ? '$horas h por dia' : '—',
      ),
      (
        Icons.school_outlined,
        'Experiência prévia',
        _simNao(answers['temExperiencia']),
      ),
      (
        Icons.child_care_outlined,
        'Crianças em casa',
        _simNao(answers['temCriancas']),
      ),
      (Icons.pets_outlined, 'Outros pets', _simNao(answers['temOutrosPets'])),
    ];

    return Column(
      children: [
        for (final it in itens)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                Icon(it.$1, size: 18, color: AppTheme.mutedForeground),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    it.$2,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.mutedForeground,
                    ),
                  ),
                ),
                Text(
                  it.$3,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.foreground,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatData(DateTime dt) {
  final now = DateTime.now();
  final diff = now.difference(dt);
  if (diff.inMinutes < 1) return 'Agora mesmo';
  if (diff.inHours < 1) return 'Há ${diff.inMinutes} min';
  if (diff.inDays < 1) return 'Há ${diff.inHours} h';
  if (diff.inDays == 1) return 'Ontem';
  return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
}

String _formatDataHora(DateTime dt) {
  final d = dt.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.day)}/${two(d.month)}/${d.year} às ${two(d.hour)}:${two(d.minute)}';
}
