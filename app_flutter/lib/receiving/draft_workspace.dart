import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../identity/identity_models.dart';
import '../identity/staff_session_controller.dart';
import '../sync/draft_crypto.dart';
import '../sync/draft_store.dart';
import '../sync/draft_store_factory.dart';
import 'receiving_draft.dart';
import 'receiving_policy.dart';
import 'receiving_repository.dart';
import 'draft_recovery_screen.dart';

class DraftWorkspace extends StatefulWidget {
  const DraftWorkspace({
    super.key,
    required this.controller,
    this.openStore = openDraftStore,
    this.repository,
    this.recovery,
    this.recoveryReason,
    this.branchName,
    this.openStockRegister,
  });
  final StaffSessionController controller;
  final Future<DraftStore> Function() openStore;
  final ReceivingRepository? repository;
  final RecoveryGrant? recovery;

  /// Set when the signed-in actor has view access to the stock register
  /// (see lib/identity/team_models.dart); null hides the entry point.
  final VoidCallback? openStockRegister;
  final String? recoveryReason, branchName;
  @override
  State<DraftWorkspace> createState() => _DraftWorkspaceState();
}

class _DraftWorkspaceState extends State<DraftWorkspace> {
  late final session = widget.controller.session!;
  late final generation = widget.controller.generation;
  late final scope = widget.recovery == null
      ? session.scope
      : PartitionScope(
          orgId: session.scope.orgId,
          branchId: session.scope.branchId,
          deviceId: session.scope.deviceId,
          actorId: widget.recovery!.originalActorId,
        );
  late final vaultId = widget.recovery?.vaultId ?? session.vaultId;
  late final keyVersion = widget.recovery?.keyVersion ?? session.keyVersion;
  late final Uint8List keyBytes = Uint8List.fromList(
    widget.recovery?.key ?? session.key,
  );
  late ReceivingDraft draft = ReceivingDraft.create(scope);
  final name = TextEditingController(),
      identifier = TextEditingController(),
      quantity = TextEditingController(),
      lot = TextEditingController(),
      notes = TextEditingController();
  DraftStore? store;
  List<(ReceivingDraft, int)> drafts = [];
  List<Map<String, dynamic>> matches = [];
  List<ReceivingCache> cached = [];
  int revision = 0, editVersion = 0;
  bool loading = true,
      saving = false,
      dirty = false,
      closed = false,
      camera = false;
  DateTime? expiry;
  String status = 'Loading drafts…';
  String? catalogStatus;
  Timer? debounce, recoveryTimer;
  Future<void>? pending;
  bool get current =>
      mounted &&
      !closed &&
      widget.controller.generation == generation &&
      widget.controller.session == session;
  @override
  void initState() {
    super.initState();
    keyBytes;
    widget.controller.addListener(_sessionChanged);
    unawaited(_open());
    if (widget.recovery != null) {
      final remaining = widget.recovery!.expiresAt.difference(
        widget.controller.serverNow ?? widget.recovery!.expiresAt,
      );
      recoveryTimer = Timer(
        remaining.isNegative ? Duration.zero : remaining,
        widget.controller.lock,
      );
    }
  }

  void _sessionChanged() {
    if (!current) {
      _sealOnClose();
    }
  }

  void _sealOnClose() {
    if (closed) return;
    debounce?.cancel();
    if (dirty && !saving && store != null) {
      pending = _save(closing: true);
    }
    closed = true;
    keyBytes.fillRange(0, keyBytes.length, 0);
    widget.recovery?.clearKey();
    name.clear();
    identifier.clear();
    quantity.clear();
    lot.clear();
    notes.clear();
    expiry = null;
    drafts = [];
    matches = [];
    cached = [];
  }

