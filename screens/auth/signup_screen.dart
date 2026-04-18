import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../services/firebase_auth_services.dart';
import '../../services/firestore_service.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with TickerProviderStateMixin {
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();
  final TextEditingController _nameCtrl = TextEditingController();
  final FirebaseAuthService _auth = FirebaseAuthService();

  bool _loading = false;
  bool _obscurePassword = true;

  static const Color primaryBlue = Color(0xFF4C97FF);
  static const Color headingColor = Color(0xFF1F2937);
  static const Color textMuted = Color(0xFF6B7280);

  // === FIELD POPUP FUNCTION (fancy tooltip bubble) ===
  void _showFieldPopup(GlobalKey key, String message, {bool success = false}) {
    final overlay = Overlay.of(context);
    if (overlay == null) return;

    final renderBox = key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    late OverlayEntry entry;
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    final animation = Tween<Offset>(
      begin: const Offset(0, -0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeOutBack),
    );

    entry = OverlayEntry(
      builder: (_) => Positioned(
        left: offset.dx,
        top: offset.dy + size.height + 6,
        width: size.width,
        child: SlideTransition(
          position: animation,
          child: Material(
            color: Colors.transparent,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Arrow
                Positioned(
                  top: -8,
                  left: 16,
                  child: Transform.rotate(
                    angle: 45 * 3.1415927 / 180,
                    child: Container(
                      width: 14,
                      height: 14,
                      color:
                          success ? Colors.green.shade600 : Colors.red.shade600,
                    ),
                  ),
                ),
                // Bubble
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color:
                        success ? Colors.green.shade600 : Colors.red.shade600,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        success ? Icons.check_circle : Icons.error_outline,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          message,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    controller.forward();

    Timer(const Duration(seconds: 2), () {
      controller.reverse().then((_) => entry.remove());
    });
  }

  final _nameKey = GlobalKey();
  final _emailKey = GlobalKey();
  final _passKey = GlobalKey();

  bool _validateFields() {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text.trim();

    if (name.isEmpty) {
      _showFieldPopup(_nameKey, "Full name cannot be empty");
      return false;
    }
    if (email.isEmpty) {
      _showFieldPopup(_emailKey, "Email cannot be empty");
      return false;
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      _showFieldPopup(_emailKey, "Enter a valid email");
      return false;
    }
    if (pass.isEmpty) {
      _showFieldPopup(_passKey, "Password cannot be empty");
      return false;
    }
    if (pass.length < 6) {
      _showFieldPopup(_passKey, "Password must be at least 6 characters");
      return false;
    }
    return true;
  }

  Future<void> _signup() async {
    if (!_validateFields()) return;

    setState(() => _loading = true);

    try {
      final uid = await _auth.signUp(
          email: _emailCtrl.text.trim(), password: _passCtrl.text.trim());
      if (uid == null) throw "Signup failed";

      await _auth.updateProfile(
        displayName: _nameCtrl.text.trim(),
      );

      await FirestoreService().createUser(
        uid: uid,
        email: _emailCtrl.text.trim(),
        name: _nameCtrl.text.trim(),
      );

      if (!mounted) return;

      // ✅ KEEP YOUR ORIGINAL SUCCESS DIALOG
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Center(
            child: Text(
              "Account Created",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          content: Text(
            "Hello ${_nameCtrl.text.trim()},\n\nYour account has been successfully created. You can now log in to access your dashboard and start using the application.",
            textAlign: TextAlign.left,
            style: const TextStyle(color: Colors.black87, fontSize: 15),
          ),
          actions: [
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                child: const Text(
                  "Continue",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            )
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showFieldPopup(_passKey, "Signup failed: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/auth_illustration.png',
              fit: BoxFit.cover,
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 420),
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
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
                          'Sign Up',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: headingColor,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Create a new account',
                          style: TextStyle(color: textMuted),
                        ),
                        const SizedBox(height: 28),

                        // Full Name
                        Container(
                          key: _nameKey,
                          child: TextField(
                            controller: _nameCtrl,
                            decoration: InputDecoration(
                              prefixIcon:
                                  const Icon(Icons.person, color: primaryBlue),
                              hintText: 'Full Name',
                              filled: true,
                              fillColor: const Color(0xFFF1F5FF),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Email
                        Container(
                          key: _emailKey,
                          child: TextField(
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
                        ),
                        const SizedBox(height: 16),

                        // Password
                        // Password
                        Container(
                          key: _passKey,
                          child: TextField(
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
                        ),
                        const SizedBox(height: 24),

                        // Sign Up Button
                        _loading
                            ? const CircularProgressIndicator(
                                color: primaryBlue)
                            : SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: _signup,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryBlue,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 4,
                                  ),
                                  child: const Text(
                                    'Sign Up',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
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
                              "Already have an account? ",
                              style: TextStyle(color: textMuted),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const LoginScreen()),
                                );
                              },
                              child: const Text(
                                "Log in",
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
