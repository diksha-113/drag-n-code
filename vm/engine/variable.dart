import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../util/uid.dart';
import '../util/xml_escape.dart';

/// ================= MONITOR MODE =================
enum MonitorMode {
  normal,
  large,
  slider,
}

class Variable {
  // ================= Scratch Types =================
  static const String SCALAR_TYPE = 'scalar';
  static const String LIST_TYPE = 'list';
  static const String BROADCAST_MESSAGE_TYPE = 'broadcast_msg';

  // ================= Core =================
  String id;
  String name;
  String type;
  bool isCloud;

  /// Checkbox visible
  bool visible;

  /// Monitor shown on stage
  bool visibleOnStage;

  /// Monitor style
  MonitorMode monitorMode;

  /// Saved position
  Offset monitorPosition;

  /// Slider range
  double sliderMin;
  double sliderMax;

  /// Global or sprite variable
  bool isGlobal;

  /// If sprite variable
  String? ownerSpriteId;

  /// Is list
  bool list;

  bool _monitorUpToDate = false;

  /// Reactive value holder
  final ValueNotifier<dynamic> notifier;

  // =========================================================
  // ================= CONSTRUCTOR ===========================
  // =========================================================
  Variable({
    String? id,
    required this.name,
    required String type,
    this.isCloud = false,
    dynamic value,
    bool? list,
    this.visible = false,
    this.visibleOnStage = false,
    this.monitorMode = MonitorMode.normal,
    this.monitorPosition = const Offset(8, 8),
    this.sliderMin = 0,
    this.sliderMax = 100,
    this.isGlobal = true,
    this.ownerSpriteId,
  })  : id = id ?? generateUid(),
        type = _normalizeType(type),
        list = list ?? (_normalizeType(type) == LIST_TYPE),
        notifier = ValueNotifier(
          value ?? (_normalizeType(type) == LIST_TYPE ? <dynamic>[] : 0),
        ) {
    if (!_isValidType(this.type)) {
      throw ArgumentError('Invalid variable type: ${this.type}');
    }
  }

  // =========================================================
  // ================= TYPE HELPERS ==========================
  // =========================================================

  static bool _isValidType(String type) {
    return type == SCALAR_TYPE ||
        type == LIST_TYPE ||
        type == BROADCAST_MESSAGE_TYPE;
  }

  static String _normalizeType(String type) {
    switch (type) {
      case 'number':
      case 'string':
      case 'boolean':
        return SCALAR_TYPE;
      case LIST_TYPE:
      case SCALAR_TYPE:
      case BROADCAST_MESSAGE_TYPE:
        return type;
      default:
        return SCALAR_TYPE;
    }
  }

  bool get isList => list;

  // =========================================================
  // ================= VALUE SYSTEM ==========================
  // =========================================================

  dynamic get value => notifier.value;

  set value(dynamic newValue) {
    if (list) {
      if (newValue is! List) {
        throw ArgumentError('List variable must contain List');
      }
    }

    notifier.value = newValue;
    _monitorUpToDate = false;
  }

  void addListener(VoidCallback listener) {
    notifier.addListener(listener);
  }

  void removeListener(VoidCallback listener) {
    notifier.removeListener(listener);
  }

  void markDirty() {
    _monitorUpToDate = false;
    notifier.notifyListeners();
  }

  bool get monitorUpToDate => _monitorUpToDate;

  set monitorUpToDate(bool v) => _monitorUpToDate = v;

  // =========================================================
  // ================= MONITOR CONTROL =======================
  // =========================================================

  void setMonitorPosition(Offset newPosition) {
    monitorPosition = newPosition;
  }

  void setSliderRange(double min, double max) {
    sliderMin = min;
    sliderMax = max;
  }

  void setMonitorMode(MonitorMode mode) {
    monitorMode = mode;
  }

  // =========================================================
  // ================= XML EXPORT ============================
  // =========================================================

  String toXML({bool isLocal = false}) {
    return '<variable type="$type" id="$id" islocal="$isLocal" iscloud="$isCloud">'
        '${xmlEscape(name)}</variable>';
  }

  // =========================================================
  // ================= JSON SAVE SUPPORT =====================
  // =========================================================

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'isCloud': isCloud,
      'value': value,
      'visible': visible,
      'visibleOnStage': visibleOnStage,
      'monitorMode': monitorMode.name,
      'monitorX': monitorPosition.dx,
      'monitorY': monitorPosition.dy,
      'sliderMin': sliderMin,
      'sliderMax': sliderMax,
      'isGlobal': isGlobal,
      'ownerSpriteId': ownerSpriteId,
    };
  }

  factory Variable.fromJson(Map<String, dynamic> json) {
    return Variable(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      isCloud: json['isCloud'] ?? false,
      value: json['value'],
      visible: json['visible'] ?? false,
      visibleOnStage: json['visibleOnStage'] ?? false,
      monitorMode: MonitorMode.values.firstWhere(
        (e) => e.name == json['monitorMode'],
        orElse: () => MonitorMode.normal,
      ),
      monitorPosition: Offset(
        (json['monitorX'] ?? 8).toDouble(),
        (json['monitorY'] ?? 8).toDouble(),
      ),
      sliderMin: (json['sliderMin'] ?? 0).toDouble(),
      sliderMax: (json['sliderMax'] ?? 100).toDouble(),
      isGlobal: json['isGlobal'] ?? true,
      ownerSpriteId: json['ownerSpriteId'],
    );
  }
}
