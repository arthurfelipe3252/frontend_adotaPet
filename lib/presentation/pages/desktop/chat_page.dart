import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:adota_pet/core/theme/app_dimens.dart';
import 'package:adota_pet/core/theme/app_theme.dart';
import 'package:adota_pet/domain/entities/chat.dart';
import 'package:adota_pet/presentation/viewmodels/auth_viewmodel.dart';
import 'package:adota_pet/presentation/viewmodels/chat_viewmodel.dart';
import 'package:adota_pet/presentation/widgets/page_header.dart';
import 'package:adota_pet/presentation/widgets/primary_button.dart';
import 'package:adota_pet/presentation/widgets/state_views.dart';

class ChatPage extends StatefulWidget {
  /// Se fornecido, a página abre diretamente esta conversa ao carregar.
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
    return ColoredBox(
      color: AppTheme.background,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSpacing.contentMaxWidth),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PageHeader(
                  title: 'Chat',
                  subtitle: 'Converse com adotantes interessados nos seus pets.',
                ),
                const SizedBox(height: AppSpacing.lg),
                Expanded(child: _ChatLayout()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Layout two-panel ──────────────────────────────────────────────────────────

class _ChatLayout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ChatViewModel>();
    final width = MediaQuery.sizeOf(context).width;
    final twoPanel = width >= 860;

    // Em telas estreitas dentro do shell, mostra só o painel ativo
    if (!twoPanel) {
      return vm.activeConversation != null
          ? _MessagePanel()
          : _ConversationList();
    }

    return Row(
      children: [
        SizedBox(width: 320, child: _ConversationList()),
        const SizedBox(width: 1, child: VerticalDivider(width: 1, color: AppTheme.border)),
        Expanded(child: _MessagePanel()),
      ],
    );
  }
}

// ── Lista de conversas ────────────────────────────────────────────────────────

class _ConversationList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ChatViewModel>();

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            child: Text(
              'Conversas',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: vm.isLoadingConversations
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2))
                : vm.conversations.isEmpty
                    ? const EmptyState(
                        icon: Icons.chat_bubble_outline_rounded,
                        title: 'Nenhuma conversa',
                        message: 'As conversas aparecem aqui quando um adotante iniciar contato.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: vm.conversations.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, indent: 16, endIndent: 16),
                        itemBuilder: (_, i) {
                          final conv = vm.conversations[i];
                          final isActive = vm.activeConversation?.id == conv.id;
                          return _ConversationTile(
                            conversation: conv,
                            isActive: isActive,
                            onTap: () => context.read<ChatViewModel>().openConversation(conv.id),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final bool isActive;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.conversation,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final nomeAdotante = conversation.adopterNome ?? 'Adotante';

    return Material(
      color: isActive ? AppTheme.primary.withOpacity(0.08) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: isActive
                    ? AppTheme.primary.withOpacity(0.18)
                    : AppTheme.inputFill,
                child: Text(
                  nomeAdotante.isNotEmpty ? nomeAdotante[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isActive ? AppTheme.primary : AppTheme.mutedForeground,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nomeAdotante,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isActive ? AppTheme.primary : AppTheme.foreground,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Solicitação de adoção',
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
              if (!conversation.isActive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
        ),
      ),
    );
  }
}

// ── Painel de mensagens ───────────────────────────────────────────────────────

class _MessagePanel extends StatefulWidget {
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

    // Sem conversa selecionada
    if (conv == null) {
      return Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: const EmptyState(
          icon: Icons.chat_rounded,
          title: 'Selecione uma conversa',
          message: 'Escolha uma conversa na lista para começar a trocar mensagens.',
        ),
      );
    }

    _scrollToBottom();

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          // Header da conversa
          _ConversationHeader(conversation: conv),
          const Divider(height: 1),

          // Área de mensagens
          Expanded(
            child: vm.isLoadingMessages
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2))
                : vm.messages.isEmpty
                    ? const EmptyState(
                        icon: Icons.chat_bubble_outline_rounded,
                        title: 'Nenhuma mensagem',
                        message: 'Envie a primeira mensagem para começar a conversa.',
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Esta conversa foi encerrada.',
                style: TextStyle(color: AppTheme.mutedForeground, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ── Header da conversa ────────────────────────────────────────────────────────

class _ConversationHeader extends StatelessWidget {
  final Conversation conversation;
  const _ConversationHeader({required this.conversation});

  @override
  Widget build(BuildContext context) {
    final nome = conversation.adopterNome ?? 'Adotante';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppTheme.primary.withOpacity(0.12),
            child: Text(
              nome.isNotEmpty ? nome[0].toUpperCase() : '?',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppTheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(nome, style: Theme.of(context).textTheme.titleSmall),
                Text(
                  conversation.isActive ? 'Conversa ativa' : 'Conversa encerrada',
                  style: TextStyle(
                    fontSize: 12,
                    color: conversation.isActive
                        ? AppTheme.sage
                        : AppTheme.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          // Botão fechar conversa ativa
          if (conversation.isActive)
            OutlinedButton.icon(
              onPressed: () => _confirmClose(context),
              icon: const Icon(Icons.close_rounded, size: 16),
              label: const Text('Encerrar'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.destructive,
                side: const BorderSide(color: AppTheme.destructive),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmClose(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Encerrar conversa?'),
        content: const Text(
          'Ao encerrar, nenhuma nova mensagem poderá ser enviada. '
          'O histórico continuará visível.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.destructive),
            child: const Text('Encerrar'),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      context.read<ChatViewModel>().closeConversation();
    }
  }
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: AppTheme.inputFill,
              child: Text(
                (message.senderNome?.isNotEmpty == true)
                    ? message.senderNome![0].toUpperCase()
                    : '?',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.mutedForeground),
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
                  constraints: const BoxConstraints(maxWidth: 460),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMine ? AppTheme.primary : AppTheme.inputFill,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isMine ? 18 : 4),
                      bottomRight: Radius.circular(isMine ? 4 : 18),
                    ),
                  ),
                  child: Text(
                    message.content,
                    style: TextStyle(
                      fontSize: 14,
                      color: isMine ? Colors.white : AppTheme.foreground,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      time,
                      style: const TextStyle(fontSize: 10, color: AppTheme.mutedForeground),
                    ),
                    if (isMine) ...[
                      const SizedBox(width: 4),
                      Icon(
                        message.isRead ? Icons.done_all_rounded : Icons.done_rounded,
                        size: 12,
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
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            _label,
            style: const TextStyle(fontSize: 11, color: AppTheme.mutedForeground, fontWeight: FontWeight.w600),
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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: 4,
              minLines: 1,
              maxLength: 2000,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                hintText: 'Escreva uma mensagem...',
                hintStyle: const TextStyle(color: AppTheme.mutedForeground),
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppTheme.inputFill,
                counterText: '',
              ),
              textInputAction: TextInputAction.newline,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            height: 52,
            width: 52,
            child: isSending
                ? const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
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
    );
  }
}