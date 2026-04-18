import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _loading = false;

  Future<void> _toggleUserStatus(String uid, String currentStatus) async {
    final newStatus = currentStatus == "blocked" ? "active" : "blocked";

    setState(() => _loading = true);
    try {
      await _db.collection("users").doc(uid).update({
        "status": newStatus,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                "User ${newStatus == "blocked" ? "blocked" : "unblocked"}")),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update user status")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _deleteUser(String uid) async {
    final currentUid = _auth.currentUser?.uid;
    if (uid == currentUid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You cannot delete your own account")),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text("Are you sure you want to delete this user?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel")),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Delete")),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _loading = true);
    try {
      await _db.collection("users").doc(uid).delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User deleted successfully")),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to delete user")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Users',
          style: Theme.of(context)
              .textTheme
              .headlineMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _db
                .collection("users")
                .where("role", isEqualTo: "user") // 👈 hide admins
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text("No users found",
                      style: TextStyle(color: Colors.blueGrey)),
                );
              }

              final users = snapshot.data!.docs;

              return ListView.separated(
                itemCount: users.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final data = users[index].data() as Map<String, dynamic>;
                  final email = data['email'] ?? 'Unknown';
                  final status = data['status'] ?? 'active';
                  final avatarLetter = email.isNotEmpty ? email[0] : 'U';

                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: status == "blocked"
                            ? Colors.redAccent
                            : Colors.blueAccent,
                        child: Text(
                          avatarLetter.toUpperCase(),
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(
                        email,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        "Status: ${status.toUpperCase()}",
                        style: TextStyle(
                          color:
                              status == "blocked" ? Colors.red : Colors.green,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              status == "blocked"
                                  ? Icons.lock_open
                                  : Icons.block,
                              color: Colors.orange,
                            ),
                            tooltip: status == "blocked"
                                ? "Unblock User"
                                : "Block User",
                            onPressed: _loading
                                ? null
                                : () =>
                                    _toggleUserStatus(users[index].id, status),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete,
                                color: Colors.redAccent),
                            tooltip: "Delete User",
                            onPressed: _loading
                                ? null
                                : () => _deleteUser(users[index].id),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
