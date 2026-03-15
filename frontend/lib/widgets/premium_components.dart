import 'dart:ui';
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../utils/responsive.dart';

/// Premium Card with gradient border and shadow
class PremiumCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final LinearGradient? gradient;
  final Color? color;
  final double borderRadius;
  final bool useGlassmorphism;
  final double? glassOpacity;
  final VoidCallback? onTap;

  const PremiumCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.gradient,
    this.color,
    this.borderRadius = 24,
    this.useGlassmorphism = false,
    this.glassOpacity,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final effectiveBorderRadius = isDesktop
        ? borderRadius + 4
        : (Responsive.isTablet(context) ? borderRadius : borderRadius - 4);

    final card = Container(
      padding: padding ??
          EdgeInsets.all(
            isDesktop ? 24 : (Responsive.isTablet(context) ? 20 : 16),
          ),
      decoration: BoxDecoration(
        color: color ??
            (useGlassmorphism
                ? Colors.transparent
                : Theme.of(context).cardColor),
        borderRadius: BorderRadius.circular(effectiveBorderRadius),
        gradient: gradient,
        border: useGlassmorphism
            ? Border.all(
                color: Colors.white.withOpacity(glassOpacity ?? 0.2),
                width: 1,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDesktop ? 0.08 : 0.05),
            blurRadius: isDesktop ? 20 : 15,
            offset: Offset(0, isDesktop ? 8 : 6),
          ),
        ],
      ),
      child: child,
    );

    final wrappedCard = useGlassmorphism
        ? ClipRRect(
            borderRadius: BorderRadius.circular(effectiveBorderRadius),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: padding ??
                    EdgeInsets.all(
                      isDesktop ? 24 : (Responsive.isTablet(context) ? 20 : 16),
                    ),
                decoration: BoxDecoration(
                  color: (glassOpacity ?? 0.15).toString().isEmpty
                      ? Colors.white.withOpacity(0.15)
                      : Colors.white.withOpacity(glassOpacity ?? 0.15),
                  borderRadius: BorderRadius.circular(effectiveBorderRadius),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: child,
              ),
            ),
          )
        : card;

    return onTap != null
        ? InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(effectiveBorderRadius),
            child: wrappedCard,
          )
        : wrappedCard;
  }
}

/// Glass Container with frosted glass effect
class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blurSigmaX;
  final double blurSigmaY;
  final Color backgroundColor;
  final double borderColorOpacity;
  final Border? border;

  const GlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 24,
    this.blurSigmaX = 10,
    this.blurSigmaY = 10,
    this.backgroundColor = const Color(0xFFFFFFFF),
    this.borderColorOpacity = 0.2,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final effectiveBorderRadius = isDesktop
        ? borderRadius + 4
        : (Responsive.isTablet(context) ? borderRadius : borderRadius - 4);

    final container = Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(effectiveBorderRadius),
        border: border ??
            Border.all(
              color: Colors.white.withOpacity(borderColorOpacity),
              width: 1,
            ),
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(effectiveBorderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigmaX, sigmaY: blurSigmaY),
        child: margin != null ? Padding(padding: margin!, child: container) : container,
      ),
    );
  }
}

/// Premium Button with gradient and pill shape
class PremiumButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final LinearGradient? gradient;
  final Color? backgroundColor;
  final Color textColor;
  final double height;
  final double borderRadius;
  final bool fullWidth;

  const PremiumButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.gradient,
    this.backgroundColor,
    this.textColor = Colors.white,
    this.height = 56,
    this.borderRadius = 28,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final effectiveHeight = isDesktop
        ? height + 4
        : (Responsive.isTablet(context) ? height : height - 4);
    final effectiveBorderRadius = isDesktop
        ? borderRadius + 2
        : (Responsive.isTablet(context) ? borderRadius : borderRadius - 2);

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: effectiveHeight,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          elevation: 0,
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 32 : 24,
            vertical: isDesktop ? 18 : 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(effectiveBorderRadius),
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(textColor),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: isDesktop ? 22 : 18),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: Responsive.getFontSize(context, FontSizeType.subtitle),
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Premium Text Form Field with pill shape
class PremiumTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final int? maxLines;
  final bool readOnly;
  final VoidCallback? onTap;

  const PremiumTextField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      maxLines: maxLines,
      readOnly: readOnly,
      onTap: onTap,
      style: TextStyle(
        fontSize: Responsive.getFontSize(context, FontSizeType.body),
        color: isDark ? AppTheme.textPrimary : const Color(0xFF1A1A1A),
      ),
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        labelStyle: TextStyle(
          color: isDark ? Colors.grey[400] : Colors.grey[600],
          fontSize: Responsive.getFontSize(context, FontSizeType.body),
        ),
        hintStyle: TextStyle(
          color: isDark ? Colors.grey[500] : Colors.grey[400],
          fontSize: Responsive.getFontSize(context, FontSizeType.body),
        ),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: isDark ? Colors.grey[400] : Colors.grey[600])
            : null,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: isDark
            ? AppTheme.surfaceColor.withOpacity(0.5)
            : const Color(0xFFF5F5F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: BorderSide(
            color: AppTheme.primaryColor,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: const BorderSide(color: AppTheme.errorColor, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: const BorderSide(color: AppTheme.errorColor, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 28 : 24,
          vertical: isDesktop ? 18 : 16,
        ),
      ),
    );
  }
}

