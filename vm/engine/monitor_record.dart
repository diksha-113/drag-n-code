// lib/vm/engine/monitor_record.dart

/// Dart equivalent of monitor_record.js (Immutable.Record)

class MonitorRecord {
  /// Block ID
  final String? id;

  /// Present only if monitor is sprite-specific (e.g., x position)
  final String? spriteName;

  /// Present only if monitor is sprite-specific
  final String? targetId;

  /// Scratch opcode (e.g., "motion_xposition")
  final String? opcode;

  /// Current monitor value
  final dynamic value;

  /// Parameter map
  final Map<String, dynamic>? params;

  /// Display mode: "default", "slider", "large", "list"
  final String mode;

  /// Slider minimum value
  final num sliderMin;

  /// Slider maximum value
  final num sliderMax;

  /// Whether slider moves in steps
  final bool isDiscrete;

  /// Monitor position (null = auto-position)
  final double? x;
  final double? y;

  /// Current rendered width/height
  final double width;
  final double height;

  /// Visibility
  final bool visible;

  const MonitorRecord({
    this.id,
    this.spriteName,
    this.targetId,
    this.opcode,
    this.value,
    this.params,
    this.mode = 'default',
    this.sliderMin = 0,
    this.sliderMax = 100,
    this.isDiscrete = true,
    this.x,
    this.y,
    this.width = 0,
    this.height = 0,
    this.visible = true,
  });

  /// Create a modified copy (immutable style)
  MonitorRecord copyWith({
    String? id,
    String? spriteName,
    String? targetId,
    String? opcode,
    dynamic value,
    Map<String, dynamic>? params,
    String? mode,
    num? sliderMin,
    num? sliderMax,
    bool? isDiscrete,
    double? x,
    double? y,
    double? width,
    double? height,
    bool? visible,
  }) {
    return MonitorRecord(
      id: id ?? this.id,
      spriteName: spriteName ?? this.spriteName,
      targetId: targetId ?? this.targetId,
      opcode: opcode ?? this.opcode,
      value: value ?? this.value,
      params: params ?? this.params,
      mode: mode ?? this.mode,
      sliderMin: sliderMin ?? this.sliderMin,
      sliderMax: sliderMax ?? this.sliderMax,
      isDiscrete: isDiscrete ?? this.isDiscrete,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      visible: visible ?? this.visible,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'spriteName': spriteName,
      'targetId': targetId,
      'opcode': opcode,
      'value': value,
      'params': params,
      'mode': mode,
      'sliderMin': sliderMin,
      'sliderMax': sliderMax,
      'isDiscrete': isDiscrete,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'visible': visible,
    };
  }

  /// Construct from JSON
  factory MonitorRecord.fromJson(Map<String, dynamic> json) {
    return MonitorRecord(
      id: json['id'],
      spriteName: json['spriteName'],
      targetId: json['targetId'],
      opcode: json['opcode'],
      value: json['value'],
      params: json['params'] != null
          ? Map<String, dynamic>.from(json['params'])
          : null,
      mode: json['mode'] ?? 'default',
      sliderMin: json['sliderMin'] ?? 0,
      sliderMax: json['sliderMax'] ?? 100,
      isDiscrete: json['isDiscrete'] ?? true,
      x: json['x']?.toDouble(),
      y: json['y']?.toDouble(),
      width: (json['width'] ?? 0).toDouble(),
      height: (json['height'] ?? 0).toDouble(),
      visible: json['visible'] ?? true,
    );
  }
}
