import 'package:flutter/material.dart';
import 'field_angle.dart';
import 'field_date.dart';
import 'field_dropdown.dart';
import 'field_iconmenu.dart';
import 'field_image.dart';
import 'field_label_serializable.dart';
import 'field_matrix.dart';
import 'field_note.dart';
import 'field_textinput_removeable.dart';
import 'field_textinput.dart';
import 'field_variable_getter.dart';
import 'field_vertical_seperator.dart'; // ✅ imported

typedef FieldValidator<T> = T? Function(T value);

/// Abstract base class for block fields (e.g., text, dropdowns).
abstract class BlockField extends StatefulWidget {
  final String initialValue;
  final String? Function(String)? validator;
  final bool editable;
  final double maxDisplayLength;
  final String? name;
  final dynamic sourceBlock;
  final List<String> argTypes = [];
  final GlobalKey<BlockFieldState>? fieldKey;

  BlockField({
    super.key,
    this.initialValue = '',
    this.validator,
    this.editable = true,
    this.maxDisplayLength = 30,
    this.name,
    this.sourceBlock,
    this.fieldKey,
  });

  void addArgType(String argType) {
    if (!argTypes.contains(argType)) argTypes.add(argType);
  }
}

/// Base State class for BlockField
abstract class BlockFieldState<T extends BlockField> extends State<T> {
  late String value;
  bool visible = true;

  @override
  void initState() {
    super.initState();
    value = widget.initialValue;
  }

  void setValue(dynamic newValue) {
    String val = (newValue is bool)
        ? (newValue ? 'TRUE' : 'FALSE')
        : newValue.toString();
    final validated = widget.validator?.call(val) ?? val;
    if (validated != value) setState(() => value = validated);
  }

  String getValue() => value;

  String getDisplayText() {
    String display = value.isEmpty ? '\u00A0' : value;
    if (display.length > widget.maxDisplayLength.toInt()) {
      display = "${display.substring(0, widget.maxDisplayLength.toInt() - 1)}…";
    }
    return display.replaceAll(' ', '\u00A0');
  }

  void setVisible(bool isVisible) {
    if (visible != isVisible) setState(() => visible = isVisible);
  }

  void forceRerender() => setState(() {});
  void disposeField() {}
  @override
  Widget build(BuildContext context);
}

/// ------------------------
/// Text label field
/// ------------------------
class FieldLabel extends BlockField {
  final String label;

  FieldLabel(this.label, {super.key, super.fieldKey});
  @override
  FieldLabelState createState() => FieldLabelState();
}

class FieldLabelState extends BlockFieldState<FieldLabel> {
  @override
  Widget build(BuildContext context) => Visibility(
        visible: visible,
        child: Text(widget.label, style: const TextStyle(fontSize: 14)),
      );

  @override
  void dispose() {
    disposeField();
    super.dispose();
  }
}

/// ------------------------
/// Angle field
/// ------------------------
class FieldAngle extends BlockField {
  final double initialAngle;
  FieldAngle({
    super.key,
    super.name,
    super.sourceBlock,
    super.fieldKey,
    this.initialAngle = 0,
  }) : super(initialValue: initialAngle.toString());

  @override
  BlockFieldState<BlockField> createState() => _FieldAngleState();
}

class _FieldAngleState extends BlockFieldState<FieldAngle> {
  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AngleField(
          initialValue: double.tryParse(value) ?? widget.initialAngle,
          onChanged: (newAngle) {
            setValue(newAngle);
            widget.sourceBlock?.setFieldValue(widget.name, newAngle);
          },
        ),
        const FieldVerticalSeparator(height: 24),
      ],
    );
  }
}

/// ------------------------
/// Date field
/// ------------------------
class FieldDateBlock extends BlockField {
  final String initialDate;

  FieldDateBlock({
    super.key,
    super.name,
    super.sourceBlock,
    super.fieldKey,
    this.initialDate = '',
  }) : super(initialValue: initialDate);

  @override
  BlockFieldState<BlockField> createState() => _FieldDateBlockState();
}

