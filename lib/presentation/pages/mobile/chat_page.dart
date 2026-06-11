import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:adota_pet/core/theme/app_theme.dart';
import 'package:adota_pet/domain/entities/chat.dart';
import 'package:adota_pet/presentation/viewmodels/auth_viewmodel.dart';
import 'package:adota_pet/presentation/viewmodels/chat_viewmodel.dart';
import 'package:adota_pet/presentation/widgets/state_views.dart';

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
      final vm = context.read<ChatViewModel>();
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
      appBar: AppBar(
        title: const Text('Chat'),
      ),
      backgroundColor: AppTheme.background,
      body: const _ConversationList(),
    );
  }
}

// ── Lista de conversas ────────────────────────────────────────────────────────

class _ConversationList extends StatelessWidget {
  const _ConversationList();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ChatViewModel>();

    if (vm.isLoadingConversations) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2),
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
        itemCount: vm.conversations.length,
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
        itemBuilder: (_, i) {
          final conv = vm.conversations[i];
          return _ConversationTile(
            conversation: conv,
            onTap: () => context.read<ChatViewModel>().openConversation(conv.id),
          );
        },
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.conversation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Para simplificar, assumimos o nome do adotante ou contato primário.
    // Pode mudar de acordo com quem está logado (ONG ou adotante),
    // mas o desktop exibia adopterNome ou 'Adotante'.
    final nomeContato = conversation.adopterNome?.isNotEmpty == true 
        ? conversation.adopterNome! 
        : 'Adotante';

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: AppTheme.primary.withOpacity(0.12),
              child: Text(
                nomeContato.isNotEmpty ? nomeContato[0].toUpperCase() : '?',
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          nomeContato,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.foreground,
                          ),
                        ),
                      ),
                      if (!conversation.isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          margin: const EdgeInsets.only(left: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.border,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Encerrada',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.mutedForeground),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Solicitação de adoção',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
    final conv = vm.activeConversation;
    final session = context.read<AuthViewModel>().session;
    final myUserId = session?.usuario.id ?? '';

    if (conv == null) {
      return const Scaffold(
        body: Center(child: Text('Erro ao carregar a conversa.')),
      );
    }

    _scrollToBottom();
    
    final nomeContato = conv.adopterNome?.isNotEmpty == true 
        ? conv.adopterNome! 
        : 'Adotante';

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
                nomeContato.isNotEmpty ? nomeContato[0].toUpperCase() : '?',
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
                    nomeContato,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  if (!conv.isActive)
                    const Text(
                      'Encerrada',
                      style: TextStyle(fontSize: 12, color: AppTheme.mutedForeground, fontWeight: FontWeight.normal),
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
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2))
                  : vm.messages.isEmpty
                      ? const EmptyState(
                          icon: Icons.chat_bubble_outline_rounded,
                          title: 'Nenhuma mensagem',
                          message: 'Envie a primeira mensagem para começar.',
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          itemCount: vm.messages.length,
                          itemBuilder: (_, i) {
                            final msg = vm.messages[i];
                            final isMine = msg.senderId == myUserId;
                            final showDate = i == 0 ||
                                !_sameDay(vm.messages[i - 1].createdAt, msg.createdAt);
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
                  style: TextStyle(color: AppTheme.mutedForeground, fontSize: 14),
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
    final time =
        '${message.createdAt.hour.toString().padLeft(2, '0')}:${message.createdAt.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
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
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.mutedForeground),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMine && message.senderNome != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 4),
                    child: Text(
                      message.senderNome!,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.mutedForeground),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                      style: const TextStyle(fontSize: 11, color: AppTheme.mutedForeground),
                    ),
                    if (isMine) ...[
                      const SizedBox(width: 4),
                      Icon(
                        message.isRead ? Icons.done_all_rounded : Icons.done_rounded,
                        size: 14,
                        color: message.isRead ? AppTheme.sage : AppTheme.mutedForeground,
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
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    if (d == today) return 'Hoje';
    if (d == today.subtract(const Duration(days: 1))) return 'Ontem';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            _label,
            style: const TextStyle(fontSize: 12, color: AppTheme.mutedForeground, fontWeight: FontWeight.w600),
          ),
        ),
        const Expanded(child: Divider()),
      ]),
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
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              margin: const EdgeInsets.only(bottom: 2), // Para alinhar pela base
              child: isSending
                  ? const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: AppTheme.primary),
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
                      child: const Icon(Icons.send_rounded, size: 20, color: Colors.white),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
