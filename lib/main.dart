import 'services/database_service.dart';

import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import 'config/mapbox_config.dart';
import 'screens/onboarding/welcome_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (MapboxConfig.isConfigured) {
    MapboxOptions.setAccessToken(MapboxConfig.accessToken);
  }
  runApp(const PlaceMemoryMapApp());
}

class PlaceMemoryMapApp extends StatelessWidget {
  const PlaceMemoryMapApp({super.key, this.database});

  final DatabaseService? database;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Place Memory Map',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: WelcomeScreen(database: database),
    );
  }
}
