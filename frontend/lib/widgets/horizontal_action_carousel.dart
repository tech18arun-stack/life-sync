import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HorizontalActionCarousel extends StatelessWidget {
  final List<ActionCardItem> actions;

  const HorizontalActionCarousel({super.key, required this.actions});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: actions.length,
        itemBuilder: (context, index) {
          final action = actions[index];
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _buildCard(action, context),
          );
        },
      ),
    );
  }

  Widget _buildCard(ActionCardItem action, BuildContext context) {
    return GestureDetector(
      onTap: action.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 120,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: action.colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: action.colors.last.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(action.icon, color: Colors.white, size: 20),
              ),
              Text(
                action.title,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ActionCardItem {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final List<Color> colors;

  ActionCardItem({
    required this.title,
    required this.icon,
    required this.onTap,
    required this.colors,
  });
}
