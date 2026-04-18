import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/workspace.dart';

class ProjectPreviewPage extends StatefulWidget {
  final String projectId;
  final String title;

  const ProjectPreviewPage(
      {super.key, required this.projectId, required this.title});

  @override
  State<ProjectPreviewPage> createState() => _ProjectPreviewPageState();
}

class _ProjectPreviewPageState extends State<ProjectPreviewPage> {
  WorkspaceEngine? workspaceEngine;
  bool isRunning = false;
  String stageImageUrl = '';
  String creatorName = '';
  List<String> likes = [];
  int views = 0;
  int shares = 0;
  int commentsCount = 0;
  bool isLoading = true;

  StreamSubscription<DocumentSnapshot>? _projectSub;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _setupProjectListener();
  }

  @override
  void dispose() {
    _projectSub?.cancel();
    workspaceEngine?.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _setupProjectListener() {
    final docRef =
        FirebaseFirestore.instance.collection('projects').doc(widget.projectId);

    _projectSub = docRef.snapshots().listen((doc) {
      if (!doc.exists) return;

      final data = doc.data() as Map<String, dynamic>? ?? {};
      final spriteData = data['sprites'] is Iterable
          ? (data['sprites'] as Iterable)
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
          : null;

      setState(() {
        creatorName = data['creatorName'] ?? 'Unknown';
        stageImageUrl = data['stageImage'] ?? '';
        likes = List<String>.from(data['likes'] ?? []);
        shares = data['shares'] ?? 0;
        views = data['views'] ?? 0;
        commentsCount = data['commentsCount'] ?? 0;

        if (workspaceEngine == null) {
          workspaceEngine = WorkspaceEngine(
            projectId: widget.projectId,
            spriteData: spriteData,
          );
        }
      });

      // Load project blocks only once via WorkspaceEngine internally
      workspaceEngine?.setProjectName(widget.title);
      workspaceEngine?.setCreatorName(creatorName);

      isLoading = false;
    });
  }

  void runProject() {
    if (workspaceEngine == null) return;
    setState(() => isRunning = true);
    workspaceEngine!.triggerEvent('when_green_flag');
  }

  void stopProject() {
    workspaceEngine?.stopAllScripts();
    setState(() => isRunning = false);
  }

  Future<void> _deleteComment(int index) async {
    final docRef =
        FirebaseFirestore.instance.collection('projects').doc(widget.projectId);

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      if (!snap.exists) return;

      final List rawComments = snap.get('comments') as List<dynamic>? ?? [];
      if (index < 0 || index >= rawComments.length) return;

      rawComments.removeAt(index);
      tx.update(docRef, {
        'comments': rawComments,
        'commentsCount': (snap.get('commentsCount') ?? 1) - 1,
      });
    });
  }

  Widget _buildSprite(String path) {
    if (path.toLowerCase().endsWith('.svg')) {
      return SvgPicture.asset(path, width: 80, height: 80);
    }
    return Image.asset(path, width: 80, height: 80);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black87,
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.play_arrow),
            tooltip: 'Run Project',
            onPressed: runProject,
          ),
          IconButton(
            icon: const Icon(Icons.stop),
            tooltip: 'Stop Project',
            onPressed: isRunning ? stopProject : null,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  // Stage
                  Container(
                    width: double.infinity,
                    height: 360,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.black26),
                      image: stageImageUrl.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(stageImageUrl),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: workspaceEngine == null
                        ? const SizedBox()
                        : StageWidget(engine: workspaceEngine!),
                  ),
                  const SizedBox(height: 12),

                  // Stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _infoIcon(Icons.favorite, likes.length),
                      _infoIcon(Icons.remove_red_eye, views),
                      _infoIcon(Icons.share, shares),
                      _infoIcon(Icons.comment, commentsCount),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Comments
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('projects')
                        .doc(widget.projectId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox();
                      final doc = snapshot.data!;
                      final rawComments =
                          doc.get('comments') as List<dynamic>? ?? [];

                      return Column(
                        children: [
                          SizedBox(
                            height: 200,
                            child: ListView.builder(
                              itemCount: rawComments.length,
                              itemBuilder: (context, index) {
                                final c = rawComments[index];
                                return ListTile(
                                  dense: true,
                                  title: Text(c['text'] ?? ''),
                                  subtitle: Text(c['uid'] ?? ''),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () => _deleteComment(index),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _infoIcon(IconData icon, int value) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 4),
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