  Future<void> _open() async {
    try {
      final opened = await widget.openStore();
      if (!current) {
        await opened.close();
        return;
      }
      store = opened;
      final rows = await opened.read(vaultId);
      final loaded = <(ReceivingDraft, int)>[];
      var corrupt = 0;
      for (final row in rows) {
        if (row.keyVersion != keyVersion) {
          corrupt++;
          continue;
        }
        try {
          final value = await DraftCrypto().open(row, scope, keyBytes);
          if (!current) return;
          loaded.add((value, row.revision));
        } catch (_) {
          corrupt++;
        }
      }
      if (opened is DraftCacheStore) {
        for (final row in await (opened as DraftCacheStore).readCache(
          vaultId,
        )) {
          try {
            final value = await DraftCrypto().openCache(row, scope, keyBytes);
            if (!current) return;
            cached.add(value);
          } catch (_) {
            /* Retain unverifiable ciphertext without displaying it. */
          }
        }
      }
      if (current) {
        setState(() {
          drafts = loaded;
          loading = false;
          status = corrupt > 0
              ? 'Some stored drafts could not be verified. Their encrypted records were retained.'
              : 'New draft · not saved';
        });
      }
    } catch (_) {
      if (current) {
        setState(() {
          loading = false;
          status = 'Storage unavailable. No drafts were replaced. Reopen this workspace to retry.';
        });
      }
    }
  }

  void _edit() {
    if (!current) return;
    widget.controller.touch();
    dirty = true;
    editVersion++;
    setState(() => status = 'Not saved');
    debounce?.cancel();
    debounce = Timer(const Duration(milliseconds: 700), () {
      pending = _save();
    });
  }

  Map<String, dynamic>? get recoveryMetadata => widget.recovery == null
      ? null
      : {
          'recovery_id': widget.recovery!.id,
          'recovering_actor_id': widget.recovery!.recoveringActorId,
          'reason': widget.recoveryReason,
          'granted_at': widget.recovery!.grantedAt.toIso8601String(),
        };
  Future<void> _save({bool closing = false}) async {
    if ((!current && !closing) || saving || store == null || !dirty) return;
    debounce?.cancel();
    saving = true;
    final edit = editVersion;
    try {
      final payload = {
        ...draft.payload,
        'entered_name': name.text.isEmpty ? null : name.text,
        'entered_identifier': identifier.text.isEmpty ? null : identifier.text,
        'quantity_text': quantity.text.isEmpty ? null : quantity.text,
        'lot': lot.text.isEmpty ? null : lot.text,
        'expiry_date': expiry?.toIso8601String().substring(0, 10),
        'expiry_basis': expiry == null ? null : 'printed',
        'notes': notes.text.isEmpty ? null : notes.text,
      };
      final snapshot = draft.edit(payload, recovery: recoveryMetadata);
      // seal() copies the key synchronously, before local concealment clears it.
      final encrypted = DraftCrypto().seal(
        snapshot,
        vaultId,
        keyVersion,
        keyBytes,
        revision: revision + 1,
      );
      if (current && !closing) {
        setState(() => status = 'Saving on this device…');
      }
      final envelope = await encrypted;
      await store!.write(envelope, expectedRevision: revision);
      revision = envelope.revision;
      if (current) {
        draft = snapshot;
        drafts.removeWhere((d) => d.$1.id == draft.id);
        drafts.add((draft, revision));
        dirty = editVersion != edit;
        setState(() => status = dirty ? 'Not saved' : 'Saved on this device');
      }
    } on ReceivingFailure catch (e) {
      if (current) {
        setState(
          () => status = e.code == 'conflict'
              ? 'Not saved: a newer draft exists. Your form is retained; reopen and compare before editing.'
              : 'Not saved: storage is full or unavailable. Your form is retained.',
        );
      }
    } catch (_) {
      if (current) {
        setState(
          () => status =
              'Not saved. Check the fields and available storage, then retry.',
        );
      }
    } finally {
      saving = false;
      if (current) {
        setState(() {});
        if (dirty && editVersion != edit) {
          debounce = Timer(const Duration(milliseconds: 700), () {
            pending = _save();
          });
        }
      }
    }
  }

  void _select(ReceivingDraft value, int rev) {
    if (dirty || saving) return;
    setState(() {
      draft = value;
      revision = rev;
      name.text = value.payload['entered_name'] as String? ?? '';
      identifier.text = value.payload['entered_identifier'] as String? ?? '';
      quantity.text = value.payload['quantity_text'] as String? ?? '';
      lot.text = value.payload['lot'] as String? ?? '';
      final expiryText = value.payload['expiry_date'] as String?;
      expiry = expiryText == null ? null : DateTime.tryParse(expiryText);
      notes.text = value.payload['notes'] as String? ?? '';
      status = rev == 0 ? 'New draft · not saved' : 'Saved on this device';
      matches = [];
    });
  }

