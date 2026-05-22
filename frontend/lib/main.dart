import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'services/appwrite_service.dart';
import 'providers/auth_provider.dart';
import 'services/deep_link_service.dart';
import 'providers/financial_data_manager.dart';
import 'providers/family_provider.dart';
import 'providers/family_number_provider.dart';
import 'providers/task_provider.dart';
import 'providers/reminder_provider.dart';
import 'providers/savings_goal_provider.dart';


import 'providers/family_event_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/analytics_provider.dart';
import 'providers/subscription_provider.dart';

import 'services/notification_service.dart';
import 'services/gemini_service.dart';
import 'services/security_service.dart';
import 'services/auth_service.dart';
import 'services/categorization_service.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';
import 'services/startio_ads.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart';
import 'widgets/app_lifecycle_manager.dart';
import 'services/config_service.dart';
import 'screens/maintenance_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Config Service First
  await ConfigService().initialize(forceRefresh: false);
  
  // Debug: Print config values to verify premium cost
  ConfigService().debugPrintConfig();

  // Initialize Appwrite
  await AppwriteService().initialize();

  // Initialize Security Service (App Lock / Biometric)
  await SecurityService().initialize();

  // ⭐ CRITICAL: Initialize Auth Service early to detect Premium status before Ads/Splash
  final authService = AuthService();
  await authService.initialize();

  // Initialize platform-specific services only on mobile
  if (!kIsWeb) {
    // Initialize Notification Service
    final notificationService = NotificationService();
    await notificationService.initialize();
    await notificationService.requestPermissions();

    // Initialize Deep Link Service
    await DeepLinkService.initDeepLinks();

    // Initialize Start.io only if enabled and user is NOT premium
    if (ConfigService().adsEnabled && ConfigService().startioEnabled && authService.currentUser?.isPremiumActive != true) {
      await StartIOAds.initialize(ConfigService().startioAppId);
    }
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

        // Centralized Financial Data Manager (Appwrite)
        ChangeNotifierProxyProvider<AuthProvider, FinancialDataManager>(
          create: (_) => FinancialDataManager(),
          update: (_, auth, manager) {
            final mgr = manager ?? FinancialDataManager();
            // Re-initialize or clear when auth state changes
            if (auth.isLoggedIn && !mgr.isInitialized) {
              Future.microtask(() => mgr.initialize());
            } else if (!auth.isLoggedIn && mgr.isInitialized) {
              Future.microtask(() => mgr.clear());
            }
            return mgr;
          },
        ),

        // Family Members Provider (Appwrite)
        ChangeNotifierProxyProvider<AuthProvider, FamilyProvider>(
          create: (_) => FamilyProvider(),
          update: (_, auth, provider) {
            final p = provider ?? FamilyProvider();
            if (auth.isLoggedIn && !p.isLoading && p.members.isEmpty) {
              Future.microtask(
                () => p.initialize(),
              ); // Simplified check for now
            }
            return p;
          },
        ),

        // Family Numbers Provider (Appwrite)
        ChangeNotifierProxyProvider<AuthProvider, FamilyNumberProvider>(
          create: (_) => FamilyNumberProvider(),
          update: (_, auth, provider) {
            final p = provider ?? FamilyNumberProvider();
            if (auth.isLoggedIn && !p.isLoading && p.numbers.isEmpty) {
              Future.microtask(() => p.initialize());
            }
            return p;
          },
        ),

        // Tasks Provider (Appwrite)
        ChangeNotifierProxyProvider<AuthProvider, TaskProvider>(
          create: (_) => TaskProvider(),
          update: (_, auth, provider) {
            final p = provider ?? TaskProvider();
            if (auth.isLoggedIn && !p.isLoading && p.tasks.isEmpty) {
              Future.microtask(() => p.initialize());
            }
            return p;
          },
        ),

        // Reminder Provider
        ChangeNotifierProxyProvider<FinancialDataManager, ReminderProvider>(
          create: (_) => ReminderProvider()..initialize(),
          update: (_, financialManager, reminderProvider) =>
              reminderProvider!..setFinancialManager(financialManager),
        ),

        // Savings Goals Provider (Appwrite)
        ChangeNotifierProxyProvider<AuthProvider, SavingsGoalProvider>(
          create: (_) => SavingsGoalProvider(),
          update: (_, auth, provider) {
            final p = provider ?? SavingsGoalProvider();
            if (auth.isLoggedIn && !p.isLoading && p.goals.isEmpty) {
              Future.microtask(() => p.initialize());
            }
            return p;
          },
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

        // Subscription Provider
        ChangeNotifierProxyProvider<AuthProvider, SubscriptionProvider>(
          create: (_) => SubscriptionProvider(),
          update: (_, auth, provider) {
            final p = provider ?? SubscriptionProvider();
            if (auth.isLoggedIn && !p.isLoading && p.subscriptions.isEmpty) {
              Future.microtask(() => p.initialize());
            } else if (!auth.isLoggedIn && p.subscriptions.isNotEmpty) {
              Future.microtask(() => p.clear());
            }
            return p;
          },
        ),



        // AI Service
        ChangeNotifierProvider(create: (_) => GeminiService()..initialize()),

        // Categorization Service (depends on GeminiService)
        ProxyProvider<GeminiService, CategorizationService>(
          update: (_, gemini, __) => CategorizationService(gemini),
        ),
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
              initialRoute: ConfigService().maintenanceMode
                  ? '/maintenance'
                  : '/',
              routes: {
                '/': (context) => const SplashScreen(),
                '/maintenance': (context) => const MaintenanceScreen(),
                '/onboarding': (context) => const OnboardingScreen(),
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
