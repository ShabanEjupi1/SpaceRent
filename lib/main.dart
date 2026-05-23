import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/router.dart';

void main() async {
  usePathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase with dummy config or from environment variables.
  // In a production setup, these are provided via --dart-define or dotenv.
  const urlEnv = String.fromEnvironment('SUPABASE_URL');
  const keyEnv = String.fromEnvironment('SUPABASE_ANON_KEY');

  const supabaseUrl = urlEnv != ''
      ? urlEnv
      : 'https://rrjndmbihxblkwzwmhoi.supabase.co';
  const supabaseAnonKey = keyEnv != ''
      ? keyEnv
      : 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJyam5kbWJpaHhibGt3endtaG9pIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk1MzE2NDUsImV4cCI6MjA5NTEwNzY0NX0.-ZmVh41piYGFr93xaf4ks72c3fjC8gbRQdPm1l4Yn_Y';

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(
    const ProviderScope(
      child: SpaceRentApp(),
    ),
  );
}

class SpaceRentApp extends ConsumerWidget {
  const SpaceRentApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'SpaceRent Kosovo',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      themeMode: ThemeMode.dark, // Default to a premium dark theme
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C5CE7), // Space Violet
          brightness: Brightness.dark,
          background: const Color(0xFF0F0F1A), // Cosmic Dark
          surface: const Color(0xFF1A1A2E), // Glassmorphism container base
          primary: const Color(0xFF6C5CE7),
          secondary: const Color(0xFF00CEC9), // Neo Teal
        ),
        scaffoldBackgroundColor: const Color(0xFF0F0F1A),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F0F1A),
          elevation: 0,
        ),
        textTheme: const TextTheme(
          displayMedium: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, color: Colors.white),
          titleLarge: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600, color: Colors.white),
          bodyLarge: TextStyle(fontFamily: 'Inter', color: Colors.white),
          bodyMedium: TextStyle(fontFamily: 'Inter', color: Colors.white70),
        ),
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'US'), // English
        Locale('sq', 'XK'), // Albanian (Kosovo)
      ],
    );
  }
}
