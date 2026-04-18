import '../models/block_model.dart';

List<BlockModel> operatorBlocks() {
  return [
    BlockModel(
      id: 'operator_add',
      type: BlockInputType.outputNumber.name,
      message: '%1 + %2',
      args: [
        {'type': 'inputValue', 'name': 'NUM1'},
        {'type': 'inputValue', 'name': 'NUM2'},
      ],
      category: 'operators',
      shape: ScratchBlockShape.stack,
    ),
    BlockModel(
      id: 'operator_subtract',
      type: BlockInputType.outputNumber.name,
      message: '%1 - %2',
      args: [
        {'type': 'inputValue', 'name': 'NUM1'},
        {'type': 'inputValue', 'name': 'NUM2'},
      ],
      category: 'operators',
      shape: ScratchBlockShape.stack,
    ),
    BlockModel(
      id: 'operator_multiply',
      type: BlockInputType.outputNumber.name,
      message: '%1 * %2',
      args: [
        {'type': 'inputValue', 'name': 'NUM1'},
        {'type': 'inputValue', 'name': 'NUM2'},
      ],
      category: 'operators',
      shape: ScratchBlockShape.stack,
    ),
    BlockModel(
      id: 'operator_divide',
      type: BlockInputType.outputNumber.name,
      message: '%1 / %2',
      args: [
        {'type': 'inputValue', 'name': 'NUM1'},
        {'type': 'inputValue', 'name': 'NUM2'},
      ],
      category: 'operators',
      shape: ScratchBlockShape.stack,
    ),
    BlockModel(
      id: 'operator_random',
      type: BlockInputType.outputNumber.name,
      message: 'pick random %1 to %2',
      args: [
        {'type': 'inputValue', 'name': 'FROM'},
        {'type': 'inputValue', 'name': 'TO'},
      ],
      category: 'operators',
      shape: ScratchBlockShape.stack,
    ),
    BlockModel(
      id: 'operator_lt',
      type: BlockInputType.outputBoolean.name,
      message: '%1 < %2',
      args: [
        {'type': 'inputValue', 'name': 'OPERAND1'},
        {'type': 'inputValue', 'name': 'OPERAND2'},
      ],
      category: 'operators',
      shape: ScratchBlockShape.stack,
    ),
    BlockModel(
      id: 'operator_equals',
      type: BlockInputType.outputBoolean.name,
      message: '%1 = %2',
      args: [
        {'type': 'inputValue', 'name': 'OPERAND1'},
        {'type': 'inputValue', 'name': 'OPERAND2'},
      ],
      category: 'operators',
      shape: ScratchBlockShape.stack,
    ),
    BlockModel(
      id: 'operator_gt',
      type: BlockInputType.outputBoolean.name,
      message: '%1 > %2',
      args: [
        {'type': 'inputValue', 'name': 'OPERAND1'},
        {'type': 'inputValue', 'name': 'OPERAND2'},
      ],
      category: 'operators',
      shape: ScratchBlockShape.stack,
    ),
    BlockModel(
      id: 'operator_and',
      type: BlockInputType.outputBoolean.name,
      message: '%1 and %2',
      args: [
        {'type': 'inputValue', 'name': 'OPERAND1', 'check': 'Boolean'},
        {'type': 'inputValue', 'name': 'OPERAND2', 'check': 'Boolean'},
      ],
      category: 'operators',
      shape: ScratchBlockShape.stack,
    ),
    BlockModel(
      id: 'operator_or',
      type: BlockInputType.outputBoolean.name,
      message: '%1 or %2',
      args: [
        {'type': 'inputValue', 'name': 'OPERAND1', 'check': 'Boolean'},
        {'type': 'inputValue', 'name': 'OPERAND2', 'check': 'Boolean'},
      ],
      category: 'operators',
      shape: ScratchBlockShape.stack,
    ),
    BlockModel(
      id: 'operator_not',
      type: BlockInputType.outputBoolean.name,
      message: 'not %1',
      args: [
        {'type': 'inputValue', 'name': 'OPERAND', 'check': 'Boolean'},
      ],
      category: 'operators',
      shape: ScratchBlockShape.stack,
    ),
    BlockModel(
      id: 'operator_join',
      type: BlockInputType.outputString.name,
      message: 'join %1 %2',
      args: [
        {'type': 'inputValue', 'name': 'STRING1'},
        {'type': 'inputValue', 'name': 'STRING2'},
      ],
      category: 'operators',
      shape: ScratchBlockShape.stack,
    ),
    BlockModel(
      id: 'operator_letter_of',
      type: BlockInputType.outputString.name,
      message: 'letter %1 of %2',
      args: [
        {'type': 'inputValue', 'name': 'LETTER'},
        {'type': 'inputValue', 'name': 'STRING'},
      ],
      category: 'operators',
      shape: ScratchBlockShape.stack,
    ),
    BlockModel(
      id: 'operator_length',
      type: BlockInputType.outputNumber.name,
      message: 'length of %1',
      args: [
        {'type': 'inputValue', 'name': 'STRING'},
      ],
      category: 'operators',
      shape: ScratchBlockShape.stack,
    ),
    BlockModel(
      id: 'operator_contains',
      type: BlockInputType.outputBoolean.name,
      message: '%1 contains %2',
      args: [
        {'type': 'inputValue', 'name': 'STRING1'},
        {'type': 'inputValue', 'name': 'STRING2'},
      ],
      category: 'operators',
      shape: ScratchBlockShape.stack,
    ),
    BlockModel(
      id: 'operator_mod',
      type: BlockInputType.outputNumber.name,
      message: '%1 mod %2',
      args: [
        {'type': 'inputValue', 'name': 'NUM1'},
        {'type': 'inputValue', 'name': 'NUM2'},
      ],
      category: 'operators',
      shape: ScratchBlockShape.stack,
    ),
    BlockModel(
      id: 'operator_round',
      type: BlockInputType.outputNumber.name,
      message: 'round %1',
      args: [
        {'type': 'inputValue', 'name': 'NUM'},
      ],
      category: 'operators',
      shape: ScratchBlockShape.stack,
    ),
    BlockModel(
      id: 'operator_mathop',
      type: BlockInputType.outputNumber.name,
      message: '%1 of %2',
      args: [
        {
          'type': 'fieldDropdown',
          'name': 'OPERATOR',
          'options': [
            ['abs', 'abs'],
            ['floor', 'floor'],
            ['ceiling', 'ceiling'],
            ['sqrt', 'sqrt'],
            ['sin', 'sin'],
            ['cos', 'cos'],
            ['tan', 'tan'],
            ['asin', 'asin'],
            ['acos', 'acos'],
            ['atan', 'atan'],
            ['ln', 'ln'],
            ['log', 'log'],
            ['e ^', 'e ^'],
            ['10 ^', '10 ^'],
          ],
        },
        {'type': 'inputValue', 'name': 'NUM'},
      ],
      category: 'operators',
      shape: ScratchBlockShape.stack,
    ),
  ];
}
