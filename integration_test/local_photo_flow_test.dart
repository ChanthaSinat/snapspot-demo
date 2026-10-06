import 'package:photo_manager/photo_manager.dart';

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:place_memory_map/models/place.dart';
import 'package:place_memory_map/services/photo_service.dart';
import 'package:place_memory_map/services/database_service.dart';
import 'package:place_memory_map/screens/verification/verification_screen.dart';
import 'package:place_memory_map/screens/map/memory_map_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'native photo GPS, explicit confirmation, SQLite and grouped home',
    (tester) async {
      final service = PhotoService();
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Text('Checking native photo fixture')),
        ),
      );
      await tester.pumpAndSettle();
      final state = await tester.runAsync(service.requestAccess);
      debugPrint('Fixture Photos permission: $state');
      expect(
        state!.hasAccess,
        isTrue,
        reason: 'Run on a simulator with Photos access and the synthetic fixture from README.',
      );
      final photos = await service.page(0);
      final fixture = photos.firstWhere(
        (p) =>
            p.hasLocation &&
            (p.latitude! - 11.5523).abs() < 0.00001 &&
            (p.longitude! - 104.9227).abs() < 0.00001,
      );
      expect(await PhotoService.thumbnail(fixture.asset.id), isNotNull);
      final rows = jsonDecode(
        await rootBundle.loadString('lib/data/demo_places.json'),
      ) as List;
      final places = rows
          .map((r) => Place.fromJson(Map<String, dynamic>.from(r as Map)))
          .toList();
      var db = DatabaseService();
      await db.remove(fixture.asset.id);
      try {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VerificationScreen(
                        photo: fixture,
                        places: places,
                        database: db,
                      ),
                    ),
                  ),
                  child: const Text('Review fixture'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Review fixture'));
        await tester.pumpAndSettle();
        expect(find.text('Selected: Garden Coffee Demo'), findsOneWidget);
        await tester.ensureVisible(find.text('Confirm place'));
        await tester.tap(find.text('Confirm place'));
        await tester.pumpAndSettle();
        await (await db.database).close();
        db = DatabaseService();
        final stored = await db.all();
        expect(
          stored.where((m) => m.photoAssetId == fixture.asset.id).length,
          1,
        );
        expect(
          stored.firstWhere((m) => m.photoAssetId == fixture.asset.id).verified,
          isTrue,
        );
        await tester.pumpWidget(
          MaterialApp(home: MemoryMapScreen(database: db)),
        );
        await tester.pumpAndSettle();
        expect(find.text('Garden Coffee Demo'), findsOneWidget);
        await tester.tap(find.text('Garden Coffee Demo'));
        await tester.pumpAndSettle();
        expect(find.text('Confirmed by you'), findsWidgets);
        await tester.tap(find.byTooltip('Remove memory').first);
        await tester.pumpAndSettle();
        expect(
          (await db.all()).where((m) => m.photoAssetId == fixture.asset.id),
          isEmpty,
        );
      } finally {
        await db.remove(fixture.asset.id);
      }
    },
    skip: !const bool.fromEnvironment('NATIVE_PHOTO_TEST'),
  );
}
