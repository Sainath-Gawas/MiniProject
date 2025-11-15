import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/home/home_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/onboarding/get_started_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/firestore_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

Future<bool> _checkIfFirstLaunch() async {
  final prefs = await SharedPreferences.getInstance();
  final hasLaunched = prefs.getBool('has_launched') ?? false;
  if (!hasLaunched) {
    await prefs.setBool('has_launched', true);
    return true;
  }
  return false;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  ThemeData _getTheme(String uiMode) {
    switch (uiMode) {
      case 'focus':
        return ThemeData(
          primarySwatch: Colors.indigo,
          primaryColor: const Color(0xFF4A148C),
          scaffoldBackgroundColor: const Color(0xFFF3E5F5),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF4A148C),
            foregroundColor: Colors.white,
          ),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF4A148C),
            brightness: Brightness.light,
          ),
          textTheme: const TextTheme(
            bodyLarge: TextStyle(color: Colors.black87),
            bodyMedium: TextStyle(color: Colors.black87),
            bodySmall: TextStyle(color: Colors.black87),
          ),
        );
      case 'live':
        return ThemeData(
          primarySwatch: Colors.green,
          primaryColor: const Color(0xFF00C853),
          scaffoldBackgroundColor: const Color(0xFFE8F5E9),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF00C853),
            foregroundColor: Colors.white,
          ),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF00C853),
            brightness: Brightness.light,
          ),
          textTheme: const TextTheme(
            bodyLarge: TextStyle(color: Colors.black87),
            bodyMedium: TextStyle(color: Colors.black87),
            bodySmall: TextStyle(color: Colors.black87),
          ),
        );
      case 'gradient':
        return ThemeData(
          primarySwatch: Colors.blue,
          primaryColor: const Color(0xFF2196F3),
          scaffoldBackgroundColor: const Color(0xFFE3F2FD),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF2196F3),
            foregroundColor: Colors.white,
          ),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2196F3),
            brightness: Brightness.light,
          ),
          textTheme: const TextTheme(
            bodyLarge: TextStyle(color: Colors.black87),
            bodyMedium: TextStyle(color: Colors.black87),
            bodySmall: TextStyle(color: Colors.black87),
          ),
        );
      case 'light':
      default:
        return ThemeData(
          primarySwatch: Colors.indigo,
          brightness: Brightness.light,
          scaffoldBackgroundColor: const Color(0xFFFAFAFA),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF283593),
            foregroundColor: Colors.white,
          ),
          textTheme: const TextTheme(
            bodyLarge: TextStyle(color: Colors.black87),
            bodyMedium: TextStyle(color: Colors.black87),
            bodySmall: TextStyle(color: Colors.black87),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        final user = authSnapshot.data;
        final uid = user?.uid ?? 'guest_user';
        final isGuest = uid == 'guest_user' || uid.toLowerCase().startsWith('guest');
        final firestoreService = FirestoreService();

        return StreamBuilder<String>(
          stream: isGuest
              ? Stream.value('light')
              : firestoreService.getUserUiMode(uid),
          builder: (context, themeSnapshot) {
            final uiMode = themeSnapshot.data ?? 'light';
            final theme = _getTheme(uiMode);

            return MaterialApp(
              title: 'Student Sathi',
              debugShowCheckedModeBanner: false,
              theme: theme,
              home: StreamBuilder(
                stream: FirebaseAuth.instance.authStateChanges(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.active) {
                    if (snapshot.hasData) {
                      return const HomeScreen(); // User logged in
                    } else {
                      return FutureBuilder<bool>(
                        future: _checkIfFirstLaunch(),
                        builder: (context, firstLaunchSnapshot) {
                          if (firstLaunchSnapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (firstLaunchSnapshot.data == true) {
                            return const GetStartedScreen();
                          }
                          return const LoginScreen();
                        },
                      );
                    }
                  }
                  return const Center(child: CircularProgressIndicator());
                },
              ),
            );
          },
        );
      },
    );
  }
}
