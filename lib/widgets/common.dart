import 'package:flutter/material.dart';
import '../theme.dart';

/// Étiquette anguleuse type .tag du web.
class LpTag extends StatelessWidget {
  final String text;
  final Color? color;
  const LpTag(this.text, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.sub;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: c.withValues(alpha: 0.6)),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
          color: c,
        ),
      ),
    );
  }
}

/// Bandeau "places restantes" (or / rouge / gris).
class SeatsBadge extends StatelessWidget {
  final int seatsLeft;
  final bool full;
  const SeatsBadge({super.key, required this.seatsLeft, required this.full});

  @override
  Widget build(BuildContext context) {
    final urgent = !full && seatsLeft <= 10;
    final color = full
        ? AppColors.danger
        : urgent
            ? AppColors.accent
            : AppColors.sub;
    final label = full
        ? 'COMPLET'
        : urgent
            ? '🔥 $seatsLeft places'
            : '$seatsLeft places';
    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
        color: color,
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final String message;
  final IconData icon;
  const EmptyState({
    super.key,
    required this.message,
    this.icon = Icons.nightlife,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: AppColors.muted),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.sub, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class LpLoader extends StatelessWidget {
  const LpLoader({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(
            strokeWidth: 2.2,
            color: AppColors.accent,
          ),
        ),
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const ErrorView({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.danger, size: 40),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.sub, height: 1.5),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 18),
              OutlinedButton(onPressed: onRetry, child: const Text('Réessayer')),
            ],
          ],
        ),
      ),
    );
  }
}

/// Titre de section avec accent doré, façon web (section-title + gold span).
class SectionTitle extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String? highlight;
  const SectionTitle({
    super.key,
    required this.eyebrow,
    required this.title,
    this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(eyebrow.toUpperCase(), style: AppTheme.mono(color: AppColors.accent)),
        const SizedBox(height: 6),
        RichText(
          text: TextSpan(
            style: AppTheme.heading(size: 30),
            children: [
              TextSpan(text: title.toUpperCase()),
              if (highlight != null)
                TextSpan(
                  text: ' ${highlight!.toUpperCase()}',
                  style: AppTheme.heading(size: 30, color: AppColors.accent),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

void showSnack(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppColors.danger.withValues(alpha: 0.15) : null,
      ),
    );
}
