import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';

class ProfilePage extends StatefulWidget {
  final String uid;
  final FirestoreService fs;
  final Future<void> Function() refreshDashboard;

  const ProfilePage({
    Key? key,
    required this.uid,
    required this.fs,
    required this.refreshDashboard,
  }) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const Color primaryBlue = Color(0xFF4C97FF);

  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _passwordCtrl;
  late TextEditingController _aboutCtrl;

  String avatarUrl = "";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  /* ================= LOAD PROFILE ================= */

  Future<void> _loadProfile() async {
    final profile = await widget.fs.getUserProfile(widget.uid);
    if (!mounted) return;

    _nameCtrl = TextEditingController(text: profile?['name'] ?? '');
    _emailCtrl = TextEditingController(text: profile?['email'] ?? '');
    _passwordCtrl = TextEditingController();
    _aboutCtrl = TextEditingController(text: profile?['aboutMe'] ?? '');
    avatarUrl = profile?['avatarUrl'] ?? '';

    setState(() => isLoading = false);
  }

  /* ================= PICK AVATAR ================= */

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final XFile? image =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image == null) return;

    final String? url = await widget.fs.uploadProfilePhoto(
      widget.uid,
      await image.readAsBytes(),
      DateTime.now().toString(),
    );

    if (url != null && url.isNotEmpty) {
      await widget.fs.updateProfile(uid: widget.uid, avatarUrl: url);
      if (!mounted) return;
      setState(() => avatarUrl = url);
    }
  }

  /* ================= SAVE PROFILE ================= */

  Future<void> _saveProfile() async {
    final newName = _nameCtrl.text.trim();
    final newEmail = _emailCtrl.text.trim();
    final newPassword = _passwordCtrl.text.trim();
    final newAbout = _aboutCtrl.text.trim();

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Reauthenticate if email/password changed
      if ((newEmail.isNotEmpty && newEmail != user.email) ||
          newPassword.isNotEmpty) {
        await _reauthenticate(user);
      }

      if (newEmail.isNotEmpty && newEmail != user.email) {
        await user.verifyBeforeUpdateEmail(newEmail);
      }

      if (newPassword.isNotEmpty) {
        await user.updatePassword(newPassword);
      }

      // 🔥 Update Firestore (including aboutMe)
      await widget.fs.updateProfile(
        uid: widget.uid,
        name: newName,
        email: newEmail,
        aboutMe: newAbout,
      );

      await user.reload();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated successfully")),
      );

      await widget.refreshDashboard();
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Update failed: $e")),
      );
    }
  }

  /* ================= REAUTH ================= */

  Future<void> _reauthenticate(User user) async {
    final passwordCtrl = TextEditingController();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("Confirm Password"),
        content: TextField(
          controller: passwordCtrl,
          obscureText: true,
          decoration: const InputDecoration(labelText: "Current Password"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final credential = EmailAuthProvider.credential(
                email: user.email!,
                password: passwordCtrl.text.trim(),
              );
              await user.reauthenticateWithCredential(credential);
              Navigator.pop(context);
            },
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }

  /* ================= UI ================= */

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // HEADER
            Container(
              height: 200,
              width: double.infinity,
              color: primaryBlue,
              child: Center(
                child: GestureDetector(
                  onTap: _pickAvatar,
                  child: CircleAvatar(
                    radius: 55,
                    backgroundColor: Colors.white,
                    backgroundImage:
                        avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                    child: avatarUrl.isEmpty
                        ? const Icon(Icons.person, size: 60)
                        : null,
                  ),
                ),
              ),
            ),

            // FORM
            Padding(
              padding: const EdgeInsets.all(24),
              child: Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      TextField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(
                          labelText: "Name",
                          prefixIcon: Icon(Icons.person),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _emailCtrl,
                        decoration: const InputDecoration(
                          labelText: "Email",
                          prefixIcon: Icon(Icons.email),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _aboutCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: "About Me",
                          prefixIcon: Icon(Icons.info_outline),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordCtrl,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: "New Password",
                          hintText: "Leave blank to keep current",
                          prefixIcon: Icon(Icons.lock),
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryBlue,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "Save Profile",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
