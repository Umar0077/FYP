import 'package:flutter/material.dart';
import 'dart:ui';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double elevation;
  final double blur;
  final Color? color;
  final Color? borderColor;
  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.elevation = 0,
    this.borderRadius = 16,
    this.blur = 16,
    this.color,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color glassBg = color ?? (isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.45));
    final Color glassBorder = borderColor ?? (isDark ? Colors.white.withOpacity(0.18) : Colors.black.withOpacity(0.08));
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: glassBorder, width: 1.2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            decoration: BoxDecoration(
              color: glassBg,
              borderRadius: BorderRadius.circular(borderRadius),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(isDark ? 0.18 : 0.08), blurRadius: 12, offset: const Offset(0, 4)),
              ],
            ),
            padding: padding ?? const EdgeInsets.all(18),
            child: child,
          ),
        ),
      ),
    );
  }
}