class _FieldDateBlockState extends BlockFieldState<FieldDateBlock> {
  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FieldDate(
          initialDate: value,
          onDateChanged: (newDate) {
            setValue(newDate);
            widget.sourceBlock?.setFieldValue(widget.name, newDate);
          },
        ),
        const FieldVerticalSeparator(height: 24),
      ],
    );
  }
}

/// ------------------------
/// Dropdown field
/// ------------------------
class FieldDropdownBlock extends BlockField {
  final List<List<String>> options;

  FieldDropdownBlock({
    super.key,
    super.name,
    super.sourceBlock,
    super.fieldKey,
    required this.options,
    super.initialValue = '',
  }) {
    addArgType('dropdown');
  }

  @override
  BlockFieldState<BlockField> createState() => _FieldDropdownBlockState();
}

class _FieldDropdownBlockState extends BlockFieldState<FieldDropdownBlock> {
  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FieldDropdown(
          options: widget.options,
          initialValue: value,
          onChanged: (newValue) {
            setValue(newValue);
            widget.sourceBlock?.setFieldValue(widget.name, newValue);
          },
        ),
        const FieldVerticalSeparator(height: 24),
      ],
    );
  }
}

/// ------------------------
/// Icon menu field
/// ------------------------
class FieldIconMenuBlock extends BlockField {
  final List<IconMenuItem> icons;

  FieldIconMenuBlock({
    super.key,
    super.name,
    super.sourceBlock,
    super.fieldKey,
    required this.icons,
    super.initialValue = '',
  }) {
    addArgType('iconmenu');
  }

  @override
  BlockFieldState<BlockField> createState() => _FieldIconMenuBlockState();
}

class _FieldIconMenuBlockState extends BlockFieldState<FieldIconMenuBlock> {
  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FieldIconMenu(
          icons: widget.icons,
          initialValue: value,
          onChanged: (newValue) {
            setValue(newValue);
            widget.sourceBlock?.setFieldValue(widget.name, newValue);
          },
        ),
        const FieldVerticalSeparator(height: 24),
      ],
    );
  }
}

/// ------------------------
/// Image field
/// ------------------------
class FieldImageBlock extends BlockField {
  final String src;
  final double width;
  final double height;
  final bool flipRTL;

  FieldImageBlock({
    super.key,
    super.name,
    super.sourceBlock,
    super.fieldKey,
    required this.src,
    required this.width,
    required this.height,
    this.flipRTL = false,
  });

  @override
  BlockFieldState<BlockField> createState() => _FieldImageBlockState();
}

class _FieldImageBlockState extends BlockFieldState<FieldImageBlock> {
  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FieldImage(
          src: widget.src,
          width: widget.width,
          height: widget.height,
          flipRTL: widget.flipRTL,
          visible: visible,
        ),
        const FieldVerticalSeparator(height: 24),
      ],
    );
  }
}

/// ------------------------
/// Label Serializable field
/// ------------------------
class FieldLabelSerializableBlock extends BlockField {
  final String text;

  FieldLabelSerializableBlock({
    super.key,
    super.name,
    super.sourceBlock,
    super.fieldKey,
    required this.text,
  }) : super(initialValue: text);

  @override
  BlockFieldState<BlockField> createState() =>
      _FieldLabelSerializableBlockState();
}

class _FieldLabelSerializableBlockState
    extends BlockFieldState<FieldLabelSerializableBlock> {
  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FieldLabelSerializable(
          text: widget.text,
          visible: visible,
        ),
        const FieldVerticalSeparator(height: 24),
      ],
    );
  }
}

/// ------------------------
/// Matrix field
/// ------------------------
class FieldMatrixBlock extends BlockField {
  FieldMatrixBlock({
    super.key,
    super.name,
    super.sourceBlock,
    super.fieldKey,
    super.initialValue = '0000000000000000000000000',
  }) {
    addArgType('matrix');
  }

  @override
  BlockFieldState<BlockField> createState() => _FieldMatrixBlockState();
}

