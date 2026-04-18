import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage>
    with SingleTickerProviderStateMixin {
  static const Color primaryBlue = Color(0xFF4C97FF);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String currentUid = FirebaseAuth.instance.currentUser!.uid;

  bool isLoading = true;
  List<Map<String, dynamic>> followingUsers = [];
  List<Map<String, dynamic>> followersUsers = [];
  List<String> myFollowingIds = [];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadFriendsData();
  }

  Future<void> _loadFriendsData() async {
    setState(() => isLoading = true);

    try {
      final currentUserDoc =
          await _firestore.collection('users').doc(currentUid).get();

      final followingIds =
          (currentUserDoc.data()?['following'] as List<dynamic>? ?? [])
              .where((id) => id != null && id.toString().isNotEmpty)
              .cast<String>()
              .toList();

      final followersIds =
          (currentUserDoc.data()?['followers'] as List<dynamic>? ?? [])
              .where((id) => id != null && id.toString().isNotEmpty)
              .cast<String>()
              .toList();

      myFollowingIds = followingIds;

      final followingDocs = followingIds.isEmpty
          ? []
          : (await _firestore
                  .collection('users')
                  .where(FieldPath.documentId, whereIn: followingIds)
                  .get())
              .docs;

      final followersDocs = followersIds.isEmpty
          ? []
          : (await _firestore
                  .collection('users')
                  .where(FieldPath.documentId, whereIn: followersIds)
                  .get())
              .docs;

      setState(() {
        followingUsers = followingDocs
            .map((doc) => {
                  'uid': doc.id,
                  ...(doc.data() as Map<String, dynamic>),
                })
            .toList();

        followersUsers = followersDocs
            .map((doc) => {
                  'uid': doc.id,
                  ...(doc.data() as Map<String, dynamic>),
                })
            .toList();

        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading friends data: $e");
      setState(() => isLoading = false);
    }
  }

  int _calculateMutualFriends(Map<String, dynamic> user) {
    final userFollowing =
        (user['following'] as List<dynamic>? ?? []).cast<String>();

    return userFollowing.where((id) => myFollowingIds.contains(id)).length;
  }

  Future<void> _toggleFollow(String userId, bool isFollowing) async {
    final currentRef = _firestore.collection('users').doc(currentUid);
    final otherRef = _firestore.collection('users').doc(userId);

    if (isFollowing) {
      await currentRef.update({
        'following': FieldValue.arrayRemove([userId])
      });
      await otherRef.update({
        'followers': FieldValue.arrayRemove([currentUid])
      });
    } else {
      await currentRef.update({
        'following': FieldValue.arrayUnion([userId])
      });
      await otherRef.update({
        'followers': FieldValue.arrayUnion([currentUid])
      });
    }

    _loadFriendsData();
  }

  Future<int> _getProjectCount(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('publicProjects')
          .where('ownerId', isEqualTo: uid)
          .get();

      return snapshot.docs.length;
    } catch (_) {
      return 0;
    }
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final name = user['name'] ?? 'Unknown';
    final about = user['aboutMe'] ?? 'No bio added yet.';
    final uid = user['uid'];
    final avatarUrl = user['avatarUrl'];

    final isFollowing = myFollowingIds.contains(uid);

    final followersCount = (user['followers'] as List?)?.length ?? 0;
    final followingCount = (user['following'] as List?)?.length ?? 0;
    final mutualCount = _calculateMutualFriends(user);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: primaryBlue.withOpacity(0.1),
                backgroundImage:
                    (avatarUrl != null && avatarUrl.toString().isNotEmpty)
                        ? NetworkImage(avatarUrl)
                        : null,
                child: (avatarUrl == null || avatarUrl.toString().isEmpty)
                    ? Text(
                        name.isNotEmpty ? name[0].toUpperCase() : "?",
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              ElevatedButton(
                onPressed: () => _toggleFollow(uid, isFollowing),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isFollowing ? Colors.grey.shade300 : primaryBlue,
                  foregroundColor: isFollowing ? Colors.black : Colors.white,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(isFollowing ? "Following" : "Follow"),
              )
            ],
          ),
          const SizedBox(height: 12),
          Text(
            about,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              height: 1.4,
            ),
          ),
          if (mutualCount > 0) ...[
            const SizedBox(height: 6),
            Text(
              "$mutualCount mutual friends",
              style: TextStyle(
                fontSize: 12,
                color: primaryBlue,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 18),
          FutureBuilder<int>(
            future: _getProjectCount(uid),
            builder: (context, snapshot) {
              final projectCount = snapshot.data ?? 0;

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statItem(followersCount, "Followers"),
                  _statItem(followingCount, "Following"),
                  _statItem(projectCount, "Projects"),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _statItem(int count, String label) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildTabList(List<Map<String, dynamic>> users) {
    if (users.isEmpty) {
      return const Center(
        child: Text("No users found"),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFriendsData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: users.length,
        itemBuilder: (context, index) => _buildUserCard(users[index]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text("Friends"),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: "Following"),
            Tab(text: "Followers"),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTabList(followingUsers),
                _buildTabList(followersUsers),
              ],
            ),
    );
  }
}
