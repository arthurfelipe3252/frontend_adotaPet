import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:adota_pet/core/notifications/app_notifier.dart';
import 'package:adota_pet/core/theme/app_dimens.dart';
import 'package:adota_pet/core/theme/app_theme.dart';
import 'package:adota_pet/presentation/viewmodels/pet_viewmodel.dart';
import 'package:adota_pet/presentation/widgets/app_filter_chip.dart';
import 'package:adota_pet/presentation/widgets/confirm_dialog.dart';
import 'package:adota_pet/presentation/widgets/page_header.dart';
import 'package:adota_pet/presentation/widgets/pet_list_card.dart';
import 'package:adota_pet/presentation/widgets/primary_button.dart';
import 'package:adota_pet/presentation/widgets/search_field.dart';
import 'package:adota_pet/presentation/widgets/state_views.dart';

class OrgPetListPage extends StatefulWidget {
  const OrgPetListPage({super.key});

  @override
  State<OrgPetListPage> createState() => _OrgPetListPageState();
}

class _OrgPetListPageState extends State<OrgPetListPage> {
  static const _filters = ['Todos', 'Disponíveis', 'Em processo', 'Adotados'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PetViewModel>().loadPets();
    });
  }

  Future<void> _confirmDelete(String petId, String petNome) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Remover pet',
      message: 'Deseja remover "$petNome"? Esta ação não pode ser desfeita.',
      confirmLabel: 'Remover',
      destructive: true,
    );
    if (!ok || !mounted) return;
    final vm = context.read<PetViewModel>();
    final removed = await vm.deletePet(petId);
    if (removed) {
      AppNotifier.instance.success('Pet removido.');
    } else {
      AppNotifier.instance.error(vm.error ?? 'Não foi possível remover o pet.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PetViewModel>();

    return ColoredBox(
      color: AppTheme.background,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppSpacing.contentMaxWidth,
          ),
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.xl,
                  AppSpacing.xl,
                  AppSpacing.lg,
                ),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PageHeader(
                        title: 'Meus Pets',
                        subtitle:
                            'Gerencie os animais cadastrados pela sua organização.',
                        actions: [
                          PrimaryButton(
                            label: 'Cadastrar pet',
                            trailingIcon: Icons.add_rounded,
                            fullWidth: false,
                            onPressed: () => context.go('/pets/new'),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 360),
                        child: SearchField(
                          hint: 'Buscar por nome ou raça...',
                          onChanged: vm.setSearch,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final f in _filters)
                            AppFilterChip(
                              label: f,
                              selected: vm.activeFilter == f,
                              onTap: () => vm.setFilter(f),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              _buildSliverBody(vm),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliverBody(PetViewModel vm) {
    if (vm.isLoading && vm.pets.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: LoadingView(),
      );
    }
    if (vm.error != null && vm.pets.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: ErrorStateView(message: vm.error!, onRetry: vm.loadPets),
      );
    }
    final pets = vm.filteredPets;
    if (pets.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: EmptyState(
          icon: Icons.pets_rounded,
          title: 'Nenhum pet encontrado',
          message: 'Cadastre seu primeiro pet para começar.',
          actionLabel: 'Cadastrar pet',
          actionIcon: Icons.add_rounded,
          onAction: () => context.go('/pets/new'),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        0,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 260,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          // Altura fixa: foto (150) + textos/paddings (~88), com folga. Evita o
          // overflow que o childAspectRatio causava em colunas estreitas.
          mainAxisExtent: 252,
        ),
        delegate: SliverChildBuilderDelegate(
          (_, i) {
            final pet = pets[i];
            return PetListCard(
              pet: pet,
              onTap: () => context.go('/pets/${pet.id}'),
              onDelete: () => _confirmDelete(pet.id, pet.nome),
            );
          },
          childCount: pets.length,
        ),
      ),
    );
  }
}
