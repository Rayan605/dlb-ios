import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/event.dart';
import '../services/format.dart';
import '../theme.dart';
import 'common.dart';

/// Carte d'une soirée à venir (image, date, ville, places).
class EventCard extends StatelessWidget {
  final PartyEvent event;
  final VoidCallback onTap;
  const EventCard({super.key, required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(kRadius),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(kRadius),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: event.cover != null
                  ? CachedNetworkImage(
                      imageUrl: event.cover!.url,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          Container(color: AppColors.raised),
                      errorWidget: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          Fmt.date(event.date),
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.mono(size: 10.5),
                        ),
                      ),
                      const SizedBox(width: 8),
                      LpTag(event.department),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    event.title.toUpperCase(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.heading(size: 21),
                  ),
                  const SizedBox(height: 6),
                  Text('📍 ${event.city}',
                      style: const TextStyle(color: AppColors.sub, fontSize: 13)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SeatsBadge(seatsLeft: event.seatsLeft, full: event.isFull),
                      const Text('→',
                          style: TextStyle(
                              color: AppColors.accent,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        color: AppColors.raised,
        alignment: Alignment.center,
        child: Text('Liste Party',
            style: AppTheme.heading(size: 22, color: AppColors.muted)),
      );
}

/// Carte "recap" d'une soirée passée.
class RecapCard extends StatelessWidget {
  final PartyEvent event;
  final VoidCallback onTap;
  const RecapCard({super.key, required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cover = event.recapCover ?? event.cover;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(kRadius),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(kRadius),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (cover != null && !cover.isVideo)
              CachedNetworkImage(imageUrl: cover.url, fit: BoxFit.cover)
            else
              Container(
                color: AppColors.raised,
                alignment: Alignment.center,
                child: Icon(
                  cover?.isVideo == true
                      ? Icons.play_circle_outline
                      : Icons.image_outlined,
                  color: AppColors.muted,
                  size: 40,
                ),
              ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.center,
                    colors: [
                      Colors.black.withValues(alpha: 0.85),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(Fmt.dateShort(event.date),
                      style: AppTheme.mono(size: 10, color: AppColors.accent)),
                  const SizedBox(height: 2),
                  Text(event.title.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.heading(size: 18)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
