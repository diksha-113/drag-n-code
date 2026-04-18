import '../models/block_model.dart';
import '../constants/colors.dart';

class BlocklyBlocksControl {
  /// Block for repeat forever
  static BlockModel controlForever() {
    return BlockModel(
      id: 'control_forever',
      name: 'Forever',
      category: 'control',
      color: AppColors.controlPrimary,
      inputType: BlockInputType.statement,
      icon: 'assets/icons/repeat.svg',
      shape: ScratchBlockShape.stack,
    );
  }

  /// Block for repeat n times
  static BlockModel controlRepeat() {
    return BlockModel(
      id: 'control_repeat',
      name: 'Repeat',
      category: 'control',
      color: AppColors.controlPrimary,
      inputType: BlockInputType.statement,
      icon: 'assets/icons/repeat.svg',
      inputFields: ['TIMES'],
      shape: ScratchBlockShape.stack,
    );
  }

  /// Block for if-then
  static BlockModel controlIf() {
    return BlockModel(
      id: 'control_if',
      name: 'If',
      category: 'control',
      color: AppColors.controlPrimary,
      inputType: BlockInputType.statement,
      inputFields: ['CONDITION'],
      shape: ScratchBlockShape.stack,
    );
  }

  /// Block for if-else
  static BlockModel controlIfElse() {
    return BlockModel(
      id: 'control_if_else',
      name: 'If-Else',
      category: 'control',
      color: AppColors.controlPrimary,
      inputType: BlockInputType.statement,
      inputFields: ['CONDITION', 'SUBSTACK', 'SUBSTACK2'],
      shape: ScratchBlockShape.stack,
    );
  }

  /// Block to stop scripts
  static BlockModel controlStop() {
    return BlockModel(
      id: 'control_stop',
      name: 'Stop',
      category: 'control',
      color: AppColors.controlPrimary,
      inputType: BlockInputType.statement,
      inputFields: ['STOP_OPTION'], // 🔥 REQUIRED
      dropdownOptions: ['all', 'this script', 'other scripts in sprite'],
      shape: ScratchBlockShape.stack,
    );
  }

  /// Block to wait
  static BlockModel controlWait() {
    return BlockModel(
      id: 'control_wait',
      name: 'Wait',
      category: 'control',
      color: AppColors.controlPrimary,
      inputType: BlockInputType.statement,
      inputFields: ['DURATION'],
      shape: ScratchBlockShape.stack,
    );
  }

  /// Block to wait until
  static BlockModel controlWaitUntil() {
    return BlockModel(
      id: 'control_wait_until',
      name: 'Wait Until',
      category: 'control',
      color: AppColors.controlPrimary,
      inputType: BlockInputType.statement,
      inputFields: ['CONDITION'],
      shape: ScratchBlockShape.stack,
    );
  }

  /// Block to repeat until
  static BlockModel controlRepeatUntil() {
    return BlockModel(
      id: 'control_repeat_until',
      name: 'Repeat Until',
      category: 'control',
      color: AppColors.controlPrimary,
      inputType: BlockInputType.statement,
      inputFields: ['CONDITION'],
      icon: 'assets/icons/repeat.svg',
      shape: ScratchBlockShape.stack,
    );
  }

  /// Block to repeat while
  static BlockModel controlWhile() {
    return BlockModel(
      id: 'control_while',
      name: 'While',
      category: 'control',
      color: AppColors.controlPrimary,
      inputType: BlockInputType.statement,
      inputFields: ['CONDITION'],
      icon: 'assets/icons/repeat.svg',
      shape: ScratchBlockShape.stack,
    );
  }

  /// Block for start as clone hat
  static BlockModel controlStartAsClone() {
    return BlockModel(
      id: 'control_start_as_clone',
      name: 'When I start as clone',
      category: 'control',
      color: AppColors.controlPrimary,
      inputType: BlockInputType.hat,
      shape: ScratchBlockShape.stack,
    );
  }

  /// Block for delete this clone
  static BlockModel controlDeleteThisClone() {
    return BlockModel(
      id: 'control_delete_this_clone',
      name: 'Delete this clone',
      category: 'control',
      color: AppColors.controlPrimary,
      inputType: BlockInputType.end,
      shape: ScratchBlockShape.stack,
    );
  }

  /// Block for get counter
  static BlockModel controlGetCounter() {
    return BlockModel(
      id: 'control_get_counter',
      name: 'Get Counter',
      category: 'control',
      color: AppColors.controlPrimary,
      inputType: BlockInputType.outputNumber,
      shape: ScratchBlockShape.stack,
    );
  }

  /// Block to increment counter
  static BlockModel controlIncrCounter() {
    return BlockModel(
      id: 'control_incr_counter',
      name: 'Increment Counter',
      category: 'control',
      color: AppColors.controlPrimary,
      inputType: BlockInputType.statement,
      shape: ScratchBlockShape.stack,
    );
  }

  /// Block to clear counter
  static BlockModel controlClearCounter() {
    return BlockModel(
      id: 'control_clear_counter',
      name: 'Clear Counter',
      category: 'control',
      color: AppColors.controlPrimary,
      inputType: BlockInputType.statement,
      shape: ScratchBlockShape.stack,
    );
  }

  /// Block to run all at once
  static BlockModel controlAllAtOnce() {
    return BlockModel(
      id: 'control_all_at_once',
      name: 'All At Once',
      category: 'control',
      color: AppColors.controlPrimary,
      inputType: BlockInputType.statement,
      shape: ScratchBlockShape.stack,
    );
  }
}

/// Exported list of control blocks for toolbox
final List<BlockModel> controlBlocks = [
  BlocklyBlocksControl.controlForever(),
  BlocklyBlocksControl.controlRepeat(),
  BlocklyBlocksControl.controlIf(),
  BlocklyBlocksControl.controlIfElse(),
  BlocklyBlocksControl.controlStop(),
  BlocklyBlocksControl.controlWait(),
  BlocklyBlocksControl.controlWaitUntil(),
  BlocklyBlocksControl.controlRepeatUntil(),
  BlocklyBlocksControl.controlWhile(),
  BlocklyBlocksControl.controlStartAsClone(),
  BlocklyBlocksControl.controlDeleteThisClone(),
  BlocklyBlocksControl.controlGetCounter(),
  BlocklyBlocksControl.controlIncrCounter(),
  BlocklyBlocksControl.controlClearCounter(),
  BlocklyBlocksControl.controlAllAtOnce(),
];
