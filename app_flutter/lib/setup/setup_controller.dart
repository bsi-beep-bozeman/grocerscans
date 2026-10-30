import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'setup_models.dart';
import 'setup_repository.dart';
import 'setup_validation.dart';

/// In-memory editing only. A server response is the only saved-state authority.
class SetupController extends ChangeNotifier {
  SetupController({required this.repository, required this.verifyIdentity});
  final SetupRepository repository;
  final Future<String?> Function() verifyIdentity;
  SetupContext? _context;
  BranchSetupState? _state;
  SetupConfiguration? _configuration;
  ReferenceCatalog? _catalog;
  SetupWireModel? _pending;
  Timer? _idleTimer;
  Timer? _expiryTimer;
  int _epoch = 0;
  bool _disposed = false;
  bool locked = true;
  bool busy = false;
  bool dirty = false;
  bool conflict = false;
  int formVersion = 0;

  /// Every concealment invalidates protected routes, even within one UI frame.
  int sessionViewVersion = 0;
  String? error;
  SetupContext? get context => locked ? null : _context;
  BranchSetupState? get state => locked ? null : _state;
  SetupConfiguration? get configuration => locked ? null : _configuration;
  ReferenceCatalog? get catalog => locked ? null : _catalog;
  bool get hasPendingOperation => !locked && _pending != null;
  bool get canEdit => !locked && !busy && !conflict && _pending == null;
  SetupValidation? get guidance =>
      configuration == null || state == null || catalog == null
      ? null
      : validateSetup(configuration!, catalog!, branchId: state!.branchId);
  bool get canActivate =>
      canEdit &&
      !dirty &&
      _state?.draft != null &&
      (_state?.readiness?.canActivate ?? false);

