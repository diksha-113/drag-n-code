class StageLayering {
  // Layer names
  static const String BACKGROUND_LAYER = 'background';
  static const String VIDEO_LAYER = 'video';
  static const String PEN_LAYER = 'pen';
  static const String SPRITE_LAYER = 'sprite';

  // Order of layer groups relative to each other
  static const List<String> LAYER_GROUPS = [
    BACKGROUND_LAYER,
    VIDEO_LAYER,
    PEN_LAYER,
    SPRITE_LAYER,
  ];
}
