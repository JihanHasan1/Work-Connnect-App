import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/faq_provider.dart';
import 'providers/chatbot_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with proper error handling
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase initialized successfully');
  } catch (e) {
    debugPrint('❌ Firebase initialization error: $e');
  }

  runApp(const WorkConnectApp());
}

class WorkConnectApp extends StatelessWidget {
  const WorkConnectApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => FAQProvider()),
        ChangeNotifierProvider(create: (_) => ChatbotProvider()),
      ],
      child: MaterialApp(
        title: 'Work-Connect',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6366F1),
            brightness: Brightness.light,
          ),
          fontFamily: 'Inter',
          scaffoldBackgroundColor: const Color(0xFFF8FAFC),
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
            backgroundColor: Colors.white,
            foregroundColor: Color(0xFF1E293B),
            iconTheme: IconThemeData(
              color: Color(0xFF1E293B),
            ),
          ),
          cardTheme: const CardThemeData(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
            color: Colors.white,
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            prefixIconColor: const Color(0xFF64748B),
            suffixIconColor: const Color(0xFF64748B),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF6366F1),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            ),
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: Color(0xFF6366F1),
            foregroundColor: Colors.white,
            elevation: 2,
          ),
          chipTheme: ChipThemeData(
            backgroundColor: const Color(0xFFF1F5F9),
            selectedColor: const Color(0xFF6366F1),
            labelStyle: const TextStyle(
              color: Color(0xFF1E293B),
              fontSize: 12,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          dividerTheme: const DividerThemeData(
            color: Color(0xFFE2E8F0),
            thickness: 1,
          ),
          progressIndicatorTheme: const ProgressIndicatorThemeData(
            color: Color(0xFF6366F1),
          ),
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.isLoading) {
          return Scaffold(
            body: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF6366F1),
                    Color(0xFF8B5CF6),
                    Color(0xFFA855F7),
                  ],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.work_outline,
                        size: 50,
                        color: Color(0xFF6366F1),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Work-Connect',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 48),
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return auth.currentUser != null
            ? const HomeScreen()
            : const LoginScreen();
      },
    );
  }
}
