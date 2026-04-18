import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RemixIdeasPage extends StatelessWidget {
  const RemixIdeasPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Remix Ideas"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('remix_ideas')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          // Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Empty
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No remix ideas yet",
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          final ideas = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: ideas.length,
            itemBuilder: (context, index) {
              final data = ideas[index].data() as Map<String, dynamic>;
              final title = data['title'] ?? "Untitled Idea";
              final description = data['description'] ?? "";
              final creatorName = data['createdByName'] ?? "Anonymous";
              final timestamp = (data['createdAt'] as Timestamp?)?.toDate();

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading: const Icon(Icons.auto_awesome, size: 36),
                  title: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(description),
                      Text("By: $creatorName"),
                      if (timestamp != null)
                        Text(
                          "Created on: ${timestamp.toLocal()}".split('.')[0],
                          style: const TextStyle(fontSize: 12),
                        ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: () {
                      // TODO: Open remix detail / start remixing
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Remix feature coming soon 🚧"),
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
    );
  }
}