  Future<void> _lookup() async {
    final repo = widget.repository;
    if (repo == null || !current) return;
    try {
      final query = CatalogQuery('name', name.text);
      final result = await repo.catalog(session, query);
      if (current && name.text == query.value) {
        setState(() {
          matches = result.items;
          catalogStatus = matches.isEmpty
              ? 'No matching items. An incomplete draft can still be saved.'
              : 'Choose an item explicitly. Catalog checked ${result.fetchedAt.toLocal()}${result.nextId == null ? '' : '; more matches exist — refine the name.'}';
        });
        try {
          await _cache(ReceivingCache.catalog(scope, query, result));
        } catch (_) {
          /* A response too large for cache still remains a valid online result. */
        }
      }
    } on ReceivingFailure catch (e) {
      if ({
        'session_expired',
        'session_revoked',
        'unauthenticated',
      }.contains(e.code)) {
        widget.controller.lock();
      } else {
        _offlineCatalog();
      }
    } catch (_) {
      if (current) {
        setState(
          () => catalogStatus =
              'Enter at least two characters to look up an item.',
        );
      }
    }
  }

  /// Looks up a scanned or manually entered UPC/SKU. Tries a UPC match first,
  /// then SKU. An unrecognized code (e.g. unlabeled raw meat) falls back to
  /// manual entry: the code is kept in the Identifier field for the staff
  /// member to name and describe themselves.
  Future<void> _lookupByCode(String value) async {
    final repo = widget.repository;
    final code = value.trim();
    if (repo == null || !current || code.isEmpty) return;
    setState(() => camera = false);
    try {
      var result = await repo.catalog(session, CatalogQuery('upc', code));
      if (result.items.isEmpty) {
        result = await repo.catalog(session, CatalogQuery('sku', code));
      }
      if (!current) return;
      if (result.items.length == 1) {
        identifier.text = code;
        await _choose(result.items.first);
      } else if (result.items.isEmpty) {
        setState(() {
          identifier.text = code;
          catalogStatus =
              'No catalog match for “$code”. Enter the item name and details manually.';
        });
        _edit();
      } else {
        setState(() {
          identifier.text = code;
          matches = result.items;
          catalogStatus = 'Multiple matches for “$code”. Choose one below.';
        });
      }
    } on ReceivingFailure catch (e) {
      if ({
        'session_expired',
        'session_revoked',
        'unauthenticated',
      }.contains(e.code)) {
        widget.controller.lock();
      } else if (current) {
        setState(
          () => catalogStatus =
              'Catalog unavailable. Enter the item details manually.',
        );
      }
    } catch (_) {
      if (current) {
        setState(
          () => catalogStatus =
              'Catalog unavailable. Enter the item details manually.',
        );
      }
    }
  }

