import 'package:flutter/material.dart';

import '../models/formula.dart';
import '../services/format.dart';
import '../theme.dart';

/// Carte formule cliquable (comportement radio) reprise du web.
class FormulaCard extends StatelessWidget {
  final Formula formula;
  final FormulaAvailability? availability;
  final bool selected;
  final bool disabled;
  final VoidCallback onTap;

  const FormulaCard({
    super.key,
    required this.formula,
    required this.availability,
    required this.selected,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final girls = formula.isGirlsOnly;
    final accent = girls ? AppColors.pink : AppColors.accent;
    final spotsLeft = availability?.spotsLeft;

    Widget? spotsWidget;
    if (spotsLeft != null) {
      if (spotsLeft <= 0) {
        spotsWidget = const Text('COMPLET',
            style: TextStyle(
                color: AppColors.danger,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4));
      } else if (spotsLeft <= 5) {
        spotsWidget = Text(
            '$spotsLeft place${spotsLeft > 1 ? 's' : ''} restante${spotsLeft > 1 ? 's' : ''}',
            style: const TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4));
      } else {
        spotsWidget = Text('$spotsLeft places restantes',
            style: const TextStyle(color: AppColors.sub, fontSize: 11));
      }
    }

    return Opacity(
      opacity: disabled ? 0.45 : 1,
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(kRadius),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected
                ? accent.withValues(alpha: 0.08)
                : AppColors.surface,
            border: Border.all(
              color: selected ? accent : AppColors.border,
              width: selected ? 1.6 : 1,
            ),
            borderRadius: BorderRadius.circular(kRadius),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(formula.name.toUpperCase(),
                              style: AppTheme.heading(size: 18)),
                        ),
                        if (girls) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.pink,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text('♀ FILLES',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.4)),
                          ),
                        ],
                      ],
                    ),
                    if (formula.description != null &&
                        formula.description!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(formula.description!,
                          style: const TextStyle(
                              color: AppColors.sub, fontSize: 13, height: 1.4)),
                    ],
                    if (girls) ...[
                      const SizedBox(height: 4),
                      const Text('Entrée gratuite — réservé aux filles',
                          style: TextStyle(
                              color: AppColors.pink,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600)),
                    ],
                    if (formula.maxGuests > 0) ...[
                      const SizedBox(height: 6),
                      Text(
                          '✦ Tu peux inviter jusqu\'à ${formula.maxGuests} personne${formula.maxGuests > 1 ? 's' : ''}',
                          style: const TextStyle(
                              color: AppColors.accent, fontSize: 12)),
                    ],
                    if (spotsWidget != null) ...[
                      const SizedBox(height: 6),
                      spotsWidget,
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Fmt.priceOrFree(formula.priceCents, free: girls),
                    style: AppTheme.heading(
                        size: 22, color: girls ? AppColors.pink : AppColors.bright),
                  ),
                  const SizedBox(height: 8),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected ? accent : Colors.transparent,
                      border: Border.all(
                          color: selected ? accent : AppColors.border),
                    ),
                    child: selected
                        ? const Icon(Icons.check, size: 15, color: Colors.black)
                        : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
