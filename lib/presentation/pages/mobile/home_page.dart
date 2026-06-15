import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:adota_pet/core/notifications/app_notifier.dart';
import 'package:adota_pet/core/theme/app_status_colors.dart';
import 'package:adota_pet/core/theme/app_theme.dart';
import 'package:adota_pet/domain/entities/adoption_request.dart';
import 'package:adota_pet/domain/entities/pet.dart';
import 'package:adota_pet/presentation/viewmodels/adoption_request_viewmodel.dart';
import 'package:adota_pet/presentation/viewmodels/auth_viewmodel.dart';
import 'package:adota_pet/presentation/viewmodels/catalog_viewmodel.dart';
import 'package:adota_pet/presentation/viewmodels/chat_viewmodel.dart';
import 'package:adota_pet/presentation/widgets/app_filter_chip.dart';
import 'package:adota_pet/presentation/widgets/confirm_dialog.dart';
import 'package:adota_pet/presentation/widgets/mobile_shell_scope.dart';
import 'package:adota_pet/presentation/widgets/primary_button.dart';
import 'package:adota_pet/presentation/widgets/state_views.dart';
import 'package:adota_pet/presentation/widgets/status_pill.dart';

/// Ação escolhida no bottom-sheet de detalhe de uma solicitação.
enum _RequestAction { chat, pet, cancel }

