import 'package:flutter/material.dart';
import '../../domain/entities/pet.dart';

class PetStatusBadge extends StatelessWidget {
  final String status;
  const PetStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case 'disponivel':
        bg = const Color(0xFF2E7D32).withOpacity(0.12);
        fg = const Color(0xFF2E7D32);
        label = 'Disponível';
        break;
      case 'em_processo':
        bg = const Color(0xFFF59E0B).withOpacity(0.15);
        fg = const Color(0xFFF59E0B);
        label = 'Em processo';
        break;
      case 'adotado':
        bg = const Color(0xFF1E88E5).withOpacity(0.12);
        fg = const Color(0xFF1E88E5);
        label = 'Adotado';
        break;
      default:
        bg = Colors.grey.withOpacity(0.12);
        fg = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: fg),
      ),
    );
  }
}

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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar com inicial
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  colors: [Color(0xFFCC6633), Color(0xFFE8923E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Text(
                  pet.nome[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Infos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pet.nome,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${pet.raca ?? pet.especieLabel} · ${pet.especieLabel}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            PetStatusBadge(status: pet.status),
            if (onDelete != null) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onDelete,
                child: Icon(Icons.more_vert, size: 18, color: Colors.grey[400]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
