import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:adota_pet/core/notifications/app_notifier.dart';
import 'package:adota_pet/core/theme/app_status_colors.dart';
import 'package:adota_pet/core/theme/app_theme.dart';
import 'package:adota_pet/domain/entities/adoption_request.dart';
import 'package:adota_pet/domain/entities/chat.dart';
import 'package:adota_pet/presentation/viewmodels/adoption_request_viewmodel.dart';
import 'package:adota_pet/presentation/viewmodels/auth_viewmodel.dart';
import 'package:adota_pet/presentation/viewmodels/catalog_viewmodel.dart';
import 'package:adota_pet/presentation/viewmodels/chat_viewmodel.dart';
import 'package:adota_pet/presentation/widgets/mobile_screen_header.dart';
import 'package:adota_pet/presentation/widgets/state_views.dart';
import 'package:adota_pet/presentation/widgets/status_pill.dart';

class ChatPage extends StatefulWidget {
  final String? conversationId;

  const ChatPage({super.key, this.conversationId});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  ChatViewModel? _chatVm;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _chatVm ??= context.read<ChatViewModel>();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!context.mounted) return;
      final vm = context.read<ChatViewModel>();
      // Dados para resolver "{contato} - {pet}" e a lista de iniciar conversa.
      final adoptionVm = context.read<AdoptionRequestViewmodel>();
      adoptionVm.loadAll();
      context.read<CatalogViewModel>().loadPets(); // guardado
      await vm.loadConversations();
      if (widget.conversationId != null && context.mounted) {
        await vm.openConversation(widget.conversationId!);
      }
    });
  }

  @override
  void dispose() {
    _chatVm?.stopPolling();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ChatViewModel>();

    // Mostra a tela de mensagens caso haja uma conversa ativa.
    if (vm.activeConversation != null) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, dynamic result) {
          if (!didPop) {
            context.read<ChatViewModel>().closeConversation();
          }
        },
        child: const _MessagePanel(),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: const [
            MobileScreenHeader(
              icon: Icons.chat_bubble_rounded,
              title: 'Conversas',
              subtitle: 'Suas mensagens com as ONGs',
            ),
            Expanded(child: _ConversationList()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _startNewChat,
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_comment_rounded),
        label: const Text('Nova conversa'),
      ),
    );
  }

  Future<void> _startNewChat() async {
    final chatVm = context.read<ChatViewModel>();
    final adoptionVm = context.read<AdoptionRequestViewmodel>();
    final catalogVm = context.read<CatalogViewModel>();

    if (adoptionVm.requests.isEmpty) await adoptionVm.loadAll();
    if (!mounted) return;
    if (chatVm.conversations.isEmpty) await chatVm.loadConversations();
    if (!mounted) return;
    catalogVm.loadPets();

    // Só solicitações que ainda não têm conversa (as demais já estão na lista).
    final comConversa = chatVm.conversations
        .map((c) => c.adoptionRequestId)
        .toSet();
    final candidatos = adoptionVm.requests
        .where((r) => !comConversa.contains(r.id))
        .where((r) => r.podeConversar)
        .toList();

    final escolhido = await showModalBottomSheet<AdoptionRequest>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _StartChatSheet(requests: candidatos),
    );
    if (escolhido == null || !mounted) return;

    final conv = await chatVm.getOrCreateConversation(escolhido.id);
    if (!mounted) return;
    if (conv == null) {
      AppNotifier.instance.error('Não foi possível iniciar a conversa.');
      return;
    }
    chatVm.openConversation(conv.id);
  }
}

// ── Lista de conversas ────────────────────────────────────────────────────────

class _ConversationList extends StatelessWidget {
  const _ConversationList();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ChatViewModel>();
    final adoptionVm = context.watch<AdoptionRequestViewmodel>();
    final catalogVm = context.watch<CatalogViewModel>();

