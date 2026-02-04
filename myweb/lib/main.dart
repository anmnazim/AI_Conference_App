import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'admin/admin_dashboard_screen.dart';
import 'admin/admin_login_screen.dart';
import 'app/screens/welcome_screen.dart';
import 'app/screens/home_screen.dart';
import 'services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ConferenceApp());
}

class ConferenceApp extends StatelessWidget {
  const ConferenceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Conference System',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),

      // ✅ Student app is DEFAULT (web + mobile)
      home: const AuthWrapper(),

      // ✅ Admin only via explicit route
     routes: {
        '/admin': (_) => const AdminAuthWrapper(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: AuthService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;

        if (user != null && !user.isAnonymous) {
          return const HomeScreen();
        }

        return const WelcomeScreen();
      },
    );
  }
}
class AdminAuthWrapper extends StatelessWidget {
  const AdminAuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<firebase_auth.User?>(
      stream: AuthService.authStateChanges, // your stream
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;

        if (user != null && !user.isAnonymous) {
          return FutureBuilder<bool>(
            future: AuthService.isAdmin(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              final isAdmin = snapshot.data!;
              if (isAdmin) {
                return const AdminDashboardScreen();
              }
              return const AdminLoginScreen(); // not admin
            },
          );
        }

        return const AdminLoginScreen();
      },
    );
  }
}
