import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:adota_pet/core/theme/app_theme.dart';
import 'package:adota_pet/domain/entities/adoption_request.dart';
import 'package:adota_pet/presentation/viewmodels/adoption_request_viewmodel.dart';
import 'package:adota_pet/presentation/widgets/org_layout.dart';

class AdoptionRequestPage extends StatefulWidget {
  const AdoptionRequestPage({super.key});

  @override
  State<AdoptionRequestPage> createState() => _AdoptionRequestPageState();
}

class _AdoptionRequestPageState extends State<AdoptionRequestPage> {
  String _filtroStatus = 'todos';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdoptionRequestViewmodel>().loadAll();
    });
  }

  static const _filtros = [
    ('todos', 'Todas'),
    ('received', 'Recebidas'),
    ('in_analysis', 'Em análise'),
    ('approved', 'Aprovadas'),
    ('rejected', 'Rejeitadas'),
  ];

  @override
  Widget build(BuildContext context) {
    return OrgLayout(
      title: 'Solicitações de Adoção',
      currentIndex: 2,
      child: Consumer<AdoptionRequestViewmodel>(
        builder: (context, vm, _) {
          final filtradas = _filtroStatus == 'todos'
              ? vm.requests
              : vm.requests.where((r) => r.status == _filtroStatus).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildFiltros(),
              _buildContadores(vm),
              Expanded(child: _buildBody(context, vm, filtradas)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFiltros() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _filtros.map((f) {
            final active = _filtroStatus == f.$1;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _filtroStatus = f.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: active ? AppTheme.primary : const Color(0xFFF1ECE3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(f.$2,
                      style: GoogleFonts.nunito(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: active ? Colors.white : AppTheme.mutedForeground)),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildContadores(AdoptionRequestViewmodel vm) {
    final total = vm.requests.length;
    final pendentes = vm.requests.where((r) => r.status == 'received').length;
    final emAnalise = vm.requests.where((r) => r.status == 'in_analysis').length;
    final aprovadas = vm.requests.where((r) => r.status == 'approved').length;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(children: [
        _CounterCard(label: 'Total', value: total, color: AppTheme.primary),
        const SizedBox(width: 8),
        _CounterCard(label: 'Pendentes', value: pendentes, color: const Color(0xFFE08A2A)),
        const SizedBox(width: 8),
        _CounterCard(label: 'Em análise', value: emAnalise, color: const Color(0xFF3B82F6)),
        const SizedBox(width: 8),
        _CounterCard(label: 'Aprovadas', value: aprovadas, color: AppTheme.sage),
      ]),
    );
  }

  Widget _buildBody(BuildContext context, AdoptionRequestViewmodel vm,
      List<AdoptionRequest> filtradas) {
    if (vm.isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.primary));
    }
    if (vm.error != null) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.wifi_off_rounded, size: 48, color: AppTheme.mutedForeground),
          const SizedBox(height: 12),
          Text(vm.error!,
              style: GoogleFonts.nunito(fontSize: 13, color: AppTheme.mutedForeground),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: vm.loadAll,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Tentar novamente'),
          ),
        ]),
      );
    }
    if (filtradas.isEmpty) return _buildEmpty();
    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: vm.loadAll,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: filtradas.length,
        itemBuilder: (context, i) => _AdoptionCard(request: filtradas[i]),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('📭', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 12),
        Text('Nenhuma solicitação encontrada',
            style: GoogleFonts.quicksand(
                fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.foreground)),
        const SizedBox(height: 6),
        Text('As solicitações de adoção aparecerão aqui.',
            style: GoogleFonts.nunito(fontSize: 13, color: AppTheme.mutedForeground)),
      ]),
    );
  }
}

class _CounterCard extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _CounterCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(children: [
          Text('$value',
              style: GoogleFonts.quicksand(
                  fontSize: 20, fontWeight: FontWeight.w800, color: color)),
          Text(label,
              style: GoogleFonts.nunito(
                  fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.mutedForeground)),
        ]),
      ),
    );
  }
}

