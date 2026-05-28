import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/follow_up_viewmodel.dart';
import '../../widgets/follow_up_status_badge.dart';
import '../../../domain/entities/adoption_follow_up.dart';
import 'package:intl/intl.dart';

class FollowUpListPage extends StatefulWidget {
  const FollowUpListPage({super.key});

  @override
  State<FollowUpListPage> createState() => _FollowUpListPageState();
}

class _FollowUpListPageState extends State<FollowUpListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FollowUpViewModel>().loadFollowUps();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Acompanhamentos'),
        elevation: 0,
      ),
      body: Consumer<FollowUpViewModel>(
        builder: (context, vm, child) {
          if (vm.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (vm.error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(vm.error!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: vm.loadFollowUps,
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (vm.followUps.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: vm.loadFollowUps,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: vm.followUps.length,
              itemBuilder: (context, index) {
                final f = vm.followUps[index];
                return _buildFollowUpCard(f);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.volunteer_activism_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            'Nenhuma adoção em acompanhamento.',
            style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 48, vertical: 8),
            child: Text(
              'Acompanharemos você e seu novo amigo nas primeiras semanas após a adoção!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFollowUpCard(AdoptionFollowUp f) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => context.push('/follow-up/${f.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (f.petFotoUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(f.petFotoUrl!, width: 80, height: 80, fit: BoxFit.cover),
                )
              else
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.pets, color: Colors.grey),
                ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      f.petNome,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    FollowUpStatusBadge(status: f.status),
                    const SizedBox(height: 8),
                    Text(
                      'Próxima atualização: ${DateFormat('dd/MM/yyyy').format(f.dataProximaAtualizacao)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
