// lib/widgets/common/quick_mode_toggle.dart - FIXED VERSION
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_settings_provider.dart';

class QuickModeToggle extends StatelessWidget {
  const QuickModeToggle({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppSettingsProvider>(
      builder: (context, settings, child) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: IconButton(
            // FIXED: Use consistent naming
            key: ValueKey(settings.isQuickMode),
            onPressed: settings.toggleQuickMode,
            icon: Icon(
              settings.isQuickMode ? Icons.flash_on : Icons.flash_off,
              color:
                  settings.isQuickMode ? Colors.amber[400] : Colors.grey[600],
            ),
            tooltip: settings.isQuickMode
                ? 'Disable Quick Mode'
                : 'Enable Quick Mode',
            style: IconButton.styleFrom(
              backgroundColor:
                  settings.isQuickMode ? Colors.amber[50] : Colors.transparent,
            ),
          ),
        );
      },
    );
  }
}
