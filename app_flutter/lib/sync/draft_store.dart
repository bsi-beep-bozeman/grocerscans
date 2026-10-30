import '../identity/identity_models.dart';
import 'draft_crypto.dart';

const draftDatabaseName = 'shelflife_drafts_v1';
const draftStores = ['vault_meta', 'drafts', 'cache', 'migration_journal'];

abstract interface class DraftStore {
  Future<List<DraftEnvelope>> read(String vaultId);
  Future<void> write(DraftEnvelope envelope, {required int expectedRevision});
  Future<bool> requestPersistence();
  Future<void> close();
}

abstract interface class DraftCacheStore {
  Future<List<DraftEnvelope>> readCache(String vaultId);
  Future<void> writeCache(DraftEnvelope value);
}

void validateDraftWrite(
  List<DraftEnvelope> existing,
  DraftEnvelope value,
  int expectedRevision, {
  int maxDrafts = 1000,
  int maxBytes = 20 * 1024 * 1024,
}) {
  final matches = existing
      .where((e) => e.storageKey == value.storageKey)
      .toList();
  if (matches.length > 1 ||
      (matches.isEmpty ? 0 : matches.single.revision) != expectedRevision ||
      value.revision != expectedRevision + 1) {
    throw const ReceivingFailure('conflict');
  }
  final retained = existing.where((e) => e.storageKey != value.storageKey);
  if (retained.length + 1 > maxDrafts ||
      retained.fold<int>(value.byteSize, (n, e) => n + e.byteSize) > maxBytes) {
    throw const ReceivingFailure('storage_unavailable');
  }
}
