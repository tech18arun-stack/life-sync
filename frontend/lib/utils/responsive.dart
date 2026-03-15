import 'package:flutter/material.dart';

/// Responsive Design Utility
/// Provides breakpoints and helper methods for responsive layouts
class Responsive {
  // Breakpoints
  static const double mobileMaxWidth = 599;
  static const double tabletMinWidth = 600;
  static const double tabletMaxWidth = 1023;
  static const double desktopMinWidth = 1024;
  static const double largeDesktopMinWidth = 1440;

  // Grid columns
  static const int mobileColumns = 1;
  static const int tabletColumns = 2;
  static const int desktopColumns = 3;
  static const int largeDesktopColumns = 4;

  // Spacing
  static const double mobilePadding = 12.0;
  static const double tabletPadding = 24.0;
  static const double desktopPadding = 32.0;
  static const double largeDesktopPadding = 48.0;

  /// Check if the current screen is mobile
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileMaxWidth;
  }

  /// Check if the current screen is tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= tabletMinWidth && width < desktopMinWidth;
  }

  /// Check if the current screen is desktop
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopMinWidth;
  }

  /// Check if the current screen is large desktop
  static bool isLargeDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= largeDesktopMinWidth;
  }

  /// Get responsive padding based on screen size
  static EdgeInsets getPadding(BuildContext context) {
    if (isLargeDesktop(context)) {
      return const EdgeInsets.all(largeDesktopPadding);
    } else if (isDesktop(context)) {
      return const EdgeInsets.all(desktopPadding);
    } else if (isTablet(context)) {
      return const EdgeInsets.all(tabletPadding);
    } else {
      return const EdgeInsets.all(mobilePadding);
    }
  }

  /// Get responsive horizontal padding
  static double getHorizontalPadding(BuildContext context) {
    if (isLargeDesktop(context)) {
      return largeDesktopPadding;
    } else if (isDesktop(context)) {
      return desktopPadding;
    } else if (isTablet(context)) {
      return tabletPadding;
    } else {
      return mobilePadding;
    }
  }

  /// Get responsive vertical padding
  static double getVerticalPadding(BuildContext context) {
    return getHorizontalPadding(context);
  }

  /// Get responsive font scale
  static double getFontScale(BuildContext context) {
    if (isLargeDesktop(context)) {
      return 1.2;
    } else if (isDesktop(context)) {
      return 1.1;
    } else if (isTablet(context)) {
      return 1.0;
    } else {
      return 0.95;
    }
  }

  /// Get number of grid columns for current screen
  static int getColumns(BuildContext context) {
    if (isLargeDesktop(context)) {
      return largeDesktopColumns;
    } else if (isDesktop(context)) {
      return desktopColumns;
    } else if (isTablet(context)) {
      return tabletColumns;
    } else {
      return mobileColumns;
    }
  }

  /// Get max width for content container
  static double getMaxContentWidth(BuildContext context) {
    if (isLargeDesktop(context)) {
      return 1600.0;
    } else if (isDesktop(context)) {
      return 1400.0;
    } else if (isTablet(context)) {
      return 900.0;
    } else {
      return double.infinity;
    }
  }

  /// Get max width for centered content
  static double getMaxWidth(BuildContext context) {
    if (isDesktop(context)) {
      return 600.0;
    } else if (isTablet(context)) {
      return 500.0;
    } else {
      return double.infinity;
    }
  }

  /// Build responsive widget using LayoutBuilder
  static Widget build(
    BuildContext context, {
    required Widget Function(BuildContext, BoxConstraints) builder,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return builder(context, constraints);
      },
    );
  }

  /// Get responsive card height
  static double getCardHeight(BuildContext context) {
    if (isLargeDesktop(context)) {
      return 200.0;
    } else if (isDesktop(context)) {
      return 180.0;
    } else if (isTablet(context)) {
      return 160.0;
    } else {
      return 140.0;
    }
  }

  /// Get responsive card border radius
  static double getCardRadius(BuildContext context) {
    if (isDesktop(context)) {
      return 28.0;
    } else if (isTablet(context)) {
      return 24.0;
    } else {
      return 20.0;
    }
  }

  /// Get responsive button border radius
  static double getButtonRadius(BuildContext context) {
    if (isDesktop(context)) {
      return 16.0;
    } else if (isTablet(context)) {
      return 14.0;
    } else {
      return 12.0;
    }
  }

  /// Get responsive icon size
  static double getIconSize(BuildContext context) {
    if (isLargeDesktop(context)) {
      return 32.0;
    } else if (isDesktop(context)) {
      return 28.0;
    } else if (isTablet(context)) {
      return 24.0;
    } else {
      return 20.0;
    }
  }

  /// Get responsive small icon size
  static double getSmallIconSize(BuildContext context) {
    if (isDesktop(context)) {
      return 20.0;
    } else if (isTablet(context)) {
      return 18.0;
    } else {
      return 16.0;
    }
  }

  /// Get responsive avatar radius
  static double getAvatarRadius(BuildContext context) {
    if (isLargeDesktop(context)) {
      return 40.0;
    } else if (isDesktop(context)) {
      return 32.0;
    } else if (isTablet(context)) {
      return 28.0;
    } else {
      return 24.0;
    }
  }

  /// Get responsive button height
  static double getButtonHeight(BuildContext context) {
    if (isLargeDesktop(context)) {
      return 60.0;
    } else if (isDesktop(context)) {
      return 56.0;
    } else if (isTablet(context)) {
      return 52.0;
    } else {
      return 48.0;
    }
  }

  /// Get responsive button padding
  static EdgeInsets getButtonPadding(BuildContext context) {
    if (isDesktop(context)) {
      return const EdgeInsets.symmetric(horizontal: 32, vertical: 18);
    } else if (isTablet(context)) {
      return const EdgeInsets.symmetric(horizontal: 28, vertical: 16);
    } else {
      return const EdgeInsets.symmetric(horizontal: 24, vertical: 14);
    }
  }

  /// Get responsive font sizes
  static double getFontSize(BuildContext context, FontSizeType type) {
    final scale = getFontScale(context);
    switch (type) {
      case FontSizeType.small:
        return 12 * scale;
      case FontSizeType.body:
        return 14 * scale;
      case FontSizeType.subtitle:
        return 16 * scale;
      case FontSizeType.title:
        return 18 * scale;
      case FontSizeType.headline:
        return 24 * scale;
      case FontSizeType.display:
        return 32 * scale;
      case FontSizeType.largeDisplay:
        return 40 * scale;
    }
  }

  /// Get responsive spacing
  static double getSpacing(BuildContext context, SpacingType type) {
    switch (type) {
      case SpacingType.xs:
        return 4 * getFontScale(context);
      case SpacingType.sm:
        return 8 * getFontScale(context);
      case SpacingType.md:
        return 16 * getFontScale(context);
      case SpacingType.lg:
        return 24 * getFontScale(context);
      case SpacingType.xl:
        return 32 * getFontScale(context);
      case SpacingType.xxl:
        return 48 * getFontScale(context);
    }
  }

  /// Get responsive elevation
  static double getElevation(BuildContext context) {
    if (isDesktop(context)) {
      return 8.0;
    } else if (isTablet(context)) {
      return 6.0;
    } else {
      return 4.0;
    }
  }

  /// Get responsive blur radius
  static double getBlurRadius(BuildContext context) {
    if (isDesktop(context)) {
      return 20.0;
    } else if (isTablet(context)) {
      return 16.0;
    } else {
      return 12.0;
    }
  }

  /// Get responsive progress indicator height
  static double getProgressHeight(BuildContext context) {
    if (isDesktop(context)) {
      return 14.0;
    } else if (isTablet(context)) {
      return 12.0;
    } else {
      return 10.0;
    }
  }

  /// Get responsive input field height
  static double getInputHeight(BuildContext context) {
    if (isDesktop(context)) {
      return 56.0;
    } else if (isTablet(context)) {
      return 52.0;
    } else {
      return 48.0;
    }
  }

  /// Get responsive dialog border radius
  static double getDialogRadius(BuildContext context) {
    if (isDesktop(context)) {
      return 32.0;
    } else if (isTablet(context)) {
      return 28.0;
    } else {
      return 24.0;
    }
  }

  /// Get responsive sheet radius
  static double getSheetRadius(BuildContext context) {
    if (isDesktop(context)) {
      return 32.0;
    } else if (isTablet(context)) {
      return 28.0;
    } else {
      return 24.0;
    }
  }
}

