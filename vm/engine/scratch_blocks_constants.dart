// lib/vm/engine/scratch_blocks_constants.dart
import 'dart:core';

/// ---------------------------
/// Scratch Block Constants
/// ---------------------------

// Event block types
const String EVENT_WHEN_FLAG_CLICKED = 'event_whenflagclicked';
const String EVENT_WHEN_I_RECEIVE = 'event_whenIReceive';

// Control block colors (example)
const int BLOCK_COLOR_CONTROL = 120;
const int BLOCK_COLOR_MOTION = 230;
const int BLOCK_COLOR_SOUND = 260;
const int BLOCK_COLOR_EVENTS = 40;
const int BLOCK_COLOR_OPERATORS = 210;
const int BLOCK_COLOR_SENSING = 180;
const int BLOCK_COLOR_PROCEDURES = 290;

// Common opcodes
const String OPCODE_PROCEDURES_CALL = 'procedures_call';
const String OPCODE_PROCEDURES_DEFNORETURN = 'procedures_defnoreturn';
const String OPCODE_PROCEDURES_DEFRETURN = 'procedures_defreturn';

// Input types
const String INPUT_NUMBER = 'number';
const String INPUT_STRING = 'string';
const String INPUT_BOOLEAN = 'boolean';

// Direction constants
const double DIRECTION_DEFAULT = 90.0;
const double SIZE_DEFAULT = 100.0;

// Stage dimensions
const int STAGE_WIDTH = 480;
const int STAGE_HEIGHT = 360;

// Misc
const String DEFAULT_COSTUME = 'costume1';
