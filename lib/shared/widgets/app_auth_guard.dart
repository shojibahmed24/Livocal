import 'dart:async';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:livocal/shared/utils/secure_pin_service.dart';
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
  bool _twoStepEnabled = false;
  final LocalAuthentication _auth = LocalAuthentication();
  final TextEditingController _pinController = TextEditingController();
  String? _pinError;
  int _lockoutSeconds = 0;
  Timer? _lockoutTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkLockStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _lockoutTimer?.cancel();
    _pinController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final fingerprintEnabled =
        SharedPref.instance.getBool('privacy_fingerprint') ?? false;

    if (state == AppLifecycleState.paused) {
      if (fingerprintEnabled || _twoStepEnabled) {
        setState(() {
          _isLocked = true;
          _pinController.clear();
          _pinError = null;
        });
      }
    } else if (state == AppLifecycleState.resumed) {
      _checkLockStatus();
      if (_isLocked && !_isAuthenticating && fingerprintEnabled) {
        _authenticate();
      }
    }
  }

  Future<void> _checkLockStatus() async {
    final fingerprintEnabled =
        SharedPref.instance.getBool('privacy_fingerprint') ?? false;
    final twoStep = await SecurePinService.isPinSet();

    if (mounted) {
      setState(() {
        _twoStepEnabled = twoStep;
        if (fingerprintEnabled || twoStep) {
          _isLocked = true;
        } else {
          _isLocked = false;
        }
      });
      if (fingerprintEnabled) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _authenticate();
        });
      }
    }
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;
    _isAuthenticating = true;

    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();

      if (!canCheck && !isSupported) {
        if (mounted) {
          setState(() {
            _isLocked = _twoStepEnabled;
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

  void _startLockoutTimer(int seconds) {
    _lockoutTimer?.cancel();
    setState(() {
      _lockoutSeconds = seconds;
      _pinError = 'Too many attempts. Locked out for $_lockoutSeconds s.';
    });
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      final remaining = SecurePinService.getRemainingLockoutSeconds();
      if (remaining <= 0) {
        t.cancel();
        setState(() {
          _lockoutSeconds = 0;
          _pinError = null;
        });
      } else {
        setState(() {
          _lockoutSeconds = remaining;
          _pinError = 'Too many attempts. Locked out for $_lockoutSeconds s.';
        });
      }
    });
  }

  Future<void> _verifyPin(String enteredPin) async {
    final lockout = SecurePinService.getRemainingLockoutSeconds();
    if (lockout > 0) {
      _startLockoutTimer(lockout);
      return;
    }

    final isValid = await SecurePinService.verifyPin(enteredPin);
    if (mounted) {
      if (isValid) {
        _lockoutTimer?.cancel();
        setState(() {
          _isLocked = false;
          _pinError = null;
          _lockoutSeconds = 0;
        });
        _pinController.clear();
      } else {
        final remaining = SecurePinService.getRemainingLockoutSeconds();
        if (remaining > 0) {
          _startLockoutTimer(remaining);
        } else {
          setState(() {
            _pinError = 'Incorrect PIN. Please try again.';
          });
        }
        _pinController.clear();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fingerprintEnabled =
        SharedPref.instance.getBool('privacy_fingerprint') ?? false;

    if ((!fingerprintEnabled && !_twoStepEnabled) || !_isLocked) {
      return widget.child;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryColor = Color(0xFF00A884);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121B22) : const Color(0xFFF0F2F5),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _twoStepEnabled ? Icons.pin_outlined : Icons.fingerprint_rounded,
                    size: 64,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Livocal Locked',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _twoStepEnabled
                      ? 'Enter your 6-digit Two-Step Verification PIN to continue'
                      : 'Touch the fingerprint sensor or authenticate to continue',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? const Color(0xFF8696A0) : const Color(0xFF667781),
                  ),
                ),
                if (_twoStepEnabled) ...[
                  const SizedBox(height: 28),
                  SizedBox(
                    width: 220,
                    child: TextField(
                      controller: _pinController,
                      enabled: _lockoutSeconds == 0,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      obscureText: true,
                      textAlign: TextAlign.center,
                      autofocus: true,
                      style: const TextStyle(
                        fontSize: 24,
                        letterSpacing: 8,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        hintText: '••••••',
                        counterText: '',
                        errorText: _pinError,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: primaryColor, width: 2),
                        ),
                      ),
                      onChanged: (val) {
                        if (val.length == 6 && _lockoutSeconds == 0) {
                          _verifyPin(val);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: _lockoutSeconds > 0
                        ? null
                        : () => _verifyPin(_pinController.text.trim()),
                    child: Text(_lockoutSeconds > 0 ? 'LOCKED (${_lockoutSeconds}s)' : 'SUBMIT PIN'),
                  ),
                ],
                if (fingerprintEnabled) ...[
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryColor,
                      side: const BorderSide(color: primaryColor),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: _authenticate,
                    icon: const Icon(Icons.fingerprint_rounded),
                    label: const Text('Unlock with Biometrics'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
