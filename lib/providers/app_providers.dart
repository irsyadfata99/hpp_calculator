// lib/providers/app_providers.dart - VERIFY this file
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'hpp_provider.dart';
import 'operational_provider.dart';
import 'menu_provider.dart';

class AppProviders {
  static List<ChangeNotifierProvider> get providers => [
        ChangeNotifierProvider(create: (_) => HPPProvider()),
        ChangeNotifierProvider(create: (_) => OperationalProvider()),
        ChangeNotifierProvider(create: (_) => MenuProvider()),
      ];

  static Widget wrapApp(Widget child) {
    return MultiProvider(
      providers: providers,
      child: child,
    );
  }
}
