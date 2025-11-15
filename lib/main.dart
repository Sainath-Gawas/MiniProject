import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/home/home_screen.dart';
import 'screens/auth/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/firestore_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  ThemeData _getTheme(String uiMode) {
    switch (uiMode) {
      case 'dark':
        return ThemeData(
          primarySwatch: Colors.indigo,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: Colors.grey[900],
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF283593),
            foregroundColor: Colors.white,
          ),
        );
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
        );
      case 'amoled':
        return ThemeData(
          primarySwatch: Colors.indigo,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: Colors.black,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF283593),
            surface: Colors.black,
            background: Colors.black,
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
                      return const LoginScreen(); // User not logged in
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
