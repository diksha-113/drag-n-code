import '../models/block_model.dart';
import '../constants/colors.dart';

class BlocklyBlocksData {
  /// Variable getter block
  static BlockModel dataVariable() {
    return BlockModel(
      id: 'data_variable',
      name: 'Variable',
      category: 'data',
      color: AppColors.dataPrimary,
      inputType: BlockInputType.outputString,
      args: [
        {'type': 'field_variable_getter', 'name': 'VARIABLE', 'text': ''}
      ],
      extensions: [
        'contextMenu_getVariableBlock',
        'colours_data',
        'output_string'
      ],
      lastDummyAlign: 'CENTRE',
      checkboxInFlyout: true,
      shape: ScratchBlockShape.stack,
    );
  }

  /// Set variable block
  static BlockModel dataSetVariableTo() {
    return BlockModel(
      id: 'data_setvariableto',
      name: 'Set Variable To',
      category: 'data',
      color: AppColors.dataPrimary,
      inputType: BlockInputType.statement,
      args: [
        {'type': 'field_variable', 'name': 'VARIABLE'},
        {'type': 'input_value', 'name': 'VALUE'}
      ],
      extensions: ['colours_data', 'shape_statement'],
      shape: ScratchBlockShape.stack,
    );
  }

  /// Change variable by block
  static BlockModel dataChangeVariableBy() {
    return BlockModel(
      id: 'data_changevariableby',
      name: 'Change Variable By',
      category: 'data',
      color: AppColors.dataPrimary,
      inputType: BlockInputType.statement,
      args: [
        {'type': 'field_variable', 'name': 'VARIABLE'},
        {'type': 'input_value', 'name': 'VALUE'}
      ],
      extensions: ['colours_data', 'shape_statement'],
      shape: ScratchBlockShape.stack,
    );
  }

  /// Show variable block
  static BlockModel dataShowVariable() {
    return BlockModel(
      id: 'data_showvariable',
      name: 'Show Variable',
      category: 'data',
      color: AppColors.dataPrimary,
      inputType: BlockInputType.statement,
      args: [
        {'type': 'field_variable', 'name': 'VARIABLE'}
      ],
      extensions: ['colours_data'],
      previousStatement: true,
      nextStatement: true,
      shape: ScratchBlockShape.stack,
    );
  }

  /// Hide variable block
  static BlockModel dataHideVariable() {
    return BlockModel(
      id: 'data_hidevariable',
      name: 'Hide Variable',
      category: 'data',
      color: AppColors.dataPrimary,
      inputType: BlockInputType.statement,
      args: [
        {'type': 'field_variable', 'name': 'VARIABLE'}
      ],
      extensions: ['colours_data'],
      previousStatement: true,
      nextStatement: true,
      shape: ScratchBlockShape.stack,
    );
  }

  /// List contents block
  static BlockModel dataListContents() {
    return BlockModel(
      id: 'data_listcontents',
      name: 'List Contents',
      category: 'dataLists',
      color: AppColors.dataLists,
      inputType: BlockInputType.outputString,
      args: [
        {
          'type': 'field_variable_getter',
          'name': 'LIST',
          'text': '',
          'variableType': 'list'
        }
      ],
      extensions: [
        'contextMenu_getListBlock',
        'colours_data_lists',
        'output_string'
      ],
      checkboxInFlyout: true,
      shape: ScratchBlockShape.stack,
    );
  }

  /// List index all block
  static BlockModel dataListIndexAll() {
    return BlockModel(
      id: 'data_listindexall',
      name: 'List Index All',
      category: 'data',
      color: AppColors.dataPrimary,
      inputType: BlockInputType.outputString,
      args: [
        {
          'type': 'field_numberdropdown',
          'name': 'INDEX',
          'value': '1',
          'min': 1,
          'precision': 1,
          'options': [
            ['1', '1'],
            ['last', 'last'],
            ['all', 'all']
          ]
        }
      ],
      extensions: ['colours_textfield', 'output_string'],
      shape: ScratchBlockShape.stack,
    );
  }

