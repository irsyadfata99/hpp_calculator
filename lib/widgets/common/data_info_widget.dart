// File: lib/widgets/common/data_info_widget.dart - NEW FILE

import 'package:flutter/material.dart';
import '../../services/storage_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/constants.dart';

class DataInfoWidget extends StatelessWidget {
  const DataInfoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: StorageService.getDataInfo(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final info = snapshot.data!;
        return Container(
          margin: const EdgeInsets.all(AppConstants.smallPadding),
          padding: const EdgeInsets.all(AppConstants.smallPadding),
          decoration: BoxDecoration(
            color: AppColors.info.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.storage, color: AppColors.info, size: 16),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Data: ${info['sharedDataItems']} items',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.info,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Size: ${(info['totalSize'] / 1024).toStringAsFixed(1)}KB',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
