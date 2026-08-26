import 'package:flutter/material.dart';
import '../../core/utils/jalali_helper.dart';

class DebtBadge extends StatelessWidget {
  final int debt;
  final VoidCallback? onPay;

  const DebtBadge({super.key, required this.debt, this.onPay});

  @override
  Widget build(BuildContext context) {
    if (debt <= 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
        ),
        child: const Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.check_circle_outline, color: Colors.green, size: 14),
          SizedBox(width: 4),
          Text('تسویه', style: TextStyle(color: Colors.green, fontSize: 12)),
        ]),
      );
    }
    return InkWell(
      onTap: onPay,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 14),
          const SizedBox(width: 4),
          Text('${JalaliHelper.formatAmount(debt)} ت',
              style: const TextStyle(color: Colors.red, fontSize: 12)),
          if (onPay != null) ...[
            const SizedBox(width: 4),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.red, size: 10),
          ],
        ]),
      ),
    );
  }
}