enum FontSizeType {
  small,
  body,
  subtitle,
  title,
  headline,
  display,
  largeDisplay,
}

enum SpacingType { xs, sm, md, lg, xl, xxl }

/// Responsive Grid Widget
/// Automatically adjusts columns based on screen size
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final int? mobileColumns;
  final int? tabletColumns;
  final int? desktopColumns;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double? childAspectRatio;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.mobileColumns,
    this.tabletColumns,
    this.desktopColumns,
    this.mainAxisSpacing = 16,
    this.crossAxisSpacing = 16,
    this.childAspectRatio,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        
        int columns;
        if (width >= Responsive.desktopMinWidth) {
          columns = desktopColumns ?? Responsive.desktopColumns;
        } else if (width >= Responsive.tabletMinWidth) {
          columns = tabletColumns ?? Responsive.tabletColumns;
        } else {
          columns = mobileColumns ?? Responsive.mobileColumns;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: mainAxisSpacing,
            crossAxisSpacing: crossAxisSpacing,
            childAspectRatio: childAspectRatio ?? _getDefaultAspectRatio(context, columns),
          ),
          itemCount: children.length,
          itemBuilder: (context, index) => children[index],
        );
      },
    );
  }

  double _getDefaultAspectRatio(BuildContext context, int columns) {
    if (Responsive.isDesktop(context)) {
      return 1.5;
    } else if (Responsive.isTablet(context)) {
      return 1.3;
    } else {
      return 1.2;
    }
  }
}

/// Responsive Wrapper
/// Centers content with max width on large screens
class ResponsiveWrapper extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsetsGeometry? padding;

  const ResponsiveWrapper({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final effectiveMaxWidth = maxWidth ?? Responsive.getMaxContentWidth(context);
        
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
            child: Padding(
              padding: padding ?? Responsive.getPadding(context),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

/// Responsive Row
/// Wraps to new line on smaller screens
class ResponsiveRow extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final WrapCrossAlignment crossAxisAlignment;
  final WrapAlignment mainAxisAlignment;

  const ResponsiveRow({
    super.key,
    required this.children,
    this.spacing = 16,
    this.runSpacing = 16,
    this.crossAxisAlignment = WrapCrossAlignment.center,
    this.mainAxisAlignment = WrapAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          crossAxisAlignment: crossAxisAlignment,
          alignment: mainAxisAlignment,
          children: children,
        );
      },
    );
  }
}

/// Responsive Card Grid Item
class ResponsiveCardItem extends StatelessWidget {
  final Widget child;
  final bool expand;

  const ResponsiveCardItem({
    super.key,
    required this.child,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (expand || Responsive.isDesktop(context)) {
          return child;
        } else if (Responsive.isTablet(context)) {
          return SizedBox(
            width: constraints.maxWidth,
            child: child,
          );
        } else {
          return SizedBox(
            width: constraints.maxWidth,
            child: child,
          );
        }
      },
    );
  }
}
