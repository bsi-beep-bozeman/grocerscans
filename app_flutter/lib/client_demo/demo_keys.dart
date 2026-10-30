/// Derives a per-actor vault key from the demo's single shared secret
/// (`demo_key`, see demo_state.dart). Index 0 (Alex, seeded) uses the key
/// unmodified; every other index XORs each byte with `0x55 * index`,
/// masked to a byte — index 1 (Sam, seeded) reproduces the original
/// hand-written `v ^ 0x55` exactly, so existing saved drafts stay
/// decryptable after this helper was introduced.
List<int> demoDerivedKey(List<int> base, int keyIndex) => keyIndex == 0
    ? base
    : base.map((v) => (v ^ (0x55 * keyIndex)) & 0xFF).toList();
