import 'package:flutter/material.dart';

import 'package:adota_pet/core/theme/app_status_colors.dart';
import 'package:adota_pet/core/theme/app_theme.dart';
import 'package:adota_pet/domain/entities/pet.dart';
import 'package:adota_pet/presentation/widgets/pet_image.dart';
import 'package:adota_pet/presentation/widgets/status_pill.dart';

/// Card de pet para o grid de "Meus Pets": foto real (ou placeholder com a
/// inicial), badge de status sobre a foto, nome, raça/espécie e atributos.
class PetListCard extends StatelessWidget {
  final Pet pet;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const PetListCard({
    super.key,
    required this.pet,
    required this.onTap,
    this.onDelete,
  });

  /// Primeira foto utilizável do pet (data-URI base64 ou URL http), ou `null`
  /// para o build exibir o placeholder com a inicial.
  ImageProvider? get _image => firstPetImageProvider(pet.fotosUrls);

  @override
  Widget build(BuildContext context) {
    final image = _image;
    return Material(
      color: AppTheme.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppTheme.border),
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 150,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  image != null
                      ? Image(
                          image: image,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _placeholder(),
                        )
                      : _placeholder(),
                  Positioned(
                    left: 8,
                    bottom: 8,
                    child: StatusPill(
                      label: pet.statusLabel,
                      color: AppStatusColors.pet(pet.status),
                    ),
                  ),
                  if (onDelete != null)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: _CircleIconButton(
                        icon: Icons.delete_outline_rounded,
                        onTap: onDelete!,
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    pet.nome,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.foreground,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${pet.raca ?? pet.especieLabel} · ${pet.especieLabel}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppTheme.mutedForeground,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${pet.idadeFormatada} · ${pet.porteLabel} · ${pet.sexoLabel}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
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

  Widget _placeholder() {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary, AppTheme.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          pet.nome.isNotEmpty ? pet.nome[0].toUpperCase() : '🐾',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.45),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 18, color: Colors.white),
        ),
      ),
    );
  }
}