/// Home do adotante (mobile) — aba "Início" do `MobileShell`.
///
/// Como não há tela separada de solicitações, este é o hub onde o adotante
/// acompanha o status das suas solicitações e dá andamento nelas (abrir o chat,
/// ver o pet, cancelar). Reaproveita os viewmodels globais — sem nova camada
/// de dados.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const double _maxWidth = 430;
  static const _tabConversas = 3;
  static const _tabCatalogo = 1;

  bool _didLoad = false;
  String _filter = 'all'; // all | received | in_analysis | approved | rejected

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didLoad) return;
    _didLoad = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AdoptionRequestViewmodel>().loadAll();
      context.read<CatalogViewModel>().loadPets(); // guardado: não baixa 2x
    });
  }

  // ── Ações ────────────────────────────────────────────────────────────────────

  Future<void> _reload() async {
    await context.read<AdoptionRequestViewmodel>().loadAll();
    if (mounted) context.read<CatalogViewModel>().loadPets(force: true);
  }

  Future<void> _openChat(AdoptionRequest r) async {
    final chatVm = context.read<ChatViewModel>();
    final conv = await chatVm.getOrCreateConversation(r.id);
    if (!mounted) return;
    if (conv == null) {
      AppNotifier.instance.error('Não foi possível abrir a conversa.');
      return;
    }
    chatVm.openConversation(conv.id);
    MobileShellScope.of(context)?.goTo(_tabConversas);
  }

  void _openPet(AdoptionRequest r) => context.push('/catalog/${r.petId}');

  Future<void> _cancel(AdoptionRequest r) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Cancelar solicitação',
      message:
          'Deseja remover esta solicitação de adoção? Esta ação não pode ser desfeita.',
      confirmLabel: 'Cancelar solicitação',
      destructive: true,
    );
    if (!ok || !mounted) return;
    // O viewmodel remove da lista de forma otimista e notifica o usuário.
    await context.read<AdoptionRequestViewmodel>().delete(r.id);
  }

  Future<void> _openDetail(AdoptionRequest r, Pet? pet) async {
    final action = await showModalBottomSheet<_RequestAction>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _RequestDetailSheet(request: r, pet: pet),
    );
    if (action == null || !mounted) return;
    switch (action) {
      case _RequestAction.chat:
        await _openChat(r);
      case _RequestAction.pet:
        _openPet(r);
      case _RequestAction.cancel:
        await _cancel(r);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdoptionRequestViewmodel>();
    final catalog = context.watch<CatalogViewModel>();
    final nome = context.read<AuthViewModel>().session?.usuario.nome ?? '';
    final primeiro = nome.trim().isEmpty ? '' : nome.trim().split(' ').first;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        centerTitle: false,
        title: Text(
          primeiro.isEmpty ? 'Início' : 'Olá, $primeiro 🐾',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: AppTheme.foreground,
          ),
        ),
      ),
      body: _buildBody(vm, catalog),
    );
  }

  Widget _buildBody(AdoptionRequestViewmodel vm, CatalogViewModel catalog) {
    if (vm.isLoading && vm.requests.isEmpty) {
      return const LoadingView(message: 'Carregando suas solicitações...');
    }
    if (vm.error != null && vm.requests.isEmpty) {
      return ErrorStateView(message: vm.error!, onRetry: _reload);
    }

    final filtered = _filter == 'all'
        ? vm.requests
        : vm.requests.where((r) => r.status == _filter).toList();

    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: _reload,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Center(
          child: SizedBox(
            width: _maxWidth,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _StatusSummary(
                    requests: vm.requests,
                    selected: _filter,
                    onSelect: (status) => setState(
                      () => _filter = _filter == status ? 'all' : status,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'Minhas solicitações',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  _FilterBar(
                    selected: _filter,
                    onSelect: (s) => setState(() => _filter = s),
                  ),
                  const SizedBox(height: 14),
                  if (vm.requests.isEmpty)
                    _emptyAll()
                  else if (filtered.isEmpty)
                    _emptyFilter()
                  else
                    ...filtered.map((r) {
                      final pet = catalog.getPetById(r.petId);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _RequestCard(
                          request: r,
                          pet: pet,
                          onTap: () => _openDetail(r, pet),
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyAll() {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: EmptyState(
        icon: Icons.favorite_border_rounded,
        title: 'Nenhuma solicitação ainda',
        message:
            'Quando você solicitar a adoção de um pet, o andamento aparece aqui.',
        actionLabel: 'Explorar pets',
        actionIcon: Icons.pets_rounded,
        onAction: () => MobileShellScope.of(context)?.goTo(_tabCatalogo),
      ),
    );
  }

  Widget _emptyFilter() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 28),
      child: Text(
        'Nenhuma solicitação neste filtro.',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppTheme.mutedForeground),
      ),
    );
  }
}

// ── Resumo por status ─────────────────────────────────────────────────────────

const _summaryStatuses = <(String, String)>[
  ('received', 'Recebidas'),
  ('in_analysis', 'Em análise'),
  ('approved', 'Aprovadas'),
  ('rejected', 'Rejeitadas'),
];

class _StatusSummary extends StatelessWidget {
  final List<AdoptionRequest> requests;
  final String selected;
  final ValueChanged<String> onSelect;

  const _StatusSummary({
    required this.requests,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < _summaryStatuses.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: _StatTile(
              count: requests.where((r) => r.status == _summaryStatuses[i].$1).length,
              label: _summaryStatuses[i].$2,
              color: AppStatusColors.request(_summaryStatuses[i].$1),
              selected: selected == _summaryStatuses[i].$1,
              onTap: () => onSelect(_summaryStatuses[i].$1),
            ),
          ),
        ],
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final int count;
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _StatTile({
    required this.count,
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          decoration: BoxDecoration(
            color: selected ? color.withOpacity(0.12) : AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? color : AppTheme.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.mutedForeground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Barra de filtros ──────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;

  const _FilterBar({required this.selected, required this.onSelect});

  static const _options = <(String, String)>[
    ('all', 'Todas'),
    ('received', 'Recebidas'),
    ('in_analysis', 'Em análise'),
    ('approved', 'Aprovadas'),
    ('rejected', 'Rejeitadas'),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final opt in _options) ...[
            AppFilterChip(
              label: opt.$2,
              selected: selected == opt.$1,
              onTap: () => onSelect(opt.$1),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

// ── Card de solicitação ───────────────────────────────────────────────────────

class _RequestCard extends StatelessWidget {
  final AdoptionRequest request;
  final Pet? pet;
  final VoidCallback onTap;

  const _RequestCard({
    required this.request,
    required this.pet,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final nome = pet?.nome ?? 'Pet';
    final meta = pet == null
        ? 'Solicitação de adoção'
        : '${pet!.especieLabel} · ${pet!.porteLabel}';

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _PetThumb(pet: pet, size: 64),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Topo: nome (esq.) + status (sup. dir.).
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                nome,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.foreground,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            StatusPill(
                              label:
                                  AppStatusColors.requestLabel(request.status),
                              color: AppStatusColors.request(request.status),
                            ),
                          ],
                        ),
                        // Base: espécie · porte (inf. esq.) + data (inf. dir.).
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                meta,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: AppTheme.mutedForeground,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.schedule_rounded,
                                size: 13, color: AppTheme.mutedForeground),
                            const SizedBox(width: 4),
                            Text(
                              _dateLabel(request.createdAt),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.mutedForeground,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Bottom-sheet de detalhe (read-only + ações) ───────────────────────────────

class _RequestDetailSheet extends StatelessWidget {
  final AdoptionRequest request;
  final Pet? pet;

  const _RequestDetailSheet({required this.request, required this.pet});

  @override
  Widget build(BuildContext context) {
    final nome = pet?.nome ?? 'Pet';
    final media = MediaQuery.of(context);
    final questionario = _questionario(request.matchAnswers);

    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: media.size.height * 0.85),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: AppTheme.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PetThumb(pet: pet, size: 72),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nome,
                          style: Theme.of(context).textTheme.titleLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (pet != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            '${pet!.especieLabel} · ${pet!.porteLabel} · ${pet!.idadeFormatada}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.mutedForeground,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        StatusPill(
                          label: AppStatusColors.requestLabel(request.status),
                          color: AppStatusColors.request(request.status),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (request.matchScore != null)
                _MatchChip(score: request.matchScore!),
              if (request.protetorNome != null &&
                  request.protetorNome!.isNotEmpty)
                _InfoRow(
                  icon: Icons.volunteer_activism_outlined,
                  label: 'Protetor/ONG',
                  value: request.protetorNome!,
                ),
              _InfoRow(
                icon: Icons.event_outlined,
                label: 'Enviada em',
                value: _fullDate(request.createdAt),
              ),
              if ((request.mensagem ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Sua mensagem',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.foreground,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.inputFill,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    request.mensagem!.trim(),
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.foreground,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
              if (questionario.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Questionário',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.foreground,
                  ),
                ),
                const SizedBox(height: 6),
                for (final e in questionario)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            e.key,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.mutedForeground,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 4,
                          child: Text(
                            e.value,
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.foreground,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
              const SizedBox(height: 22),
              PrimaryButton(
                label: 'Conversar',
                trailingIcon: Icons.chat_bubble_outline_rounded,
                onPressed: () => Navigator.pop(context, _RequestAction.chat),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context, _RequestAction.pet),
                      icon: const Icon(Icons.pets_rounded, size: 18),
                      label: const Text('Ver pet'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          Navigator.pop(context, _RequestAction.cancel),
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      label: const Text('Cancelar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.destructive,
                        side: const BorderSide(color: AppTheme.destructive),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MatchChip extends StatelessWidget {
  final double score;
  const _MatchChip({required this.score});

  @override
  Widget build(BuildContext context) {
    final pct = score.round();
    final color = pct >= 70
        ? AppTheme.sage
        : (pct >= 50 ? AppTheme.accent : AppTheme.destructive);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(Icons.favorite_rounded, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            'Compatibilidade $pct%',
            style: TextStyle(fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.mutedForeground),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 13, color: AppTheme.mutedForeground),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.foreground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Thumb do pet (foto base64 ou placeholder) ─────────────────────────────────

class _PetThumb extends StatelessWidget {
  final Pet? pet;
  final double size;

  const _PetThumb({required this.pet, required this.size});

  @override
  Widget build(BuildContext context) {
    final fotos = pet?.fotosUrls ?? const [];
    if (fotos.isNotEmpty) {
      try {
        final raw = fotos.first;
        final b64 = raw.contains(',') ? raw.split(',').last : raw;
        final bytes = base64Decode(b64);
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(
            bytes,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _placeholder(),
          ),
        );
      } catch (_) {
        // cai no placeholder
      }
    }
    return _placeholder();
  }

  Widget _placeholder() {
    final letter = (pet?.nome.isNotEmpty == true) ? pet!.nome[0].toUpperCase() : '?';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withOpacity(0.28),
            AppTheme.accent.withOpacity(0.18),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: TextStyle(
          fontSize: size * 0.4,
          fontWeight: FontWeight.w800,
          color: AppTheme.primary,
        ),
      ),
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────────

String _dateLabel(DateTime dt) {
  final local = dt.toLocal();
  final now = DateTime.now();
  final diff = now.difference(local);
  if (diff.inDays <= 0) return 'Hoje';
  if (diff.inDays == 1) return 'Ontem';
  if (diff.inDays < 7) return 'há ${diff.inDays}d';
  return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}';
}

String _fullDate(DateTime dt) {
  final d = dt.toLocal();
  return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

List<MapEntry<String, String>> _questionario(Map<String, dynamic>? a) {
  if (a == null) return const [];
  final out = <MapEntry<String, String>>[];
  final moradia = a['tipoMoradia'] as String?;
  if (moradia != null) out.add(MapEntry('Moradia', _moradiaLabel(moradia)));
  final horas = a['horasDisponiveisDia'];
  if (horas is num) out.add(MapEntry('Tempo disponível', '${horas.toInt()} h/dia'));
  if (a['temExperiencia'] is bool) {
    out.add(MapEntry('Experiência prévia', a['temExperiencia'] == true ? 'Sim' : 'Não'));
  }
  if (a['temCriancas'] is bool) {
    out.add(MapEntry('Crianças em casa', a['temCriancas'] == true ? 'Sim' : 'Não'));
  }
  if (a['temOutrosPets'] is bool) {
    out.add(MapEntry('Outros pets', a['temOutrosPets'] == true ? 'Sim' : 'Não'));
  }
  return out;
}

String _moradiaLabel(String m) {
  switch (m) {
    case 'casa_com_quintal':
      return 'Casa com quintal';
    case 'casa_sem_quintal':
      return 'Casa sem quintal';
    case 'apartamento':
      return 'Apartamento';
    default:
      return m;
  }
}
