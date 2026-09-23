import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.4';
import { SUPABASE_URL, SUPABASE_ANON_KEY } from './config.js';

export const supa = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
  auth: {
    persistSession: true,
    autoRefreshToken: true,
    // Kiosk devices stay signed in as their device account until an admin
    // rotates it. Regular users log out via UI.
    storageKey: 'shelflife.auth',
  },
});

export async function currentUser() {
  const { data } = await supa.auth.getUser();
  return data.user ?? null;
}

export async function currentProfile() {
  const user = await currentUser();
  if (!user) return null;

  // Check if this session is a kiosk device
  const { data: kiosk } = await supa
    .from('kiosk_devices')
    .select('id, branch_id, label, org_id, branches(name)')
    .eq('device_auth_user_id', user.id)
    .eq('active', true)
    .maybeSingle();
  if (kiosk) {
    return { kind: 'kiosk', user, kiosk };
  }

  const { data: profile } = await supa
    .from('staff_profiles')
    .select('id, org_id, branch_id, display_name, role, is_shift_lead, branches(name)')
    .eq('id', user.id)
    .maybeSingle();
  if (profile) {
    return { kind: 'user', user, profile };
  }

  return { kind: 'unknown', user };
}

export async function signOut() {
  await supa.auth.signOut();
}
