/// Supabase connection config.
///
/// For local dev, values come from `npx supabase status` after
/// `npx supabase start`. For hosted, values come from Project Settings → API.
///
/// Override at build time with:
///   flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
library;

const supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'http://127.0.0.1:54321',
);

/// Local Supabase anon key. This is the deterministic key the Supabase CLI
/// generates for every local dev install — safe to commit. Rotate for hosted
/// via `--dart-define=SUPABASE_ANON_KEY=...` (never bake a prod key here).
const supabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue:
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
      'eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.'
      'CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0',
);