class _AdoptionCard extends StatelessWidget {
  final AdoptionRequest request;
  const _AdoptionCard({required this.request});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
        boxShadow: const [
          BoxShadow(color: Color(0x082A2622), blurRadius: 8, offset: Offset(0, 2))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _PetAvatar(petId: request.petId),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(
                    child: Text('Pet: ${_shortId(request.petId)}',
                        style: GoogleFonts.quicksand(
                            fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.foreground),
                        overflow: TextOverflow.ellipsis),
                  ),
                  _StatusBadge(status: request.status),
                ]),
                const SizedBox(height: 4),
                Text('Adotante: ${_shortId(request.adopterId)}',
                    style: GoogleFonts.nunito(fontSize: 12, color: AppTheme.mutedForeground),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Row(children: [
                  _PreTriageBadge(status: request.preTriageStatus),
                  if (request.matchScore != null) ...[
                    const SizedBox(width: 8),
                    _MatchScoreChip(score: request.matchScore!),
                  ],
                ]),
              ]),
            ),
          ]),
          if (request.mensagem != null && request.mensagem!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F3F0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.format_quote_rounded,
                    color: AppTheme.mutedForeground, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    request.mensagem!.length > 120
                        ? '${request.mensagem!.substring(0, 120)}...'
                        : request.mensagem!,
                    style: GoogleFonts.nunito(
                        fontSize: 12, color: AppTheme.mutedForeground, height: 1.5),
                  ),
                ),
              ]),
            ),
          ],
          if (request.matchAnswers != null) ...[
            const SizedBox(height: 12),
            _QuestionarioChips(answers: request.matchAnswers!),
          ],
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_formatDate(request.createdAt),
                  style: GoogleFonts.nunito(fontSize: 11, color: AppTheme.mutedForeground)),
              _ActionButtons(request: request),
            ],
          ),
        ]),
      ),
    );
  }

  String _shortId(String id) => id.length > 13 ? '${id.substring(0, 8)}...' : id;

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Agora mesmo';
    if (diff.inHours < 1) return 'Há ${diff.inMinutes}min';
    if (diff.inDays < 1) return 'Há ${diff.inHours}h';
    if (diff.inDays == 1) return 'Ontem';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
}

class _PetAvatar extends StatelessWidget {
  final String petId;
  const _PetAvatar({required this.petId});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48, height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withOpacity(0.3),
            AppTheme.accent.withOpacity(0.2)
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

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  static const _config = {
    'received':    (Color(0xFFE08A2A), Color(0xFFFFF7ED), 'Recebida'),
    'in_analysis': (Color(0xFF3B82F6), Color(0xFFEFF6FF), 'Em análise'),
    'approved':    (AppTheme.sage,     Color(0xFFF0FDF4), 'Aprovada'),
    'rejected':    (AppTheme.destructive, Color(0xFFFEF2F2), 'Rejeitada'),
  };

  @override
  Widget build(BuildContext context) {
    final cfg = _config[status] ??
        (AppTheme.mutedForeground, const Color(0xFFF1ECE3), status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cfg.$2,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(cfg.$3,
          style: GoogleFonts.nunito(
              fontSize: 11, fontWeight: FontWeight.w700, color: cfg.$1)),
    );
  }
}

class _PreTriageBadge extends StatelessWidget {
  final String status;
  const _PreTriageBadge({required this.status});

  static const _config = {
    'qualified':    (AppTheme.sage,          '✓ Qualificado'),
    'review':       (Color(0xFFE08A2A),      '⏳ Em revisão'),
    'disqualified': (AppTheme.destructive,   '✗ Desqualificado'),
  };

  @override
  Widget build(BuildContext context) {
    final cfg = _config[status] ?? (AppTheme.mutedForeground, status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cfg.$1.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cfg.$1.withOpacity(0.3)),
      ),
      child: Text(cfg.$2,
          style: GoogleFonts.nunito(
              fontSize: 10, fontWeight: FontWeight.w700, color: cfg.$1)),
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
            ? const Color(0xFFE08A2A)
            : AppTheme.destructive;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.star_rounded, size: 12, color: color),
        const SizedBox(width: 3),
        Text('${score.toStringAsFixed(0)}%',
            style: GoogleFonts.nunito(
                fontSize: 11, fontWeight: FontWeight.w700, color: color)),
      ]),
    );
  }
}

