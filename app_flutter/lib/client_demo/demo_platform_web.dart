import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import '../sync/draft_store.dart';
import '../sync/draft_store_web.dart' as drafts;
import 'demo_state.dart';

const demoStorageKey = 'shelflife.client-dry-run.v1';
const demoDatabaseName = 'shelflife_client_dry_run_drafts_v1';

Future<bool> acquireDemoLease() async {
  final ready = Completer<bool>();
  final lifetime = Completer<JSAny?>();
  try {
    unawaited(
      web.window.navigator.locks
          .request(
            'shelflife-client-dry-run-v1',
            web.LockOptions(mode: 'exclusive', ifAvailable: true),
            ((web.Lock? lock) {
              ready.complete(lock != null);
              // Browser releases this isolated lease when the page closes/reloads.
              return lock == null
                  ? Future<JSAny?>.value(null).toJS
                  : lifetime.future.toJS;
            }).toJS,
          )
          .toDart
          .then<void>(
            (_) {},
            onError: (Object _) {
              if (!ready.isCompleted) ready.complete(false);
            },
          ),
    );
  } catch (_) {
    if (!ready.isCompleted) ready.complete(false);
  }
  return ready.future;
}

class BrowserDemoPersistence implements DemoPersistence {
  @override
  String? read() => web.window.localStorage.getItem(demoStorageKey);
  @override
  void write(String value) =>
      web.window.localStorage.setItem(demoStorageKey, value);
  @override
  void remove() => web.window.localStorage.removeItem(demoStorageKey);
}

DemoPersistence createDemoPersistence() => BrowserDemoPersistence();
Future<DraftStore> openDemoDraftStore() =>
    drafts.openDraftStore(databaseName: demoDatabaseName);
Future<void> resetDemoData() async {
  // Reset is offered only from the welcome page, after role widgets close.
  final store = await drafts.openDraftStore(
    databaseName: demoDatabaseName,
  ) as drafts.WebDraftStore;
  try {
    final tx = store.db.transactionList(draftStores, 'readwrite');
    for (final name in draftStores) {
      await tx.objectStore(name).clear();
    }
    await tx.completed;
  } finally {
    await store.close();
  }
  BrowserDemoPersistence().remove();
}