  /// List index random block
  static BlockModel dataListIndexRandom() {
    return BlockModel(
      id: 'data_listindexrandom',
      name: 'List Index Random',
      category: 'data',
      color: AppColors.dataPrimary,
      inputType: BlockInputType.outputString,
      args: [
        {
          'type': 'field_numberdropdown',
          'name': 'INDEX',
          'value': '1',
          'min': 1,
          'precision': 1,
          'options': [
            ['1', '1'],
            ['last', 'last'],
            ['random', 'random']
          ]
        }
      ],
      extensions: ['colours_textfield', 'output_string'],
      shape: ScratchBlockShape.stack,
    );
  }

  /// Add item to list block
  static BlockModel dataAddToList() {
    return BlockModel(
      id: 'data_addtolist',
      name: 'Add To List',
      category: 'dataLists',
      color: AppColors.dataLists,
      inputType: BlockInputType.statement,
      args: [
        {'type': 'input_value', 'name': 'ITEM'},
        {
          'type': 'field_variable',
          'name': 'LIST',
          'variableTypes': ['list']
        }
      ],
      extensions: ['colours_data_lists', 'shape_statement'],
      shape: ScratchBlockShape.stack,
    );
  }

  /// Delete item of list block
  static BlockModel dataDeleteOfList() {
    return BlockModel(
      id: 'data_deleteoflist',
      name: 'Delete Of List',
      category: 'dataLists',
      color: AppColors.dataLists,
      inputType: BlockInputType.statement,
      args: [
        {'type': 'input_value', 'name': 'INDEX'},
        {
          'type': 'field_variable',
          'name': 'LIST',
          'variableTypes': ['list']
        }
      ],
      extensions: ['colours_data_lists', 'shape_statement'],
      shape: ScratchBlockShape.stack,
    );
  }

  /// Delete all of list block
  static BlockModel dataDeleteAllOfList() {
    return BlockModel(
      id: 'data_deletealloflist',
      name: 'Delete All Of List',
      category: 'dataLists',
      color: AppColors.dataLists,
      inputType: BlockInputType.statement,
      args: [
        {
          'type': 'field_variable',
          'name': 'LIST',
          'variableTypes': ['list']
        }
      ],
      extensions: ['colours_data_lists', 'shape_statement'],
      shape: ScratchBlockShape.stack,
    );
  }

  /// Insert at list block
  static BlockModel dataInsertAtList() {
    return BlockModel(
      id: 'data_insertatlist',
      name: 'Insert At List',
      category: 'dataLists',
      color: AppColors.dataLists,
      inputType: BlockInputType.statement,
      args: [
        {'type': 'input_value', 'name': 'ITEM'},
        {'type': 'input_value', 'name': 'INDEX'},
        {
          'type': 'field_variable',
          'name': 'LIST',
          'variableTypes': ['list']
        }
      ],
      extensions: ['colours_data_lists', 'shape_statement'],
      shape: ScratchBlockShape.stack,
    );
  }

  /// Replace item of list block
  static BlockModel dataReplaceItemOfList() {
    return BlockModel(
      id: 'data_replaceitemoflist',
      name: 'Replace Item Of List',
      category: 'dataLists',
      color: AppColors.dataLists,
      inputType: BlockInputType.statement,
      args: [
        {'type': 'input_value', 'name': 'INDEX'},
        {
          'type': 'field_variable',
          'name': 'LIST',
          'variableTypes': ['list']
        },
        {'type': 'input_value', 'name': 'ITEM'}
      ],
      extensions: ['colours_data_lists', 'shape_statement'],
      shape: ScratchBlockShape.stack,
    );
  }

