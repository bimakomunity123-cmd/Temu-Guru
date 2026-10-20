import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final String? customLabel;

  const StatusBadge({
    super.key,
    required this.status,
    this.customLabel,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color textColor;
    IconData icon;
    String label;

    switch (status.toLowerCase()) {
      case 'approved':
      case 'active':
        bg = AppColors.successLight;
        textColor = const Color(0xFF065F46);
        icon = Icons.check_circle_rounded;
        label = customLabel ?? 'Disetujui';
        break;
      case 'rejected':
        bg = AppColors.errorLight;
        textColor = const Color(0xFF991B1B);
        icon = Icons.cancel_rounded;
        label = customLabel ?? 'Ditolak';
        break;
      case 'pending':
      default:
        bg = AppColors.warningLight;
        textColor = const Color(0xFF92400E);
        icon = Icons.hourglass_top_rounded;
        label = customLabel ?? 'Menunggu Verifikasi';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
