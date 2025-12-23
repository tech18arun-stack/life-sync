import 'package:flutter/material.dart';

class AppTheme {
  // Brand Colors
  static const primaryColor = Color(0xFF6C63FF);
  static const secondaryColor = Color(0xFFFF6584);
  static const accentColor = Color(0xFF4ECDC4);
  static const backgroundColor = Color(0xFF0F0E17);
  static const surfaceColor = Color(0xFF1C1B29);
  static const cardColor = Color(0xFF2A2938);

  // Text Colors
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFB8B8D1);
  static const textTertiary = Color(0xFF6E6D7A);

  // Border Color
  static const borderColor = Color(0xFF2A2938);

  // Status Colors
  static const successColor = Color(0xFF00D9A3);
  static const warningColor = Color(0xFFFFC107);
  static const errorColor = Color(0xFFFF5252);
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
      case 'credit card':
        return warningColor;
      case 'kids':
        return const Color(0xFFFFCCBC);
      case 'pets':
        return const Color(0xFFD7CCC8);
      case 'emergency fund':
      case 'emergency':
        return errorColor;
      default:
        return othersColor;
    }
  }

  static LinearGradient get primaryGradient {
    return const LinearGradient(
      colors: [primaryColor, Color(0xFF8B7FFF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  static LinearGradient get accentGradient {
    return const LinearGradient(
      colors: [accentColor, Color(0xFF3ABCB3)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  static BoxShadow get cardShadow {
    return BoxShadow(
      color: Colors.black.withValues(alpha: 0.2),
      blurRadius: 10,
      offset: const Offset(0, 4),
    );
  }

  // Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      cardColor: Colors.white,

      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: accentColor,
        surface: Colors.white,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Color(0xFF1A1A1A),
      ),

      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1A1A1A),
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1A1A1A),
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1A1A1A),
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1A1A1A),
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1A1A1A),
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Color(0xFF1A1A1A),
        ),
        bodyLarge: TextStyle(fontSize: 16, color: Color(0xFF1A1A1A)),
        bodyMedium: TextStyle(fontSize: 14, color: Color(0xFF4A4A4A)),
        bodySmall: TextStyle(fontSize: 12, color: Color(0xFF6A6A6A)),
      ),

      cardTheme: const CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: Color(0xFFE0E0E0), width: 1),
        ),
        color: Colors.white,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF5F5F5),
        foregroundColor: Color(0xFF1A1A1A),
        elevation: 0,
        centerTitle: false,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  static IconData getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
      case 'food & dining':
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
      case 'credit card':
        return Icons.money_off;
      case 'recharge':
        return Icons.phone_android;
      case 'subscription':
        return Icons.subscriptions;
      case 'kids':
        return Icons.child_care;
      case 'pets':
        return Icons.pets;
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
