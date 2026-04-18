import 'package:flutter/material.dart';

class AppColors {
  // Control blocks
  static const Color controlPrimary = Color(0xFFFFAB19);
  static const Color controlSecondary = Color(0xFFFFC966);
  static const Color controlTertiary = Color(0xFFFFD999);
  static const Color controlQuaternary = Color(0xFFFFECCC);
  static const Color controlPrimaryDark = Color(0xFFD18E00); // dark variant

  // Data blocks (variables)
  static const Color dataPrimary = Color(0xFFFF8C1A);
  static const Color dataSecondary = Color(0xFFFFB266);
  static const Color dataTertiary = Color(0xFFFFCC99);
  static const Color dataQuaternary = Color(0xFFFFE0CC);

  // Data lists blocks
  static const Color dataLists = Color(0xFFFF661A);
  static const Color dataListsSecondary = Color(0xFFFF9966);
  static const Color dataListsTertiary = Color(0xFFFFB399);
  static const Color dataListsQuaternary = Color(0xFFFFCCB3);

  // Sound blocks
  static const Color soundPrimary = Color(0xFFFF6680);
  static const Color soundSecondary = Color(0xFFFF99A3);
  static const Color soundTertiary = Color(0xFFFFB3B3);
  static const Color soundQuaternary = Color(0xFFFFCCCC);

  // Motion blocks
  static const Color motionPrimary = Color(0xFF4C97FF);
  static const Color motionSecondary = Color(0xFF66B2FF);
  static const Color motionTertiary = Color(0xFF99CCFF);
  static const Color motionQuaternary = Color(0xFFCCE5FF);

  // Looks blocks
  static const Color looksPrimary = Color(0xFF9966FF);
  static const Color looksSecondary = Color(0xFFB399FF);
  static const Color looksTertiary = Color(0xFFCCB3FF);
  static const Color looksQuaternary = Color(0xFFE6CCFF);

  // Event blocks
  static const Color eventPrimary = Color(0xFFFFBF00);
  static const Color eventSecondary = Color(0xFFFFD966);
  static const Color eventTertiary = Color(0xFFFFEB99);
  static const Color eventQuaternary = Color(0xFFFFF2CC);

  // Sensing blocks
  static const Color sensingPrimary = Color(0xFF5CB1D6);
  static const Color sensingSecondary = Color(0xFF7FC6E0);
  static const Color sensingTertiary = Color(0xFF99D9EA);
  static const Color sensingQuaternary = Color(0xFFCCEAF4);

  // Operators blocks
  static const Color operatorsPrimary = Color(0xFF59C059);
  static const Color operatorsSecondary = Color(0xFF80D680);
  static const Color operatorsTertiary = Color(0xFF99E699);
  static const Color operatorsQuaternary = Color(0xFFCCF2CC);

  // Pen blocks
  static const Color penPrimary = Color(0xFF0FBD8C);
  static const Color penSecondary = Color(0xFF19CDAA);
  static const Color penTertiary = Color(0xFF66E0C0);
  static const Color penQuaternary = Color(0xFFCCF2E6);

  // TextField blocks (all same color)
  static const Color textField = Color(0xFFFFFFFF);

  // More category (custom extensions)
  static const Color morePrimary = Color(0xFF999999);
  static const Color moreSecondary = Color(0xFFB3B3B3);
  static const Color moreTertiary = Color(0xFFCCCCCC);
  static const Color moreQuaternary = Color(0xFFE6E6E6);
}

/// ----------------------------
/// BlocklyColours map for CSS
/// ----------------------------
class BlocklyColours {
  static Map<String, String> coloursMap = {
    'workspace': '#FFFFFF',
    'controlPrimary': '#FFAB19',
    'controlSecondary': '#FFC966',
    'controlTertiary': '#FFD999',
    'controlQuaternary': '#FFECCC',
    'dataPrimary': '#FF8C1A',
    'dataSecondary': '#FFB266',
    'dataTertiary': '#FFCC99',
    'dataQuaternary': '#FFE0CC',
    'dataLists': '#FF661A',
    'dataListsSecondary': '#FF9966',
    'dataListsTertiary': '#FFB399',
    'dataListsQuaternary': '#FFCCB3',
    'soundPrimary': '#FF6680',
    'soundSecondary': '#FF99A3',
    'soundTertiary': '#FFB3B3',
    'soundQuaternary': '#FFCCCC',
    'motionPrimary': '#4C97FF',
    'motionSecondary': '#66B2FF',
    'motionTertiary': '#99CCFF',
    'motionQuaternary': '#CCE5FF',
    'looksPrimary': '#9966FF',
    'looksSecondary': '#B399FF',
    'looksTertiary': '#CCB3FF',
    'looksQuaternary': '#E6CCFF',
    'eventPrimary': '#FFBF00',
    'eventSecondary': '#FFD966',
    'eventTertiary': '#FFEB99',
    'eventQuaternary': '#FFF2CC',
    'sensingPrimary': '#5CB1D6',
    'sensingSecondary': '#7FC6E0',
    'sensingTertiary': '#99D9EA',
    'sensingQuaternary': '#CCEAF4',
    'operatorsPrimary': '#59C059',
    'operatorsSecondary': '#80D680',
    'operatorsTertiary': '#99E699',
    'operatorsQuaternary': '#CCF2CC',
    'penPrimary': '#0FBD8C',
    'penSecondary': '#19CDAA',
    'penTertiary': '#66E0C0',
    'penQuaternary': '#CCF2E6',
    'morePrimary': '#999999',
    'moreSecondary': '#B3B3B3',
    'moreTertiary': '#CCCCCC',
    'moreQuaternary': '#E6E6E6',
  };
}
