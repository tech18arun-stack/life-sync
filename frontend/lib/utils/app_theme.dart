import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors
  static const primaryColor = Color(0xFF8A56FF); // Premium Purple
  static const primaryDark = Color(0xFF5E35B1); // Dark Purple
  static const primaryLight = Color(0xFFB388FF); // Light Purple
  static const secondaryColor = Color(0xFFFF6584);
  static const accentColor = Color(0xFF4ECDC4);
  static const accentBlue = Color(0xFF2E65F3); // Modern Blue
  static const accentGreen = Color(0xFF2E7D32); // Success Green

  // Background Colors
  static const backgroundColor = Color(0xFF0F0E17);
  static const backgroundColorLight = Color(0xFFF5F7FA);
  static const surfaceColor = Color(0xFF1C1B29);
  static const cardColor = Color(0xFF2A2938);
  static const glassWhite = Color(0xFFFFFFFF);

  // Text Colors
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFB8B8D1);
  static const textTertiary = Color(0xFF6E6D7A);
  static const textDark = Color(0xFF1A1A1A);
  static const textDarkSecondary = Color(0xFF4A4A4A);

  // Border Color
  static const borderColor = Color(0xFF2A2938);
  static const borderColorLight = Color(0xFFE0E0E0);

  // Status Colors
  static const successColor = Color(0xFF00D9A3);
  static const successGreen = Color(0xFF4CAF50);
  static const warningColor = Color(0xFFFFC107);
  static const errorColor = Color(0xFFD32F2F);
  static const infoColor = Color(0xFF64B5F6);

  // Category Colors
  static const foodColor = Color(0xFFFF6B6B);
  static const transportColor = Color(0xFF4ECDC4);
  static const healthColor = Color(0xFFFFE66D);
  static const educationColor = Color(0xFF95E1D3);
  static const entertainmentColor = Color(0xFFAA96DA);
  static const utilitiesColor = Color(0xFFFCAA67);
  static const shoppingColor = Color(0xFFFF8B94);
  static const rentColor = Color(0xFF8D6E63);
  static const insuranceColor = Color(0xFF3F51B5);
  static const groceriesColor = Color(0xFF66BB6A);
  static const diningOutColor = Color(0xFFFF7043);
  static const travelColor = Color(0xFF42A5F5);
  static const personalCareColor = Color(0xFFEC407A);
  static const giftsColor = Color(0xFFAB47BC);
  static const investmentsColor = Color(0xFF26A69A);
  static const othersColor = Color(0xFF9FA0FF);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      cardColor: cardColor,

      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: accentColor,
        surface: surfaceColor,
        error: errorColor,
        onPrimary: textPrimary,
        onSecondary: textPrimary,
        onSurface: textPrimary,
        onError: textPrimary,
      ),

      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        bodyLarge: TextStyle(fontSize: 16, color: textSecondary),
        bodyMedium: TextStyle(fontSize: 14, color: textSecondary),
        bodySmall: TextStyle(fontSize: 12, color: textTertiary),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundColor,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),

      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: textPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: textPrimary,
        elevation: 4,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintStyle: const TextStyle(color: textTertiary),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
      ),

      dividerTheme: const DividerThemeData(
        color: surfaceColor,
        thickness: 1,
        space: 1,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: surfaceColor,
        selectedColor: primaryColor,
        labelStyle: const TextStyle(color: textPrimary),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  static Color getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
      case 'food & dining':
        return foodColor;
      case 'transport':
      case 'transportation':
      case 'car':
        return transportColor;
      case 'health':
      case 'healthcare':
      case 'health & fitness':
      case 'medical':
        return healthColor;
      case 'education':
      case 'school fees':
        return educationColor;
      case 'entertainment':
      case 'subscription':
      case 'gadgets':
        return entertainmentColor;
      case 'utilities':
      case 'bills':
      case 'bill':
      case 'recharge':
      case 'mobile recharge':
      case 'dth':
      case 'mobile bill':
      case 'internet bill':
        return utilitiesColor;
      case 'shopping':
        return shoppingColor;
      case 'rent':
      case 'housing':
      case 'home':
        return rentColor;
      case 'insurance':
        return insuranceColor;
      case 'groceries':
      case 'vegetables':
      case 'fruits':
      case 'meat':
      case 'dairy':
        return groceriesColor;
      case 'dining out':
        return diningOutColor;
      case 'travel':
      case 'vacation':
        return travelColor;
      case 'personal care':
        return personalCareColor;
      case 'gifts':
      case 'gifts & donations':
      case 'charity':
      case 'wedding':
        return giftsColor;
      case 'investments':
      case 'investment':
      case 'retirement':
      case 'business':
        return investmentsColor;
      case 'debt payments':
      case 'loan':
      case 'emi':
      case 'emi payment':
      case 'credit card':
        return warningColor;
      case 'kids':
      case 'childcare':
      case 'school':
      case 'tuition':
      case 'education fee':
        return const Color(0xFFFFCCBC);
      case 'pets':
      case 'pet care':
        return const Color(0xFFD7CCC8);
      case 'household':
      case 'home maintenance':
      case 'cleaning supplies':
      case 'furniture':
        return const Color(0xFFA1887F);
      case 'family':
      case 'family outing':
      case 'family dinner':
        return const Color(0xFF81C784);
      case 'emergency fund':
      case 'emergency':
        return errorColor;
      default:
        return othersColor;
    }
  }

  // Brand Gradients
  static LinearGradient get primaryGradient {
    return const LinearGradient(
      colors: [Color(0xFF8A56FF), Color(0xFF5E35B1)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  static LinearGradient get purpleGradient {
    return const LinearGradient(
      colors: [Color(0xFF8A56FF), Color(0xFF5E35B1)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );
  }

  static LinearGradient get blueGradient {
    return const LinearGradient(
      colors: [Color(0xFF2E65F3), Color(0xFF152A72)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  static LinearGradient get successGradient {
    return const LinearGradient(
      colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  static LinearGradient get accentGradient {
    return const LinearGradient(
      colors: [Color(0xFF4ECDC4), Color(0xFF3ABCB3)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  static LinearGradient get sunsetGradient {
    return const LinearGradient(
      colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  static LinearGradient get oceanGradient {
    return const LinearGradient(
      colors: [Color(0xFF2E65F3), Color(0xFF4ECDC4)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  static LinearGradient get darkGradient {
    return const LinearGradient(
      colors: [Color(0xFF1C1B29), Color(0xFF0F0E17)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );
  }

  static LinearGradient get cardGradient {
    return LinearGradient(
      colors: [primaryColor.withOpacity(0.1), primaryColor.withOpacity(0.02)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  static LinearGradient get glassGradient {
    return LinearGradient(
      colors: [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.02)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  // Shadows
  static BoxShadow get cardShadow {
    return BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 20,
      offset: const Offset(0, 8),
    );
  }

  static BoxShadow get softShadow {
    return BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 15,
      offset: const Offset(0, 5),
    );
  }

  static BoxShadow get elevatedShadow {
    return BoxShadow(
      color: Colors.black.withOpacity(0.12),
      blurRadius: 25,
      offset: const Offset(0, 10),
    );
  }

  static BoxShadow get glowShadow {
    return BoxShadow(
      color: primaryColor.withOpacity(0.3),
      blurRadius: 20,
      offset: const Offset(0, 8),
    );
  }

  static BoxShadow get greenGlowShadow {
    return BoxShadow(
      color: successColor.withOpacity(0.3),
      blurRadius: 20,
      offset: const Offset(0, 8),
    );
  }

  // Border Radius Constants
  static const double smallRadius = 12.0;
  static const double mediumRadius = 20.0;
  static const double largeRadius = 24.0;
  static const double extraLargeRadius = 32.0;
  static const double pillRadius = 50.0;

  // Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColorLight,
      cardColor: Colors.white,

      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: accentColor,
        surface: Colors.white,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textDark,
      ),

      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textDark,
          letterSpacing: -0.5,
        ),
        displayMedium: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: textDark,
        ),
        displaySmall: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textDark,
        ),
        headlineMedium: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textDark,
        ),
        titleLarge: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textDark,
        ),
        titleMedium: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textDark,
        ),
        bodyLarge: const TextStyle(fontSize: 16, color: textDarkSecondary),
        bodyMedium: const TextStyle(fontSize: 14, color: textDarkSecondary),
        bodySmall: const TextStyle(fontSize: 12, color: textSecondary),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundColorLight,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textDark,
        ),
        iconTheme: IconThemeData(color: textDark),
      ),

      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderColorLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderColorLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintStyle: const TextStyle(color: textSecondary),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primaryColor,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
      ),

      dividerTheme: const DividerThemeData(
        color: borderColorLight,
        thickness: 1,
        space: 1,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: primaryColor,
        labelStyle: const TextStyle(color: textDark),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  static IconData getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
      case 'food & dining':
      case 'vegetables':
      case 'fruits':
      case 'meat':
      case 'dairy':
        return Icons.restaurant;
      case 'transport':
      case 'transportation':
        return Icons.directions_car;
      case 'health':
      case 'healthcare':
      case 'health & fitness':
      case 'medical':
        return Icons.medical_services;
      case 'education':
      case 'school fees':
        return Icons.school;
      case 'entertainment':
        return Icons.movie;
      case 'utilities':
      case 'bills':
      case 'bill':
        return Icons.electrical_services;
      case 'shopping':
        return Icons.shopping_bag;
      case 'rent':
      case 'housing':
      case 'home':
        return Icons.home;
      case 'insurance':
        return Icons.security;
      case 'groceries':
        return Icons.local_grocery_store;
      case 'dining out':
        return Icons.dining;
      case 'travel':
      case 'vacation':
        return Icons.flight;
      case 'personal care':
        return Icons.face;
      case 'gifts':
      case 'gifts & donations':
      case 'charity':
        return Icons.card_giftcard;
      case 'investments':
      case 'investment':
      case 'business':
        return Icons.trending_up;
      case 'debt payments':
      case 'loan':
      case 'emi':
      case 'emi payment':
      case 'credit card':
        return Icons.money_off;
      case 'recharge':
      case 'mobile recharge':
      case 'mobile bill':
        return Icons.phone_android;
      case 'dth':
      case 'internet bill':
        return Icons.router;
      case 'subscription':
        return Icons.subscriptions;
      case 'kids':
      case 'childcare':
        return Icons.child_care;
      case 'pets':
      case 'pet care':
        return Icons.pets;
      case 'school':
      case 'tuition':
      case 'education fee':
        return Icons.school;
      case 'household':
      case 'home maintenance':
        return Icons.home_repair_service;
      case 'cleaning supplies':
        return Icons.clean_hands;
      case 'furniture':
        return Icons.chair_alt;
      case 'family':
      case 'family outing':
      case 'family dinner':
        return Icons.family_restroom;
      case 'car':
        return Icons.directions_car;
      case 'wedding':
        return Icons.favorite;
      case 'retirement':
        return Icons.elderly;
      case 'gadgets':
        return Icons.devices;
      case 'emergency fund':
      case 'emergency':
        return Icons.warning;
      default:
        return Icons.category;
    }
  }
}
