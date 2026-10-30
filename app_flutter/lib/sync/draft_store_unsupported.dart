import 'draft_store.dart';

Future<DraftStore> openDraftStore({
  String databaseName = draftDatabaseName,
}) async => throw UnsupportedError(
  'Durable drafts require Android or a supported browser',
);
