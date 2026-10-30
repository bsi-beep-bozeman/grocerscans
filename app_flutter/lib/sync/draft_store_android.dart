import 'dart:convert';
import 'dart:io';

import 'package:sqflite/sqflite.dart';

import '../identity/identity_models.dart';
import 'draft_crypto.dart';
import 'draft_store.dart';
import 'draft_migrations.dart';

Future<DraftStore> openDraftStore({
  String databaseName = draftDatabaseName,
}) async {
  if (!RegExp(r'^shelflife_[a-z0-9_]+$').hasMatch(databaseName)) invalidWire();
  if (!Platform.isAndroid) {
    throw UnsupportedError(
      'Durable drafts are available on Android and supported browsers',
    );
  }
  final db = await openDatabase(
    '$databaseName.db',
    version: 1,
    onConfigure: (db) async {
      final journal = await db.rawQuery('PRAGMA journal_mode=DELETE');
      if (journal.single.values.single != 'delete') {
        throw const ReceivingFailure('storage_unavailable');
      }
      await db.execute('PRAGMA synchronous=FULL');
      final sync = Sqflite.firstIntValue(
        await db.rawQuery('PRAGMA synchronous'),
      );
      if (sync != 2) throw const ReceivingFailure('storage_unavailable');
    },
    onCreate: (db, version) async {
      for (final table in draftStores) {
        await db.execute(
          'CREATE TABLE $table (record_key TEXT PRIMARY KEY NOT NULL, envelope TEXT NOT NULL)',
        );
      }
    },
    onUpgrade: (_, oldVersion, newVersion) async =>
        throw UnsupportedError('Draft migration unavailable'),
    onDowngrade: (_, oldVersion, newVersion) async =>
        throw UnsupportedError('Newer draft schema retained'),
  );
  DraftMigrations.requireCurrent(await db.getVersion());
  return AndroidDraftStore(db);
}

class AndroidDraftStore implements DraftStore, DraftCacheStore {
  AndroidDraftStore(this.db);
  final Database db;
  @override
  Future<List<DraftEnvelope>> read(String vaultId) async {
    wireId(vaultId);
    final rows = await db.query(
      'drafts',
      where: 'record_key LIKE ?',
      whereArgs: ['$vaultId:%'],
    );
    return rows
        .map((r) => DraftEnvelope.fromJson(jsonDecode(r['envelope'] as String)))
        .toList();
  }

  @override
  Future<void> write(
    DraftEnvelope value, {
    required int expectedRevision,
  }) async {
    await db.transaction((tx) async {
      final rows = await tx.query('drafts');
      final all = rows
          .map(
            (r) => DraftEnvelope.fromJson(jsonDecode(r['envelope'] as String)),
          )
          .toList();
      validateDraftWrite(all, value, expectedRevision);
      final caches = await tx.query('cache');
      final bytes =
          all
              .where((e) => e.storageKey != value.storageKey)
              .fold<int>(value.byteSize, (n, e) => n + e.byteSize) +
          caches.fold<int>(
            0,
            (n, r) =>
                n +
                DraftEnvelope.fromJson(jsonDecode(r['envelope'] as String))
                    .byteSize,
          );
      if (bytes > 20 * 1024 * 1024) await tx.delete('cache');
      await tx.insert('drafts', {
        'record_key': value.storageKey,
        'envelope': jsonEncode(value.toJson()),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }, exclusive: true);
  }

  @override
  Future<bool> requestPersistence() async => true;
  @override
  Future<List<DraftEnvelope>> readCache(String vaultId) async {
    wireId(vaultId);
    return (await db.query(
          'cache',
          where: 'record_key LIKE ?',
          whereArgs: ['$vaultId:%'],
        ))
        .map((r) => DraftEnvelope.fromJson(jsonDecode(r['envelope'] as String)))
        .toList();
  }

  @override
  Future<void> writeCache(DraftEnvelope value) async {
    await db.transaction((tx) async {
      final drafts = await tx.query('drafts');
      final caches = await tx.query('cache');
      final draftBytes = drafts.fold<int>(
        0,
        (n, r) =>
            n +
            DraftEnvelope.fromJson(jsonDecode(r['envelope'] as String))
                .byteSize,
      );
      final cacheBytes = caches.fold<int>(
        0,
        (n, r) =>
            n +
            DraftEnvelope.fromJson(jsonDecode(r['envelope'] as String))
                .byteSize,
      );
      if (draftBytes + value.byteSize > 20 * 1024 * 1024) {
        throw const ReceivingFailure('storage_unavailable');
      }
      if (caches.length >= 100 ||
          draftBytes + cacheBytes + value.byteSize > 20 * 1024 * 1024) {
        await tx.delete('cache');
      }
      await tx.insert('cache', {
        'record_key': value.storageKey,
        'envelope': jsonEncode(value.toJson()),
      }, conflictAlgorithm: ConflictAlgorithm.abort);
    }, exclusive: true);
  }

  @override
  Future<void> close() => db.close();
}
