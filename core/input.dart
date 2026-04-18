/*import 'block.dart';
import 'connection.dart';
import 'field.dart';
import '../models/block_model.dart';
import 'block_svg.dart';

/// Types of input
const int DUMMY_INPUT = 0;
const int INPUT_VALUE = 1;
const int INPUT_STATEMENT = 2;

/// Alignment constants
const int ALIGN_LEFT = 0;
const int ALIGN_CENTRE = 1;
const int ALIGN_RIGHT = 2;

/// Helper to safely resolve target blocks
BlockModel? resolveTarget(dynamic target) {
  if (target is Function) {
    final result = target();
    if (result is BlockModel) return result;
  } else if (target is BlockModel) {
    return target;
  }
  return null;
}

/// Class representing an input on a block (value, statement, or dummy)
class Input {
  int type;
  String name;
  Block sourceBlock;
  Connection? connection;
  List<BlockField> fieldRow = [];
  dynamic outlinePath; // Placeholder for Flutter Path/Canvas
  int align = ALIGN_LEFT;
  bool _visible = true;

  double renderWidth = 0;
  double renderHeight = 0;
  double fieldWidth = 0;

  // Added block property for BlockSvg assignment
  BlockSvg? _block;
  BlockSvg? get block => _block;
  set block(BlockSvg? value) => _block = value;

  Input(this.type, this.name, this.sourceBlock, [this.connection]) {
    if (type != DUMMY_INPUT && name.isEmpty) {
      throw Exception(
          'Value inputs and statement inputs must have non-empty name.');
    }
  }

  /// Append a field (or label) to the end of the input's field row
  Input appendField(BlockField field) {
    insertFieldAt(fieldRow.length, field);
    return this;
  }

  /// Insert a field at a given index
  int insertFieldAt(int index, BlockField field) {
    if (index < 0 || index > fieldRow.length) {
      throw Exception('Index $index out of bounds.');
    }

    fieldRow.insert(index, field);
    index++;

    if (sourceBlock.hasUi) {
      sourceBlock.render();
      sourceBlock.bumpNeighbours();
    }

    return index;
  }

  /// Remove a field by reference
  void removeField(BlockField field) {
    fieldRow.remove(field);
    if (sourceBlock.hasUi) {
      sourceBlock.render();
      sourceBlock.bumpNeighbours();
    }
  }

  /// Check if input is visible
  bool isVisible() => _visible;

  /// Set visibility of input
  List<BlockModel> setVisible(bool visible) {
    List<BlockModel> renderList = [];
    if (_visible == visible) return renderList;

    _visible = visible;

    if (connection != null) {
      if (visible) {
        renderList = connection!.unhideAll();
      } else {
        connection!.hideAll();
      }

      // Safely get child block
      final child = resolveTarget(connection!.targetBlock);
      if (child != null) {
        child.uiBlock?.hasUi = visible;
      }
    }

    return renderList;
  }

  /// Set connection type compatibility
  Input setCheck(List<String>? check) {
    connection?.setCheck(check);
    return this;
  }

  /// Set alignment of fields
  Input setAlign(int alignment) {
    align = alignment;
    if (sourceBlock.hasUi) sourceBlock.render();
    return this;
  }

  /// Initialize all fields (safe for empty)
  void init() {
    // Nothing needed for Flutter widgets; render is handled in UI
  }

  /// Dispose of input and all associated resources
  void dispose() {
    outlinePath = null;
    fieldRow.clear();
    connection?.dispose();
  }

  /// Initialize the outline path for rendering connections
  void initOutlinePath(dynamic svgRoot) {
    if (!sourceBlock.hasUi) return;
    if (outlinePath != null) return;

    if (type == INPUT_VALUE) {
      outlinePath = {}; // Placeholder
    }
  }

  /// Check if input is filled (needed by Block.allInputsFilled)
  bool isFilled([bool shadowBlocksAreFilled = true]) {
    if (connection?.targetBlock != null) return true;
    if (shadowBlocksAreFilled && type == INPUT_VALUE && connection != null) {
      return true;
    }
    return false;
  }

  // ------------------- XML Export -------------------
  String toXml() {
    final buffer = StringBuffer();
    buffer.write('<input name="$name" type="$type">');

    // Export fields
    for (var field in fieldRow) {
      if (field is BlockFieldWithXml) {
        buffer.write(field.toXml());
      } else {
        // Safe getValue call
        String value = '';
        try {
          value = (field as dynamic).getValue();
        } catch (_) {}
        buffer.write('<field>$value</field>');
      }
    }

    // Export connected block recursively
    final child = resolveTarget(connection?.targetBlock);
    if (child != null) buffer.write(child.toXml());

    buffer.write('</input>');
    return buffer.toString();
  }

  // ------------------- Descendant IDs -------------------
  List<String> getDescendantIds() {
    List<String> ids = [];
    final child = resolveTarget(connection?.targetBlock);
    if (child != null) {
      if (child.id != null) ids.add(child.id!);
      ids.addAll(child.getDescendantIds());
    }
    return ids;
  }
}

/// Extend BlockField to support XML export
abstract class BlockFieldWithXml extends BlockField {
  BlockFieldWithXml({
    super.key,
    super.initialValue,
    super.validator,
    super.editable,
    super.maxDisplayLength,
    super.name,
    super.sourceBlock,
    super.fieldKey,
  });

  String toXml();
}
*/
