import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shimmer/shimmer.dart';
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.accentColor.withOpacity(0.15),
            AppTheme.primaryColor.withOpacity(0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.accentColor.withOpacity(0.3),
          width: 1,
        ),
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
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accentColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const FaIcon(
                  FontAwesomeIcons.wandMagicSparkles,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (widget.onRefresh != null)
                IconButton(
                  onPressed: widget.isLoading ? null : widget.onRefresh,
                  icon: widget.isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
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

          const SizedBox(height: 16),

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
                  padding: const EdgeInsets.only(right: 8, top: 2),
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
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(height: 1.5, fontSize: 14),
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
      baseColor: AppTheme.surfaceColor,
      highlightColor: AppTheme.cardColor,
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
            color: AppTheme.textTertiary,
          ),
          const SizedBox(height: 12),
          Text(
            'Set up your Gemini API key in Settings\nto get personalized financial tips',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textTertiary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
