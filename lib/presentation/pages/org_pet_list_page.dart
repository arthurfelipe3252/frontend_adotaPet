import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/pet_viewmodel.dart';
import '../widgets/org_layout.dart';
import '../widgets/pet_list_card.dart';
import 'pet_form_page.dart';

class OrgPetListPage extends StatefulWidget {
  const OrgPetListPage({super.key});

  @override
  State<OrgPetListPage> createState() => _OrgPetListPageState();
}

class _OrgPetListPageState extends State<OrgPetListPage> {
  final _searchController = TextEditingController();
  final _filters = ['Todos', 'Disponíveis', 'Em processo', 'Adotados'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PetViewModel>().loadPets();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _confirmDelete(BuildContext context, String petId, String petNome) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remover pet', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text('Deseja remover "$petNome"? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final vm = context.read<PetViewModel>();
              final ok = await vm.deletePet(petId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ok ? 'Pet removido.' : vm.error ?? 'Erro ao remover.'),
                    backgroundColor: ok ? const Color(0xFF2E7D32) : Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }
            },
            child: const Text('Remover', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PetViewModel>();

    return OrgLayout(
      title: 'Meus Pets',
      currentIndex: 1,
      child: Column(
        children: [
          // Search + botão novo
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              children: [
                // Search bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEEAE6),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search, size: 18, color: Colors.grey[500]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: vm.setSearch,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Buscar pet...',
                            hintStyle: TextStyle(fontSize: 13, color: Colors.grey[500]),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // Botão cadastrar
                SizedBox(
                  width: double.infinity,
                  child: GestureDetector(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PetFormPage()),
                      );
                      if (context.mounted) context.read<PetViewModel>().loadPets();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFCC6633), Color(0xFFE8923E)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFCC6633).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add, size: 16, color: Colors.white),
                          SizedBox(width: 6),
                          Text(
                            'Cadastrar novo pet',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Filtros
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final f = _filters[i];
                final isActive = vm.activeFilter == f;
                return GestureDetector(
                  onTap: () => vm.setFilter(f),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0xFFCC6633) : const Color(0xFFEEEAE6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      f,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isActive ? Colors.white : Colors.grey[600],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          // Lista
          Expanded(
            child: vm.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFCC6633)),
                  )
                : vm.error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 8),
                            Text(
                              vm.error!,
                              style: TextStyle(color: Colors.grey[500], fontSize: 13),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: vm.loadPets,
                              child: const Text('Tentar novamente'),
                            ),
                          ],
                        ),
                      )
                    : vm.filteredPets.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('🐾', style: TextStyle(fontSize: 48)),
                                const SizedBox(height: 8),
                                Text(
                                  'Nenhum pet encontrado.',
                                  style: TextStyle(color: Colors.grey[500], fontSize: 13),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: vm.filteredPets.length,
                            itemBuilder: (_, i) {
                              final pet = vm.filteredPets[i];
                              return PetListCard(
                                pet: pet,
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => PetFormPage(petId: pet.id),
                                    ),
                                  );
                                  if (context.mounted) {
                                    context.read<PetViewModel>().loadPets();
                                  }
                                },
                                onDelete: () => _confirmDelete(context, pet.id, pet.nome),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
