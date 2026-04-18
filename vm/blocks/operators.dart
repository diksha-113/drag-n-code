// lib/blocks_vertical/operators.dart
//
// Direct Dart conversion of Scratch3OperatorsBlocks (operators.js)
// Logic preserved exactly, no modifications.

import 'dart:math' as math;
import '../util/cast.dart';
import '../util/math_util.dart';

class Scratch3OperatorsBlocks {
  final dynamic runtime;

  Scratch3OperatorsBlocks(this.runtime);

  // -------------------- Primitives --------------------
  Map<String, Function> getPrimitives() {
    return {
      'operator_add': add,
      'operator_subtract': subtract,
      'operator_multiply': multiply,
      'operator_divide': divide,
      'operator_lt': lt,
      'operator_equals': equals,
      'operator_gt': gt,
      'operator_and': and,
      'operator_or': or,
      'operator_not': not,
      'operator_random': random,
      'operator_join': join,
      'operator_letter_of': letterOf,
      'operator_length': length,
      'operator_contains': contains,
      'operator_mod': mod,
      'operator_round': round,
      'operator_mathop': mathop,
    };
  }

  // -------------------- Operator functions --------------------
  dynamic add(Map<String, dynamic> args) =>
      Cast.toNumber(args['NUM1']) + Cast.toNumber(args['NUM2']);

  dynamic subtract(Map<String, dynamic> args) =>
      Cast.toNumber(args['NUM1']) - Cast.toNumber(args['NUM2']);

  dynamic multiply(Map<String, dynamic> args) =>
      Cast.toNumber(args['NUM1']) * Cast.toNumber(args['NUM2']);

  dynamic divide(Map<String, dynamic> args) =>
      Cast.toNumber(args['NUM1']) / Cast.toNumber(args['NUM2']);

  dynamic lt(Map<String, dynamic> args) =>
      Cast.compare(args['OPERAND1'], args['OPERAND2']) < 0;

  dynamic equals(Map<String, dynamic> args) =>
      Cast.compare(args['OPERAND1'], args['OPERAND2']) == 0;

  dynamic gt(Map<String, dynamic> args) =>
      Cast.compare(args['OPERAND1'], args['OPERAND2']) > 0;

  dynamic and(Map<String, dynamic> args) =>
      Cast.toBoolean(args['OPERAND1']) && Cast.toBoolean(args['OPERAND2']);

  dynamic or(Map<String, dynamic> args) =>
      Cast.toBoolean(args['OPERAND1']) || Cast.toBoolean(args['OPERAND2']);

  dynamic not(Map<String, dynamic> args) => !Cast.toBoolean(args['OPERAND']);

  dynamic random(Map<String, dynamic> args) {
    final double nFrom = Cast.toNumber(args['FROM']);
    final double nTo = Cast.toNumber(args['TO']);
    final double low = nFrom <= nTo ? nFrom : nTo;
    final double high = nFrom <= nTo ? nTo : nFrom;

    if (low == high) return low;

    if (Cast.isInt(args['FROM']) && Cast.isInt(args['TO'])) {
      return MathUtil.randomInt(low.toInt(), high.toInt());
    }

    return MathUtil.randomDouble(low, high);
  }

  dynamic join(Map<String, dynamic> args) =>
      Cast.toStringValue(args['STRING1']) + Cast.toStringValue(args['STRING2']);

  dynamic letterOf(Map<String, dynamic> args) {
    final int index = Cast.toNumber(args['LETTER']).toInt() - 1;
    final String str = Cast.toStringValue(args['STRING']);
    if (index < 0 || index >= str.length) return '';
    return str[index];
  }

  dynamic length(Map<String, dynamic> args) =>
      Cast.toStringValue(args['STRING']).length;

  dynamic contains(Map<String, dynamic> args) {
    String format(dynamic val) => Cast.toStringValue(val).toLowerCase();
    return format(args['STRING1']).contains(format(args['STRING2']));
  }

