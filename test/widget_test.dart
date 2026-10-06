import 'package:place_memory_map/models/memory.dart';
import 'package:place_memory_map/services/database_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:place_memory_map/main.dart';

class EmptyDatabase extends DatabaseService {
  @override
  Future<List<Memory>> all() async => [];
}

void main() {
  testWidgets('welcome opens empty real map and explicit sample preview', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(PlaceMemoryMapApp(database: EmptyDatabase()));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('You stay in control.'), findsOneWidget);
    await tester.tap(find.text('Open map'));
    await tester.pumpAndSettle();
    expect(find.text('My memory map'), findsOneWidget);
    expect(find.text('Mapbox token needed'), findsOneWidget);
    expect(find.text('Garden Coffee Demo'), findsNothing);
    await tester.tap(find.text('Add photos'));
    await tester.pumpAndSettle();
    expect(find.text('Choose photo access'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Sample preview'));
    await tester.pumpAndSettle();
    expect(find.text('Demo memories'), findsOneWidget);
    await tester.ensureVisible(find.text('Garden Coffee Demo'));
    await tester.tap(find.text('Garden Coffee Demo'));
    await tester.pumpAndSettle();
    expect(find.text('1 demo memory at this place'), findsOneWidget);
  });
}
