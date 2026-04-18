import 'package:flutter/material.dart';

import 'friends_page.dart';
import 'activity_feed_page.dart';
import 'explore_projects_page.dart';
import 'collaborate_page.dart';
import 'remix_ideas_page.dart';
import 'learn_blocks_page.dart';

class UserSidebar extends StatelessWidget {
  final String displayName;
  final String email;
  final VoidCallback onOpenEditor;
  final VoidCallback onLogout;

  const UserSidebar({
    super.key,
    required this.displayName,
    required this.email,
    required this.onOpenEditor,
    required this.onLogout,
  });

  void _navigate(BuildContext context, Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile
          ListTile(
            leading: const Icon(Icons.person, size: 40),
            title: Text(displayName),
            subtitle: Text(email),
          ),

          const Divider(),

          // Core
          _SideBtn("Open Editor", Icons.edit, onOpenEditor),
          _SideBtn(
            "Learn Blocks",
            Icons.school,
            () => _navigate(context, const LearnBlocksPage()),
          ),

          const Divider(),

          // Social & Community
          _SideBtn(
            "Friends",
            Icons.group,
            () => _navigate(context, const FriendsPage()),
          ),
          _SideBtn(
            "Activity Feed",
            Icons.dynamic_feed,
            () => _navigate(context, const ActivityFeedPage()),
          ),
          _SideBtn(
            "Explore Projects",
            Icons.explore,
            () => _navigate(context, const ExploreProjectsPage()),
          ),
          _SideBtn(
            "Collaborate",
            Icons.handshake,
            () => _navigate(context, const CollaboratePage()),
          ),

          const Divider(),

          _SideBtn(
            "Remix Ideas",
            Icons.auto_awesome,
            () => _navigate(context, const RemixIdeasPage()),
          ),

          const Spacer(),
          const Divider(),

          // Logout
          _SideBtn("Logout", Icons.logout, onLogout),
        ],
      ),
    );
  }
}

class _SideBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _SideBtn(this.label, this.icon, this.onTap);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: onTap,
    );
  }
}