  dynamic mod(Map<String, dynamic> args) {
    final num n = Cast.toNumber(args['NUM1']);
    final num modulus = Cast.toNumber(args['NUM2']);
    num result = n % modulus;
    if (result / modulus < 0) result += modulus;
    return result;
  }

  dynamic round(Map<String, dynamic> args) =>
      Cast.toNumber(args['NUM']).round();

  dynamic mathop(Map<String, dynamic> args) {
    final String operator = Cast.toStringValue(args['OPERATOR']).toLowerCase();
    final double n = Cast.toNumber(args['NUM']).toDouble();

    switch (operator) {
      case 'abs':
        return n.abs();
      case 'floor':
        return n.floor();
      case 'ceiling':
        return n.ceil();
      case 'sqrt':
        return math.sqrt(n);
      case 'sin':
        return double.parse((MathUtil.sinDeg(n)).toStringAsFixed(10));
      case 'cos':
        return double.parse((MathUtil.cosDeg(n)).toStringAsFixed(10));
      case 'tan':
        return MathUtil.tan(n);
      case 'asin':
        return MathUtil.asinDeg(n);
      case 'acos':
        return MathUtil.acosDeg(n);
      case 'atan':
        return MathUtil.atanDeg(n);
      case 'ln':
        return MathUtil.ln(n);
      case 'log':
        return MathUtil.log10(n);
      case 'e ^':
        return MathUtil.exp(n);
      case '10 ^':
        return MathUtil.pow10(n);
    }

    return 0;
  }

  // -------------------- Block metadata --------------------
  Map<String, Map<String, dynamic>> blockTypes = {
    'operator_add': {
      'blockType': 'reporter',
      'arguments': {'NUM1': 'number', 'NUM2': 'number'}
    },
    'operator_subtract': {
      'blockType': 'reporter',
      'arguments': {'NUM1': 'number', 'NUM2': 'number'}
    },
    'operator_multiply': {
      'blockType': 'reporter',
      'arguments': {'NUM1': 'number', 'NUM2': 'number'}
    },
    'operator_divide': {
      'blockType': 'reporter',
      'arguments': {'NUM1': 'number', 'NUM2': 'number'}
    },
    'operator_lt': {
      'blockType': 'boolean',
      'arguments': {'OPERAND1': 'any', 'OPERAND2': 'any'}
    },
    'operator_equals': {
      'blockType': 'boolean',
      'arguments': {'OPERAND1': 'any', 'OPERAND2': 'any'}
    },
    'operator_gt': {
      'blockType': 'boolean',
      'arguments': {'OPERAND1': 'any', 'OPERAND2': 'any'}
    },
    'operator_and': {
      'blockType': 'boolean',
      'arguments': {'OPERAND1': 'boolean', 'OPERAND2': 'boolean'}
    },
    'operator_or': {
      'blockType': 'boolean',
      'arguments': {'OPERAND1': 'boolean', 'OPERAND2': 'boolean'}
    },
    'operator_not': {
      'blockType': 'boolean',
      'arguments': {'OPERAND': 'boolean'}
    },
    'operator_random': {
      'blockType': 'reporter',
      'arguments': {'FROM': 'number', 'TO': 'number'}
    },
    'operator_join': {
      'blockType': 'reporter',
      'arguments': {'STRING1': 'string', 'STRING2': 'string'}
    },
    'operator_letter_of': {
      'blockType': 'reporter',
      'arguments': {'LETTER': 'number', 'STRING': 'string'}
    },
    'operator_length': {
      'blockType': 'reporter',
      'arguments': {'STRING': 'string'}
    },
    'operator_contains': {
      'blockType': 'boolean',
      'arguments': {'STRING1': 'string', 'STRING2': 'string'}
    },
    'operator_mod': {
      'blockType': 'reporter',
      'arguments': {'NUM1': 'number', 'NUM2': 'number'}
    },
    'operator_round': {
      'blockType': 'reporter',
      'arguments': {'NUM': 'number'}
    },
    'operator_mathop': {
      'blockType': 'reporter',
      'arguments': {'NUM': 'number', 'OPERATOR': 'string'}
    },
  };
}
