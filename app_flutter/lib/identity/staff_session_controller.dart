import 'dart:async';

import 'package:flutter/foundation.dart';

import 'identity_models.dart';
import 'identity_repository.dart';

class StaffSessionController extends ChangeNotifier {
  StaffSessionController(this.repository, {Duration Function()? elapsed}) {
    _watch.start();
    _elapsed = elapsed ?? (() => _watch.elapsed);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => checkTime());
  }
  final IdentityRepository repository;
  final _watch = Stopwatch();
  late final Duration Function() _elapsed;
  Timer? _timer;
  StaffSession? session;
  bool busy = false, _disposed = false, available = true;
  String? error;
  int generation = 0;
  Duration _started = Duration.zero,
      _touched = Duration.zero,
      _last = Duration.zero;
  bool get locked => session == null;
  Duration get sessionElapsed => _elapsed() - _started;
  DateTime? get serverNow => session?.serverTime.add(sessionElapsed);
  Future<void> unlock(String pin) async {
    if (busy || _disposed || !available) return;
    lock();
    final ticket = generation;
    busy = true;
    error = null;
    notifyListeners();
    final requested = _elapsed();
    try {
      final result = await repository.begin(pin);
      if (_disposed || ticket != generation || !available) {
        result.clearKey();
        unawaited(_end(result));
        return;
      }
      // Charge the whole request duration against expiry; never extend on latency.
      session = result;
      _started = requested;
      _touched = _last = _elapsed();
      checkTime();
    } on ReceivingFailure catch (failure) {
      if (!_disposed && ticket == generation) {
        error = failure.code == 'cooldown'
            ? 'Try again in ${failure.retryAfterSeconds ?? 300} seconds.'
            : 'Unable to verify. Check your PIN and connection.';
      }
    } catch (_) {
      if (!_disposed && ticket == generation) {
        error = 'Unable to verify. Try again online.';
      }
    } finally {
      if (!_disposed && ticket == generation) {
        busy = false;
        notifyListeners();
      }
    }
  }

  Future<void> _end(StaffSession value) async {
    try {
      await repository.end(value);
    } catch (_) {
      /* Best effort; local lock already took effect. */
    }
  }

  void checkTime() {
    if (_disposed || session == null) return;
    final now = _elapsed();
    if (now < _last ||
        now - _touched >= const Duration(minutes: 5) ||
        now - _started >= session!.expiresAt.difference(session!.serverTime)) {
      lock();
      return;
    }
    _last = now;
  }

  void touch() {
    checkTime();
    if (!locked) _touched = _elapsed();
  }

  void setAvailable(bool value) {
    available = value;
    if (!value) lock();
  }

  void lock() {
    generation++;
    final old = session;
    session = null;
    busy = false;
    old?.clearKey();
    if (old != null) unawaited(_end(old));
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    lock();
    _timer?.cancel();
    _watch.stop();
    super.dispose();
  }
}
