import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'firebase_options.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/admin_dashboard.dart';
import 'screens/dashboard/user_dashboard.dart';
import 'screens/auth/home_page.dart';

// ================= GLOBAL VARIABLES =================

// Navigator key for dialogs
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Tracks if a color is being picked
ValueNotifier<bool> colorPickingActive = ValueNotifier(false);

// Preview color while picking
ValueNotifier<Color?> previewColor = ValueNotifier(null);

// Stores selected colors for keys
Map<String, ValueNotifier<Color>> _colors = {};

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await Hive.openBox('motion_blocks');

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Drag N Code',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),

      // Named routes
      routes: {
        '/login': (context) => const LoginScreen(),
        '/adminDashboard': (context) => const AdminDashboard(),
        '/userDashboard': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as String;
          return UserDashboard(uid: args);
        },
      },

      // Default home
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnap) {
        if (authSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!authSnap.hasData) {
          return const LoginScreen();
        }

        final uid = authSnap.data!.uid;

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
          builder: (context, userSnap) {
            if (userSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (!userSnap.hasData || !userSnap.data!.exists) {
              return FutureBuilder<void>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .set({
                  'email': authSnap.data!.email,
                  'role': 'user',
                  'createdAt': FieldValue.serverTimestamp(),
                }),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }
                  return HomePage(uid: uid);
                },
              );
            }

            final userData = userSnap.data!.data() as Map<String, dynamic>?;
            final role = userData?['role'] ?? 'user';

            if (role == 'admin') {
              return const AdminDashboard();
            } else {
              return HomePage(uid: uid);
            }
          },
        );
      },
    );
  }
}
