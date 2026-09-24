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

const supabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue: '__replace_after_supabase_start__',
);