    if (vm.isLoadingConversations) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppTheme.primary,
          strokeWidth: 2,
        ),
      );
    }

    if (vm.error != null && vm.conversations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            vm.error!,
            style: const TextStyle(color: AppTheme.destructive),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (vm.conversations.isEmpty) {
      return const EmptyState(
        icon: Icons.chat_bubble_outline_rounded,
        title: 'Nenhuma conversa',
        message: 'As conversas aparecem aqui quando for iniciado um contato.',
      );
    }

    return RefreshIndicator(
      onRefresh: vm.loadConversations,
      color: AppTheme.primary,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 96),
        itemCount: vm.conversations.length,
        separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
        itemBuilder: (_, i) {
          final conv = vm.conversations[i];
          return _ConversationTile(
            conversation: conv,
            petName: _petNameFor(conv, adoptionVm, catalogVm),
            onTap: () =>
                context.read<ChatViewModel>().openConversation(conv.id),
          );
        },
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final String? petName;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.conversation,
    required this.petName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final souAdotante =
        context.read<AuthViewModel>().session?.usuario.isAdotante ?? false;
    final contato = _contactName(conversation, souAdotante);
    final titulo = _chatTitle(conversation, souAdotante, petName);
    final last = conversation.lastMessage;
    final hasUnread = conversation.unreadCount > 0;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasUnread
              ? AppTheme.primary.withOpacity(0.45)
              : AppTheme.border,
          width: hasUnread ? 1.4 : 1,
        ),
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
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppTheme.primary.withOpacity(0.12),
                  child: Text(
                    contato.isNotEmpty ? contato[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              titulo,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.foreground,
                              ),
                            ),
                          ),
                          if (last != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              _timeLabel(last.createdAt),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: hasUnread
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: hasUnread
                                    ? AppTheme.primary
                                    : AppTheme.mutedForeground,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _previewText(last, souAdotante),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: hasUnread
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                                color: hasUnread
                                    ? AppTheme.foreground
                                    : AppTheme.mutedForeground,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (hasUnread)
                            _UnreadBadge(count: conversation.unreadCount)
                          else if (!conversation.isActive)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.border,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Encerrada',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.mutedForeground,
                                ),
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
    );
  }

  String _previewText(LastMessagePreview? last, bool souAdotante) {
    if (last == null) return 'Solicitação de adoção';
    final ehMinha = souAdotante
        ? last.senderTipo == 'adotante'
        : last.senderTipo == 'protetor';
    return ehMinha ? 'Você: ${last.content}' : last.content;
  }

  String _timeLabel(DateTime dt) {
    final local = dt.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(local.year, local.month, local.day);
    if (d == today) {
      return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    }
    if (d == today.subtract(const Duration(days: 1))) return 'Ontem';
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}';
  }
}

/// Bolinha laranja com a contagem de mensagens não lidas.
class _UnreadBadge extends StatelessWidget {
  final int count;
  const _UnreadBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 20),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ── Helpers de título (contato + nome do pet) ─────────────────────────────────

/// Nome do outro lado da conversa. Para o adotante, o protetor/ONG.
String _contactName(Conversation c, bool souAdotante) {
  if (souAdotante) {
    return (c.protetorNome?.isNotEmpty == true) ? c.protetorNome! : 'Protetor';
  }
  return (c.adopterNome?.isNotEmpty == true) ? c.adopterNome! : 'Adotante';
}

/// Nome do pet da conversa, via `adoptionRequestId` → solicitação → catálogo.
/// `null` se ainda não resolvido (catálogo carregando) ou pet indisponível.
String? _petNameFor(
  Conversation c,
  AdoptionRequestViewmodel adoptionVm,
  CatalogViewModel catalogVm,
) {
  for (final r in adoptionVm.requests) {
    if (r.id == c.adoptionRequestId) {
      return catalogVm.getPetById(r.petId)?.nome;
    }
  }
  return null;
}

