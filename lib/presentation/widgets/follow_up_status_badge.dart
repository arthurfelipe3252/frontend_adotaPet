import 'package:flutter/material.dart';
import '../../domain/entities/adoption_follow_up.dart';

class FollowUpStatusBadge extends StatelessWidget {
  final FollowUpStatus status;

  const FollowUpStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;

    switch (status) {
      case FollowUpStatus.emDia:
        color = Colors.green;
        text = 'EM DIA';
        break;
      case FollowUpStatus.proximoVencimento:
        color = Colors.orange;
        text = 'PRÓXIMO AO VENCIMENTO';
        break;
      case FollowUpStatus.atrasado:
        color = Colors.red;
        text = 'ATRASADO';
        break;
      case FollowUpStatus.pendente:
        color = Colors.blue;
        text = 'PENDENTE';
        break;
      case FollowUpStatus.concluido:
        color = Colors.grey;
        text = 'CONCLUÍDO';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
