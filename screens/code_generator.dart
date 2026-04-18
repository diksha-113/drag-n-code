// lib/code_generator.dart
import 'editor_screen.dart';

enum CodeLanguage { dart, python, javascript, php, lua, xml, json }

String generateCodePreview(
    List<EditorBlock> workspaceBlocks, CodeLanguage lang) {
  final buffer = StringBuffer();

  // Header based on language
  switch (lang) {
    case CodeLanguage.dart:
      buffer.writeln('// Dart code preview\n');
      break;
    case CodeLanguage.python:
      buffer.writeln('# Python code preview\n');
      break;
    case CodeLanguage.javascript:
      buffer.writeln('// JavaScript code preview\n');
      break;
    case CodeLanguage.json:
      buffer.writeln('{\n  "blocks": [');
      break;
    case CodeLanguage.xml:
      buffer.writeln('<blocks>');
      break;
    default:
      buffer.writeln('// Code preview\n');
  }

  for (int i = 0; i < workspaceBlocks.length; i++) {
    final block = workspaceBlocks[i];
    buffer.writeln(_blockToCode(block, lang, 0));
    if ((lang == CodeLanguage.json) && (i != workspaceBlocks.length - 1)) {
      buffer.writeln(',');
    }
  }

  if (lang == CodeLanguage.json) buffer.writeln('  ]\n}');
  if (lang == CodeLanguage.xml) buffer.writeln('</blocks>');

  return buffer.toString();
}

// ================= BLOCK TO CODE =================