  /// Item of list reporter
  static BlockModel dataItemOfList() {
    return BlockModel(
      id: 'data_itemoflist',
      name: 'Item Of List',
      category: 'dataLists',
      color: AppColors.dataLists,
      inputType: BlockInputType.outputString,
      args: [
        {'type': 'input_value', 'name': 'INDEX'},
        {
          'type': 'field_variable',
          'name': 'LIST',
          'variableTypes': ['list']
        }
      ],
      extensions: ['colours_data_lists'],
      outputShape: BlockOutputShape.round,
      shape: ScratchBlockShape.stack,
    );
  }

  /// Item number of list
  static BlockModel dataItemNumOfList() {
    return BlockModel(
      id: 'data_itemnumoflist',
      name: 'Item Number Of List',
      category: 'dataLists',
      color: AppColors.dataLists,
      inputType: BlockInputType.outputNumber,
      args: [
        {'type': 'input_value', 'name': 'ITEM'},
        {
          'type': 'field_variable',
          'name': 'LIST',
          'variableTypes': ['list']
        }
      ],
      extensions: ['colours_data_lists'],
      outputShape: BlockOutputShape.round,
      shape: ScratchBlockShape.stack,
    );
  }

  /// Length of list
  static BlockModel dataLengthOfList() {
    return BlockModel(
      id: 'data_lengthoflist',
      name: 'Length Of List',
      category: 'dataLists',
      color: AppColors.dataLists,
      inputType: BlockInputType.outputNumber,
      args: [
        {
          'type': 'field_variable',
          'name': 'LIST',
          'variableTypes': ['list']
        }
      ],
      extensions: ['colours_data_lists', 'output_number'],
      shape: ScratchBlockShape.stack,
    );
  }

  /// List contains item
  static BlockModel dataListContainsItem() {
    return BlockModel(
      id: 'data_listcontainsitem',
      name: 'List Contains Item',
      category: 'dataLists',
      color: AppColors.dataLists,
      inputType: BlockInputType.outputBoolean,
      args: [
        {
          'type': 'field_variable',
          'name': 'LIST',
          'variableTypes': ['list']
        },
        {'type': 'input_value', 'name': 'ITEM'}
      ],
      extensions: ['colours_data_lists', 'output_boolean'],
      shape: ScratchBlockShape.stack,
    );
  }

  /// Show list
  static BlockModel dataShowList() {
    return BlockModel(
      id: 'data_showlist',
      name: 'Show List',
      category: 'dataLists',
      color: AppColors.dataLists,
      inputType: BlockInputType.statement,
      args: [
        {
          'type': 'field_variable',
          'name': 'LIST',
          'variableTypes': ['list']
        }
      ],
      extensions: ['colours_data_lists', 'shape_statement'],
      shape: ScratchBlockShape.stack,
    );
  }

  /// Hide list
  static BlockModel dataHideList() {
    return BlockModel(
      id: 'data_hidelist',
      name: 'Hide List',
      category: 'dataLists',
      color: AppColors.dataLists,
      inputType: BlockInputType.statement,
      args: [
        {
          'type': 'field_variable',
          'name': 'LIST',
          'variableTypes': ['list']
        }
      ],
      extensions: ['colours_data_lists', 'shape_statement'],
      shape: ScratchBlockShape.stack,
    );
  }

  /// ------------------ ALL BLOCKS ------------------
  /// Returns all data blocks as a list
  static List<BlockModel> allBlocks() {
    return [
      dataVariable(),
      dataSetVariableTo(),
      dataChangeVariableBy(),
      dataShowVariable(),
      dataHideVariable(),
      dataListContents(),
      dataListIndexAll(),
      dataListIndexRandom(),
      dataAddToList(),
      dataDeleteOfList(),
      dataDeleteAllOfList(),
      dataInsertAtList(),
      dataReplaceItemOfList(),
      dataItemOfList(),
      dataItemNumOfList(),
      dataLengthOfList(),
      dataListContainsItem(),
      dataShowList(),
      dataHideList(),
    ];
  }
}
