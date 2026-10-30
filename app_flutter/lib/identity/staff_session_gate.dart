import 'dart:async';

import 'package:flutter/material.dart';

import '../sync/workspace_lifecycle.dart';
import 'staff_session_controller.dart';
import 'pin_screen.dart';

class StaffSessionGate extends StatefulWidget {
  const StaffSessionGate({
    super.key,
    required this.controller,
    required this.workspaceBuilder,
    this.signOut,
  });
  final StaffSessionController controller;
  final Widget Function() workspaceBuilder;
  final VoidCallback? signOut;
  @override
  State<StaffSessionGate> createState() => _StaffSessionGateState();
}

class _StaffSessionGateState extends State<StaffSessionGate>
    with WidgetsBindingObserver {
  late final WorkspaceLifecycle lifecycle;
  bool foreground = true, platformAvailable = false;
  bool wasLocked = true;
  void _sessionChanged() {
    if (widget.controller.locked && !wasLocked && mounted) {
      // Flutter dialogs default to the root navigator. Remove them immediately,
      // without a reverse animation that could expose a locked person's data.
      final root = Navigator.of(context, rootNavigator: true);
      while (true) {
        Route<dynamic>? top;
        root.popUntil((route) {
          top = route;
          return true;
        });
        if (top == null || top!.isFirst) break;
        root.removeRoute(top!);
      }
    }
    wasLocked = widget.controller.locked;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    foreground =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    widget.controller.setAvailable(false);
    widget.controller.addListener(_sessionChanged);
    lifecycle = WorkspaceLifecycle((value) {
      platformAvailable = value;
      widget.controller.setAvailable(value && foreground);
      if (mounted) setState(() {});
    }, widget.controller.lock);
    unawaited(lifecycle.start());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    foreground = state == AppLifecycleState.resumed;
    widget.controller.setAvailable(foreground && platformAvailable);
    if (!foreground) lifecycle.broadcastLock();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_sessionChanged);
    WidgetsBinding.instance.removeObserver(this);
    lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) {
      if (widget.controller.locked) {
        return PinScreen(
          controller: widget.controller,
          signOut: widget.signOut,
        );
      }
      return Listener(
        onPointerDown: (_) => widget.controller.touch(),
        onPointerSignal: (_) => widget.controller.touch(),
        child: Focus(
          onKeyEvent: (_, event) {
            widget.controller.touch();
            return KeyEventResult.ignored;
          },
          child: Navigator(
            key: ValueKey(widget.controller.generation),
            onGenerateRoute: (_) => MaterialPageRoute<void>(
              builder: (_) => widget.workspaceBuilder(),
            ),
          ),
        ),
      );
    },
  );
}