/// Circular Progress Gauge (Premium Style)
class PremiumGauge extends StatelessWidget {
  final double value; // 0.0 to 1.0
  final double size;
  final String? label;
  final String? subLabel;
  final Color? progressColor;
  final Color? backgroundColor;
  final double strokeWidth;
  final bool showPercentage;

  const PremiumGauge({
    super.key,
    required this.value,
    this.size = 120,
    this.label,
    this.subLabel,
    this.progressColor,
    this.backgroundColor,
    this.strokeWidth = 12,
    this.showPercentage = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final effectiveSize = isDesktop
        ? size + 20
        : (Responsive.isTablet(context) ? size : size - 10);
    final effectiveStrokeWidth = isDesktop
        ? strokeWidth + 2
        : (Responsive.isTablet(context) ? strokeWidth : strokeWidth - 2);

    final clampedValue = value.clamp(0.0, 1.0);
    final displayColor = progressColor ?? AppTheme.successColor;
    final bgColor = backgroundColor ?? Colors.grey[200]!;

    return SizedBox(
      width: effectiveSize,
      height: effectiveSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: effectiveSize,
            height: effectiveSize,
            child: CircularProgressIndicator(
              value: clampedValue,
              strokeWidth: effectiveStrokeWidth,
              backgroundColor: bgColor,
              valueColor: AlwaysStoppedAnimation<Color>(displayColor),
              strokeCap: StrokeCap.round,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showPercentage)
                Text(
                  '${(clampedValue * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: isDesktop ? 28 : 24,
                    fontWeight: FontWeight.bold,
                    color: displayColor,
                  ),
                ),
              if (label != null) ...[
                const SizedBox(height: 2),
                Text(
                  label!,
                  style: TextStyle(
                    fontSize: Responsive.getFontSize(context, FontSizeType.small),
                    color: Colors.grey[600],
                  ),
                ),
              ],
              if (subLabel != null) ...[
                const SizedBox(height: 2),
                Text(
                  subLabel!,
                  style: TextStyle(
                    fontSize: Responsive.getFontSize(context, FontSizeType.small) - 2,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Floating Action Button (Premium Style)
class PremiumFAB extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color iconColor;
  final String? tooltip;
  final bool isLoading;

  const PremiumFAB({
    super.key,
    required this.icon,
    this.onPressed,
    this.backgroundColor,
    this.iconColor = Colors.white,
    this.tooltip,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: backgroundColor ?? AppTheme.primaryColor,
      elevation: 8,
      tooltip: tooltip,
      shape: const CircleBorder(),
      child: isLoading
          ? SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(iconColor),
              ),
            )
          : Icon(icon, color: iconColor, size: 28),
    );
  }
}

/// Premium Chip for filters
class PremiumChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final Color? selectedColor;
  final Color? unselectedColor;

  const PremiumChip({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onTap,
    this.selectedColor,
    this.unselectedColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final effectiveColor = isSelected
        ? (selectedColor ?? AppTheme.primaryColor)
        : (unselectedColor ?? Theme.of(context).cardColor);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 20 : 16,
          vertical: isDesktop ? 10 : 8,
        ),
        decoration: BoxDecoration(
          color: effectiveColor,
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? null
              : Border.all(
                  color: Colors.grey.withOpacity(0.2),
                  width: 1,
                ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: (selectedColor ?? AppTheme.primaryColor)
                        .withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: Responsive.getFontSize(context, FontSizeType.small),
          ),
        ),
      ),
    );
  }
}

/// Premium Section Header
class PremiumSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final VoidCallback? onActionTap;
  final String? actionLabel;
  final IconData? actionIcon;

  const PremiumSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.onActionTap,
    this.actionLabel,
    this.actionIcon,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: isDesktop ? 20 : 16,
        top: isDesktop ? 12 : 8,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  padding: EdgeInsets.all(isDesktop ? 10 : 8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: AppTheme.primaryColor,
                    size: isDesktop ? 20 : 18,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: isDesktop
                          ? Responsive.getFontSize(context, FontSizeType.title)
                          : Responsive.getFontSize(context, FontSizeType.subtitle),
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: Responsive.getFontSize(context, FontSizeType.small),
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          if (onActionTap != null)
            GestureDetector(
              onTap: onActionTap,
              child: Row(
                children: [
                  if (actionIcon != null)
                    Icon(
                      actionIcon,
                      size: isDesktop ? 18 : 16,
                      color: AppTheme.primaryColor,
                    ),
                  if (actionLabel != null) ...[
                    const SizedBox(width: 4),
                    Text(
                      actionLabel!,
                      style: TextStyle(
                        fontSize: Responsive.getFontSize(context, FontSizeType.small),
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
