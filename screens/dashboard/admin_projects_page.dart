import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../core/workspace.dart';
import '../editor_screen.dart';

class AdminProjectsPage extends StatefulWidget {
  const AdminProjectsPage({super.key});

  @override
  State<AdminProjectsPage> createState() => _AdminProjectsPageState();
}

class _AdminProjectsPageState extends State<AdminProjectsPage> {
  static const Color primaryBlue = Color(0xFF4C97FF);
  static const Color textMuted = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    final usersRef = FirebaseFirestore.instance
        .collection('users')
        .where('role', isNotEqualTo: 'admin');

    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Projects"),
        backgroundColor: primaryBlue,
        elevation: 6,
        shadowColor: Colors.blueAccent.withOpacity(0.3),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: StreamBuilder<QuerySnapshot>(
          stream: usersRef.snapshots(),
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snap.hasData || snap.data!.docs.isEmpty) {
              return const Center(
                  child: Text("No users found",
                      style: TextStyle(color: textMuted)));
            }

            final users = snap.data!.docs;

            return ListView.separated(
              itemCount: users.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (_, i) {
                final user = users[i];
                final data = user.data() as Map<String, dynamic>;
                final name = data['name'] ?? 'Unknown';
                final avatar = data['photoUrl'];

                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  elevation: 5,
                  shadowColor: Colors.blue.shade100,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    leading: CircleAvatar(
                      radius: 28,
                      backgroundColor: primaryBlue.withOpacity(0.2),
                      backgroundImage:
                          avatar != null ? NetworkImage(avatar) : null,
                      child: avatar == null
                          ? Text(name[0].toUpperCase(),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18))
                          : null,
                    ),
                    title: Text(
                      name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 17),
                    ),
                    trailing: const Icon(Icons.arrow_forward,
                        color: primaryBlue, size: 26),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              UserProjectsPage(userId: user.id, userName: name),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// ================== USER PROJECTS PAGE ==================
class UserProjectsPage extends StatelessWidget {
  final String userId;
  final String userName;

  const UserProjectsPage(
      {super.key, required this.userId, required this.userName});

  static const Color primaryBlue = Color(0xFF4C97FF);
  static const Color textMuted = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    final privateProjectsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('projects')
        .orderBy('updatedAt', descending: true);

    final publicProjectsRef = FirebaseFirestore.instance
        .collection('publicProjects')
        .where('ownerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text("$userName's Projects"),
          backgroundColor: primaryBlue,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Private'),
              Tab(text: 'Public'),
            ],
          ),
          elevation: 6,
          shadowColor: Colors.blueAccent.withOpacity(0.3),
        ),
        body: TabBarView(
          children: [
            // ===== PRIVATE PROJECTS =====
            StreamBuilder<QuerySnapshot>(
              stream: privateProjectsRef.snapshots(),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return const Center(
                      child: Text("No private projects",
                          style: TextStyle(color: textMuted)));
                }

                final docs = snap.data!.docs;

                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final doc = docs[i];
                    final data = doc.data() as Map<String, dynamic>;
                    final title = data['title'] ?? 'Untitled';
                    final updatedAt =
                        (data['updatedAt'] as Timestamp?)?.toDate();

                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                      shadowColor: Colors.blue.shade100,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        title: Text(title,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        subtitle: updatedAt != null
                            ? Text(
                                'Updated: ${DateFormat('MMM d, yyyy').format(updatedAt)}',
                                style: const TextStyle(color: textMuted))
                            : null,
                        trailing: IconButton(
                          icon:
                              const Icon(Icons.play_arrow, color: primaryBlue),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EditorScreen(
                                  uid: userId,
                                  projectId: doc.id,
                                  currentProjectTitle:
                                      data['title'] ?? 'Untitled',
                                  runtimeState: data['runtimeState'] ?? {},
                                  stage: Stage(),
                                  initialProjectData: Map<String, dynamic>.from(
                                      data['data'] ?? {}),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),

            // ===== PUBLIC PROJECTS =====
            StreamBuilder<QuerySnapshot>(
              stream: publicProjectsRef.snapshots(),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return const Center(
                      child: Text("No public projects",
                          style: TextStyle(color: textMuted)));
                }

                final docs = snap.data!.docs;

                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final doc = docs[i];
                    final data = doc.data() as Map<String, dynamic>;
                    final title = data['title'] ?? 'Untitled';
                    final views = data['viewsCount'] ?? 0;
                    final likes = data['likesCount'] ?? 0;
                    final comments = data['commentsCount'] ?? 0;
                    final createdAt =
                        (data['createdAt'] as Timestamp?)?.toDate();
                    final thumbnail = data['thumbnailUrl'] ?? '';

                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                      shadowColor: Colors.orange.shade100,
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: thumbnail.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  thumbnail,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.code,
                                    size: 36, color: Colors.grey),
                              ),
                        title: Text(title,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (createdAt != null)
                              Text(DateFormat('MMM d, yyyy').format(createdAt),
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.black38)),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                _icon(Icons.visibility, views),
                                const SizedBox(width: 12),
                                _icon(Icons.favorite, likes),
                                const SizedBox(width: 12),
                                _icon(Icons.comment, comments),
                              ],
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon:
                              const Icon(Icons.play_arrow, color: primaryBlue),
                          onPressed: () async {
                            final privateSnap = await FirebaseFirestore.instance
                                .collection('users')
                                .doc(userId)
                                .collection('projects')
                                .doc(doc.id)
                                .get();

                            if (!privateSnap.exists) return;
                            final pdata = privateSnap.data()!;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EditorScreen(
                                  uid: userId,
                                  projectId: doc.id,
                                  currentProjectTitle:
                                      pdata['title'] ?? 'Untitled',
                                  runtimeState: pdata['runtimeState'] ?? {},
                                  stage: Stage(),
                                  initialProjectData: Map<String, dynamic>.from(
                                      pdata['data'] ?? {}),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _icon(IconData icon, int value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.black45),
        const SizedBox(width: 4),
        Text(value.toString(),
            style: const TextStyle(fontSize: 12, color: Colors.black45)),
      ],
    );
  }
}
