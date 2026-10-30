import '../receiving/receiving_draft.dart';

/// A has no production stock transport. Local persistence cannot confirm stock.
class DraftQueue {
  bool get canUpload => false;
  Future<void> send(ReceivingDraft draft) async =>
      throw UnsupportedError('Stock confirmation is not available');
}
