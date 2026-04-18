// lib/vm/util/new_block_ids.dart
import 'uid.dart';

/// Mutate the given blocks to have new IDs and update all internal ID references.
/// Updates blocks in-place.
void assignNewBlockIds(List<Map<String, dynamic>> blocks) {
  final Map<String, String> oldToNew = {};

  // First update all top-level IDs and create old-to-new mapping
  for (final block in blocks) {
    final newId = uid();
    final oldId = block['id'] as String;
    block['id'] = oldToNew[oldId] = newId;
  }

  // Then go back through and update inputs (block/shadow) and next/parent properties
  for (final block in blocks) {
    final inputs = block['inputs'] as Map<String, dynamic>?;

    if (inputs != null) {
      for (final key in inputs.keys) {
        final input = inputs[key] as Map<String, dynamic>;
        if (input['block'] != null && oldToNew.containsKey(input['block'])) {
          input['block'] = oldToNew[input['block']];
        }
        if (input['shadow'] != null && oldToNew.containsKey(input['shadow'])) {
          input['shadow'] = oldToNew[input['shadow']];
        }
      }
    }

    if (block['parent'] != null && oldToNew.containsKey(block['parent'])) {
      block['parent'] = oldToNew[block['parent']];
    }
    if (block['next'] != null && oldToNew.containsKey(block['next'])) {
      block['next'] = oldToNew[block['next']];
    }
  }
}
