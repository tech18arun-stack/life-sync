import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'providers/auth_provider.dart';
import 'services/deep_link_service.dart';
import 'providers/financial_data_manager.dart';
import 'providers/health_provider.dart';
import 'providers/family_provider.dart';
import 'providers/family_number_provider.dart';
import 'providers/task_provider.dart';
import 'providers/reminder_provider.dart';
import 'providers/savings_goal_provider.dart';

import 'providers/family_event_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/analytics_provider.dart';

import 'services/notification_service.dart';
import 'services/gemini_service.dart';
import 'services/security_service.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'widgets/app_lifecycle_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://fjmjxkevxhftfzfhcnbd.supabase.co', // Your Supabase URL
    anonKey:
        'sb_publishable_CjWTGM3MaKZFSehLfunyJA_pa2p9gek', // Your Supabase anon key
  );

  // Initialize Security Service (App Lock / Biometric)
  await SecurityService().initialize();

  // Initialize platform-specific services only on mobile
  if (!kIsWeb) {
    // Initialize Notification Service
    final notificationService = NotificationService();
    await notificationService.initialize();
    await notificationService.requestPermissions();

    // Initialize Deep Link Service
    await DeepLinkService.initDeepLinks();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Auth Provider (must be first)
        ChangeNotifierProvider(create: (_) => AuthProvider()),

        // Theme Provider
        ChangeNotifierProvider(create: (_) => ThemeProvider()),

        // Centralized Financial Data Manager (Supabase)
        ChangeNotifierProvider(
          create: (_) => FinancialDataManager()..initialize(),
        ),

        // Family Members Provider (Supabase)
        ChangeNotifierProvider(create: (_) => FamilyProvider()..initialize()),

        // Family Numbers Provider (Supabase)
        ChangeNotifierProvider(
          create: (_) => FamilyNumberProvider()..initialize(),
        ),

        // Tasks Provider (Supabase)
        ChangeNotifierProvider(create: (_) => TaskProvider()..initialize()),

        // Health Provider (Supabase)
        ChangeNotifierProvider(create: (_) => HealthProvider()..initialize()),

        // Reminder Provider
        ChangeNotifierProxyProvider<FinancialDataManager, ReminderProvider>(
          create: (_) => ReminderProvider()..initialize(),
          update: (_, financialManager, reminderProvider) =>
              reminderProvider!..setFinancialManager(financialManager),
        ),

        // Savings Goals Provider (Supabase)
        ChangeNotifierProvider(
          create: (_) => SavingsGoalProvider()..initialize(),
        ),

        // Family Event Provider (still uses local for now)
        ChangeNotifierProvider(
          create: (_) => FamilyEventProvider()..initialize(),
        ),

        // Analytics Provider
        ChangeNotifierProxyProvider<FinancialDataManager, AnalyticsProvider>(
          create: (_) => AnalyticsProvider(),
          update: (_, financialManager, analyticsProvider) =>
              analyticsProvider!..setFinancialManager(financialManager),
        ),

        // AI Service
        ChangeNotifierProvider(create: (_) => GeminiService()..initialize()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return AppLifecycleManager(
            child: MaterialApp(
              title: 'LifeSync',
              debugShowCheckedModeBanner: false,
              theme: themeProvider.themeData.copyWith(
                textTheme: GoogleFonts.interTextTheme(
                  themeProvider.themeData.textTheme,
                ),
              ),
              initialRoute: '/',
              routes: {
                '/': (context) => const SplashScreen(),
                '/login': (context) => const LoginScreen(),
                '/home': (context) => const HomeScreen(),
              },
            ),
          );
        },
      ),
    );
  }
}