  String newOperationId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 15) | 64;
    bytes[8] = (bytes[8] & 63) | 128;
    final s = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${s.substring(0, 8)}-${s.substring(8, 12)}-${s.substring(12, 16)}-${s.substring(16, 20)}-${s.substring(20)}';
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  bool _owns(int epoch) => !_disposed && epoch == _epoch && !locked;
  void touch() {
    if (locked || _disposed) return;
    _idleTimer?.cancel();
    _idleTimer = Timer(const Duration(minutes: 5), lock);
  }

  void lock() {
    if (_disposed) return;
    sessionViewVersion++;
    _epoch++;
    locked = true;
    busy = false;
    _idleTimer?.cancel();
    _expiryTimer?.cancel();
    error = null;
    _notify();
  }

  void _clear() {
    _context = null;
    _state = null;
    _catalog = null;
    _configuration = null;
    _pending = null;
    dirty = false;
    conflict = false;
  }

  void clearSession() {
    lock();
    _clear();
    _notify();
  }

  Future<void> unlock() async {
    if (busy || _disposed) return;
    final epoch = ++_epoch;
    locked = true;
    busy = true;
    error = null;
    _notify();
    try {
      final userId = await verifyIdentity();
      if (_disposed || epoch != _epoch) return;
      if (userId == null) {
        throw SetupRepositoryException(
          SetupErrorKind.expired,
          'Sign in again.',
        );
      }
      final value = await repository.context();
      if (_disposed || epoch != _epoch) return;
      if (value.adminId != userId ||
          !value.sessionExpiresAt.isAfter(DateTime.now())) {
        throw SetupRepositoryException(
          SetupErrorKind.denied,
          'Admin access could not be verified.',
        );
      }
      if (_context?.adminId != value.adminId ||
          _context?.orgId != value.orgId) {
        _clear();
      }
      _context = value;
      _catalog = value.catalog;
      // Current availability may have changed while locked. Require a fresh
      // saved-state response before activation; in-session edits remain intact.
      if (_state != null) _state = _withCatalog(_state!, value.catalog);
      locked = false;
      touch();
      _expiryTimer = Timer(
        value.sessionExpiresAt.difference(DateTime.now()),
        lock,
      );
    } catch (e) {
      if (_disposed || epoch != _epoch) return;
      if (e is SetupRepositoryException &&
          (e.kind == SetupErrorKind.denied ||
              e.kind == SetupErrorKind.expired)) {
        _clear();
      }
      error =
          'Admin access could not be verified online. Sign in again or retry.';
    } finally {
      if (!_disposed && epoch == _epoch) {
        busy = false;
        _notify();
      }
    }
  }

  Future<void> selectBranch(
    String branchId, {
    bool discardUnsaved = false,
  }) async {
    if (locked || busy || _pending != null) return;
    if ((dirty || conflict) && !discardUnsaved) {
      error = 'Confirm discarding your unsaved changes before reloading.';
      _notify();
      return;
    }
    if (!_catalog!.branches.any(
      (b) => b.id == branchId && b.active && b.orgId == _context!.orgId,
    )) {
      return;
    }
    final epoch = ++_epoch;
    busy = true;
    error = null;
    _notify();
    try {
      final value = await repository.load(branchId);
      if (!_owns(epoch)) return;
      _accept(value, branchId);
    } catch (e) {
      if (_owns(epoch)) _fail(e);
    } finally {
      if (_owns(epoch)) {
        busy = false;
        _notify();
      }
    }
  }

  Future<void> reload({bool discardUnsaved = false}) async {
    if (_state != null) {
      await selectBranch(_state!.branchId, discardUnsaved: discardUnsaved);
    }
  }

  void edit(SetupConfiguration value) {
    if (!canEdit || _state == null) return;
    _configuration = value;
    dirty = true;
    error = null;
    touch();
    _notify();
  }

  Future<void> save() async {
    if (!canEdit || _state == null || _configuration == null) return;
    final validation = guidance!;
    if (!validation.validDraft) {
      error = validation.errors.join('\n');
      _notify();
      return;
    }
    _pending = SaveSetupDraftRequest(
      operationId: newOperationId(),
      branchId: _state!.branchId,
      expectedRevision: _state!.draft?.revision ?? 0,
      configuration: _configuration!,
    );
    await _runPending();
  }

  Future<void> activate(String reason) async {
    if (!canActivate) return;
    try {
      _pending = ActivateSetupRequest(
        operationId: newOperationId(),
        branchId: _state!.branchId,
        draftId: _state!.draft!.id,
        expectedDraftRevision: _state!.draft!.revision,
        expectedActiveRevision: _state!.activeRevision,
        reason: reason,
      );
    } on FormatException {
      error = 'Enter a change reason (up to 2,000 characters).';
      _notify();
      return;
    }
    await _runPending();
  }

  Future<void> mutatePreset(MutatePresetRequest request) async {
    if (!canEdit) return;
    _pending = request;
    await _runPending();
  }

  Future<void> mutateLocation(MutateLocationRequest request) async {
    if (!canEdit || _state?.branchId != request.branchId) return;
    _pending = request;
    await _runPending();
  }

  Future<void> retry() async {
    if (locked || busy || _pending == null) return;
    await _runPending();
  }

  BranchSetupState _withCatalog(
    BranchSetupState value,
    ReferenceCatalog catalog, {
    List<SetupAuditEntry>? history,
  }) => BranchSetupState(
    branchId: value.branchId,
    draft: value.draft,
    active: value.active,
    activeRevision: value.activeRevision,
    catalog: catalog,
    history: history ?? value.history,
  );

  void _accept(BranchSetupState value, String branchId) {
    if (value.branchId != branchId || value.catalog.orgId != _context!.orgId) {
      throw SetupRepositoryException(
        SetupErrorKind.network,
        'Unexpected response.',
      );
    }
    _state = value;
    formVersion++;
    _catalog = value.catalog;
    _configuration =
        value.draft?.configuration ??
        value.active?.configuration ??
        SetupConfiguration.empty();
    dirty = false;
    conflict = false;
  }

  Future<void> _runPending() async {
    final request = _pending!;
    final epoch = ++_epoch;
    busy = true;
    error = null;
    touch();
    _notify();
    try {
      final Object result;
      if (request is SaveSetupDraftRequest) {
        result = await repository.saveDraft(request);
      } else if (request is ActivateSetupRequest) {
        result = await repository.activate(request);
      } else if (request is MutatePresetRequest) {
        result = await repository.mutatePreset(request);
      } else {
        result = await repository.mutateLocation(
          request as MutateLocationRequest,
        );
      }
      if (!_owns(epoch)) return;
      if (result is BranchSetupState) {
        _accept(result, _state!.branchId);
      } else {
        final refs = result as ReferenceMutationResult;
        if (refs.catalog.orgId != _context!.orgId) {
          throw SetupRepositoryException(
            SetupErrorKind.network,
            'Unexpected response.',
          );
        }
        _catalog = refs.catalog;
        if (_state != null) {
          _state = _withCatalog(_state!, refs.catalog, history: refs.history);
        }
      }
      _pending = null;
    } catch (e) {
      if (_owns(epoch)) _fail(e);
    } finally {
      if (_owns(epoch)) {
        busy = false;
        _notify();
      }
    }
  }

  void _fail(Object e) {
    final kind = e is SetupRepositoryException
        ? e.kind
        : SetupErrorKind.network;
    if (kind == SetupErrorKind.denied || kind == SetupErrorKind.expired) {
      clearSession();
      error = 'Your admin session is no longer valid. Sign in again.';
    } else if (kind == SetupErrorKind.conflict) {
      _pending = null;
      conflict = true;
      error = 'Someone changed this setup. Your edits are retained. Review them before discarding and reloading.';
    } else if (kind == SetupErrorKind.invalid) {
      _pending = null;
      error = 'The server rejected this configuration. Review the fields and current references.';
    } else {
      error = _pending == null
          ? 'Could not load setup. Your existing edits are retained.'
          : 'The result is not confirmed. Retry the same operation before making changes.';
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _epoch++;
    _idleTimer?.cancel();
    _expiryTimer?.cancel();
    _clear();
    super.dispose();
  }
}
