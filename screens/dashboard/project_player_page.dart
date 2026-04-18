import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/workspace.dart';
import '../../models/block_model.dart';

// ================= Project Player Page =================
class ProjectPlayerPage extends StatefulWidget {
  final String projectId;

  const ProjectPlayerPage({super.key, required this.projectId});

  @override
  State<ProjectPlayerPage> createState() => _ProjectPlayerPageState();
}

class _ProjectPlayerPageState extends State<ProjectPlayerPage> {
  bool isRunning = false;
  WorkspaceEngine? workspaceEngine;

  String projectName = '';
  String creatorName = '';
  String? stageImageUrl;
  List<BlockModel> blocks = [];

  List<String> likes = [];
  int commentsCount = 0;
  int shares = 0;
  int views = 0;

  bool isLoading = true;
  User? currentUser;

  StreamSubscription<DocumentSnapshot>? _projectSub;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;
    _setupProjectListener();
  }

  @override
  void dispose() {
    _projectSub?.cancel();
    workspaceEngine?.dispose();
    _commentController.dispose();
    super.dispose();
  }

  // ================= Firebase Listener =================
  void _setupProjectListener() {
    final docRef =
        FirebaseFirestore.instance.collection('projects').doc(widget.projectId);

    _projectSub = docRef.snapshots().listen((doc) async {
      if (!doc.exists) return;

      final data = doc.data() as Map<String, dynamic>? ?? {};

      final List<String> safeLikes = data['likes'] is Iterable
          ? (data['likes'] as Iterable).map((e) => e.toString()).toList()
          : [];

      final int safeComments =
          data['commentsCount'] is int ? data['commentsCount'] : 0;
      final int safeShares = data['shares'] is int ? data['shares'] : 0;
      final int safeViews = data['views'] is int ? data['views'] : 0;

      final Iterable rawBlocks =
          data['blocks'] is Iterable ? data['blocks'] : const [];

      final List<BlockModel> mappedBlocks = rawBlocks
          .map<BlockModel?>((b) {
            try {
              return BlockModel.fromMap(Map<String, dynamic>.from(b as Map));
            } catch (_) {
              return null;
            }
          })
          .whereType<BlockModel>()
          .toList();

      final bool blocksChanged = mappedBlocks.length != blocks.length;

      final List<Map<String, dynamic>>? spriteData = data['sprites'] is Iterable
          ? (data['sprites'] as Iterable)
              .map((s) => Map<String, dynamic>.from(s))
              .toList()
          : null;

      setState(() {
        projectName = data['name'] ?? 'Unnamed Project';
        creatorName = data['creatorName'] ?? 'Unknown';
        stageImageUrl = data['stageImage'];

        likes = safeLikes;
        commentsCount = safeComments;
        shares = safeShares;
        views = safeViews;

        if (workspaceEngine == null) {
          workspaceEngine = WorkspaceEngine(
            projectId: widget.projectId,
            spriteData: spriteData,
          );
        }

        workspaceEngine!
          ..setProjectName(projectName)
          ..setCreatorName(creatorName);

        if (blocksChanged) {
          blocks = mappedBlocks;

          final Map<String, dynamic> projectMap = {
            'projectName': projectName,
            'creatorName': creatorName,
            'sprites': spriteData,
            'workspaces': {
              for (final sprite in spriteData ?? [])
                sprite['id']: blocks.map((b) => b.toJson()).toList(),
            },
          };

          workspaceEngine!.loadProjectFromFirebase(blocks);
        }

        isLoading = false;
      });

      // Safe view increment
      if (currentUser != null) {
        final uid = currentUser!.uid;
        final List<String> viewedBy = data['viewedBy'] is Iterable
            ? (data['viewedBy'] as Iterable).map((e) => e.toString()).toList()
            : [];

        if (!viewedBy.contains(uid)) {
          viewedBy.add(uid);
          await FirebaseFirestore.instance.runTransaction((tx) async {
            final snap = await tx.get(docRef);
            final currentViews = snap.get('views') ?? 0;
            tx.update(docRef, {
              'viewedBy': viewedBy,
              'views': currentViews + 1,
            });
          });
        }
      }
    });
  }

  // ================= Counter / Like / Share =================
  Future<void> _incrementCounter(String field) async {
    final docRef =
        FirebaseFirestore.instance.collection('projects').doc(widget.projectId);

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      if (!snap.exists) return;

      final uid = currentUser?.uid;
      if (uid == null) return;

      if (field == 'likes') {
        final raw = snap.get('likes');
        final List<String> list =
            raw is Iterable ? raw.map((e) => e.toString()).toList() : [];

        list.contains(uid) ? list.remove(uid) : list.add(uid);
        tx.update(docRef, {'likes': list});
      } else if (field == 'shares') {
        final raw = snap.get('sharedBy');
        final List<String> sharedBy =
            raw is Iterable ? raw.map((e) => e.toString()).toList() : [];

        if (!sharedBy.contains(uid)) {
          sharedBy.add(uid);
          tx.update(docRef, {
            'shares': (snap.get('shares') ?? 0) + 1,
            'sharedBy': sharedBy,
          });
        }
      } else {
        tx.update(docRef, {
          field: (snap.get(field) ?? 0) + 1,
        });
      }
    });
  }

  // ================= Add Comment =================
  Future<void> _addComment(String text) async {
    if (currentUser == null || text.trim().isEmpty) return;
    final docRef =
        FirebaseFirestore.instance.collection('projects').doc(widget.projectId);

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      final rawComments = snap.get('comments') as List<dynamic>? ?? [];
      rawComments.add({
        'uid': currentUser!.uid,
        'text': text.trim(),
        'timestamp': DateTime.now().toIso8601String(),
      });
      tx.update(docRef, {
        'comments': rawComments,
        'commentsCount': (snap.get('commentsCount') ?? 0) + 1,
      });
    });

    _commentController.clear();
  }

  // ================= Run / Stop =================
  void runProject() {
    if (workspaceEngine == null) return;

    setState(() => isRunning = true);
    workspaceEngine!.triggerEvent("when_green_flag");
  }

  void stopProject() {
    workspaceEngine?.stopAllScripts();
    setState(() => isRunning = false);
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    final liked = currentUser != null && likes.contains(currentUser!.uid);

    return Scaffold(
      backgroundColor: const Color(0xFFE5E5E5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4C4C4C),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(projectName,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text("by $creatorName",
                style: const TextStyle(fontSize: 14, color: Colors.white70)),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    // Run / Stop Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: runProject,
                          icon: const Icon(Icons.flag, color: Colors.green),
                          label: const Text("Run"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                          ),
                        ),
                        const SizedBox(width: 20),
                        ElevatedButton.icon(
                          onPressed: isRunning ? stopProject : null,
                          icon: const Icon(Icons.stop, color: Colors.red),
                          label: const Text("Stop"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Stage
                    Container(
                      width: double.infinity,
                      height: 360,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.black26),
                        image: stageImageUrl == null
                            ? null
                            : DecorationImage(
                                image: NetworkImage(stageImageUrl!),
                                fit: BoxFit.cover,
                              ),
                      ),
                      child: workspaceEngine == null
                          ? const SizedBox()
                          : StageWidget(engine: workspaceEngine!),
                    ),

                    const SizedBox(height: 12),

                    // Likes / Shares / Views
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _counter(Icons.favorite, likes.length, liked,
                              () => _incrementCounter('likes')),
                          _counter(Icons.comment, commentsCount, false, () {}),
                          _counter(Icons.share, shares, false,
                              () => _incrementCounter('shares')),
                          Row(
                            children: [
                              const Icon(Icons.remove_red_eye),
                              const SizedBox(width: 4),
                              Text('$views'),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Comments
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          SizedBox(
                            height: 200,
                            child: StreamBuilder<DocumentSnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('projects')
                                  .doc(widget.projectId)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) return const SizedBox();
                                final doc = snapshot.data!;
                                final rawComments =
                                    doc.get('comments') as List<dynamic>? ?? [];
                                return ListView.builder(
                                  itemCount: rawComments.length,
                                  itemBuilder: (context, index) {
                                    final c = rawComments[index];
                                    return ListTile(
                                      dense: true,
                                      title: Text(c['text'] ?? ''),
                                      subtitle: Text(c['uid'] ?? ''),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _commentController,
                                  decoration: InputDecoration(
                                    hintText: "Add a comment...",
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide.none),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.send),
                                onPressed: () =>
                                    _addComment(_commentController.text),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _counter(IconData icon, int value, bool active, VoidCallback onTap) {
    return Row(
      children: [
        IconButton(
          icon: Icon(icon, color: active ? Colors.red : Colors.black45),
          onPressed: onTap,
        ),
        Text('$value'),
      ],
    );
  }
}

// ================= Stage Widget =================
class StageWidget extends StatefulWidget {
  final WorkspaceEngine engine;

  const StageWidget({super.key, required this.engine});

  @override
  State<StageWidget> createState() => _StageWidgetState();
}

class _StageWidgetState extends State<StageWidget> {
  StreamSubscription? _spriteSub;

  @override
  void initState() {
    super.initState();
    _spriteSub = widget.engine.spriteStream.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _spriteSub?.cancel();
    super.dispose();
  }

  Widget _buildSprite(String path) {
    if (path.toLowerCase().endsWith('.svg')) {
      return SvgPicture.asset(path, width: 80, height: 80);
    }
    return Image.asset(path, width: 80, height: 80);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: widget.engine.sprites.map((sprite) {
        if (!sprite.visible) return const SizedBox.shrink();

        final double x = (sprite.x + 240 - 40).clamp(0, 480);
        final double y = (180 - sprite.y - 40).clamp(0, 360);

        return Positioned(
          left: x,
          top: y,
          child: Transform.rotate(
            angle: (sprite.direction - 90) * pi / 180,
            child: _buildSprite(sprite.assetPath),
          ),
        );
      }).toList(),
    );
  }
}