/// "{contato} - {pet}" (ou só o contato, se o pet não resolveu).
String _chatTitle(Conversation c, bool souAdotante, String? petName) {
  final contato = _contactName(c, souAdotante);
  return (petName != null && petName.isNotEmpty)
      ? '$contato - $petName'
      : contato;
}

// ── Bottom-sheet: iniciar nova conversa ───────────────────────────────────────

class _StartChatSheet extends StatelessWidget {
  final List<AdoptionRequest> requests;
  const _StartChatSheet({required this.requests});

  @override
  Widget build(BuildContext context) {
    final catalogVm = context.watch<CatalogViewModel>();
    final media = MediaQuery.of(context);

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: media.size.height * 0.7),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Iniciar conversa',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.foreground,
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Escolha uma solicitação para começar a conversa.',
                style: TextStyle(fontSize: 13, color: AppTheme.mutedForeground),
              ),
            ),
          ),
          if (requests.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 36),
              child: Text(
                'Você já tem conversas para todas as suas solicitações.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.mutedForeground),
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                itemCount: requests.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final r = requests[i];
                  final pet = catalogVm.getPetById(r.petId);
                  return _StartChatItem(
                    request: r,
                    petNome: pet?.nome ?? 'Pet',
                    onTap: () => Navigator.pop(context, r),
                  );
                },
              ),
            ),
          SizedBox(height: media.padding.bottom),
        ],
      ),
    );
  }
}

class _StartChatItem extends StatelessWidget {
  final AdoptionRequest request;
  final String petNome;
  final VoidCallback onTap;

