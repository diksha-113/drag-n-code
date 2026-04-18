import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';

import 'comments_page.dart';
import '../editor_screen.dart';
import '../../core/workspace.dart';

class ExploreProjectsPage extends StatefulWidget {
  const ExploreProjectsPage({super.key});

  @override
  State<ExploreProjectsPage> createState() => _ExploreProjectsPageState();
}

class _ExploreProjectsPageState extends State<ExploreProjectsPage> {
  final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

  List<String> _cleanList(dynamic list) {
    return List<String>.from(list ?? []).where((e) => e.isNotEmpty).toList();
  }

  Future<bool> _isFollowing(String ownerId) async {
    if (ownerId == currentUid || currentUid.isEmpty) return false;

    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUid)
          .get();

      final following = List<String>.from(snap.data()?['following'] ?? []);
      return following.contains(ownerId);
    } catch (_) {
      return false;
    }
  }

  Future<void> _toggleFollow(String ownerId, bool isFollowing) async {
    if (ownerId == currentUid || currentUid.isEmpty) return;

    final currentRef =
        FirebaseFirestore.instance.collection('users').doc(currentUid);
    final otherRef =
        FirebaseFirestore.instance.collection('users').doc(ownerId);

    if (isFollowing) {
      await currentRef.update({
        'following': FieldValue.arrayRemove([ownerId])
      });
      await otherRef.update({
        'followers': FieldValue.arrayRemove([currentUid])
      });
    } else {
      await currentRef.update({
        'following': FieldValue.arrayUnion([ownerId])
      });
      await otherRef.update({
        'followers': FieldValue.arrayUnion([currentUid])
      });
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text('Explore Projects'),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('publicProjects')
            .orderBy('updatedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _error(snapshot.error.toString());
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                "No public projects yet 🚀",
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            );
          }

          int crossAxisCount = 4;
          double width = MediaQuery.of(context).size.width;
          if (width > 1200) {
            crossAxisCount = 4;
          } else if (width > 900) {
            crossAxisCount = 3;
          } else if (width > 600) {
            crossAxisCount = 2;
          } else {
            crossAxisCount = 1;
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.78,
            ),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final title = data['title'] ?? 'Untitled Project';
              final ownerId = data['ownerId'] ?? '';
              final ownerName = data['ownerName'] ?? 'Unknown';
              final ownerAvatar = data['ownerAvatar'] ?? '';
              final thumbnail = data['thumbnailUrl'] ?? '';

              final likedBy = _cleanList(data['likedBy']);
              final viewedBy = _cleanList(data['viewedBy']);

              int likesCount = data['likesCount'] ?? 0;
              int viewsCount = data['viewsCount'] ?? 0;
              int commentsCount = data['commentsCount'] ?? 0;

              bool isLiked = likedBy.contains(currentUid);

              return GestureDetector(
                onTap: () async {
                  try {
                    final projectRef = FirebaseFirestore.instance
                        .collection('publicProjects')
                        .doc(doc.id);

                    if (currentUid.isNotEmpty &&
                        !viewedBy.contains(currentUid)) {
                      await projectRef.update({
                        'viewedBy': FieldValue.arrayUnion([currentUid]),
                        'viewsCount': FieldValue.increment(1),
                      });
                      setState(() {
                        viewsCount += 1;
                      });
                    }

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditorScreen(
                          uid: ownerId,
                          projectId: doc.id,
                          currentProjectTitle: title,
                          runtimeState: data['runtimeState'] ?? {},
                          stage: Stage(),
                          initialProjectData: Map<String, dynamic>.from(
                            data['data'] ??
                                {
                                  'stage': {'blocks': [], 'backdrop': null},
                                  'sprites': {}
                                },
                          ),
                        ),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Cannot open project: $e')),
                    );
                  }
                },
                child: Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 140,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          image: thumbnail.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(thumbnail),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: thumbnail.isEmpty
                            ? const Center(child: Icon(Icons.code, size: 48))
                            : null,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundImage: ownerAvatar.isNotEmpty
                                      ? NetworkImage(ownerAvatar)
                                      : null,
                                  child: ownerAvatar.isEmpty
                                      ? const Icon(Icons.person, size: 18)
                                      : null,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    ownerName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ),
                                if (ownerId != currentUid)
                                  FutureBuilder<bool>(
                                    future: _isFollowing(ownerId),
                                    builder: (_, followSnap) {
                                      final isFollowing =
                                          followSnap.data ?? false;
                                      return TextButton(
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 6),
                                          backgroundColor: isFollowing
                                              ? Colors.grey.shade300
                                              : Colors.blue.shade100,
                                          minimumSize: const Size(0, 0),
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        onPressed: () =>
                                            _toggleFollow(ownerId, isFollowing),
                                        child: Text(
                                          isFollowing ? 'Following' : 'Follow',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: isFollowing
                                                ? Colors.grey.shade700
                                                : Colors.blue.shade800,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _iconWithCount(Icons.visibility, viewsCount),
                            _iconWithCount(Icons.favorite, likesCount,
                                isActive: isLiked, onTap: () async {
                              if (currentUid.isEmpty) return;

                              final projectRef = FirebaseFirestore.instance
                                  .collection('publicProjects')
                                  .doc(doc.id);

                              await projectRef.update({
                                'likedBy': isLiked
                                    ? FieldValue.arrayRemove([currentUid])
                                    : FieldValue.arrayUnion([currentUid]),
                                'likesCount':
                                    FieldValue.increment(isLiked ? -1 : 1),
                              });

                              setState(() {
                                isLiked = !isLiked;
                                likesCount += isLiked ? 1 : -1;
                              });
                            }),
                            _iconWithCount(Icons.comment, commentsCount,
                                onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CommentsPage(
                                    projectId: doc.id,
                                    projectOwnerId: ownerId,
                                  ),
                                ),
                              );
                            }),
                            IconButton(
                              icon: const Icon(Icons.share,
                                  size: 24, color: Colors.blueAccent),
                              onPressed: () {
                                final projectLink =
                                    'https://yourapp.web.app/#/project/${doc.id}';

                                Share.share(
                                  'Check out this project 🚀\n\n'
                                  '$title\n\n'
                                  'Open here:\n$projectLink',
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _iconWithCount(IconData icon, int count,
      {bool isActive = false, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22, color: isActive ? Colors.red : Colors.black54),
          const SizedBox(height: 2),
          Text(
            count.toString(),
            style: TextStyle(
                fontSize: 14, color: isActive ? Colors.red : Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _error(String msg) {
    return Center(
      child: Text(
        msg,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.red),
      ),
    );
  }
}
