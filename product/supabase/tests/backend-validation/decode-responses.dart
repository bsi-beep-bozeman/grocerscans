import 'dart:convert';
import 'dart:io';
import '../../../../app_flutter/lib/setup/setup_repository.dart';

Object? canonical(Object? value) {
  if (value is Map) {
    final keys = value.keys.cast<String>().toList()..sort();
    return {for (final key in keys) key: canonical(value[key])};
  }
  if (value is List) return value.map(canonical).toList();
  return value;
}

Map<String, dynamic> decode(String type, Map<String, dynamic> value) {
  switch (type) {
    case 'context':
      return SetupContext.fromJson(value).toJson();
    case 'state':
      final state = BranchSetupState.fromJson(value);
      if ((state.active?.version ?? 0) != state.activeRevision) {
        throw const FormatException('Active pair mismatch');
      }
      return state.toJson();
    case 'reference':
      return ReferenceMutationResult.fromJson(value).toJson();
    default:
      throw FormatException('Unknown response type: $type');
  }
}

void main(List<String> args) {
  if (args.length != 1) throw ArgumentError('Pass the captured response file');
  final responses = jsonDecode(File(args.single).readAsStringSync()) as List;
  final counts = <String, int>{};
  for (final response in responses) {
    final type = response['type'] as String;
    final parsed = decode(type, Map<String, dynamic>.from(response['data'] as Map));
    final reparsed = decode(type, parsed);
    if (jsonEncode(canonical(parsed)) != jsonEncode(canonical(reparsed))) {
      throw FormatException('Unstable DTO round trip for ${response['name']}');
    }
    counts[type] = (counts[type] ?? 0) + 1;
  }
  if (!['context', 'state', 'reference'].every(counts.containsKey)) {
    throw StateError('Missing response families');
  }
  stdout.writeln(jsonEncode({'status': 'PASS', 'responses': responses.length, 'types': counts}));
}
