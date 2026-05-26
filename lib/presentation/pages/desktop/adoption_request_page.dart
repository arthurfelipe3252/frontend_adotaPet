import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:adota_pet/domain/entities/adoption_request.dart';
import 'package:adota_pet/presentation/viewmodels/adoption_request_viewmodel.dart';
import 'package:adota_pet/presentation/widgets/org_layout.dart';

class AdoptionRequestPage extends StatefulWidget {
  const AdoptionRequestPage({super.key});

  @override
  State<AdoptionRequestPage> createState() => _AdoptionRequestPageState();
}

class _AdoptionRequestPageState extends State<AdoptionRequestPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdoptionRequestViewmodel>().loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    return OrgLayout(
      title: 'Solicitações de Adoção',
      currentIndex: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: () => _showCreateDialog(context),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('Nova solicitação'),
              ),
            ),
          ),
          Expanded(
            child: Consumer<AdoptionRequestViewmodel>(
              builder: (context, vm, _) {
                if (vm.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (vm.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(vm.error!, style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: vm.loadAll,
                          child: const Text('Tentar novamente'),
                        ),
                      ],
                    ),
                  );
                }
                if (vm.requests.isEmpty) {
                  return const Center(child: Text('Nenhuma solicitação encontrada.'));
                }
                return RefreshIndicator(
                  onRefresh: vm.loadAll,
                  child: ListView.builder(
                    itemCount: vm.requests.length,
                    padding: const EdgeInsets.all(12),
                    itemBuilder: (context, index) =>
                        _AdoptionRequestCard(request: vm.requests[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    final petIdController = TextEditingController();
    final adopterIdController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nova Solicitação'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: petIdController, decoration: const InputDecoration(labelText: 'ID do Pet')),
            const SizedBox(height: 8),
            TextField(controller: adopterIdController, decoration: const InputDecoration(labelText: 'ID do Adotante')),
            const SizedBox(height: 8),
            TextField(controller: notesController, decoration: const InputDecoration(labelText: 'Observações (opcional)'), maxLines: 3),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (petIdController.text.isEmpty || adopterIdController.text.isEmpty) return;
              await context.read<AdoptionRequestViewmodel>().create(
                    petId: petIdController.text.trim(),
                    adopterId: adopterIdController.text.trim(),
                    notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                  );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Criar'),
          ),
        ],
      ),
    );
  }
}

class _AdoptionRequestCard extends StatelessWidget {
  final AdoptionRequest request;
  const _AdoptionRequestCard({required this.request});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text('Pet: ${request.petId}', style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                _StatusBadge(status: request.status),
              ],
            ),
            const SizedBox(height: 4),
            Text('Adotante: ${request.adopterId}', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 4),
            Row(children: [
              _PreTriageBadge(status: request.preTriageStatus),
              if (request.matchScore != null) ...[
                const SizedBox(width: 8),
                Text('Score: ${request.matchScore!.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12)),
              ],
            ]),
            if (request.notes != null) ...[
              const SizedBox(height: 4),
              Text(request.notes!, style: const TextStyle(fontSize: 12)),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _StatusActions(request: request),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => context.read<AdoptionRequestViewmodel>().delete(request.id),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusActions extends StatelessWidget {
  final AdoptionRequest request;
  const _StatusActions({required this.request});

  @override
  Widget build(BuildContext context) {
    final vm = context.read<AdoptionRequestViewmodel>();
    if (request.status == 'received') {
      return ElevatedButton(
        onPressed: () => vm.updateStatus(request.id, 'in_analysis'),
        child: const Text('Iniciar análise'),
      );
    }
    if (request.status == 'in_analysis') {
      return Row(children: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          onPressed: () => vm.updateStatus(request.id, 'approved'),
          child: const Text('Aprovar', style: TextStyle(color: Colors.white)),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => vm.updateStatus(request.id, 'rejected'),
          child: const Text('Rejeitar', style: TextStyle(color: Colors.white)),
        ),
      ]);
    }
    return const SizedBox.shrink();
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final colors = {'received': Colors.grey, 'in_analysis': Colors.blue, 'approved': Colors.green, 'rejected': Colors.red};
    final labels = {'received': 'Recebida', 'in_analysis': 'Em análise', 'approved': 'Aprovada', 'rejected': 'Rejeitada'};
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: (colors[status] ?? Colors.grey),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(labels[status] ?? status, style: TextStyle(fontSize: 11, color: colors[status] ?? Colors.grey, fontWeight: FontWeight.w500)),
    );
  }
}

class _PreTriageBadge extends StatelessWidget {
  final String status;
  const _PreTriageBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final colors = {'qualified': Colors.green, 'review': Colors.orange, 'disqualified': Colors.red};
    final labels = {'qualified': 'Qualificado', 'review': 'Em revisão', 'disqualified': 'Desqualificado'};
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: (colors[status] ?? Colors.grey),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: (colors[status] ?? Colors.grey)),
      ),
      child: Text(labels[status] ?? status, style: TextStyle(fontSize: 11, color: colors[status] ?? Colors.grey)),
    );
  }
}