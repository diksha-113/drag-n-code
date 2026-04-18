import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Save a project with a given ID and JSON data
  Future<void> saveProject({
    required String projectId,
    required Map<String, dynamic> projectData,
  }) async {
    try {
      await _firestore
          .collection('projects')
          .doc(projectId)
          .set(projectData, SetOptions(merge: true));
      print('Project saved: $projectId');
    } catch (e) {
      print('Error saving project: $e');
    }
  }

  /// Load a project by its ID
  Future<Map<String, dynamic>?> loadProject(String projectId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('projects').doc(projectId).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error loading project: $e');
      return null;
    }
  }

  /// Delete a project by its ID
  Future<void> deleteProject(String projectId) async {
    try {
      await _firestore.collection('projects').doc(projectId).delete();
      print('Project deleted: $projectId');
    } catch (e) {
      print('Error deleting project: $e');
    }
  }

  /// List all projects
  Future<List<Map<String, dynamic>>> listProjects() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('projects').get();
      return snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
    } catch (e) {
      print('Error listing projects: $e');
      return [];
    }
  }
}
