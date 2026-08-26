import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class CaneleCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderRadius;
  final double elevation;

  const CaneleCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.onTap,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius = 16,
    this.elevation = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBg = isDark
        ? AppColors.darkPastryCard
        : AppColors.warmPastryCrust.withValues(alpha: 0.35);
    final defaultBorder = isDark
        ? AppColors.darkPastryBorder
        : AppColors.pastryCrustBorder;

    Widget cardBody = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? defaultBg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? defaultBorder,
          width: 1.2,
        ),
      ),
      child: child,
    );

    if (onTap != null) {
      cardBody = Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: cardBody,
        ),
      );
    }

    if (margin != null) {
      return Padding(
        padding: margin!,
        child: cardBody,
      );
    }

    return cardBody;
  }
}
