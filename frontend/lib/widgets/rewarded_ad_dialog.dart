import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/startio_ads.dart';
import '../providers/auth_provider.dart';

/// Rewarded Ad Dialog for Premium Features
///
/// Users can watch a rewarded video to unlock:
/// - AI Financial Insights
/// - Premium Budget Tips
/// - Advanced Analytics
class RewardedAdDialog extends StatefulWidget {
  final String featureName;
  final Function onRewardEarned;

  const RewardedAdDialog({
    super.key,
    required this.featureName,
    required this.onRewardEarned,
  });

  @override
  State<RewardedAdDialog> createState() => _RewardedAdDialogState();
}

class _RewardedAdDialogState extends State<RewardedAdDialog> {
  bool _isLoading = false;
  bool _adWatched = false;

  @override
  void initState() {
    super.initState();
    // Auto-grant if already premium
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.currentUser?.isPremiumActive ?? false) {
        widget.onRewardEarned();
        Navigator.pop(context);
      }
    });
  }

  Future<void> _watchAd() async {
    setState(() {
      _isLoading = true;
    });

    // Show rewarded video (passes context for premium check)
    final success = await StartIOAds.showRewarded(context);

    if (success && mounted) {
      setState(() {
        _adWatched = true;
        _isLoading = false;
      });

      // Grant reward after short delay
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        widget.onRewardEarned();
        Navigator.pop(context);
      }
    } else if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.workspace_premium,
                size: 48,
                color: Color(0xFF6C63FF),
              ),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              'Unlock ${widget.featureName}',
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Description
            Text(
              'Watch a short video to unlock this premium feature for free!',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),

            // Benefits
            _buildBenefitRow('✨ Instant access'),
            _buildBenefitRow('🎯 No subscription needed'),
            _buildBenefitRow('⏱️ Takes less than 30 seconds'),
            const SizedBox(height: 24),

            // Watch Ad Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _watchAd,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Text(
                        '🎬 Watch Video to Unlock',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),

            // Skip Button
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Maybe Later',
                style: GoogleFonts.inter(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitRow(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle,
            size: 16,
            color: Colors.green,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
