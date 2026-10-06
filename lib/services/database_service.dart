import 'package:sqflite/sqflite.dart';

import '../models/memory.dart';

class DatabaseService {
  DatabaseService({Database? database})
    : _database = database; // ignore: prefer_initializing_formals
  Database? _database;
  Future<Database>? _opening;
  Future<Database> get database async {
    if (_database != null) return _database!;
    try {
      return _database = await (_opening ??= _open());
    } catch (_) {
      _opening = null;
      rethrow;
    }
  }

  Future<Database> _open() async => openDatabase(
    '${await getDatabasesPath()}/place_memories.db',
    version: 1,
    onCreate: (db, _) async {
      await db.execute(
        'CREATE TABLE memories (id TEXT PRIMARY KEY, placeId TEXT NOT NULL, photoAssetId TEXT NOT NULL UNIQUE, photoDate TEXT NOT NULL, photoLatitude REAL NOT NULL, photoLongitude REAL NOT NULL, verified INTEGER NOT NULL CHECK(verified = 1), createdAt TEXT NOT NULL)',
      );
    },
  );
  Future<List<Memory>> all() async => (await (await database).query(
    'memories',
    orderBy: 'photoDate DESC',
  )).map(Memory.fromMap).toList();
  Future<void> confirm(Memory memory) async {
    if (!memory.verified) {
      throw ArgumentError('Only confirmed memories can be saved');
    }
    await (await database).insert(
      'memories',
      memory.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> remove(String id) async =>
      (await database).delete('memories', where: 'id = ?', whereArgs: [id]);
}
