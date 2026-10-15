import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:livocal/shared/utils/shared_pref.dart';

class AppAuthGuard extends StatefulWidget {
  final Widget child;
  const AppAuthGuard({super.key, required this.child});

  @override
  State<AppAuthGuard> createState() => _AppAuthGuardState();
}

class _AppAuthGuardState extends State<AppAuthGuard>
    with WidgetsBindingObserver {
  bool _isLocked = false;
  bool _isAuthenticating = false;
  final LocalAuthentication _auth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkLockStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      final fingerprintEnabled =
          SharedPref.instance.getBool('privacy_fingerprint') ?? false;
      if (fingerprintEnabled) {
        setState(() {
          _isLocked = true;
        });
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_isLocked && !_isAuthenticating) {
        _authenticate();
      }
    }
  }

  void _checkLockStatus() {
    final fingerprintEnabled =
        SharedPref.instance.getBool('privacy_fingerprint') ?? false;
    if (fingerprintEnabled) {
      setState(() {
        _isLocked = true;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _authenticate();
      });
    } else {
      setState(() {
        _isLocked = false;
      });
    }
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;
    _isAuthenticating = true;

    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();

      if (!canCheck && !isSupported) {
        // Biometrics unavailable, unlock gracefully
        if (mounted) {
          setState(() {
            _isLocked = false;
            _isAuthenticating = false;
          });
        }
        return;
      }

      final authenticated = await _auth.authenticate(
        localizedReason: 'Please unlock Livocal to access your chats',
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );

      if (mounted) {
        setState(() {
          _isLocked = !authenticated;
          _isAuthenticating = false;
        });
      }
    } catch (e) {
      debugPrint('[AppAuthGuard] Authentication error: $e');
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fingerprintEnabled =
        SharedPref.instance.getBool('privacy_fingerprint') ?? false;

    if (!fingerprintEnabled || !_isLocked) {
      return widget.child;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryColor = Color(0xFF00A884);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121B22) : const Color(0xFFF0F2F5),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.fingerprint_rounded,
                    size: 72,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Livocal Locked',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Touch the fingerprint sensor or authenticate to continue',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? const Color(0xFF8696A0) : const Color(0xFF667781),
                  ),
                ),
                const SizedBox(height: 36),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  onPressed: _authenticate,
                  icon: const Icon(Icons.lock_open_rounded),
                  label: const Text(
                    'Unlock Livocal',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
