import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

class WorkspaceLifecycle {
  WorkspaceLifecycle(this.onAvailable, this.onLock);
  final void Function(bool) onAvailable;
  final void Function() onLock;
  final _release = Completer<JSAny?>();
  web.BroadcastChannel? _channel;
  bool _held = false, _disposed = false;
  late final JSFunction _blur = ((web.Event _) {
    onAvailable(false);
    onLock();
    broadcastLock();
  }).toJS;
  late final JSFunction _focus = ((web.Event _) {
    if (!_disposed) {
      onAvailable(_held && web.document.visibilityState == 'visible');
    }
  }).toJS;
  late final JSFunction _visibility = ((web.Event _) {
    if (web.document.visibilityState != 'visible') {
      onAvailable(false);
      onLock();
      broadcastLock();
    } else if (!_disposed) {
      onAvailable(_held && web.document.hasFocus());
    }
  }).toJS;
  Future<void> start() async {
    try {
      _channel = web.BroadcastChannel('shelflife-workspace-lock-v1');
      _channel!.onmessage = ((web.MessageEvent _) {
        if (!_disposed) onLock();
      }).toJS;
      web.window.addEventListener('blur', _blur);
      web.window.addEventListener('pagehide', _blur);
      web.window.addEventListener('focus', _focus);
      web.document.addEventListener('visibilitychange', _visibility);
      final ready = Completer<void>();
      unawaited(
        web.window.navigator.locks
            .request(
              'shelflife-drafts-v1',
              web.LockOptions(mode: 'exclusive', ifAvailable: true),
              ((web.Lock? lock) {
                if (!_disposed) {
                  _held = lock != null;
                  onAvailable(
                    _held &&
                        web.document.visibilityState == 'visible' &&
                        web.document.hasFocus(),
                  );
                }
                if (!ready.isCompleted) ready.complete();
                return lock == null
                    ? Future<JSAny?>.value(null).toJS
                    : _release.future.toJS;
              }).toJS,
            )
            .toDart
            .then<void>(
              (_) {},
              onError: (Object _) {
                if (!_disposed) onAvailable(false);
                if (!ready.isCompleted) ready.complete();
              },
            ),
      );
      await ready.future;
    } catch (_) {
      if (!_disposed) onAvailable(false);
    }
  }

  void broadcastLock() {
    try {
      _channel?.postMessage('lock'.toJS);
    } catch (_) {}
  }

  void dispose() {
    _disposed = true;
    _held = false;
    web.window.removeEventListener('blur', _blur);
    web.window.removeEventListener('pagehide', _blur);
    web.window.removeEventListener('focus', _focus);
    web.document.removeEventListener('visibilitychange', _visibility);
    _channel?.close();
    if (!_release.isCompleted) _release.complete(null);
  }
}
