import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import '../services/startio_ads.dart';
import '../utils/app_theme.dart';

class PremiumGate extends StatefulWidget {
  final Widget child;
  final String featureName;
  final int requiredAds;
  final Duration unlockDuration;
  final IconData icon;
  final bool isInline;

  const PremiumGate({
    super.key,
    required this.child,
    required this.featureName,
    this.requiredAds = 3,
    this.unlockDuration = const Duration(hours: 12),
    this.icon = Icons.workspace_premium,
    this.isInline = false,
  });

  @override
  State<PremiumGate> createState() => _PremiumGateState();
}

class _PremiumGateState extends State<PremiumGate> {
  bool _isInit = false;
  int _adsWatched = 0;
  DateTime? _unlockExpiry;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final featureKey = widget.featureName.replaceAll(' ', '_').toLowerCase();
    
    final expiryStr = prefs.getString('gate_expiry_$featureKey');
    final watched = prefs.getInt('gate_watched_$featureKey') ?? 0;

    DateTime? expiry;
    if (expiryStr != null) {
      expiry = DateTime.parse(expiryStr);
    }

    // Reset ads watched if expired
    if (expiry != null && expiry.isBefore(DateTime.now())) {
      expiry = null;
      await prefs.remove('gate_expiry_$featureKey');
      await prefs.remove('gate_watched_$featureKey');
    }

    if (mounted) {
      setState(() {
        _unlockExpiry = expiry;
        _adsWatched = expiry == null ? watched : widget.requiredAds;
        _isInit = true;
      });
    }
  }

  Future<void> _watchAd() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await StartIOAds.showRewarded(context);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (success) {
          _adsWatched++;
          
          final prefs = await SharedPreferences.getInstance();
          final featureKey = widget.featureName.replaceAll(' ', '_').toLowerCase();
          
          if (_adsWatched >= widget.requiredAds) {
            _unlockExpiry = DateTime.now().add(widget.unlockDuration);
            await prefs.setString('gate_expiry_$featureKey', _unlockExpiry!.toIso8601String());
            await prefs.setInt('gate_watched_$featureKey', _adsWatched);
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('🎉 Unlocked! You have access to ${widget.featureName} for the next ${widget.unlockDuration.inHours} hours!'),
                backgroundColor: AppTheme.successColor,
                behavior: SnackBarBehavior.floating,
              )
            );
          } else {
            await prefs.setInt('gate_watched_$featureKey', _adsWatched);
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ Ad watched! $_adsWatched/${widget.requiredAds} required ads completed.'),
                backgroundColor: AppTheme.primaryColor,
                behavior: SnackBarBehavior.floating,
              )
            );
          }
        } else {
          // Ad failed to load or user closed it early
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Unable to load ad. Please check your internet and try again.'),
              backgroundColor: AppTheme.errorColor,
              behavior: SnackBarBehavior.floating,
            )
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          )
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInit) return const Center(child: CircularProgressIndicator());

    final auth = Provider.of<AuthProvider>(context);
    final isPremium = auth.currentUser?.isPremiumActive ?? false;

    // Check if successfully unlocked via ads or premium
    final isUnlocked = isPremium || (_unlockExpiry != null && _unlockExpiry!.isAfter(DateTime.now()));

    if (isUnlocked) {
      return widget.child;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (widget.isInline) {
      return Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.1)),
          boxShadow: [AppTheme.cardShadow],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(widget.icon, size: 32, color: AppTheme.primaryColor),
            ),
            const SizedBox(height: 16),
            Text(
              'Premium Feature',
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
            ),
            const SizedBox(height: 8),
            Text(
              'Unlock ${widget.featureName} by watching ${widget.requiredAds} short ads.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 20),
            
            // Tiny progress
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.requiredAds, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 30,
                  height: 6,
                  decoration: BoxDecoration(
                    color: index < _adsWatched ? AppTheme.primaryColor : (isDark ? Colors.white10 : Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(10),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _watchAd,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(_isLoading ? 'Loading...' : 'Watch Ad to Unlock', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundColor : const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: Text(widget.featureName, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 20)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: isDark ? Colors.white : Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(widget.icon, size: 72, color: AppTheme.primaryColor),
            ),
            const SizedBox(height: 32),
            Text(
              'Premium Feature',
              style: GoogleFonts.inter(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${widget.featureName} is available exclusively to Premium users.\n\nAlternatively, you can watch ${widget.requiredAds} short ads to unlock full access for ${widget.unlockDuration.inHours} hours.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: isDark ? Colors.white70 : Colors.black87,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 48),
            
            // Progress Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.requiredAds, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  width: 40,
                  height: 10,
                  decoration: BoxDecoration(
                    gradient: index < _adsWatched 
                        ? AppTheme.primaryGradient 
                        : null,
                    color: index < _adsWatched 
                        ? null 
                        : (isDark ? Colors.white12 : Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(10),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            Text(
              '$_adsWatched / ${widget.requiredAds} Ads Watched',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 48),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _watchAd,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
                icon: _isLoading 
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.play_circle_fill, size: 26),
                label: Text(
                  _isLoading ? 'Loading Ad...' : 'Watch Ad to Unlock',
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text('Maybe Later', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
