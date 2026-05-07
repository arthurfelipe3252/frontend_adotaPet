import 'package:flutter/material.dart';

import 'package:adota_pet/presentation/viewmodels/register_protetor_ong_viewmodel.dart';

class PasswordStrengthIndicator extends StatelessWidget {
  final SenhaForca strength;

  const PasswordStrengthIndicator({super.key, required this.strength});

  @override
  Widget build(BuildContext context) {
    if (strength.label.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 4, right: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: strength.progress,
              minHeight: 4,
              backgroundColor: const Color(0x14000000),
              valueColor: AlwaysStoppedAnimation<Color>(strength.color),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Força: ${strength.label}',
            style: TextStyle(
              fontSize: 12,
              color: strength.color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
