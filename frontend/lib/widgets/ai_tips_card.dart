import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shimmer/shimmer.dart';
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts
import '../utils/app_theme.dart';

class AITipsCard extends StatefulWidget {
  final String? tip;
  final bool isLoading;
  final VoidCallback? onRefresh;
  final String title;

  const AITipsCard({
    super.key,
    this.tip,
    this.isLoading = false,
    this.onRefresh,
    this.title = '💡 AI Tips',
  });

  @override
  State<AITipsCard> createState() => _AITipsCardState();
}

class _AITipsCardState extends State<AITipsCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: AppTheme.accentGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accentColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const FaIcon(
                  FontAwesomeIcons.wandMagicSparkles,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  widget.title,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ),
              if (widget.onRefresh != null)
                IconButton(
                  onPressed: widget.isLoading ? null : widget.onRefresh,
                  icon: widget.isLoading
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.accentColor,
                            ),
                          ),
                        )
                      : const FaIcon(FontAwesomeIcons.arrowsRotate, size: 16),
                  color: AppTheme.accentColor,
                  tooltip: 'Refresh tips',
                ),
            ],
          ),

          const SizedBox(height: 20),

          // Content
          if (widget.isLoading)
            _buildShimmerLoading()
          else if (widget.tip != null && widget.tip!.isNotEmpty)
            _buildTipContent()
          else
            _buildEmptyState(),
        ],
      ),
    );
  }

  Widget _buildTipContent() {
    // Parse the tip into sections if it contains numbered points
    final lines = widget.tip!
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        // Check if it's a numbered point or bullet
        final isNumbered = RegExp(r'^\d+\.|^-|^•').hasMatch(line.trim());

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isNumbered)
                Padding(
                  padding: const EdgeInsets.only(right: 10, top: 6),
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              Expanded(
                child: Text(
                  line.replaceAll(RegExp(r'^\d+\.|^-|^•'), '').trim(),
                  style: GoogleFonts.inter(
                    height: 1.6,
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Theme.of(context).cardColor,
      highlightColor: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 16,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 16,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 16,
            width: MediaQuery.of(context).size.width * 0.7,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          FaIcon(
            FontAwesomeIcons.robot,
            size: 40,
            color: Theme.of(context).disabledColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Set up your Gemini API key in Settings\nto get personalized financial tips',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: Theme.of(context).disabledColor,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
