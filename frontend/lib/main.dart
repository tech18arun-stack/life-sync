import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'providers/auth_provider.dart';
import 'providers/financial_data_manager.dart';
import 'providers/health_provider.dart';
import 'providers/family_provider.dart';
import 'providers/family_number_provider.dart';
import 'providers/task_provider.dart';
import 'providers/reminder_provider.dart';
import 'providers/savings_goal_provider.dart';
import 'providers/shopping_list_provider.dart';
import 'providers/family_event_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/analytics_provider.dart';
import 'services/notification_service.dart';
import 'services/backup_service.dart';
import 'utils/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/expenses_screen.dart';
import 'screens/health_screen.dart';
import 'screens/tasks_screen.dart';
import 'screens/menu_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';

import 'package:font_awesome_flutter/font_awesome_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize platform-specific services only on mobile
  if (!kIsWeb) {
    // Initialize Notification Service
    final notificationService = NotificationService();
    await notificationService.initialize();
    await notificationService.requestPermissions();

    // Request Storage Permission (for backup features)
    final backupService = BackupService();
    await backupService.requestStoragePermission();
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

        // Centralized Financial Data Manager (MongoDB)
        ChangeNotifierProvider(create: (_) => FinancialDataManager()),

        // Family Members Provider (MongoDB)
        ChangeNotifierProvider(create: (_) => FamilyProvider()),

        // Family Numbers Provider (MongoDB)
        ChangeNotifierProvider(create: (_) => FamilyNumberProvider()),

        // Tasks Provider (MongoDB)
        ChangeNotifierProvider(create: (_) => TaskProvider()),

        // Health Provider (still uses local for now)
        ChangeNotifierProvider(create: (_) => HealthProvider()..initialize()),

        // Reminder Provider
        ChangeNotifierProxyProvider<FinancialDataManager, ReminderProvider>(
          create: (_) => ReminderProvider()..initialize(),
          update: (_, financialManager, reminderProvider) =>
              reminderProvider!..setFinancialManager(financialManager),
        ),

        // Savings Goals Provider (MongoDB)
        ChangeNotifierProxyProvider<FinancialDataManager, SavingsGoalProvider>(
          create: (_) => SavingsGoalProvider(),
          update: (_, financialManager, savingsProvider) =>
              savingsProvider!..setFinancialManager(financialManager),
        ),

        // Shopping List Provider (still uses local for now)
        ChangeNotifierProvider(
          create: (_) => ShoppingListProvider()..initialize(),
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
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
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
              '/home': (context) => const MainScreen(),
             
            },
          );
        },
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    ExpensesScreen(),
    HealthScreen(),
    TasksScreen(),
    MenuScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Theme.of(context).cardColor,
          selectedItemColor: AppTheme.primaryColor,
          unselectedItemColor: Theme.of(context).textTheme.bodySmall?.color,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: const [
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: FaIcon(FontAwesomeIcons.house, size: 20),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: FaIcon(FontAwesomeIcons.house, size: 22),
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: FaIcon(FontAwesomeIcons.wallet, size: 20),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: FaIcon(FontAwesomeIcons.wallet, size: 22),
              ),
              label: 'Expenses',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: FaIcon(FontAwesomeIcons.heartPulse, size: 20),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: FaIcon(FontAwesomeIcons.heartPulse, size: 22),
              ),
              label: 'Health',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: FaIcon(FontAwesomeIcons.listCheck, size: 20),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: FaIcon(FontAwesomeIcons.listCheck, size: 22),
              ),
              label: 'Tasks',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: FaIcon(FontAwesomeIcons.bars, size: 20),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: FaIcon(FontAwesomeIcons.bars, size: 22),
              ),
              label: 'Menu',
            ),
          ],
        ),
      ),
    );
  }
}
