class ProjectModel {
  final String id;
  final String name;
  final String ownerId;

  /// Stage snapshot (NOT animation)
  final Map<String, dynamic> stage;

  /// Serialized blocks
  final List<Map<String, dynamic>> blocks;

  ProjectModel({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.stage,
    required this.blocks,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'ownerId': ownerId,
        'stage': stage,
        'blocks': blocks,
        'updatedAt': DateTime.now(),
      };

  static ProjectModel fromDoc(String id, Map<String, dynamic> data) {
    return ProjectModel(
      id: id,
      name: data['name'],
      ownerId: data['ownerId'],
      stage: Map<String, dynamic>.from(data['stage']),
      blocks: List<Map<String, dynamic>>.from(data['blocks']),
    );
  }
}
