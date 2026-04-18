import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminSettingsPage extends StatefulWidget {
  const AdminSettingsPage({super.key});

  @override
  State<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends State<AdminSettingsPage> {
  bool maintenanceMode = false;
  DateTime? maintenanceStart;
  DateTime? maintenanceEnd;
  bool notificationsEnabled = true;
  bool mfaEnabled = false;

  static const Color primaryBlue = Color(0xFF4C97FF);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color cardBg = Colors.white;

  @override
  void initState() {
    super.initState();
    _listenSettings();
  }

  /* ================= SETTINGS STREAM ================= */
  void _listenSettings() {
    FirebaseFirestore.instance
        .collection('meta')
        .doc('flags')
        .snapshots()
        .listen((doc) {
      if (!doc.exists) return;
      final data = doc.data()!;
      setState(() {
        maintenanceMode = data['maintenance'] ?? false;
        maintenanceStart = (data['maintenanceStart'] as Timestamp?)?.toDate();
        maintenanceEnd = (data['maintenanceEnd'] as Timestamp?)?.toDate();
        notificationsEnabled = data['notificationsEnabled'] ?? true;
        mfaEnabled = data['mfaEnabled'] ?? false;
      });
    });
  }

  /* ================= MAINTENANCE ================= */
  Future<void> _toggleMaintenance(bool value) async {
    await FirebaseFirestore.instance.collection('meta').doc('flags').set({
      'maintenance': value,
    }, SetOptions(merge: true));
  }

  Future<void> _setMaintenanceSchedule() async {
    final start = await _pickDateTime(context, maintenanceStart);
    if (start == null) return;

    final end = await _pickDateTime(context, maintenanceEnd);
    if (end == null) return;

    final now = DateTime.now();
    final active = now.isAfter(start) && now.isBefore(end);

    await FirebaseFirestore.instance.collection('meta').doc('flags').set({
      'maintenanceStart': Timestamp.fromDate(start),
      'maintenanceEnd': Timestamp.fromDate(end),
      'maintenance': active,
    }, SetOptions(merge: true));
  }

  /* ================= PICKER ================= */
  Future<DateTime?> _pickDateTime(
      BuildContext context, DateTime? initial) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (date == null) return null;

    final time = await showTimePicker(
      context: context,
      initialTime: initial != null
          ? TimeOfDay(hour: initial.hour, minute: initial.minute)
          : TimeOfDay.now(),
    );
    if (time == null) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  /* ================= TOGGLES ================= */
  Future<void> _toggleNotifications(bool value) async {
    await FirebaseFirestore.instance
        .collection('meta')
        .doc('flags')
        .set({'notificationsEnabled': value}, SetOptions(merge: true));
  }

  Future<void> _toggleMFA(bool value) async {
    await FirebaseFirestore.instance
        .collection('meta')
        .doc('flags')
        .set({'mfaEnabled': value}, SetOptions(merge: true));
  }

  /* ================= BROADCAST ADMIN MESSAGE ================= */
  Future<void> broadcastAdminMessage(String message) async {
    try {
      final usersSnapshot =
          await FirebaseFirestore.instance.collection('users').get();

      if (usersSnapshot.docs.isEmpty) {
        print("No users found to send messages.");
        return;
      }

      for (var userDoc in usersSnapshot.docs) {
        final userId = userDoc.id;

        // Ensure parent document exists
        final adminDocRef =
            FirebaseFirestore.instance.collection('adminMessages').doc(userId);
        await adminDocRef.set({}, SetOptions(merge: true));

        await adminDocRef.collection('messages').add({
          'from': 'admin',
          'message': message,
          'timestamp': FieldValue.serverTimestamp(),
          'read': false,
        });
      }

      print("Broadcast sent successfully!");
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Message sent to all users.")));
    } catch (e) {
      print("Error broadcasting message: $e");
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to send message.")));
    }
  }

  void _showAdminMessageDialog() {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Broadcast Admin Message'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Type message here...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final text = controller.text.trim();
              if (text.isEmpty) return;

              await broadcastAdminMessage(text);
              Navigator.pop(context);
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  /* ================= DELETE ADMIN MESSAGE ================= */
  Future<void> deleteMessage(String userId, String messageId) async {
    await FirebaseFirestore.instance
        .collection('adminMessages')
        .doc(userId)
        .collection('messages')
        .doc(messageId)
        .delete();
  }

  /* ================= UI ================= */
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Settings',
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          // -------- Maintenance --------
          _card(
            Column(
              children: [
                SwitchListTile(
                  title: const Text('Maintenance Mode',
                      style: TextStyle(color: primaryBlue)),
                  value: maintenanceMode,
                  onChanged: _toggleMaintenance,
                  secondary: Icon(
                    maintenanceMode ? Icons.lock : Icons.lock_open,
                    color: maintenanceMode ? Colors.red : Colors.green,
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.schedule, color: primaryBlue),
                  title: const Text('Set Schedule',
                      style: TextStyle(color: primaryBlue)),
                  subtitle: Text(
                    maintenanceStart != null && maintenanceEnd != null
                        ? '${maintenanceStart!} → ${maintenanceEnd!}'
                        : 'No schedule set',
                    style: const TextStyle(color: textMuted),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _setMaintenanceSchedule,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // -------- Notifications --------
          _card(
            SwitchListTile(
              title: const Text('Enable Notifications',
                  style: TextStyle(color: primaryBlue)),
              subtitle: const Text('Global app notifications',
                  style: TextStyle(color: textMuted)),
              value: notificationsEnabled,
              onChanged: _toggleNotifications,
              secondary: const Icon(Icons.notifications, color: primaryBlue),
            ),
          ),
          const SizedBox(height: 16),

          // -------- MFA --------
          _card(
            SwitchListTile(
              title: const Text('Enable MFA',
                  style: TextStyle(color: primaryBlue)),
              value: mfaEnabled,
              onChanged: _toggleMFA,
              secondary: const Icon(Icons.security, color: primaryBlue),
            ),
          ),
          const SizedBox(height: 16),

          // -------- Broadcast Admin Message --------
          _card(
            ListTile(
              leading: const Icon(Icons.chat, color: primaryBlue),
              title: const Text(
                'Send Message to All Users',
                style: TextStyle(color: primaryBlue),
              ),
              subtitle: const Text(
                'Live broadcast admin message',
                style: TextStyle(color: textMuted),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _showAdminMessageDialog,
            ),
          ),
          const SizedBox(height: 16),

          // -------- View & Delete Admin Messages --------
          _card(
            ExpansionTile(
              leading: const Icon(Icons.message, color: primaryBlue),
              title: const Text('Admin Messages Sent',
                  style: TextStyle(color: primaryBlue)),
              children: [
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(),
                      );
                    }

                    final userDocs = snapshot.data!.docs;

                    if (userDocs.isEmpty) {
                      return const ListTile(
                        title: Text('No users found',
                            style: TextStyle(color: textMuted)),
                      );
                    }

                    return Column(
                      children: userDocs.map((userDoc) {
                        final userId = userDoc.id;

                        return StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('adminMessages')
                              .doc(userId)
                              .collection('messages')
                              .orderBy('timestamp', descending: true)
                              .snapshots(),
                          builder: (context, msgSnapshot) {
                            if (!msgSnapshot.hasData) return Container();

                            final messages = msgSnapshot.data!.docs;

                            if (messages.isEmpty) {
                              return ListTile(
                                title: Text('No messages',
                                    style: const TextStyle(color: textMuted)),
                              );
                            }

                            return Column(
                              children: messages.map((msgDoc) {
                                final data =
                                    msgDoc.data() as Map<String, dynamic>;
                                final messageId = msgDoc.id;

                                return ListTile(
                                  title: Text(
                                    data['message'] ?? '',
                                    style: const TextStyle(color: textMuted),
                                  ),
                                  subtitle: Text(
                                    (data['timestamp'] as Timestamp?)
                                            ?.toDate()
                                            .toString() ??
                                        '',
                                    style: const TextStyle(color: textMuted),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () =>
                                        deleteMessage(userId, messageId),
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // -------- Access Logs (REAL-TIME) --------
          _card(
            ExpansionTile(
              leading: const Icon(Icons.history, color: primaryBlue),
              title: const Text('Recent Access Logs',
                  style: TextStyle(color: primaryBlue)),
              children: [
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('accessLogs')
                      .orderBy('timestamp', descending: true)
                      .limit(10)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(),
                      );
                    }

                    final docs = snapshot.data!.docs;

                    if (docs.isEmpty) {
                      return const ListTile(
                        title: Text('No logs yet',
                            style: TextStyle(color: textMuted)),
                      );
                    }

                    return Column(
                      children: docs.map((doc) {
                        final d = doc.data() as Map<String, dynamic>;
                        return ListTile(
                          title: Text(
                            '${d['action']}',
                            style: const TextStyle(color: textMuted),
                          ),
                          subtitle: Text(
                            (d['timestamp'] as Timestamp).toDate().toString(),
                            style: const TextStyle(color: textMuted),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(Widget child) => Card(
        color: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
        child: child,
      );
}
