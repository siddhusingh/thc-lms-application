import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

import '../theme/app_theme.dart';

void showSuccessToast(BuildContext context, {required String message}) {
  _showCompactToast(
    context,
    message: message,
    icon: Icons.check_circle_rounded,
    color: Colors.green,
  );
}

void showErrorToast(BuildContext context, {required String message}) {
  _showCompactToast(
    context,
    message: message,
    icon: Icons.error_rounded,
    color: Colors.red,
  );
}

void showInfoToast(BuildContext context, {required String message}) {
  _showCompactToast(
    context,
    message: message,
    icon: Icons.info_rounded,
    color: AppTheme.primary,
  );
}

void _showCompactToast(
  BuildContext context, {
  required String message,
  required IconData icon,
  required Color color,
}) {
  toastification.showCustom(
    context: context,
    alignment: Alignment.center,
    autoCloseDuration: const Duration(seconds: 3),
    builder: (context, _) =>
        _CompactToast(message: message, icon: icon, color: color),
  );
}

class _CompactToast extends StatelessWidget {
  const _CompactToast({
    required this.message,
    required this.icon,
    required this.color,
  });

  final String message;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width - 32,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withValues(alpha: 0.45)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 18, color: color),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        message,
                        style: const TextStyle(
                          color: AppTheme.accent,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
