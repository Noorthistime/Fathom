import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/projects/presentation/providers/projects_provider.dart';
import 'features/settings/presentation/providers/settings_provider.dart';
import 'features/chat/presentation/providers/chat_provider.dart';
import 'features/chat/presentation/pages/chat_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    // Print Firebase error but allow offline launch/testing framework overrides.
    debugPrint("Firebase init error: $e");
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProjectsProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: const FathomApp(),
    ),
  );
}

class FathomApp extends StatelessWidget {
  const FathomApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);

    // Dynamic initializations when user changes
    if (authProvider.isAuthenticated) {
      final uid = authProvider.user!.uid;
      // Triggers stream setups silently in backgrounds
      Provider.of<ProjectsProvider>(context, listen: false).initialize(uid);
      Provider.of<SettingsProvider>(context, listen: false).initialize(uid);
      Provider.of<ChatProvider>(context, listen: false).initializeChats(uid);
    }

    return MaterialApp(
      title: 'Fathom AI Chat',
      debugShowCheckedModeBanner: false,
      themeMode: settingsProvider.themeMode,
      theme: AppTheme.getLightTheme(settingsProvider.accentColor),
      darkTheme: AppTheme.getDarkTheme(settingsProvider.accentColor),
      home: authProvider.isAuthenticated ? const ChatPage() : const LoginPage(),
    );
  }
}
