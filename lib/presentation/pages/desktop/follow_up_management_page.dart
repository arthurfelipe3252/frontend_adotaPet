import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/follow_up_viewmodel.dart';
import '../../widgets/follow_up_status_badge.dart';
import '../../widgets/org_layout.dart';
import '../../../domain/entities/adoption_follow_up.dart';
import 'package:intl/intl.dart';

class FollowUpManagementPage extends StatefulWidget {
  const FollowUpManagementPage({super.key});

  @override
  State<FollowUpManagementPage> createState() => _FollowUpManagementPageState();
}

class _FollowUpManagementPageState extends State<FollowUpManagementPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FollowUpViewModel>().loadFollowUps();
    });
  }

  @override
  Widget build(BuildContext context) {
    return OrgLayout(
      title: 'Acompanhamento Pós-Adoção',
      currentIndex: 3, // Corresponde ao índice no OrgLayout
      child: Column(
        children: [
          Expanded(
            child: Consumer<FollowUpViewModel>(
              builder: (context, vm, child) {
                if (vm.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (vm.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(vm.error!, style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: vm.loadFollowUps,
                          child: const Text('Tentar novamente'),
                        ),
                      ],
                    ),
                  );
                }

                if (vm.followUps.isEmpty) {
                  return _buildEmptyState();
                }

                return _buildTable(vm.followUps);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_rounded, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            'Nenhum acompanhamento ativo encontrado.',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
          const SizedBox(height: 16),
          const Text(
            'Acompanhamentos são criados automaticamente\nquando uma adoção é aprovada.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(List<AdoptionFollowUp> followUps) {
    return Container(
      margin: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          child: DataTable(
            headingRowColor: MaterialStateProperty.all(const Color(0xFFF8F9FA)),
            dataRowHeight: 64,
            columns: const [
              DataColumn(label: Text('PET', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('ADOTANTE', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('DATA INÍCIO', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('ÚLT. ATUALIZAÇÃO', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('PRÓX. ATUALIZAÇÃO', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('STATUS', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('AÇÕES', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: followUps.map((f) {
              return DataRow(cells: [
                DataCell(
                  Row(
                    children: [
                      if (f.petFotoUrl != null)
                        CircleAvatar(
                          backgroundImage: NetworkImage(f.petFotoUrl!),
                          radius: 18,
                        )
                      else
                        const CircleAvatar(
                          backgroundColor: Color(0xFFE0E0E0),
                          radius: 18,
                          child: Icon(Icons.pets, size: 18, color: Colors.white),
                        ),
                      const SizedBox(width: 12),
                      Text(f.petNome, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                DataCell(Text(f.adotanteNome)),
                DataCell(Text(DateFormat('dd/MM/yyyy').format(f.dataInicio))),
                DataCell(Text(f.dataUltimaAtualizacao != null 
                    ? DateFormat('dd/MM/yyyy').format(f.dataUltimaAtualizacao!)
                    : 'Nenhuma')),
                DataCell(Text(DateFormat('dd/MM/yyyy').format(f.dataProximaAtualizacao))),
                DataCell(FollowUpStatusBadge(status: f.status)),
                DataCell(
                  IconButton(
                    icon: const Icon(Icons.visibility),
                    tooltip: 'Ver detalhes',
                    onPressed: () => context.go('/org/follow-up/${f.id}'),
                  ),
                ),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }
}
