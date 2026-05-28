import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/follow_up_viewmodel.dart';
import '../../widgets/follow_up_status_badge.dart';
import '../../widgets/follow_up_timeline_item.dart';
import '../../widgets/org_layout.dart';
import '../../../domain/entities/adoption_follow_up.dart';
import 'package:intl/intl.dart';

class FollowUpReviewPage extends StatefulWidget {
  final String id;
  const FollowUpReviewPage({super.key, required this.id});

  @override
  State<FollowUpReviewPage> createState() => _FollowUpReviewPageState();
}

class _FollowUpReviewPageState extends State<FollowUpReviewPage> {
  final _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FollowUpViewModel>().loadFollowUpDetails(widget.id);
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OrgLayout(
      title: 'Detalhes do Acompanhamento',
      currentIndex: 3,
      child: Consumer<FollowUpViewModel>(
        builder: (context, vm, child) {
          if (vm.isLoading) return const Center(child: CircularProgressIndicator());
          if (vm.selectedFollowUp == null) return const Center(child: Text('Acompanhamento não encontrado'));

          final f = vm.selectedFollowUp!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(f, vm),
                const SizedBox(height: 32),
                const Text(
                  'Histórico de Atualizações',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                if (vm.updates.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Text('O adotante ainda não enviou atualizações.'),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: vm.updates.length,
                    itemBuilder: (context, index) {
                      final update = vm.updates[index];
                      return FollowUpTimelineItem(
                        update: update,
                        isLast: index == vm.updates.length - 1,
                        onRespond: update.comentarioAnunciante == null 
                            ? () => _showRespondDialog(context, vm, update.id)
                            : null,
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(AdoptionFollowUp f, FollowUpViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (f.petFotoUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(f.petFotoUrl!, width: 120, height: 120, fit: BoxFit.cover),
            )
          else
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.pets, size: 48, color: Colors.grey),
            ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      f.petNome,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                    ),
                    FollowUpStatusBadge(status: f.status),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Adotante: ${f.adotanteNome}', style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 40,
                  runSpacing: 16,
                  children: [
                    _buildInfoColumn('Data Início', DateFormat('dd/MM/yyyy').format(f.dataInicio)),
                    _buildInfoColumn('Próxima Atualização', DateFormat('dd/MM/yyyy').format(f.dataProximaAtualizacao)),
                    if (f.dataUltimaAtualizacao != null)
                      _buildInfoColumn('Última Atualização', DateFormat('dd/MM/yyyy').format(f.dataUltimaAtualizacao!)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          if (f.status != 'CONCLUIDO')
            ElevatedButton(
              onPressed: () => _showConcludeDialog(context, vm, f.id),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              ),
              child: const Text('Finalizar Processo'),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  void _showRespondDialog(BuildContext context, FollowUpViewModel vm, String updateId) {
    _commentController.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Comentar Atualização'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Seu comentário ajudará o adotante a se sentir mais seguro no processo.'),
            const SizedBox(height: 16),
            TextField(
              controller: _commentController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Ex: "Que alegria ver o pet tão bem adaptado! Continue assim."',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final ok = await vm.respondUpdate(
                updateId, 
                widget.id, 
                aprovado: true, 
                comentario: _commentController.text,
              );
              if (ok && mounted) Navigator.pop(ctx);
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }

  void _showConcludeDialog(BuildContext context, FollowUpViewModel vm, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Finalizar Acompanhamento?'),
        content: const Text(
          'Iso indica que o pet está totalmente adaptado e as revisões periódicas obrigatórias não são mais necessárias.\n\nDeseja continuar?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Não')),
          ElevatedButton(
            onPressed: () async {
              final ok = await vm.concludeFollowUp(id);
              if (ok && mounted) Navigator.pop(ctx);
            },
            child: const Text('Sim, Finalizar'),
          ),
        ],
      ),
    );
  }
}
