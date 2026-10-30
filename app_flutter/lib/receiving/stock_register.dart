/// A read-only, denormalized view over every captured receiving entry —
/// title, identifiers, batch, expiration and quantity in one place, for
/// admin/staff/vendor visibility (see lib/receiving/stock_register_screen.dart).
class StockRegisterEntry {
  const StockRegisterEntry({
    required this.title,
    required this.description,
    required this.upc,
    required this.sku,
    required this.batchLabel,
    required this.expiryDate,
    required this.quantity,
    required this.unitCode,
    required this.capturedBy,
  });
  final String title, description, upc, sku, batchLabel, quantity, unitCode;
  final String capturedBy;
  final DateTime? expiryDate;

  int? get daysRemaining => expiryDate?.difference(DateTime.now()).inDays;
}

abstract interface class StockRegisterRepository {
  Future<List<StockRegisterEntry>> list();
}
