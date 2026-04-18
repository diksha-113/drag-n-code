import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';

class CommentsPage extends StatefulWidget {
  final String projectId;
  final String projectOwnerId;

  const CommentsPage({
    super.key,
    required this.projectId,
    required this.projectOwnerId,
  });

  @override
  State<CommentsPage> createState() => _CommentsPageState();
}

class _CommentsPageState extends State<CommentsPage> {
  final _commentCtrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final _uid = FirebaseAuth.instance.currentUser!.uid;

  bool _showEmoji = false;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdmin();

    _focusNode.addListener(() {
      if (_focusNode.hasFocus && _showEmoji) {
        setState(() => _showEmoji = false);
      }
    });
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _checkAdmin() async {
    final snap =
        await FirebaseFirestore.instance.collection('users').doc(_uid).get();

    setState(() {
      _isAdmin = snap.data()?['role'] == 'admin';
    });
  }

  List<String> _extractMentions(String text) {
    final regex = RegExp(r'@(\w+)');
    return regex.allMatches(text).map((m) => m.group(1)!).toList();
  }

  Future<void> _addComment() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;

    final mentions = _extractMentions(text);

    // 🔥 FETCH CURRENT USER DATA
    final userSnap =
        await FirebaseFirestore.instance.collection('users').doc(_uid).get();

    final userData = userSnap.data() ?? {};

    await FirebaseFirestore.instance
        .collection('publicProjects')
        .doc(widget.projectId)
        .collection('comments')
        .add({
      'text': text,
      'userId': _uid,
      'userName': userData['name'] ?? 'Unknown',
      'userAvatar': userData['avatarUrl'] ?? '',
      'mentions': mentions,
      'createdAt': FieldValue.serverTimestamp(),
    });

    FirebaseFirestore.instance
        .collection('publicProjects')
        .doc(widget.projectId)
        .update({
      'commentsCount': FieldValue.increment(1),
    });

    if (_uid != widget.projectOwnerId) {
      _sendNotification(
        widget.projectOwnerId,
        'Someone commented on your project 💬',
      );
    }

    for (final username in mentions) {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) {
        _sendNotification(
          snap.docs.first.id,
          'You were mentioned in a comment 👋',
        );
      }
    }

    _commentCtrl.clear();
  }

  Future<void> _sendNotification(String toUid, String message) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(toUid)
        .collection('notifications')
        .add({
      'message': message,
      'projectId': widget.projectId,
      'fromUserId': _uid,
      'createdAt': FieldValue.serverTimestamp(),
      'read': false,
    });
  }

  Future<void> _deleteComment(String id, String ownerId) async {
    if (!_isAdmin && ownerId != _uid) return;

    await FirebaseFirestore.instance
        .collection('publicProjects')
        .doc(widget.projectId)
        .collection('comments')
        .doc(id)
        .delete();

    FirebaseFirestore.instance
        .collection('publicProjects')
        .doc(widget.projectId)
        .update({
      'commentsCount': FieldValue.increment(-1),
    });
  }

  void _toggleEmoji() {
    if (_showEmoji) {
      setState(() => _showEmoji = false);
      _focusNode.requestFocus();
    } else {
      FocusScope.of(context).unfocus();
      Future.delayed(const Duration(milliseconds: 100), () {
        setState(() => _showEmoji = true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return WillPopScope(
      onWillPop: () async {
        if (_showEmoji) {
          setState(() => _showEmoji = false);
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(title: const Text("Comments")),
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            FocusScope.of(context).unfocus();
            setState(() => _showEmoji = false);
          },
          child: Column(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('publicProjects')
                      .doc(widget.projectId)
                      .collection('comments')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (_, snap) {
                    if (!snap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snap.data!.docs.isEmpty) {
                      return const Center(child: Text("No comments yet 📝"));
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: snap.data!.docs.length,
                      itemBuilder: (_, i) {
                        final doc = snap.data!.docs[i];
                        final data = doc.data() as Map<String, dynamic>;

                        final name = data['userName'] ?? 'Unknown';
                        final avatar = data['userAvatar'] ?? '';
                        final canDelete = _isAdmin || data['userId'] == _uid;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundImage: avatar.isNotEmpty
                                  ? NetworkImage(avatar)
                                  : null,
                              child: avatar.isEmpty
                                  ? const Icon(Icons.person)
                                  : null,
                            ),
                            title: Text(name),
                            subtitle: Linkify(
                              text: data['text'] ?? '',
                              onOpen: (link) async {
                                final uri = Uri.parse(link.url);
                                if (await canLaunchUrl(uri)) {
                                  launchUrl(uri);
                                }
                              },
                              style: const TextStyle(fontSize: 14),
                              linkStyle: const TextStyle(color: Colors.blue),
                            ),
                            trailing: canDelete
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () =>
                                        _deleteComment(doc.id, data['userId']),
                                  )
                                : null,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.emoji_emotions),
                          onPressed: _toggleEmoji,
                        ),
                        Expanded(
                          child: TextField(
                            controller: _commentCtrl,
                            focusNode: _focusNode,
                            onTap: () {
                              setState(() => _showEmoji = false);
                            },
                            decoration: const InputDecoration(
                              hintText: "Write a comment…",
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.send),
                          onPressed: () {
                            _addComment();
                            FocusScope.of(context).unfocus();
                          },
                        ),
                      ],
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: _showEmoji ? 250 : 0,
                      child: _showEmoji
                          ? EmojiPicker(
                              onEmojiSelected: (_, e) {
                                _commentCtrl
                                  ..text += e.emoji
                                  ..selection = TextSelection.fromPosition(
                                    TextPosition(
                                        offset: _commentCtrl.text.length),
                                  );
                              },
                            )
                          : null,
                    ),
                    SizedBox(height: keyboardHeight > 0 ? keyboardHeight : 0),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
