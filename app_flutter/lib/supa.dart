import 'package:supabase_flutter/supabase_flutter.dart';

SupabaseClient get supa => Supabase.instance.client;

sealed class SessionProfile {
  const SessionProfile(this.user);
  final User user;
}

final class KioskSession extends SessionProfile {
  const KioskSession(super.user, this.kiosk);
  final Map<String, dynamic> kiosk;
}

final class UserSession extends SessionProfile {
  const UserSession(super.user, this.profile);
  final Map<String, dynamic> profile;
}

final class UnknownSession extends SessionProfile {
  const UnknownSession(super.user);
}

Future<SessionProfile?> currentProfile() async {
  final user = supa.auth.currentUser;
  if (user == null) return null;

  final kiosk = await supa
      .from('kiosk_devices')
      .select('id, branch_id, label, org_id, branches(name)')
      .eq('device_auth_user_id', user.id)
      .eq('active', true)
      .maybeSingle();
  if (kiosk != null) return KioskSession(user, kiosk);

  final profile = await supa
      .from('staff_profiles')
      .select(
        'id, org_id, branch_id, display_name, role, '
        'is_shift_lead, branches(name)',
      )
      .eq('id', user.id)
      .maybeSingle();
  if (profile != null) return UserSession(user, profile);

  return UnknownSession(user);
}

Future<void> signOut() => supa.auth.signOut();
