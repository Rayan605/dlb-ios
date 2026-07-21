import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

import '../models/reservation.dart';
import '../services/format.dart';
import '../theme.dart';

/// Feuille modale affichant le billet + QR. Le QR arrive en PNG base64 du
/// backend (champ qr_base64) → décodé et affiché via Image.memory.
class QrTicketSheet extends StatelessWidget {
  final QrTicket ticket;
  final bool isGuest;
  const QrTicketSheet({super.key, required this.ticket, this.isGuest = false});

  static Future<void> show(BuildContext context, QrTicket ticket,
      {bool isGuest = false}) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => QrTicketSheet(ticket: ticket, isGuest: isGuest),
    );
  }

  @override
  Widget build(BuildContext context) {
    Uint8List? bytes;
    try {
      bytes = base64Decode(ticket.qrBase64);
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(kRadius + 4),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 18),
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(isGuest ? 'BILLET INVITÉ' : 'MON BILLET',
              style: AppTheme.mono(color: AppColors.accent, size: 11)),
          const SizedBox(height: 8),
          Text(
            ticket.eventTitle.toUpperCase(),
            textAlign: TextAlign.center,
            style: AppTheme.heading(size: 24),
          ),
          const SizedBox(height: 4),
          Text(Fmt.date(ticket.eventDate),
              style: const TextStyle(color: AppColors.sub, fontSize: 13)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(kRadius),
            ),
            child: bytes != null
                ? Image.memory(bytes, width: 220, height: 220)
                : const SizedBox(
                    width: 220,
                    height: 220,
                    child: Center(child: Text('QR indisponible')),
                  ),
          ),
          const SizedBox(height: 18),
          Text(ticket.holderName,
              style: AppTheme.heading(size: 20, color: AppColors.bright)),
          if (isGuest && ticket.hostName != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('Invité(e) de ${ticket.hostName}',
                  style: const TextStyle(color: AppColors.lime, fontSize: 13)),
            ),
          if (!isGuest && ticket.formulaName != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('✦ ${ticket.formulaName}',
                  style: const TextStyle(color: AppColors.accent, fontSize: 13)),
            ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fermer'),
            ),
          ),
          const SizedBox(height: 8),
          Text('Présente ce QR à l\'entrée · une seule scannée',
              textAlign: TextAlign.center,
              style: AppTheme.mono(size: 10, color: AppColors.muted)),
        ],
      ),
    );
  }
}
