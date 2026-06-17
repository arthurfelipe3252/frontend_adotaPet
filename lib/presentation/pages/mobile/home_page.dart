import 'dart:convert';
import 'dart:typed_data';

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
import 'package:adota_pet/presentation/viewmodels/user_settings_viewmodel.dart';
import 'package:adota_pet/presentation/widgets/confirm_dialog.dart';
import 'package:adota_pet/presentation/widgets/mobile_screen_header.dart';
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
  static const _tabCatalogo = 1;
  static const _tabMatch = 2;
  static const _tabConversas = 3;
  static const _tabPerfil = 4;

  bool _didLoad = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didLoad) return;
    _didLoad = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AdoptionRequestViewmodel>().loadAll();
      context.read<CatalogViewModel>().loadPets(); // guardado: não baixa 2x
      // Carrega o perfil do adotante (foto/avatar do header); guardado.
      final usuario = context.read<AuthViewModel>().session?.usuario;
      if (usuario != null) {
        context.read<UserSettingsViewModel>().loadFor(usuario);
      }
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
      backgroundColor: AppTheme.background,
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

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.primary,
          onRefresh: _reload,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Center(
              child: SizedBox(
                width: _maxWidth,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _GreetingHeader(
                        onProfile: () =>
                            MobileShellScope.of(context)?.goTo(_tabPerfil),
                      ),
                      const SizedBox(height: 18),
                      _MatchBanner(
                        onTap: () =>
                            MobileShellScope.of(context)?.goTo(_tabMatch),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        'Suas solicitações',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      _buildRequests(vm, catalog),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRequests(AdoptionRequestViewmodel vm, CatalogViewModel catalog) {
    if (vm.isLoading && vm.requests.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: CircularProgressIndicator(
            color: AppTheme.primary,
            strokeWidth: 2,
          ),
        ),
      );
    }
    if (vm.error != null && vm.requests.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: ErrorStateView(message: vm.error!, onRetry: _reload),
      );
    }
    if (vm.requests.isEmpty) return _emptyAll();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...vm.requests.map((r) {
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

}

// ── Cabeçalho (saudação + avatar) ─────────────────────────────────────────────

class _GreetingHeader extends StatelessWidget {
  final VoidCallback onProfile;
  const _GreetingHeader({required this.onProfile});

  @override
  Widget build(BuildContext context) {
    final nome = context.read<AuthViewModel>().session?.usuario.nome ?? '';
    final primeiro = nome.trim().isEmpty ? '' : nome.trim().split(' ').first;
    final inicial = primeiro.isNotEmpty ? primeiro[0].toUpperCase() : '?';

    // Foto de perfil do usuário (carregada pelo UserSettingsViewModel), se houver.
    final settings = context.watch<UserSettingsViewModel>();
    final fotoBytes = settings.imagemBytes ?? _decodeImage(settings.imagemBase64);
    final hasFoto = fotoBytes != null && !settings.removerImagem;

    final avatar = InkWell(
      customBorder: const CircleBorder(),
      onTap: onProfile,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.primary,
          image: hasFoto
              ? DecorationImage(image: MemoryImage(fotoBytes), fit: BoxFit.cover)
              : null,
        ),
        alignment: Alignment.center,
        child: hasFoto
            ? null
            : Text(
                inicial,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
      ),
    );

    return MobileScreenHeader(
      leading: avatar,
      title: primeiro.isEmpty ? 'Olá' : 'Olá, $primeiro',
      subtitle: 'Encontre seu novo companheiro',
    );
  }
}

// ── Banner CTA de Match (gradiente) ───────────────────────────────────────────

class _MatchBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _MatchBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primary, AppTheme.accent],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Descubra seu pet ideal 🐾',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Responda algumas perguntas e encontre o match perfeito',
            style: TextStyle(fontSize: 13, color: Colors.white, height: 1.35),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Material(
              color: Colors.white.withOpacity(0.22),
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(999),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Fazer o Match',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(width: 6),
                      Icon(Icons.arrow_forward_rounded,
                          size: 18, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ),
          ),
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
    final ong = (request.protetorNome?.isNotEmpty == true)
        ? request.protetorNome!
        : 'ONG';

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
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
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _PetThumb(pet: pet, size: 52),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        nome,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.foreground,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        ong,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppTheme.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                StatusPill(
                  label: AppStatusColors.requestLabel(request.status),
                  color: AppStatusColors.request(request.status),
                ),
              ],
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
    final protetor = request.protetorNome;
    final mensagem = (request.mensagem ?? '').trim();

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
              // Alça de arrasto
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
              // Header: pet + status + compatibilidade
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
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            StatusPill(
                              label:
                                  AppStatusColors.requestLabel(request.status),
                              color: AppStatusColors.request(request.status),
                            ),
                            if (request.matchScore != null)
                              _matchPill(request.matchScore!),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              // Detalhes (protetor + data)
              _SheetSection(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (protetor != null && protetor.isNotEmpty) ...[
                      _DetailRow(
                        icon: Icons.volunteer_activism_outlined,
                        label: 'Protetor/ONG',
                        value: protetor,
                      ),
                      const SizedBox(height: 12),
                    ],
                    _DetailRow(
                      icon: Icons.event_outlined,
                      label: 'Enviada em',
                      value: _fullDate(request.createdAt),
                    ),
                  ],
                ),
              ),
              if (mensagem.isNotEmpty) ...[
                const SizedBox(height: 16),
                _SheetSection(
                  title: 'Sua mensagem',
                  child: Text(
                    mensagem,
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
                _SheetSection(
                  title: 'Questionário',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < questionario.length; i++) ...[
                        if (i > 0) const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                questionario[i].key,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.mutedForeground,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 4,
                              child: Text(
                                questionario[i].value,
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
                      ],
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

  Widget _matchPill(double score) {
    final pct = score.round();
    final color = pct >= 70
        ? AppTheme.sage
        : (pct >= 50 ? AppTheme.accent : AppTheme.destructive);
    return StatusPill(
      label: 'Compatibilidade $pct%',
      color: color,
      icon: Icons.favorite_rounded,
    );
  }
}

/// Card de seção do bottom-sheet (mobile): título opcional + superfície
/// arredondada com borda. Raio 16, igual aos cards da Home.
class _SheetSection extends StatelessWidget {
  final String? title;
  final Widget child;

  const _SheetSection({this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 8),
            child: Text(
              title!,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.foreground,
              ),
            ),
          ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border),
          ),
          child: child,
        ),
      ],
    );
  }
}

/// Linha de detalhe: ícone + rótulo discreto sobre o valor (sem "Label:").
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppTheme.mutedForeground),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.mutedForeground,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
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

/// Decodifica uma imagem base64 (com ou sem prefixo data-URI). `null` se vazio/ inválido.
Uint8List? _decodeImage(String? value) {
  final raw = value?.trim();
  if (raw == null || raw.isEmpty) return null;
  final payload = raw.contains(',') ? raw.split(',').last : raw;
  try {
    return base64Decode(payload);
  } catch (_) {
    return null;
  }
}