String _blockToCode(EditorBlock block, CodeLanguage lang, int indentLevel) {
  final indent = '  ' * indentLevel;
  String codeLine = '';
  final value = block.value ?? '';

  switch (block.type) {
    // ===== Motion =====
    case 'motion_movesteps':
      codeLine =
          _langLine(lang, '${indent}move(${value.isNotEmpty ? value : "10"})');
      break;
    case 'motion_turnright':
      codeLine = _langLine(
          lang, '${indent}turnRight(${value.isNotEmpty ? value : "15"})');
      break;
    case 'motion_turnleft':
      codeLine = _langLine(
          lang, '${indent}turnLeft(${value.isNotEmpty ? value : "15"})');
      break;
    case 'motion_goto':
      codeLine = _langLine(lang,
          '${indent}goTo(${value.isNotEmpty ? value : "0"}, ${value.isNotEmpty ? value : "0"})');
      break;
    case 'motion_glideto':
      codeLine = _langLine(lang,
          '${indent}glide(${value.isNotEmpty ? value : "1"}s, ${value.isNotEmpty ? value : "0"}, ${value.isNotEmpty ? value : "0"})');
      break;

    // ===== Looks =====
    case 'looks_say':
      codeLine =
          _langLine(lang, '${indent}say("${value.isNotEmpty ? value : ""}")');
      break;
    case 'looks_think':
      codeLine =
          _langLine(lang, '${indent}think("${value.isNotEmpty ? value : ""}")');
      break;
    case 'looks_show':
      codeLine = _langLine(lang, '${indent}show()');
      break;
    case 'looks_hide':
      codeLine = _langLine(lang, '${indent}hide()');
      break;
    case 'looks_switchbackdrop':
      codeLine = _langLine(
          lang, '${indent}switchBackdrop("${value.isNotEmpty ? value : ""}")');
      break;

    // ===== Sound =====
    case 'sound_play':
      codeLine = _langLine(
          lang, '${indent}playSound("${value.isNotEmpty ? value : ""}")');
      break;
    case 'sound_stopallsounds':
      codeLine = _langLine(lang, '${indent}stopAllSounds()');
      break;
    case 'sound_changevolume':
      codeLine = _langLine(
          lang, '${indent}changeVolume(${value.isNotEmpty ? value : "10"})');
      break;

    // ===== Control =====
    case 'control_repeat':
      codeLine =
          _openBlock(lang, indent, 'repeat ${value.isNotEmpty ? value : "10"}');
      codeLine += _childrenCode(block, lang, indentLevel + 1);
      codeLine += _closeBlock(lang, indent);
      break;
    case 'control_forever':
      codeLine = _openBlock(lang, indent, 'forever');
      codeLine += _childrenCode(block, lang, indentLevel + 1);
      codeLine += _closeBlock(lang, indent);
      break;
    case 'control_if':
      codeLine =
          _openBlock(lang, indent, 'if ${value.isNotEmpty ? value : "true"}');
      codeLine += _childrenCode(block, lang, indentLevel + 1);
      codeLine += _closeBlock(lang, indent);
      break;
    case 'control_if_else':
      codeLine =
          _openBlock(lang, indent, 'if ${value.isNotEmpty ? value : "true"}');
      codeLine += _childrenCode(block, lang, indentLevel + 1);
      codeLine += _closeBlock(lang, indent);
      codeLine += '\n${indent}// else { ... }';
      break;
    case 'control_wait':
      codeLine =
          _langLine(lang, '${indent}wait(${value.isNotEmpty ? value : "1"})');
      break;

    // ===== Events =====
    case 'event_whenflagclicked':
      codeLine = _openBlock(lang, indent, 'onStart');
      codeLine += _childrenCode(block, lang, indentLevel + 1);
      codeLine += _closeBlock(lang, indent);
      break;
    case 'event_broadcast':
      codeLine = _langLine(
          lang, '${indent}broadcast("${value.isNotEmpty ? value : ""}")');
      break;

    // ===== Operators =====
    case 'operator_add':
      codeLine = _langLine(lang,
          '${indent}${value.isNotEmpty ? value : "0"} + ${value.isNotEmpty ? value : "0"}');
      break;
    case 'operator_subtract':
      codeLine = _langLine(lang,
          '${indent}${value.isNotEmpty ? value : "0"} - ${value.isNotEmpty ? value : "0"}');
      break;
    case 'operator_multiply':
      codeLine = _langLine(lang,
          '${indent}${value.isNotEmpty ? value : "0"} * ${value.isNotEmpty ? value : "0"}');
      break;
    case 'operator_divide':
      codeLine = _langLine(lang,
          '${indent}${value.isNotEmpty ? value : "0"} / ${value.isNotEmpty ? value : "1"}');
      break;

    // ===== Variables =====
    case 'data_setvariableto':
      codeLine = _langLine(lang,
          '${indent}set ${value.isNotEmpty ? value : "variable"} = ${value.isNotEmpty ? value : "0"}');
      break;
    case 'data_changevariableby':
      codeLine = _langLine(lang,
          '${indent}change ${value.isNotEmpty ? value : "variable"} by ${value.isNotEmpty ? value : "1"}');
      break;

    // ===== Notes / Unknown =====
    default:
      codeLine = block.isNote
          ? '${indent}// NOTE: ${block.noteText ?? ""}'
          : '${indent}// ${block.label}';
  }

  // Add stacked/next blocks
  if (block.next != null) {
    codeLine += '\n' + _blockToCode(block.next!, lang, indentLevel);
  }

  return codeLine;
}

// ================= CHILDREN =================

String _childrenCode(EditorBlock block, CodeLanguage lang, int indentLevel) {
  final buffer = StringBuffer();
  for (final child in block.children) {
    buffer.writeln(_blockToCode(child, lang, indentLevel));
  }
  return buffer.toString();
}

// ================= OPEN / CLOSE BLOCK =================

String _openBlock(CodeLanguage lang, String indent, String header) {
  switch (lang) {
    case CodeLanguage.python:
      return '$indent$header:\n';
    default:
      return '$indent$header {\n';
  }
}

String _closeBlock(CodeLanguage lang, String indent) {
  switch (lang) {
    case CodeLanguage.python:
      return '';
    default:
      return '$indent}';
  }
}

// ================= LANGUAGE LINE =================

String _langLine(CodeLanguage lang, String line) {
  switch (lang) {
    case CodeLanguage.python:
    case CodeLanguage.lua:
      return line;
    case CodeLanguage.json:
      return '    { "code": "${line.replaceAll("\"", "\\\"")}" }';
    case CodeLanguage.xml:
      return '<block>${line.trim()}</block>';
    default:
      return '$line;';
  }
}