  const _StartChatItem({
    required this.request,
    required this.petNome,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final protetor = request.protetorNome;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppTheme.primary.withOpacity(0.12),
                child: Text(
                  petNome.isNotEmpty ? petNome[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            petNome,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.foreground,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        StatusPill(
                          label: AppStatusColors.requestLabel(request.status),
                          color: AppStatusColors.request(request.status),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      protetor != null && protetor.isNotEmpty
                          ? 'Falar com $protetor'
                          : 'Solicitação de adoção',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.mutedForeground,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Painel de mensagens (Tela Secundária Mobile) ──────────────────────────────

class _MessagePanel extends StatefulWidget {
  const _MessagePanel();

  @override
  State<_MessagePanel> createState() => _MessagePanelState();
}

class _MessagePanelState extends State<_MessagePanel> {
  final _msgController = TextEditingController();
  final _scrollController = ScrollController();

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final content = _msgController.text.trim();
    if (content.isEmpty) return;
    _msgController.clear();
    final ok = await context.read<ChatViewModel>().sendMessage(content);
    if (ok) _scrollToBottom();
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ChatViewModel>();
    final adoptionVm = context.watch<AdoptionRequestViewmodel>();
    final catalogVm = context.watch<CatalogViewModel>();
    final conv = vm.activeConversation;
    final session = context.read<AuthViewModel>().session;
    // O backend envia senderId como id de PERFIL (não usuario.id); o lado do
    // balão é decidido pelo tipo do remetente vs o tipo do usuário logado.
    final souAdotante = session?.usuario.isAdotante ?? false;

    if (conv == null) {
      return const Scaffold(
        body: Center(child: Text('Erro ao carregar a conversa.')),
      );
    }

    _scrollToBottom();

    final contato = _contactName(conv, souAdotante);
    final petName = _petNameFor(conv, adoptionVm, catalogVm);
    final titulo = _chatTitle(conv, souAdotante, petName);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.read<ChatViewModel>().closeConversation(),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primary.withOpacity(0.12),
              child: Text(
                contato.isNotEmpty ? contato[0].toUpperCase() : '?',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (!conv.isActive)
                    const Text(
                      'Encerrada',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.mutedForeground,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Área de mensagens
            Expanded(
              child: vm.isLoadingMessages
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primary,
                        strokeWidth: 2,
                      ),
                    )
                  : vm.messages.isEmpty
                  ? const EmptyState(
                      icon: Icons.chat_bubble_outline_rounded,
                      title: 'Nenhuma mensagem',
                      message: 'Envie a primeira mensagem para começar.',
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      itemCount: vm.messages.length,
                      itemBuilder: (_, i) {
                        final msg = vm.messages[i];
                        final isMine = souAdotante
                            ? msg.senderTipo == 'adotante'
                            : msg.senderTipo == 'protetor';
                        final showDate =
                            i == 0 ||
                            !_sameDay(
                              vm.messages[i - 1].createdAt,
                              msg.createdAt,
                            );
                        return Column(
                          children: [
                            if (showDate) _DateDivider(date: msg.createdAt),
                            _MessageBubble(message: msg, isMine: isMine),
                          ],
                        );
                      },
                    ),
            ),
            const Divider(height: 1),

            // Input de mensagem
            if (conv.isActive)
              _MessageInput(
                controller: _msgController,
                isSending: vm.isSending,
                onSend: _send,
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: AppTheme.surface,
                child: const Text(
                  'Esta conversa foi encerrada.',
                  style: TextStyle(
                    color: AppTheme.mutedForeground,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ── Balão de mensagem ─────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMine;

  const _MessageBubble({required this.message, required this.isMine});

  @override
  Widget build(BuildContext context) {
    final local = message.createdAt.toLocal();
    final time =
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMine
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) ...[
            CircleAvatar(
              radius: 12,
              backgroundColor: AppTheme.inputFill,
              child: Text(
                (message.senderNome?.isNotEmpty == true)
                    ? message.senderNome![0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.mutedForeground,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMine
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!isMine && message.senderNome != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 4),
                    child: Text(
                      message.senderNome!,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.mutedForeground,
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isMine ? AppTheme.primary : AppTheme.surface,
                    border: isMine ? null : Border.all(color: AppTheme.border),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMine ? 16 : 4),
                      bottomRight: Radius.circular(isMine ? 4 : 16),
                    ),
                  ),
                  child: Text(
                    message.content,
                    style: TextStyle(
                      fontSize: 15,
                      color: isMine ? Colors.white : AppTheme.foreground,
                      height: 1.3,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      time,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.mutedForeground,
                      ),
                    ),
                    if (isMine) ...[
                      const SizedBox(width: 4),
                      Icon(
                        message.isRead
                            ? Icons.done_all_rounded
                            : Icons.done_rounded,
                        size: 14,
                        color: message.isRead
                            ? AppTheme.sage
                            : AppTheme.mutedForeground,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (isMine) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

// ── Divider de data ───────────────────────────────────────────────────────────

class _DateDivider extends StatelessWidget {
  final DateTime date;
  const _DateDivider({required this.date});

  String get _label {
    final local = date.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(local.year, local.month, local.day);
    if (d == today) return 'Hoje';
    if (d == today.subtract(const Duration(days: 1))) return 'Ontem';
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              _label,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.mutedForeground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }
}

// ── Input de mensagem ─────────────────────────────────────────────────────────

class _MessageInput extends StatelessWidget {
  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  const _MessageInput({
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    // Adaptado para telas de celular
    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.inputFill,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: controller,
                  maxLines: 4,
                  minLines: 1,
                  maxLength: 2000,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSend(),
                  decoration: const InputDecoration(
                    hintText: 'Mensagem...',
                    hintStyle: TextStyle(color: AppTheme.mutedForeground),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: InputBorder.none,
                    counterText: '',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              height: 48,
              width: 48,
              margin: const EdgeInsets.only(
                bottom: 2,
              ), // Para alinhar pela base
              child: isSending
                  ? const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppTheme.primary,
                        ),
                      ),
                    )
                  : ElevatedButton(
                      onPressed: onSend,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        shape: const CircleBorder(),
                        padding: EdgeInsets.zero,
                        elevation: 0,
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
