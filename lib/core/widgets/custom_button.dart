import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

enum ButtonVariant { primary, secondary, outline, text, danger }

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final ButtonVariant variant;
  final IconData? icon;
  final double? width;
  final double height;
  final double borderRadius;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.variant = ButtonVariant.primary,
    this.icon,
    this.width,
    this.height = 52.0,
    this.borderRadius = 14.0,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null && !isLoading;

    Widget childWidget = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(
                variant == ButtonVariant.outline || variant == ButtonVariant.text
                    ? AppColors.primary
                    : Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Memproses...',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: variant == ButtonVariant.outline || variant == ButtonVariant.text
                  ? AppColors.primary
                  : Colors.white,
            ),
          ),
        ] else ...[
          if (icon != null) ...[
            Icon(
              icon,
              size: 20,
              color: _getTextColor(),
            ),
            const SizedBox(width: 8),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _getTextColor(),
              letterSpacing: 0.2,
            ),
          ),
        ],
      ],
    );

    if (variant == ButtonVariant.primary) {
      return Container(
        width: width ?? double.infinity,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          gradient: isEnabled ? AppColors.primaryGradient : null,
          color: !isEnabled ? Colors.grey.shade300 : null,
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.28),
                    offset: const Offset(0, 4),
                    blurRadius: 12,
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(borderRadius),
            onTap: isEnabled ? onPressed : null,
            child: Center(child: childWidget),
          ),
        ),
      );
    }

    if (variant == ButtonVariant.danger) {
      return Container(
        width: width ?? double.infinity,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          color: isEnabled ? AppColors.error : Colors.grey.shade300,
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: AppColors.error.withValues(alpha: 0.25),
                    offset: const Offset(0, 4),
                    blurRadius: 12,
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(borderRadius),
            onTap: isEnabled ? onPressed : null,
            child: Center(child: childWidget),
          ),
        ),
      );
    }

    if (variant == ButtonVariant.outline) {
      return SizedBox(
        width: width ?? double.infinity,
        height: height,
        child: OutlinedButton(
          onPressed: isEnabled ? onPressed : null,
          style: OutlinedButton.styleFrom(
            side: BorderSide(
              color: isEnabled ? AppColors.primary : Colors.grey.shade300,
              width: 1.6,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
          ),
          child: childWidget,
        ),
      );
    }

    if (variant == ButtonVariant.secondary) {
      return SizedBox(
        width: width ?? double.infinity,
        height: height,
        child: ElevatedButton(
          onPressed: isEnabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryContainer,
            foregroundColor: AppColors.primaryDark,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
          ),
          child: childWidget,
        ),
      );
    }

    // Text variant
    return TextButton(
      onPressed: isEnabled ? onPressed : null,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
      child: childWidget,
    );
  }

  Color _getTextColor() {
    switch (variant) {
      case ButtonVariant.primary:
      case ButtonVariant.danger:
        return Colors.white;
      case ButtonVariant.secondary:
        return AppColors.primaryDark;
      case ButtonVariant.outline:
      case ButtonVariant.text:
        return AppColors.primary;
    }
  }
}
