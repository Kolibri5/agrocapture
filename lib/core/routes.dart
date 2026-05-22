import 'package:flutter/material.dart';

/// Centralised named-route table.
///
/// Add feature routes here as screens are implemented.
class AppRoutes {
  AppRoutes._();

  static const String map = '/map';
  static const String directory = '/directory';
  static const String farmDetail = '/directory/detail';
  static const String scanner = '/scanner';
  static const String scanResult = '/scanner/result';

  /// Returns the route map to feed into [MaterialApp.routes].
  static Map<String, WidgetBuilder> get routes {
    return {
      // TODO: wire up screens as they are built
      // map:        (_) => const MapScreen(),
      // directory:  (_) => const DirectoryScreen(),
      // scanner:    (_) => const ScannerScreen(),
    };
  }
}
