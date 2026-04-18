import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/firestore_service.dart';
import '../editor_screen.dart';
import '../../core/workspace.dart';
import '../auth/login_screen.dart';
import '../dashboard/admin_messages_page.dart';
import '../dashboard/friends_page.dart';
import '../dashboard/explore_projects_page.dart';
import '../dashboard/remix_ideas_page.dart';
import '../dashboard/learn_blocks_page.dart';
import '../dashboard/profile_page.dart';

class UserDashboard extends StatefulWidget {
  final String uid;
  const UserDashboard({Key? key, required this.uid}) : super(key: key);

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  final FirestoreService _fs = FirestoreService();

  List<Map<String, dynamic>> userProjects = [];
  bool isLoading = true;

  String displayName = "User";
  String email = "";
  String avatarUrl = "";

  bool sidebarCollapsed = false;

  // Color palette
  static const Color primaryBlue = Color(0xFF4C97FF);
  static const Color sidebarBg = Color(0xFFF8F9FA);
  static const Color cardBg = Colors.white;
  static const Color accentColor = Color(0xFF367CF7);
  static const Color textColor = Colors.grey;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _openEditor() async {
    final projectId = DateTime.now().millisecondsSinceEpoch.toString();

    await _fs.createProject(
      uid: widget.uid,
      projectId: projectId,
      title: "Untitled",
      initialData: {
        'stage': {
          'blocks': [],
          'backdrop': null,
        },
        'sprites': {},
      },
    );

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditorScreen(
          uid: widget.uid,
          projectId: projectId,
          currentProjectTitle: "Untitled",
          runtimeState: {},
          stage: Stage(),
          initialProjectData: {
            'stage': {'blocks': [], 'backdrop': null},
            'sprites': {},
          },
        ),
      ),
    ).then((_) {
      _loadAllData();
    });
  }

  Future<void> _loadAllData() async {
    try {
      final profile = await _fs.getUserProfile(widget.uid);
      final projects = await _fs.loadProjects(widget.uid);

      if (!mounted) return;

      setState(() {
        displayName = profile?['name'] ?? "User";
        email = profile?['email'] ?? "";
        avatarUrl = profile?['avatarUrl'] ?? "";
        userProjects = projects;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load data. Please try again.')),
      );

      debugPrint("Error loading data: $e");
    }
  }

  void _openProject(Map<String, dynamic> project) async {
    final savedProject = await _fs.getProject(
      uid: widget.uid,
      projectId: project['id'],
    );

    if (savedProject == null || !mounted) return;

    final data = Map<String, dynamic>.from(savedProject['data'] ?? {});

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditorScreen(
          uid: widget.uid,
          projectId: savedProject['id'],
          currentProjectTitle: savedProject['title'] ?? 'Untitled',
          runtimeState: savedProject['runtimeState'] ?? {},
          stage: Stage(),
          initialProjectData: data,
        ),
      ),
    ).then((_) {
      _loadAllData();
    });
  }

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final XFile? image =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image == null) return;

    final String? url = await _fs.uploadProfilePhoto(
      widget.uid,
      await image.readAsBytes(),
      DateTime.now().toString(),
    );

    if (url != null && url.isNotEmpty) {
      await _fs.updateProfile(uid: widget.uid, avatarUrl: url);
      if (!mounted) return;
      setState(() => avatarUrl = url);
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _navigateTo(Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Column(
        children: [
          _Header(
            uid: widget.uid,
            displayName: displayName,
            avatarUrl: avatarUrl,
            onPickAvatar: _pickAndUploadAvatar,
            primaryColor: primaryBlue,
          ),
          Expanded(
            child: Row(
              children: [
                _CollapsibleSidebar(
                  collapsed: sidebarCollapsed,
                  toggleCollapse: () =>
                      setState(() => sidebarCollapsed = !sidebarCollapsed),
                  onOpenEditor: _openEditor,
                  onLogout: _logout,
                  onNavigate: _navigateTo,
                  uid: widget.uid,
                  fs: _fs,
                  refreshDashboard: _loadAllData,
                  bgColor: sidebarBg,
                  accentColor: accentColor,
                ),
                const VerticalDivider(width: 1, color: Colors.grey),
                _MainContent(
                  projects: userProjects,
                  uid: widget.uid,
                  fs: _fs,
                  onOpenProject: _openProject,
                  displayName: displayName,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* ---------------- HEADER ---------------- */
class _Header extends StatelessWidget {
  final String uid;
  final String displayName;
  final String avatarUrl;
  final VoidCallback onPickAvatar;
  final Color primaryColor;

  const _Header({
    required this.uid,
    required this.displayName,
    required this.avatarUrl,
    required this.onPickAvatar,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, primaryColor.withOpacity(0.85)],
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onPickAvatar,
                child: CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.grey.shade200,
                  child: ClipOval(
                    child: avatarUrl.isNotEmpty
                        ? Image.network(avatarUrl,
                            width: 60, height: 60, fit: BoxFit.cover)
                        : Image.asset('assets/profile_pic.png',
                            width: 60, height: 60, fit: BoxFit.cover),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Text(
                displayName,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('adminMessages')
                .doc(uid)
                .collection('messages')
                .where('read', isEqualTo: false)
                .snapshots(),
            builder: (context, snapshot) {
              int unreadCount = 0;
              if (snapshot.hasData) {
                unreadCount = snapshot.data!.docs.length;
              }

              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications,
                        color: Colors.white, size: 28),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AdminMessagesPage(uid: uid),
                        ),
                      );
                    },
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 4,
                      top: 4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          )
        ],
      ),
    );
  }
}

/* ---------------- COLLAPSIBLE SIDEBAR ---------------- */
class _CollapsibleSidebar extends StatelessWidget {
  final bool collapsed;
  final VoidCallback toggleCollapse;
  final VoidCallback onOpenEditor;
  final VoidCallback onLogout;
  final Function(Widget page) onNavigate;
  final String uid;
  final FirestoreService fs;
  final Future<void> Function() refreshDashboard;
  final Color bgColor;
  final Color accentColor;

  const _CollapsibleSidebar({
    required this.collapsed,
    required this.toggleCollapse,
    required this.onOpenEditor,
    required this.onLogout,
    required this.onNavigate,
    required this.uid,
    required this.fs,
    required this.refreshDashboard,
    required this.bgColor,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: collapsed ? 70 : 260,
      color: bgColor,
      child: Column(
        children: [
          IconButton(
            icon: Icon(collapsed ? Icons.arrow_right : Icons.arrow_left),
            onPressed: toggleCollapse,
            color: accentColor,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(8),
              children: [
                _sideBtn(
                    "My Profile",
                    Icons.person,
                    () => onNavigate(ProfilePage(
                        uid: uid, fs: fs, refreshDashboard: refreshDashboard))),
                const SizedBox(height: 16),
                _section("CREATE"),
                _sideBtn("Open Editor", Icons.add_box, onOpenEditor),
                _sideBtn("Learn Blocks", Icons.school,
                    () => onNavigate(const LearnBlocksPage())),
                const SizedBox(height: 16),
                _section("COMMUNITY"),
                _sideBtn("Friends", Icons.group,
                    () => onNavigate(const FriendsPage())),
                _sideBtn("Explore Projects", Icons.explore,
                    () => onNavigate(const ExploreProjectsPage())),
                const SizedBox(height: 16),
                _section("ENGAGE"),
                _sideBtn("Remix Ideas", Icons.auto_awesome,
                    () => onNavigate(const RemixIdeasPage())),
                const SizedBox(height: 16),
                _section("SYSTEM"),
                _sideBtn(
                  "Admin Messages",
                  Icons.message,
                  () => onNavigate(AdminMessagesPage(uid: uid)),
                ),
                _sideBtn("Logout", Icons.logout, onLogout),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        child: Text(
          collapsed ? "" : title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
          ),
        ),
      );

  Widget _sideBtn(String label, IconData icon, VoidCallback onTap) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: ListTile(
        leading: SizedBox(
          width: 24,
          height: 24,
          child: Icon(icon, color: accentColor, size: 20),
        ),
        minLeadingWidth: 24,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        title: collapsed
            ? null
            : Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
        onTap: onTap,
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        hoverColor: Colors.blue.shade50,
      ),
    );
  }
}

/* ---------------- MAIN CONTENT ---------------- */
class _MainContent extends StatefulWidget {
  final List<Map<String, dynamic>> projects;
  final Function(Map<String, dynamic>) onOpenProject;
  final String uid;
  final FirestoreService fs;
  final String displayName;

  const _MainContent({
    required this.projects,
    required this.onOpenProject,
    required this.uid,
    required this.fs,
    required this.displayName,
  });

  @override
  State<_MainContent> createState() => _MainContentState();
}

class _MainContentState extends State<_MainContent> {
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.grey.shade100, Colors.grey.shade200],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Welcome / Quote Section ---
            Container(
              height: 160,
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blueAccent.shade400,
                    Colors.blueAccent.shade200
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Welcome back, ${widget.displayName}!",
                    style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "“Every block you place is a step towards mastery.”",
                    style: TextStyle(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                        color: Colors.white70),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      "You have ${widget.projects.length} project${widget.projects.length == 1 ? '' : 's'}",
                      style: const TextStyle(fontSize: 14, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // --- Projects Header ---
            Text(
              "My Projects",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 18),

            // --- Projects List ---
            Expanded(
              child: widget.projects.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.folder_open,
                              size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            "No projects yet",
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Scrollbar(
                      controller: _scrollController,
                      thumbVisibility: true,
                      thickness: 6,
                      radius: const Radius.circular(6),
                      child: ListView.separated(
                        controller: _scrollController,
                        itemCount: widget.projects.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final project = widget.projects[index];
                          final bool isPublic = project['isPublic'] ?? false;

                          String createdAtText = '';
                          final createdAt = project['createdAt'];
                          if (createdAt != null) {
                            try {
                              if (createdAt is Timestamp) {
                                createdAtText = createdAt
                                    .toDate()
                                    .toLocal()
                                    .toString()
                                    .split(' ')[0];
                              } else if (createdAt is DateTime) {
                                createdAtText = createdAt
                                    .toLocal()
                                    .toString()
                                    .split(' ')[0];
                              } else {
                                createdAtText = createdAt.toString();
                              }
                            } catch (_) {
                              createdAtText = createdAt.toString();
                            }
                          }

                          return Card(
                            elevation: 4,
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  const Icon(Icons.code,
                                      size: 40, color: Colors.black54),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          project['title'] ?? 'Untitled',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.black,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          createdAtText,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    children: [
                                      // ----------------- Visibility Toggle -----------------
                                      Switch(
                                        value: isPublic,
                                        onChanged: (val) async {
                                          final confirmed =
                                              await showDialog<bool>(
                                            context: context,
                                            builder: (_) => AlertDialog(
                                              title: const Text(
                                                  "Change Visibility"),
                                              content: Text(
                                                  "Make this project ${val ? 'Public' : 'Private'}?"),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                          context, false),
                                                  child: const Text("Cancel"),
                                                ),
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                          context, true),
                                                  child: const Text("Confirm"),
                                                ),
                                              ],
                                            ),
                                          );

                                          if (confirmed != true) return;

                                          final oldValue = project['isPublic'];

                                          setState(() {
                                            project['isPublic'] =
                                                val; // optimistic UI
                                          });

                                          try {
                                            await widget.fs
                                                .updateProjectVisibility(
                                              uid: widget.uid,
                                              projectId: project['id'],
                                              isPublic: val,
                                            );
                                          } catch (_) {
                                            setState(() {
                                              project['isPublic'] =
                                                  oldValue; // revert
                                            });
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(const SnackBar(
                                              content: Text(
                                                  "Failed to update visibility"),
                                            ));
                                          }
                                        },
                                      ),

                                      // ----------------- Edit / Delete Buttons -----------------
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit,
                                                color: Colors.blueAccent),
                                            onPressed: () =>
                                                widget.onOpenProject(project),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete,
                                                color: Colors.redAccent),
                                            onPressed: () async {
                                              final confirmed =
                                                  await showDialog<bool>(
                                                context: context,
                                                builder: (_) => AlertDialog(
                                                  title: const Text(
                                                      "Delete Project"),
                                                  content: const Text(
                                                      "Are you sure you want to delete this project?"),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              context, false),
                                                      child:
                                                          const Text("Cancel"),
                                                    ),
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              context, true),
                                                      child:
                                                          const Text("Delete"),
                                                    ),
                                                  ],
                                                ),
                                              );

                                              if (confirmed != true) return;

                                              try {
                                                await widget.fs.deleteProject(
                                                    widget.uid, project['id']);
                                                setState(() {
                                                  widget.projects
                                                      .removeAt(index);
                                                });
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                        const SnackBar(
                                                  content:
                                                      Text("Project deleted"),
                                                ));
                                              } catch (_) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                        const SnackBar(
                                                  content: Text(
                                                      "Failed to delete project"),
                                                ));
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
