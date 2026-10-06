import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:place_memory_map/models/memory.dart';
import 'package:place_memory_map/models/place.dart';
import 'package:place_memory_map/services/database_service.dart';
import 'package:place_memory_map/services/place_matcher.dart';
import 'package:place_memory_map/screens/map/memory_map_screen.dart';

const place = Place(
  id: 'a',
  name: 'A',
  category: 'Cafe',
  latitude: 11.56,
  longitude: 104.92,
);
Memory memory(
  String id,
  DateTime date, {
  bool verified = true,
  String placeId = 'a',
}) => Memory(
  id: id,
  placeId: placeId,
  photoAssetId: id,
  photoDate: date,
  photoLatitude: 11.56,
  photoLongitude: 104.92,
  verified: verified,
  createdAt: date,
);
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('matching sorts nearby venues and excludes distant and invalid GPS', () {
    const near = Place(
      id: 'b',
      name: 'B',
      category: 'Cafe',
      latitude: 11.561,
      longitude: 104.92,
    );
    const far = Place(
      id: 'c',
      name: 'C',
      category: 'Cafe',
      latitude: 12,
      longitude: 105,
    );
    final matches = PlaceMatcher().match(11.56, 104.92, [far, near, place]);
    expect(matches.map((m) => m.place.id), ['a', 'b']);
    expect(matches.last.distanceMeters, closeTo(111.2, 1));
    expect(PlaceMatcher().match(0, 0, [place]), isEmpty);
    expect(PlaceMatcher().match(double.nan, 104.92, [place]), isEmpty);
  });
  test('grouping counts dates, sorts recent photos, excludes unverified and unknown places', () {
    final groups = PlaceMemories.group(
      [
        memory('old', DateTime(2026, 1, 1)),
        memory('new', DateTime(2026, 1, 2, 12)),
        memory('same-day', DateTime(2026, 1, 2, 13)),
        memory('unverified', DateTime(2026), verified: false),
        memory('unknown', DateTime(2026), placeId: 'unknown'),
      ],
      [place],
    );
    expect(groups.length, 1);
    expect(groups.single.visitCount, 2);
    expect(groups.single.memories.map((m) => m.id), ['same-day', 'new', 'old']);
  });
  test('SQLite saves only confirmation, replaces duplicate photos, can be read by a new repository and removes locally', () async {
    sqfliteFfiInit();
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await db.execute(
      'CREATE TABLE memories (id TEXT PRIMARY KEY, placeId TEXT NOT NULL, photoAssetId TEXT NOT NULL UNIQUE, photoDate TEXT NOT NULL, photoLatitude REAL NOT NULL, photoLongitude REAL NOT NULL, verified INTEGER NOT NULL CHECK(verified = 1), createdAt TEXT NOT NULL)',
    );
    final service = DatabaseService(database: db);
    addTearDown(db.close);
    final row = memory('photo-1', DateTime(2026, 1, 1));
    await expectLater(
      service.confirm(memory('bad', DateTime(2026), verified: false)),
      throwsArgumentError,
    );
    expect(await service.all(), isEmpty);
    await service.confirm(row);
    await service.confirm(
      Memory.fromMap({...row.toMap(), 'id': 'replacement', 'placeId': 'b'}),
    );
    expect((await service.all()).length, 1);
    expect((await service.all()).single.placeId, 'b');
    final reopenedRepository = DatabaseService(database: db);
    expect((await reopenedRepository.all()).single.photoAssetId, 'photo-1');
    await service.remove('replacement');
    expect(await service.all(), isEmpty);
  });
}