class _QuestionarioChips extends StatelessWidget {
  final Map<String, dynamic> answers;
  const _QuestionarioChips({required this.answers});

  @override
  Widget build(BuildContext context) {
    final chips = <String>[];
    final moradia = answers['tipoMoradia'] as String?;
    if (moradia == 'casa_com_quintal') chips.add('🏡 Casa c/ quintal');
    if (moradia == 'casa_sem_quintal') chips.add('🏠 Casa s/ quintal');
    if (moradia == 'apartamento') chips.add('🏢 Apartamento');
    final horas = answers['horasDisponiveisDia'];
    if (horas != null) chips.add('⏰ ${horas}h/dia');
    if (answers['temExperiencia'] == true) chips.add('⭐ Experiente');
    if (answers['temCriancas'] == true) chips.add('👶 Tem crianças');
    if (answers['temOutrosPets'] == true) chips.add('🐾 Tem outros pets');
    if (chips.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: chips
          .map((c) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1ECE3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(c,
                    style: GoogleFonts.nunito(
                        fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.foreground)),
              ))
          .toList(),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final AdoptionRequest request;
  const _ActionButtons({required this.request});

  @override
  Widget build(BuildContext context) {
    final vm = context.read<AdoptionRequestViewmodel>();

    return Row(mainAxisSize: MainAxisSize.min, children: [
      if (request.status == 'received')
        _ActionBtn(
          label: 'Analisar',
          icon: Icons.search_rounded,
          color: const Color(0xFF3B82F6),
          onTap: () => vm.updateStatus(request.id, 'in_analysis'),
        ),
      if (request.status == 'in_analysis') ...[
        _ActionBtn(
          label: 'Aprovar',
          icon: Icons.check_rounded,
          color: AppTheme.sage,
          onTap: () => _confirmar(context,
              title: 'Aprovar adoção',
              message: 'Deseja aprovar esta solicitação? O adotante será notificado.',
              confirmLabel: 'Aprovar',
              confirmColor: AppTheme.sage,
              onConfirm: () => vm.updateStatus(request.id, 'approved')),
        ),
        const SizedBox(width: 6),
        _ActionBtn(
          label: 'Rejeitar',
          icon: Icons.close_rounded,
          color: AppTheme.destructive,
          onTap: () => _confirmar(context,
              title: 'Rejeitar solicitação',
              message: 'Deseja rejeitar esta solicitação?',
              confirmLabel: 'Rejeitar',
              confirmColor: AppTheme.destructive,
              onConfirm: () => vm.updateStatus(request.id, 'rejected')),
        ),
      ],
      const SizedBox(width: 6),
      GestureDetector(
        onTap: () => _confirmar(context,
            title: 'Remover solicitação',
            message: 'Esta ação não pode ser desfeita.',
            confirmLabel: 'Remover',
            confirmColor: AppTheme.destructive,
            onConfirm: () => vm.delete(request.id)),
        child: Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: AppTheme.destructive.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.delete_outline_rounded,
              color: AppTheme.destructive, size: 16),
        ),
      ),
    ]);
  }

  void _confirmar(BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title,
            style: GoogleFonts.quicksand(fontWeight: FontWeight.w800)),
        content: Text(message,
            style: GoogleFonts.nunito(fontSize: 13, color: AppTheme.mutedForeground)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar',
                style: GoogleFonts.nunito(color: AppTheme.mutedForeground)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
              shape: const StadiumBorder(),
              elevation: 0,
            ),
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: Text(confirmLabel,
                style: GoogleFonts.nunito(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn(
      {required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(label,
              style: GoogleFonts.nunito(
                  fontSize: 12, fontWeight: FontWeight.w700, color: color)),
        ]),
      ),
    );
  }
}