import 'package:flutter/material.dart';

import 'staff_session_controller.dart';

class PinScreen extends StatefulWidget {
  const PinScreen({super.key, required this.controller, this.signOut});
  final StaffSessionController controller;
  final VoidCallback? signOut;
  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  final pin = TextEditingController();
  @override
  void dispose() {
    pin.clear();
    pin.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    final value = pin.text;
    pin.clear();
    await widget.controller.unlock(value);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('ShelfLife · Receiving')),
    body: Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Enter your staff PIN',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                if (widget.signOut != null)
                  TextButton(
                    style: TextButton.styleFrom(minimumSize: const Size(0, 56)),
                    onPressed: widget.signOut,
                    child: const Text('Sign out of device'),
                  ),
                const SizedBox(height: 16),
                const Text(
                  'Verify online to open your drafts. Locking or restarting requires another online verification.',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: pin,
                  obscureText: true,
                  enableSuggestions: false,
                  autocorrect: false,
                  maxLength: 6,
                  keyboardType: TextInputType.number,
                  enabled:
                      widget.controller.available && !widget.controller.busy,
                  decoration: const InputDecoration(labelText: 'Staff PIN'),
                  onSubmitted: (_) => submit(),
                ),
                if (!widget.controller.available)
                  const Text(
                    'This workspace is unavailable. Return to the active tab, or close another ShelfLife tab and reopen this workspace.',
                  ),
                if (widget.controller.error != null)
                  Semantics(
                    liveRegion: true,
                    child: Text(widget.controller.error!),
                  ),
                const SizedBox(height: 16),
                FilledButton(
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 56)),
                  onPressed:
                      widget.controller.busy || !widget.controller.available
                      ? null
                      : submit,
                  child: Text(
                    widget.controller.busy ? 'Verifying…' : 'Verify and unlock',
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Drafts stay on this device. Site clearing, storage eviction or device loss can remove unsynced work.',
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
