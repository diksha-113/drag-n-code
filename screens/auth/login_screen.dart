import 'dart:ui';
import 'package:flutter/material.dart';
import '../../services/firebase_auth_services.dart';
import '../dashboard/user_dashboard.dart';
import '../dashboard/admin_dashboard.dart';
import '../auth/signup_screen.dart';
import '../../services/firestore_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();

  final FirebaseAuthService _auth = FirebaseAuthService();

  bool _loading = false;
  bool _obscurePassword = true;

  // 🎨 Colors
  static const Color primaryBlue = Color(0xFF4C97FF);
  static const Color headingColor = Color(0xFF1F2937);
  static const Color textMuted = Color(0xFF6B7280);

  void _showPopup(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        content: Text(message, style: const TextStyle(fontSize: 15)),
        actions: [
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          )
        ],
      ),
    );
  }

  Future<void> _login() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text.trim();

    if (email.isEmpty || pass.isEmpty) {
      if (!mounted) return;
      _showPopup("Please fill in all required fields.");
      return;
    }

    setState(() => _loading = true);

    try {
      final uid = await _auth.signIn(email: email, password: pass);

      if (!mounted) return;

      if (uid == null) {
        _showPopup("Invalid email or password.");
        return;
      }

      final role = await FirestoreService().getUserRole(uid);

      if (!mounted) return;

      if (role == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboard()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => UserDashboard(uid: uid)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showPopup("Login failed. Please try again.");
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 🌈 FULL SCREEN SOLID BACKGROUND IMAGE
          Positioned.fill(
            child: Image.asset(
              'assets/images/auth_illustration.png',
              fit: BoxFit.cover,
            ),
          ),

          // 🔐 CENTER GLASS LOGIN CARD
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 420),
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8), // 👈 card only
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset('assets/images/coding_cat.png', height: 80),
                        const SizedBox(height: 16),

                        const Text(
                          'Log In',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: headingColor,
                          ),
                        ),
                        const SizedBox(height: 6),

                        const Text(
                          'Welcome back to Drag N Code',
                          style: TextStyle(color: textMuted),
                        ),
                        const SizedBox(height: 28),

                        // EMAIL
                        TextField(
                          controller: _emailCtrl,
                          decoration: InputDecoration(
                            prefixIcon:
                                const Icon(Icons.email, color: primaryBlue),
                            hintText: 'Email address',
                            filled: true,
                            fillColor: const Color(0xFFF1F5FF),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // PASSWORD
                        TextField(
                          controller: _passCtrl,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            prefixIcon:
                                const Icon(Icons.lock, color: primaryBlue),
                            hintText: 'Password',
                            filled: true,
                            fillColor: const Color(0xFFF1F5FF),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: primaryBlue,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        _loading
                            ? const CircularProgressIndicator(
                                color: primaryBlue,
                              )
                            : SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: _login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryBlue,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    'Log In',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                        const SizedBox(height: 22),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Don’t have an account? ",
                              style: TextStyle(color: textMuted),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const SignupScreen(),
                                  ),
                                );
                              },
                              child: const Text(
                                "Create one",
                                style: TextStyle(
                                  color: primaryBlue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
