import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  CollectionReference get usersRef => _db.collection('users');
  CollectionReference get projectsRef =>
      _db.collection('projects'); // optional global collection

  // ------------------------------------------
  // USER MANAGEMENT
  // ------------------------------------------
  Future<void> createUser({
    required String uid,
    required String email,
    required String name,
  }) async {
    await usersRef.doc(uid).set({
      'email': email,
      'name': name,
      'avatarUrl': '',
      'aboutMe': '',
      'followers': [],
      'following': [],
      'remixesCount': 0,
      'role': 'user',
      'status': 'active', // <-- add this line
      'createdAt': FieldValue.serverTimestamp(),
      'lastLogin': FieldValue.serverTimestamp(),
    });
  }

  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final doc = await usersRef.doc(uid).get();
    if (!doc.exists) return null;
    return doc.data() as Map<String, dynamic>;
  }

  // ------------------------------------------
// QUICK USER LOOKUP (FOR OTHER USERS)
// ------------------------------------------
  Future<String> getUserNameByUid(String uid) async {
    final doc = await usersRef.doc(uid).get();
    if (!doc.exists) return 'User';

    final data = doc.data() as Map<String, dynamic>? ?? {};
    return data['name'] ?? 'User';
  }

  Future<void> updateProfile({
    required String uid,
    String? name,
    String? email,
    String? aboutMe,
    String? avatarUrl,
  }) async {
    await usersRef.doc(uid).update({
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (aboutMe != null) 'aboutMe': aboutMe,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      'lastLogin': FieldValue.serverTimestamp(),
    });
  }

  Future<String> getUserRole(String uid) async {
    final doc = await usersRef.doc(uid).get();
    if (!doc.exists) return 'user';
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return data['role'] ?? 'user';
  }

  Future<void> updateUserRole(String uid, String role) async {
    await usersRef.doc(uid).update({'role': role});
  }

  Future<void> deleteUserData(String uid) async {
    await usersRef.doc(uid).delete();
  }

  // ------------------------------------------
  // STORAGE
  // ------------------------------------------
  Future<String?> uploadProfilePhoto(
      String uid, Uint8List bytes, String filename) async {
    final ref = _storage.ref().child('profile_photos/$uid/$filename');
    final task = await ref.putData(bytes);
    return await task.ref.getDownloadURL();
  }

  Future<String?> uploadThumbnail(
      String projectId, Uint8List bytes, String filename) async {
    final ref = _storage.ref().child('project_thumbnails/$projectId/$filename');
    final task = await ref.putData(bytes);
    return await task.ref.getDownloadURL();
  }

  Future<void> logUserActivity({
    required String uid,
    required String title,
    required String description,
  }) async {
    await _db.collection('activities').add({
      'userId': uid,
      'title': title,
      'description': description,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // ------------------------------------------
  // FOLLOW / UNFOLLOW
  // ------------------------------------------
  Future<void> followUser(String currentUid, String targetUid) async {
    if (currentUid == targetUid) return;
    final currentRef = usersRef.doc(currentUid);
    final targetRef = usersRef.doc(targetUid);

    await _db.runTransaction((transaction) async {
      final currentSnap = await transaction.get(currentRef);
      final targetSnap = await transaction.get(targetRef);

      final currentData = currentSnap.data() as Map<String, dynamic>? ?? {};
      final targetData = targetSnap.data() as Map<String, dynamic>? ?? {};
      final currentFollowing =
          List<String>.from(currentData['following'] ?? []);
      final targetFollowers = List<String>.from(targetData['followers'] ?? []);

      if (!currentFollowing.contains(targetUid))
        currentFollowing.add(targetUid);
      if (!targetFollowers.contains(currentUid))
        targetFollowers.add(currentUid);

      transaction.update(currentRef, {'following': currentFollowing});
      transaction.update(targetRef, {'followers': targetFollowers});
    });
  }

  Future<void> unfollowUser(String currentUid, String targetUid) async {
    final currentRef = usersRef.doc(currentUid);
    final targetRef = usersRef.doc(targetUid);

    await _db.runTransaction((transaction) async {
      final currentSnap = await transaction.get(currentRef);
      final targetSnap = await transaction.get(targetRef);

      final currentFollowing =
          List<String>.from(currentSnap['following'] ?? []);
      final targetFollowers = List<String>.from(targetSnap['followers'] ?? []);

      currentFollowing.remove(targetUid);
      targetFollowers.remove(currentUid);

      transaction.update(currentRef, {'following': currentFollowing});
      transaction.update(targetRef, {'followers': targetFollowers});
    });
  }

  Future<bool> isFollowing(String currentUid, String targetUid) async {
    final doc = await usersRef.doc(currentUid).get();
    final following = List<String>.from(doc['following'] ?? []);
    return following.contains(targetUid);
  }

  // ------------------------------------------
  // USER ACTIVITY
  // ------------------------------------------
  Future<List<Map<String, dynamic>>> loadUserActivity(String uid) async {
    final snap = await _db
        .collection('activities')
        .where('userId', isEqualTo: uid)
        .orderBy('timestamp', descending: true)
        .limit(20)
        .get();

    return snap.docs.map((d) => d.data()).toList();
  }

  // ------------------------------------------
  // PROJECT VISIBILITY
  // ------------------------------------------
  Future<void> updateProjectVisibility({
    required String uid,
    required String projectId,
    required bool isPublic,
  }) async {
    final privateRef = usersRef.doc(uid).collection("projects").doc(projectId);
    final publicRef = _db.collection('publicProjects').doc(projectId);

    // 1️⃣ Update private project visibility
    await privateRef.update({
      "isPublic": isPublic,
      "updatedAt": FieldValue.serverTimestamp(),
    });

    if (isPublic) {
      // 2️⃣ Make sure private project exists
      final snap = await privateRef.get();
      if (!snap.exists) return;

      final data = snap.data()!;

      // 🔹 fetch owner profile
      final userSnap = await usersRef.doc(uid).get();
      final userData = userSnap.data() as Map<String, dynamic>? ?? {};

      // 3️⃣ Create or update public project
      await publicRef.set({
        "projectId": projectId,
        "title": data["title"] ?? "Untitled Project",
        "thumbnailUrl": data["thumbnailUrl"] ?? "",

        // 👤 Owner info
        "ownerId": uid,
        "ownerName": userData["name"] ?? "Unknown",
        "ownerAvatar": userData["avatarUrl"] ?? "",

        // 📊 Counters
        "viewsCount": data["viewsCount"] ?? 0,
        "likesCount": data["likesCount"] ?? 0,
        "commentsCount": data["commentsCount"] ?? 0,
        "sharesCount": data["sharesCount"] ?? 0,

        // 🔑 Dates
        "createdAt": data["createdAt"] ?? FieldValue.serverTimestamp(),
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } else {
      // 4️⃣ Remove from public collection if made private
      await publicRef.delete();
    }
  }

  Future<void> incrementProjectViews(String projectId) async {
    await _db.collection('publicProjects').doc(projectId).update({
      'viewsCount': FieldValue.increment(1),
    });
  }

  Future<void> incrementProjectLikes(String projectId) async {
    final ref = _db.collection('publicProjects').doc(projectId);

    await ref.update({
      'likesCount': FieldValue.increment(1),
    });
  }

  Future<void> toggleFollow(String currentUid, String targetUid) async {
    final isFollowing = await this.isFollowing(currentUid, targetUid);

    if (isFollowing) {
      await unfollowUser(currentUid, targetUid);
    } else {
      await followUser(currentUid, targetUid);
    }
  }

  Future<void> syncPublicProject({
    required String uid,
    required String projectId,
  }) async {
    final privateRef = usersRef.doc(uid).collection('projects').doc(projectId);
    final publicRef = _db.collection('publicProjects').doc(projectId);

    final snap = await privateRef.get();
    if (!snap.exists) return;

    final data = snap.data()!;
    if (data['isPublic'] != true) return;

    await publicRef.set({
      'title': data['title'],
      'thumbnailUrl': data['thumbnailUrl'],
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ------------------------------------------
  // PROJECT OPERATIONS
  // ------------------------------------------
  Future<void> createProject({
    required String uid,
    required String projectId,
    required String title,
    Map<String, dynamic>? initialData, // <-- add this
  }) async {
    await usersRef.doc(uid).collection("projects").doc(projectId).set({
      "title": title,
      "data": initialData ??
          {
            "blocks": {},
            "sprites": {},
            "backdrops": {},
            "sounds": {},
          },
      "runtimeState": {},
      "thumbnailUrl": "",
      "commentsCount": 0,
      "likesCount": 0,
      "sharesCount": 0,
      "viewsCount": 0,
      "isPublic": false,
      "createdAt": FieldValue.serverTimestamp(),
      "updatedAt": FieldValue.serverTimestamp(),
    });
  }

  Future<void> saveProject({
    required String uid,
    required String projectId,
    required Map<String, dynamic> jsonData,
    Map<String, dynamic>? runtimeState,
    String? title,
    String? thumbnailUrl,
    int? likesCount,
    int? commentsCount,
    int? sharesCount,
    int? viewsCount,
  }) async {
    await usersRef.doc(uid).collection("projects").doc(projectId).update({
      if (title != null) "title": title,
      "data": jsonData,
      if (runtimeState != null) "runtimeState": runtimeState,
      if (thumbnailUrl != null) "thumbnailUrl": thumbnailUrl,
      if (likesCount != null) "likesCount": likesCount,
      if (commentsCount != null) "commentsCount": commentsCount,
      if (sharesCount != null) "sharesCount": sharesCount,
      if (viewsCount != null) "viewsCount": viewsCount,
      "updatedAt": FieldValue.serverTimestamp(),
    });
  }

  Future<void> renameProject(
      String uid, String projectId, String newName) async {
    await usersRef.doc(uid).collection("projects").doc(projectId).update({
      "title": newName,
      "updatedAt": FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateProject({
    required String uid,
    required String projectId,
    required Map<String, dynamic> projectData,
    Map<String, dynamic>? runtimeState,
    String? title, // ✅ Add this
  }) async {
    await usersRef.doc(uid).collection('projects').doc(projectId).update({
      'data': projectData,
      'runtimeState': runtimeState ?? {},
      'updatedAt': FieldValue.serverTimestamp(),
      if (title != null) 'title': title, // ✅ Update title if provided
    });
  }

  // ------------------------------------------
// GET SINGLE PROJECT
// ------------------------------------------
  Future<Map<String, dynamic>?> getProject({
    required String uid,
    required String projectId,
  }) async {
    final doc =
        await usersRef.doc(uid).collection('projects').doc(projectId).get();

    if (!doc.exists) return null;

    final data = doc.data()!;
    return {
      "id": doc.id,
      "title": data["title"] ?? "",
      "data": data["data"] ??
          {
            "blocks": [], // ✅ list
            "sprites": [], // ✅ list
            "backdrops": [],
            "sounds": [],
          },
      "runtimeState": data["runtimeState"] ?? {},
      "createdAt": data["createdAt"],
      "updatedAt": data["updatedAt"],
      "thumbnailUrl": data["thumbnailUrl"] ?? "",
      "isPublic": data["isPublic"] ?? false,
    };
  }

  Future<void> deleteProject(String uid, String projectId) async {
    await usersRef.doc(uid).collection("projects").doc(projectId).delete();
  }

  Future<List<Map<String, dynamic>>> loadProjects(String uid) async {
    final snap = await usersRef
        .doc(uid)
        .collection("projects")
        .orderBy("createdAt", descending: true) // <-- use createdAt
        .get();

    return snap.docs.map((d) {
      final data = d.data();
      return {
        "id": d.id,
        "title": data["title"] ?? "",
        "updatedAt": data["updatedAt"],
        "data": data["data"] ??
            {
              "blocks": [],
              "sprites": [],
              "backdrops": [],
              "sounds": [],
            },
        "runtimeState": data["runtimeState"] ?? {},
        "thumbnailUrl": data["thumbnailUrl"] ?? "",
        "commentsCount": data["commentsCount"] ?? 0,
        "likesCount": data["likesCount"] ?? 0,
        "sharesCount": data["sharesCount"] ?? 0,
        "viewsCount": data["viewsCount"] ?? 0,
        "isPublic": data["isPublic"] ?? false,
      };
    }).toList();
  }

  // ------------------------------------------
  // MIGRATION: UPDATE OLD PROJECTS
  // ------------------------------------------
  Future<void> migrateProjects() async {
    final usersSnapshot = await usersRef.get();

    for (final userDoc in usersSnapshot.docs) {
      final userId = userDoc.id;
      final projectsSnapshot =
          await usersRef.doc(userId).collection('projects').get();

      for (final projectDoc in projectsSnapshot.docs) {
        final data = projectDoc.data();
        final updates = <String, dynamic>{};

        if (!data.containsKey('runtimeState')) updates['runtimeState'] = {};
        if (!data.containsKey('isPublic')) updates['isPublic'] = false;
        if (!data.containsKey('commentsCount')) updates['commentsCount'] = 0;
        if (!data.containsKey('likesCount')) updates['likesCount'] = 0;
        if (!data.containsKey('sharesCount')) updates['sharesCount'] = 0;
        if (!data.containsKey('viewsCount')) updates['viewsCount'] = 0;

        if (updates.isNotEmpty) {
          await usersRef
              .doc(userId)
              .collection('projects')
              .doc(projectDoc.id)
              .update(updates);
          print('Updated project ${projectDoc.id} for user $userId');
        }
      }
    }

    print('✅ Migration completed for all users!');
  }

  Future<void> saveOrUpdateProject({
    required String uid,
    String? projectId, // if null → new project
    required String projectTitle,
    required Map<String, dynamic> projectData,
    Map<String, dynamic>? runtimeState,
    bool isPublic = false, // <-- new
  }) async {
    final projectRef = projectId != null
        ? usersRef.doc(uid).collection('projects').doc(projectId)
        : usersRef.doc(uid).collection('projects').doc(); // auto ID

    await projectRef.set({
      'title': projectTitle,
      'data': projectData,
      'runtimeState': runtimeState ?? {},
      'isPublic': isPublic, // <-- add this
      if (projectId == null) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<List<Map<String, dynamic>>> loadPublicProjects() async {
    final snap = await _db
        .collection('publicProjects') // use dedicated public collection
        .orderBy('updatedAt', descending: true)
        .get();

    return snap.docs.map((d) {
      final data = d.data();
      return {
        "id": d.id,
        "title": data["title"] ?? "",
        "uid": d.reference.parent.parent!.id, // owner UID
        "updatedAt": data["updatedAt"],
        "thumbnailUrl": data["thumbnailUrl"] ?? "",
      };
    }).toList();
  }
}
