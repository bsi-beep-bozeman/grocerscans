import '../sync/draft_store.dart';
import 'demo_state.dart';

DemoPersistence createDemoPersistence() =>
    throw UnsupportedError('Open the client preview in a web browser.');
Future<bool> acquireDemoLease() async => true;
Future<DraftStore> openDemoDraftStore() async =>
    throw UnsupportedError('Web preview only');
Future<void> resetDemoData() async =>
    throw UnsupportedError('Web preview only');
