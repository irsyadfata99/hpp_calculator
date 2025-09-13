// lib/widgets/common/loading_widget.dart
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class LoadingWidget extends StatelessWidget {
  final String? message;
  final bool showMessage;

  const LoadingWidget({
    super.key,
    this.message,
    this.showMessage = true,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          if (showMessage) ...[
            const SizedBox(height: 16),
            Text(
              message ?? 'Loading...',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
