import 'dart:async';
import 'dart:js_interop';

import 'package:idb_shim/idb_client_native.dart';
import 'package:web/web.dart' as web;

import '../identity/identity_models.dart';
import 'draft_crypto.dart';
import 'draft_store.dart';
import 'draft_migrations.dart';

Future<DraftStore> openDraftStore({
  String databaseName = draftDatabaseName,
}) async {
  if (!RegExp(r'^shelflife_[a-z0-9_]+$').hasMatch(databaseName)) invalidWire();
  // Never use idbFactoryBrowser: that convenience getter can fall back to memory.
  final ready = Completer<DraftStore>();
  var abandoned = false;
  unawaited(
    idbFactoryNative
        .open(
          databaseName,
          version: 1,
          onUpgradeNeeded: (event) {
            if (event.oldVersion != 0) {
              throw UnsupportedError('Draft migration unavailable');
            }
            for (final name in draftStores) {
              event.database.createObjectStore(name);
            }
          },
          onBlocked: (_) {
            abandoned = true;
            if (!ready.isCompleted) {
              ready.completeError(
                const ReceivingFailure('storage_unavailable'),
              );
            }
          },
        )
        .then<void>(
          (db) {
            if (abandoned) {
              db.close();
              return;
            }
            try {
              DraftMigrations.requireCurrent(db.version);
              db.onVersionChange.listen((_) => db.close());
              ready.complete(WebDraftStore(db));
            } catch (_) {
              db.close();
              if (!ready.isCompleted) {
                ready.completeError(
                  const ReceivingFailure('storage_unavailable'),
                );
              }
            }
          },
          onError: (Object _) {
            if (!ready.isCompleted) {
              ready.completeError(
                const ReceivingFailure('storage_unavailable'),
              );
            }
          },
        ),
  );
  return ready.future.timeout(
    const Duration(seconds: 10),
    onTimeout: () {
      abandoned = true;
      throw const ReceivingFailure('storage_unavailable');
    },
  );
}

class WebDraftStore implements DraftStore, DraftCacheStore {
  WebDraftStore(this.db);
  final Database db;
  @override
  Future<List<DraftEnvelope>> read(String vaultId) async {
    wireId(vaultId);
    final tx = db.transaction('drafts', idbModeReadOnly);
    unawaited(tx.completed.then<void>((_) {}, onError: (Object _) {}));
    final rows = await tx.objectStore('drafts').getAll();
    await tx.completed;
    return rows
        .map(DraftEnvelope.fromJson)
        .where((e) => e.vaultId == vaultId)
        .toList();
  }

  @override
  Future<void> write(
    DraftEnvelope value, {
    required int expectedRevision,
  }) async {
    final tx = db.transactionList(['drafts', 'cache'], idbModeReadWrite);
    // Attach a handler immediately; abort must never produce an unhandled error.
    final completion = tx.completed.then<void>((_) {}, onError: (Object _) {});
    try {
      final store = tx.objectStore('drafts');
      final all = (await store.getAll()).map(DraftEnvelope.fromJson).toList();
      validateDraftWrite(all, value, expectedRevision);
      final caches = (await tx.objectStore('cache').getAll())
          .map(DraftEnvelope.fromJson)
          .toList();
      final bytes =
          all
              .where((e) => e.storageKey != value.storageKey)
              .fold<int>(value.byteSize, (n, e) => n + e.byteSize) +
          caches.fold<int>(0, (n, e) => n + e.byteSize);
      if (bytes > 20 * 1024 * 1024) await tx.objectStore('cache').clear();
      await store.put(value.toJson(), value.storageKey);
      await tx.completed;
    } catch (_) {
      try {
        tx.abort();
      } catch (_) {
        /* May already be aborted by the platform. */
      }
      await completion;
      rethrow;
    }
  }

  @override
  Future<bool> requestPersistence() async {
    try {
      return (await web.window.navigator.storage.persist().toDart).toDart;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<List<DraftEnvelope>> readCache(String vaultId) async {
    wireId(vaultId);
    final tx = db.transaction('cache', idbModeReadOnly);
    unawaited(tx.completed.then<void>((_) {}, onError: (Object _) {}));
    final values = await tx.objectStore('cache').getAll();
    await tx.completed;
    return values
        .map(DraftEnvelope.fromJson)
        .where((e) => e.vaultId == vaultId)
        .toList();
  }

  @override
  Future<void> writeCache(DraftEnvelope value) async {
    final tx = db.transactionList(['drafts', 'cache'], idbModeReadWrite);
    final completion = tx.completed.then<void>((_) {}, onError: (Object _) {});
    try {
      final drafts = (await tx.objectStore('drafts').getAll())
          .map(DraftEnvelope.fromJson)
          .toList();
      final caches = (await tx.objectStore('cache').getAll())
          .map(DraftEnvelope.fromJson)
          .toList();
      final draftBytes = drafts.fold<int>(0, (n, e) => n + e.byteSize),
          cacheBytes = caches.fold<int>(0, (n, e) => n + e.byteSize);
      if (draftBytes + value.byteSize > 20 * 1024 * 1024) {
        throw const ReceivingFailure('storage_unavailable');
      }
      if (caches.length >= 100 ||
          draftBytes + cacheBytes + value.byteSize > 20 * 1024 * 1024) {
        await tx.objectStore('cache').clear();
      }
      await tx.objectStore('cache').add(value.toJson(), value.storageKey);
      await tx.completed;
    } catch (_) {
      try {
        tx.abort();
      } catch (_) {}
      await completion;
      rethrow;
    }
  }

  @override
  Future<void> close() async => db.close();
}