class _FieldMatrixBlockState extends BlockFieldState<FieldMatrixBlock> {
  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FieldMatrix(
          value: value,
          onChanged: (newValue) {
            setValue(newValue);
            widget.sourceBlock?.setFieldValue(widget.name, newValue);
          },
        ),
        const FieldVerticalSeparator(height: 24),
      ],
    );
  }
}

/// ------------------------
/// Note field
/// ------------------------
class FieldNoteBlock extends BlockField {
  final int initialNote;

  FieldNoteBlock({
    super.key,
    super.name,
    super.sourceBlock,
    super.fieldKey,
    this.initialNote = 60,
  }) : super(initialValue: initialNote.toString()) {
    addArgType('note');
  }

  @override
  BlockFieldState<BlockField> createState() => _FieldNoteBlockState();
}

class _FieldNoteBlockState extends BlockFieldState<FieldNoteBlock> {
  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FieldNotePicker(
          initialNote: int.tryParse(value) ?? widget.initialNote,
          onNoteSelected: (note) {
            setValue(note);
            widget.sourceBlock?.setFieldValue(widget.name, note);
          },
        ),
        const FieldVerticalSeparator(height: 24),
      ],
    );
  }
}

/// ------------------------
/// Text input removable field
/// ------------------------
class FieldTextInputRemovableBlock extends BlockField {
  FieldTextInputRemovableBlock({
    super.key,
    super.name,
    super.sourceBlock,
    super.fieldKey,
    super.initialValue = '',
  }) {
    addArgType('text');
  }

  @override
  BlockFieldState<BlockField> createState() =>
      _FieldTextInputRemovableBlockState();
}

class _FieldTextInputRemovableBlockState
    extends BlockFieldState<FieldTextInputRemovableBlock> {
  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FieldTextInputRemovable(
          initialValue: value,
          onChanged: (newValue) {
            setValue(newValue);
            widget.sourceBlock?.setFieldValue(widget.name, newValue);
          },
          onRemove: () {
            setValue('');
            widget.sourceBlock?.setFieldValue(widget.name, '');
          },
        ),
        const FieldVerticalSeparator(height: 24),
      ],
    );
  }
}

/// ------------------------
/// Text input field
/// ------------------------
class FieldTextInputBlock extends BlockField {
  FieldTextInputBlock({
    super.key,
    super.name,
    super.sourceBlock,
    super.fieldKey,
    super.initialValue = '',
  }) {
    addArgType('text');
  }

  @override
  BlockFieldState<BlockField> createState() => _FieldTextInputBlockState();
}

class _FieldTextInputBlockState extends BlockFieldState<FieldTextInputBlock> {
  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FieldTextInput(
          initialValue: value,
          onChanged: (newValue) {
            setValue(newValue);
            widget.sourceBlock?.setFieldValue(widget.name, newValue);
          },
        ),
        const FieldVerticalSeparator(height: 24),
      ],
    );
  }
}

/// ------------------------
/// Variable field
/// ------------------------
class FieldVariableBlock extends BlockField {
  final List<String> variables;

  FieldVariableBlock({
    super.key,
    super.name,
    super.sourceBlock,
    super.fieldKey,
    required this.variables,
    super.initialValue = '',
  }) {
    addArgType('variable');
  }

  @override
  BlockFieldState<BlockField> createState() => _FieldVariableBlockState();
}

class _FieldVariableBlockState extends BlockFieldState<FieldVariableBlock> {
  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FieldVariableGetter(
          initialName: value,
          availableVariables: widget.variables,
          onChanged: (newValue) {
            setValue(newValue);
            widget.sourceBlock?.setFieldValue(widget.name, newValue);
          },
        ),
        const FieldVerticalSeparator(height: 24),
      ],
    );
  }
}

/// ------------------------
/// XML compatibility model
/// ------------------------
class FieldModel {
  String name;
  String value;
  bool serializable;
  bool referencesVariable;
  String? variableId;
  String? variableType;

  FieldModel({
    required this.name,
    required this.value,
    this.serializable = true,
    this.referencesVariable = false,
    this.variableId,
    this.variableType,
  });
}
