import 'dart:convert';

import 'package:flutter/material.dart';

Map<String, dynamic> copySetupMap(Map<String, dynamic> value) =>
    Map<String, dynamic>.from(jsonDecode(jsonEncode(value)) as Map);

class SetupSection extends StatelessWidget {
  const SetupSection({
    super.key,
    required this.title,
    this.description,
    required this.children,
  });
  final String title;
  final String? description;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 20),
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          if (description != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(description!),
            ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    ),
  );
}

Widget setupText(
  String label,
  Object? value,
  ValueChanged<String> onChanged, {
  Key? key,
  int max = 120,
  bool required = false,
  bool multiline = false,
}) => Padding(
  padding: const EdgeInsets.only(bottom: 16),
  child: TextFormField(
    key: key,
    initialValue: value?.toString() ?? '',
    maxLength: max,
    minLines: multiline ? 2 : 1,
    maxLines: multiline ? 4 : 1,
    decoration: InputDecoration(
      labelText: label,
      counterText: '',
      border: const OutlineInputBorder(),
    ),
    onChanged: onChanged,
    validator: (v) =>
        required && (v ?? '').trim().isEmpty ? 'Enter $label' : null,
  ),
);

Widget setupNumber(
  String label,
  Object? value,
  ValueChanged<num?> onChanged, {
  bool whole = false,
}) => Padding(
  padding: const EdgeInsets.only(bottom: 16),
  child: TextFormField(
    initialValue: value?.toString() ?? '',
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    ),
    validator: (value) {
      if ((value ?? '').isEmpty) return null;
      final n = num.tryParse(value!);
      return n == null || !n.isFinite || n < 0 || (whole && n % 1 != 0)
          ? (whole
                ? 'Enter a nonnegative whole number'
                : 'Enter a nonnegative number')
          : null;
    },
    onChanged: (v) {
      final n = num.tryParse(v);
      if (v.isEmpty || (n != null && n.isFinite && n >= 0)) onChanged(n);
    },
  ),
);

Widget setupChoice(
  String label,
  String value,
  Map<String, String> options,
  ValueChanged<String> onChanged,
) {
  final choices = {...options};
  if (!choices.containsKey(value)) {
    choices[value] = value.isEmpty ? 'Not configured' : 'Unavailable selection';
  }
  return Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: DropdownButtonFormField<String>(
      key: ValueKey('$label:$value'),
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: choices.entries
          .map(
            (e) => DropdownMenuItem(
              value: e.key,
              child: Text(e.value, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    ),
  );
}

Future<Map<String, dynamic>?> editSetupDialog(
  BuildContext context, {
  required String title,
  required Map<String, dynamic> initial,
  required Widget Function(Map<String, dynamic>, VoidCallback) fields,
  String confirm = 'Apply to draft',
  String? Function(Map<String, dynamic>)? validate,
}) => showDialog<Map<String, dynamic>>(
  context: context,
  useRootNavigator: false,
  barrierDismissible: false,
  builder: (_) => _SetupEditDialog(
    title: title,
    initial: initial,
    fields: fields,
    confirm: confirm,
    validate: validate,
  ),
);

class _SetupEditDialog extends StatefulWidget {
  const _SetupEditDialog({
    required this.title,
    required this.initial,
    required this.fields,
    required this.confirm,
    this.validate,
  });
  final String title, confirm;
  final Map<String, dynamic> initial;
  final Widget Function(Map<String, dynamic>, VoidCallback) fields;
  final String? Function(Map<String, dynamic>)? validate;
  @override
  State<_SetupEditDialog> createState() => _SetupEditDialogState();
}

class _SetupEditDialogState extends State<_SetupEditDialog> {
  final form = GlobalKey<FormState>();
  late final value = copySetupMap(widget.initial);
  String? error;
  @override
  Widget build(BuildContext context) => Dialog(
    insetPadding: const EdgeInsets.all(16),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 680),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),
                widget.fields(value, () => setState(() {})),
                if (error != null)
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 56),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 56),
                      ),
                      onPressed: () {
                        if (!form.currentState!.validate()) return;
                        final issue = widget.validate?.call(value);
                        if (issue != null) {
                          setState(() => error = issue);
                          return;
                        }
                        Navigator.of(context).pop(value);
                      },
                      child: Text(widget.confirm),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
