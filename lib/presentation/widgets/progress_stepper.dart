import 'package:flutter/material.dart';

import 'package:adota_pet/core/theme/app_theme.dart';

class ProgressStepper extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final List<String>? stepLabels;

  const ProgressStepper({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.stepLabels,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(totalSteps, (i) {
            final isActive = i <= currentStep;
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(right: i < totalSteps - 1 ? 8 : 0),
                height: 6,
                decoration: BoxDecoration(
                  color: isActive ? AppTheme.sage : AppTheme.border,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            );
          }),
        ),
        if (stepLabels != null) ...[
          const SizedBox(height: 8),
          Text(
            'Passo ${currentStep + 1} de $totalSteps — ${stepLabels![currentStep]}',
            style: const TextStyle(
              color: AppTheme.mutedForeground,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}