  Future<void> _pickExpiry() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: expiry ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && current) {
      setState(() => expiry = picked);
      _edit();
    }
  }

  Future<void> _choose(Map<String, dynamic> item) async {
    final requestedEdit = editVersion;
    try {
      final policy = await widget.repository!.policy(
        session,
        item['id'] as String,
      );
      if (!current || editVersion != requestedEdit) return;
      try {
        await _cache(ReceivingCache.policy(scope, policy));
      } catch (_) {
        /* Optional cache failure must not block verified online selection. */
      }
      if (!current || editVersion != requestedEdit) return;
      final p = policy.toJson();
      final setup = p['setup'] as Map?;
      draft = ReceivingDraft.fromJson({
        ...draft.toJson(),
        'known_setup_version_id': setup?['version_id'],
        'known_setup_revision': setup?['revision'],
        'payload': {...draft.payload, 'product_id': item['id']},
      });
      draft = ReceivingDraft.fromJson({
        ...draft.toJson(),
        'payload': {
          ...draft.payload,
          'supplier_id': item['default_supplier_id'],
          'unit_code': (p['unit'] as Map?)?['code'],
        },
      });
      name.text = item['name'] as String;
      matches = [];
      if (lot.text.isEmpty) {
        final sameProduct = drafts
            .where((d) => d.$1.payload['product_id'] == item['id'])
            .length;
        lot.text = generateBatchLabel(
          code: batchCodeForSku(item['sku'] as String?),
          sequence: sameProduct + 1,
          date: DateTime.now(),
        );
      }
      _edit();
    } on ReceivingFailure catch (e) {
      if ({
        'session_expired',
        'session_revoked',
        'unauthenticated',
      }.contains(e.code)) {
        widget.controller.lock();
      } else if (current) {
        setState(
          () => catalogStatus =
              'Policy unavailable. Your draft remains incomplete.',
        );
      }
    } catch (_) {
      if (current) {
        setState(
          () => catalogStatus =
              'Policy could not be verified. Your draft remains incomplete.',
        );
      }
    }
  }

  Future<void> _cache(ReceivingCache value) async {
    if (!current || store is! DraftCacheStore) return;
    try {
      final envelope = await DraftCrypto().sealCache(
        value,
        vaultId,
        keyVersion,
        keyBytes,
      );
      if (!current) return;
      await (store as DraftCacheStore).writeCache(envelope);
      if (current) cached.add(value);
    } catch (_) {
      /* Cache is optional. A failure never changes the draft's saved state. */
    }
  }

  void _offlineCatalog() {
    if (!current) return;
    final candidates = cached.where((c) {
      final j = c.toJson();
      return j['type'] == 'catalog' &&
          (j['query'] as Map)['kind'] == 'name' &&
          (j['query'] as Map)['value'] == name.text;
    }).toList();
    if (candidates.isEmpty) {
      setState(
        () => catalogStatus =
            'Catalog unavailable. You can save an incomplete draft.',
      );
      return;
    }
    candidates.sort(
      (a, b) =>
          wireTime(a.toJson()['fetched_at'])
              .compareTo(wireTime(b.toJson()['fetched_at'])),
    );
    final last = candidates.last.toJson();
    final result = ReceivingCatalog.fromJson(last['data']);
    setState(() {
      matches = result.items;
      catalogStatus =
          'Offline catalog · last checked ${result.fetchedAt.toLocal()}. Policy must be verified online before selecting an item.';
    });
  }

  Future<void> _persistence() async {
    final granted = await store?.requestPersistence();
    if (current) {
      setState(
        () => status = granted == true
            ? 'Persistent storage granted. Site clearing or device loss can still remove drafts.'
            : 'Persistent storage was not granted. Storage eviction can remove drafts.',
      );
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_sessionChanged);
    _sealOnClose();
    recoveryTimer?.cancel();
    debounce?.cancel();
    final opened = store;
    if (opened != null) {
      unawaited((pending ?? Future<void>.value()).whenComplete(opened.close));
    }
    name.dispose();
    identifier.dispose();
    quantity.dispose();
    lot.dispose();
    notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Receiving drafts'),
      actions: [
        TextButton(
          onPressed: widget.controller.lock,
          child: const Text('Lock'),
        ),
      ],
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.recovery == null
                    ? session.displayName
                    : 'Recovery · original actor ${scope.actorId}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text('Branch: ${widget.branchName ?? scope.branchId}'),
              const SizedBox(height: 12),
              const Text(
                'Drafts are saved only on this device. Saving does not receive stock or submit a receipt. Recent unsaved edits may be lost on lock or interruption.',
              ),
              if (widget.recovery != null)
                const Text(
                  'Full-partition recovery is audited. Original ownership is retained. This view expires within five minutes.',
                ),
              const SizedBox(height: 16),
              Semantics(liveRegion: true, child: Text(status)),
              if (catalogStatus != null) Text(catalogStatus!),
              const SizedBox(height: 16),
              if (loading) const LinearProgressIndicator(),
              if (drafts.isNotEmpty)
                DropdownButtonFormField<String>(
                  initialValue: drafts.any((d) => d.$1.id == draft.id)
                      ? draft.id
                      : null,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Open a saved draft',
                  ),
                  items: [
                    for (final d in drafts)
                      DropdownMenuItem(
                        value: d.$1.id,
                        child: Text(
                          d.$1.payload['entered_name'] as String? ??
                              'Incomplete draft',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: dirty || saving
                      ? null
                      : (id) {
                          final d = drafts.firstWhere((d) => d.$1.id == id);
                          _select(d.$1, d.$2);
                        },
                ),
              if (widget.repository != null) ...[
                if (camera)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      height: 240,
                      child: MobileScanner(
                        onDetect: (capture) {
                          if (!camera) return;
                          for (final barcode in capture.barcodes) {
                            final value = barcode.rawValue;
                            if (value != null && value.isNotEmpty) {
                              unawaited(_lookupByCode(value));
                              break;
                            }
                          }
                        },
                        errorBuilder: (context, exception) => Container(
                          color: Colors.black,
                          padding: const EdgeInsets.all(24),
                          alignment: Alignment.center,
                          child: const Text(
                            'Camera unavailable. Allow camera access in your browser or phone settings, or use the identifier field below. Mobile web camera requires HTTPS.',
                            style: TextStyle(color: Colors.white, height: 1.5),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 56),
                    ),
                    onPressed: () => setState(() => camera = true),
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Scan barcode'),
                  ),
                if (camera)
                  TextButton(
                    onPressed: () => setState(() => camera = false),
                    child: const Text('Stop scanning'),
                  ),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Item name'),
                maxLength: 120,
                onChanged: (_) => _edit(),
              ),
              if (widget.repository != null)
                TextButton(
                  style: TextButton.styleFrom(minimumSize: const Size(0, 56)),
                  onPressed: _lookup,
                  child: const Text('Look up item by name'),
                ),
              for (final item in matches)
                TextButton(
                  style: TextButton.styleFrom(minimumSize: const Size(0, 56)),
                  onPressed: () => _choose(item),
                  child: Text(
                    '${item['name']} · ${item['upc'] ?? item['sku'] ?? 'No identifier'}',
                  ),
                ),
              TextField(
                controller: identifier,
                decoration: const InputDecoration(labelText: 'Identifier'),
                maxLength: 128,
                onChanged: (_) => _edit(),
                onSubmitted: widget.repository == null ? null : _lookupByCode,
              ),
              if (widget.repository != null)
                TextButton(
                  style: TextButton.styleFrom(minimumSize: const Size(0, 56)),
                  onPressed: () => _lookupByCode(identifier.text),
                  child: const Text('Look up this identifier'),
                ),
              TextField(
                controller: lot,
                decoration: const InputDecoration(
                  labelText: 'Batch',
                  helperText: 'Auto-filled when an item is chosen; editable before saving.',
                ),
                maxLength: 120,
                onChanged: (_) => _edit(),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      expiry == null
                          ? 'No expiration set'
                          : 'Expires ${expiry!.toLocal().toIso8601String().substring(0, 10)}',
                    ),
                    FilledButton.tonal(
                      onPressed: _pickExpiry,
                      child: Text(expiry == null ? 'Set expiration' : 'Change'),
                    ),
                  ],
                ),
              ),
              TextField(
                controller: quantity,
                decoration: const InputDecoration(
                  labelText: 'Quantity as entered',
                ),
                maxLength: 32,
                onChanged: (_) => _edit(),
              ),
              TextField(
                controller: notes,
                decoration: const InputDecoration(labelText: 'Notes'),
                maxLength: 1000,
                minLines: 2,
                maxLines: 4,
                onChanged: (_) => _edit(),
              ),
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size(0, 56)),
                onPressed: saving || store == null
                    ? null
                    : () {
                        pending = _save();
                      },
                child: const Text('Save on this device'),
              ),
              TextButton(
                style: TextButton.styleFrom(minimumSize: const Size(0, 56)),
                onPressed: dirty || saving
                    ? null
                    : () => _select(ReceivingDraft.create(scope), 0),
                child: const Text('New draft'),
              ),
              TextButton(
                style: TextButton.styleFrom(minimumSize: const Size(0, 56)),
                onPressed: store == null ? null : _persistence,
                child: const Text('Request persistent storage'),
              ),
              if (widget.openStockRegister != null)
                TextButton(
                  style: TextButton.styleFrom(minimumSize: const Size(0, 56)),
                  onPressed: widget.openStockRegister,
                  child: const Text('View stock register'),
                ),
              if (session.isLead && widget.recovery == null)
                TextButton(
                  style: TextButton.styleFrom(minimumSize: const Size(0, 56)),
                  onPressed: dirty || saving
                      ? null
                      : () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => DraftRecoveryScreen(
                              controller: widget.controller,
                              repository: widget.repository,
                              branchName: widget.branchName,
                            ),
                          ),
                        ),
                  child: const Text("Recover another person's drafts"),
                ),
              const Text(
                'Admin recovery and stock confirmation are unavailable in this step.',
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
