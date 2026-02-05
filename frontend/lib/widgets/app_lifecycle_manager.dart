import 'package:flutter/material.dart';
import '../services/security_service.dart';
import '../screens/biometric_auth_screen.dart';

class AppLifecycleManager extends StatefulWidget {
  final Widget child;

  const AppLifecycleManager({super.key, required this.child});

  @override
  State<AppLifecycleManager> createState() => _AppLifecycleManagerState();
}

class _AppLifecycleManagerState extends State<AppLifecycleManager>
    with WidgetsBindingObserver {
  bool _isLocked = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initSecurity();
  }

  Future<void> _initSecurity() async {
    // Wait for security service to be ready
    await SecurityService().initialize();

    if (mounted) {
      setState(() {
        _initialized = true;
        _isLocked = SecurityService().isAppLockEnabled;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_initialized) return;

    if (state == AppLifecycleState.paused) {
      // App went to background
      if (SecurityService().isAppLockEnabled) {
        setState(() {
          _isLocked = true;
        });
      }
    }
  }

  void _onAuthenticated() {
    setState(() {
      _isLocked = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show loading while initializing
    if (!_initialized) {
      return widget.child;
    }

    // Show lock screen if locked
    if (_isLocked && SecurityService().isAppLockEnabled) {
      return BiometricAuthScreen(onAuthenticated: _onAuthenticated);
    }

    return widget.child;
  }
}
