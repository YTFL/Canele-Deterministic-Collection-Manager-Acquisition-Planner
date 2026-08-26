import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class CaneleProgressBar extends StatelessWidget {
  final double value; // 0.0 to 1.0
  final double height;
  final Color? progressColor;
  final Color? backgroundColor;
  final bool showPercentage;

  const CaneleProgressBar({
    super.key,
    required this.value,
    this.height = 8,
    this.progressColor,
    this.backgroundColor,
    this.showPercentage = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final clampedValue = value.clamp(0.0, 1.0);
    final bg = backgroundColor ??
        (isDark ? AppColors.darkPastryCardElevated : AppColors.pastryCrustLight);
    final fg = progressColor ??
        (isDark ? AppColors.caramelizedAmberLight : AppColors.caramelizedAmber);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: Container(
            height: height,
            width: double.infinity,
            color: bg,
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: clampedValue,
              child: Container(
                decoration: BoxDecoration(
                  color: fg,
                  borderRadius: BorderRadius.circular(height / 2),
                ),
              ),
            ),
          ),
        ),
        if (showPercentage) ...[
          const SizedBox(height: 4),
          Text(
            '${(clampedValue * 100).toInt()}%',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
          ),
        ],
      ],
    );
  }
}
