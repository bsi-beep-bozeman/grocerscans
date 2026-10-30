/// Schema 1 has no predecessor. Unknown formats are retained, never reset.
/// Any future encrypted upgrade needs shadow generations and an approved migrator.
class DraftMigrations {
  static void requireCurrent(int version) {
    if (version != 1) {
      throw UnsupportedError('Draft schema requires a compatible application');
    }
  }
}
