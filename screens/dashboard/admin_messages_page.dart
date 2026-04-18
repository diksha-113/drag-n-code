import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminMessagesPage extends StatelessWidget {
  final String uid;
  const AdminMessagesPage({super.key, required this.uid});

  Future<void> _deleteMessage(
      BuildContext context, DocumentReference msgRef) async {
    try {
      await msgRef.delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Message deleted")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to delete message")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Messages"),
        backgroundColor: Colors.blueAccent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('adminMessages')
            .doc(uid)
            .collection('messages')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final messages = snapshot.data!.docs;

          if (messages.isEmpty) {
            return const Center(child: Text("No new messages"));
          }

          return ListView.builder(
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final msg = messages[index];
              final isRead = msg['read'] ?? false;
              final timestamp =
                  (msg['timestamp'] as Timestamp?)?.toDate().toString() ?? '';

              return ListTile(
                title: Text(msg['message'] ?? "Message"),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (msg['from'] != null) Text("From: ${msg['from']}"),
                    if (timestamp.isNotEmpty) Text("Sent: $timestamp"),
                  ],
                ),
                tileColor: isRead ? Colors.white : Colors.blue.shade50,
                onTap: () async {
                  // Mark as read
                  try {
                    await msg.reference.update({'read': true});
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Failed to mark as read")),
                    );
                  }
                },
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text("Delete Message"),
                        content: const Text(
                            "Are you sure you want to delete this message?"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text("Cancel"),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text("Delete"),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      await _deleteMessage(context, msg.reference);
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
