import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:livocal/shared/utils/secure_pin_service.dart';
import 'package:livocal/shared/utils/shared_pref.dart';
import 'package:livocal/theme/app_colors.dart';

class AppAuthGuard extends StatefulWidget {
  final Widget child;
  const AppAuthGuard({super.key, required this.child});

  /// Global flag indicating whether any biometric/PIN prompt is currently in-flight
  static bool isSystemAuthenticating = false;
  static DateTime? lastUnlockedAt;

  static void markUnlocked() {
    lastUnlockedAt = DateTime.now();
  }

  @override
  State<AppAuthGuard> createState() => AppAuthGuardState();
}

class AppAuthGuardState extends State<AppAuthGuard>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  bool _isLocked = false;
  bool _isAuthenticating = false;
  bool _twoStepEnabled = false;
  final LocalAuthentication _auth = LocalAuthentication();
  String _enteredPin = '';
  String? _pinError;
  int _lockoutSeconds = 0;
  Timer? _lockoutTimer;
  DateTime? _pausedTimestamp;

  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut),
    );

    _checkLockStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _shakeController.dispose();
    _lockoutTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final fingerprintEnabled =
        SharedPref.instance.getBool('privacy_fingerprint') ?? false;

    // Ignore transitions when an authentication dialog (ours or settings) is open
    if (_isAuthenticating || AppAuthGuard.isSystemAuthenticating) {
      return;
    }

    if (state == AppLifecycleState.paused) {
      _pausedTimestamp = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final paused = _pausedTimestamp;
      _pausedTimestamp = null;

      if (paused != null) {
        final timeInBackground = DateTime.now().difference(paused);
        // Only lock if app was genuinely in background for >2 seconds
        // (prevents re-locking during notification shade, system popups, or camera/picker sheets)
        if (timeInBackground > const Duration(seconds: 2)) {
          if (fingerprintEnabled || _twoStepEnabled) {
            if (mounted) {
              setState(() {
                _isLocked = true;
                _enteredPin = '';
                _pinError = null;
              });
              if (fingerprintEnabled) {
                _authenticate();
              }
            }
          }
        }
      }
    }
  }

  Future<void> _checkLockStatus() async {
    final fingerprintEnabled =
        SharedPref.instance.getBool('privacy_fingerprint') ?? false;
    final twoStep = await SecurePinService.isPinSet();

    if (!mounted) return;

    final recentlyUnlocked = AppAuthGuard.lastUnlockedAt != null &&
        DateTime.now().difference(AppAuthGuard.lastUnlockedAt!) <
            const Duration(seconds: 15);

    setState(() {
      _twoStepEnabled = twoStep;
      if ((fingerprintEnabled || twoStep) && !recentlyUnlocked) {
        _isLocked = true;
      } else {
        _isLocked = false;
      }
    });

    if (_isLocked &&
        fingerprintEnabled &&
        !_isAuthenticating &&
        !AppAuthGuard.isSystemAuthenticating) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _isLocked) {
          _authenticate();
        }
      });
    }
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating || AppAuthGuard.isSystemAuthenticating) return;
    _isAuthenticating = true;
    AppAuthGuard.isSystemAuthenticating = true;

    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();

      if (!canCheck && !isSupported) {
        if (mounted) {
          setState(() {
            _isLocked = _twoStepEnabled;
            _isAuthenticating = false;
            AppAuthGuard.isSystemAuthenticating = false;
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
          AppAuthGuard.isSystemAuthenticating = false;
          if (authenticated) {
            AppAuthGuard.markUnlocked();
          }
        });
      }
    } catch (e) {
      debugPrint('[AppAuthGuard] Authentication error: $e');
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
          AppAuthGuard.isSystemAuthenticating = false;
        });
      }
    }
  }

  void _startLockoutTimer(int seconds) {
    _lockoutTimer?.cancel();
    setState(() {
      _lockoutSeconds = seconds;
      _pinError = 'Too many attempts. Locked out for $_lockoutSeconds s.';
      _enteredPin = '';
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

  void _onKeyPress(String digit) {
    if (_lockoutSeconds > 0) return;
    HapticFeedback.lightImpact();

    if (_enteredPin.length < 6) {
      setState(() {
        _enteredPin += digit;
        _pinError = null;
      });

      if (_enteredPin.length == 6) {
        _verifyPin(_enteredPin);
      }
    }
  }

  void _onBackspace() {
    if (_enteredPin.isNotEmpty) {
      HapticFeedback.lightImpact();
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        _pinError = null;
      });
    }
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
        AppAuthGuard.markUnlocked();
        setState(() {
          _isLocked = false;
          _pinError = null;
          _lockoutSeconds = 0;
          _enteredPin = '';
        });
      } else {
        _shakeController.forward(from: 0.0);
        HapticFeedback.heavyImpact();

        final remaining = SecurePinService.getRemainingLockoutSeconds();
        if (remaining > 0) {
          _startLockoutTimer(remaining);
        } else {
          setState(() {
            _pinError = 'Incorrect PIN. Please try again.';
            _enteredPin = '';
          });
        }
      }
    }
  }

  Widget _buildKeypadButton({
    required Widget child,
    required VoidCallback onTap,
    Color? backgroundColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBg = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.black.withValues(alpha: 0.04);

    return InkResponse(
      onTap: onTap,
      radius: 36,
      splashColor: AppColors.primary.withValues(alpha: 0.25),
      highlightShape: BoxShape.circle,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: backgroundColor ?? defaultBg,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fingerprintEnabled =
        SharedPref.instance.getBool('privacy_fingerprint') ?? false;

    if ((!fingerprintEnabled && !_twoStepEnabled) || !_isLocked) {
      return widget.child;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryColor = AppColors.primary;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightSurfaceContainer,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Top Icon / Shield
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: primaryColor.withValues(alpha: 0.25),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    _twoStepEnabled ? Icons.lock_outline_rounded : Icons.fingerprint_rounded,
                    size: 48,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                Text(
                  'Livocal Locked',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _twoStepEnabled
                      ? 'Enter your 6-digit Two-Step PIN'
                      : 'Authenticate with fingerprint or biometrics',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? const Color(0xFF8696A0) : const Color(0xFF667781),
                  ),
                ),

                if (_twoStepEnabled) ...[
                  const SizedBox(height: 28),

                  // 6 Animated Dots with Physical Shake Animation
                  AnimatedBuilder(
                    animation: _shakeAnimation,
                    builder: (context, child) {
                      final double offset = 12 *
                          (1 - _shakeAnimation.value) *
                          (1 - _shakeAnimation.value) *
                          (0.5 - (0.5 - _shakeAnimation.value).abs()) *
                          4 *
                          (0.5 - ((_shakeAnimation.value * 6) % 1.0));
                      return Transform.translate(
                        offset: Offset(offset, 0),
                        child: child,
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(6, (index) {
                        final isFilled = index < _enteredPin.length;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          width: isFilled ? 18 : 16,
                          height: isFilled ? 18 : 16,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isFilled ? primaryColor : Colors.transparent,
                            border: Border.all(
                              color: isFilled
                                  ? primaryColor
                                  : (_pinError != null
                                      ? Colors.redAccent
                                      : (isDark ? Colors.white38 : Colors.black26)),
                              width: 2,
                            ),
                          ),
                        );
                      }),
                    ),
                  ),

                  // Inline Error / Lockout notice
                  if (_pinError != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            size: 15, color: Colors.redAccent),
                        const SizedBox(width: 5),
                        Text(
                          _pinError!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ] else
                    const SizedBox(height: 20),

                  const SizedBox(height: 8),

                  // Bank-Grade Custom Numeric Keypad (4 rows)
                  SizedBox(
                    width: 270,
                    child: Column(
                      children: [
                        // Row 1
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildKeypadButton(
                              child: const Text('1',
                                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w500)),
                              onTap: () => _onKeyPress('1'),
                            ),
                            _buildKeypadButton(
                              child: const Text('2',
                                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w500)),
                              onTap: () => _onKeyPress('2'),
                            ),
                            _buildKeypadButton(
                              child: const Text('3',
                                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w500)),
                              onTap: () => _onKeyPress('3'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Row 2
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildKeypadButton(
                              child: const Text('4',
                                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w500)),
                              onTap: () => _onKeyPress('4'),
                            ),
                            _buildKeypadButton(
                              child: const Text('5',
                                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w500)),
                              onTap: () => _onKeyPress('5'),
                            ),
                            _buildKeypadButton(
                              child: const Text('6',
                                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w500)),
                              onTap: () => _onKeyPress('6'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Row 3
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildKeypadButton(
                              child: const Text('7',
                                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w500)),
                              onTap: () => _onKeyPress('7'),
                            ),
                            _buildKeypadButton(
                              child: const Text('8',
                                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w500)),
                              onTap: () => _onKeyPress('8'),
                            ),
                            _buildKeypadButton(
                              child: const Text('9',
                                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w500)),
                              onTap: () => _onKeyPress('9'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Row 4: Biometrics / Fingerprint, 0, Backspace
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            fingerprintEnabled
                                ? _buildKeypadButton(
                                    child: const Icon(
                                      Icons.fingerprint_rounded,
                                      size: 30,
                                      color: primaryColor,
                                    ),
                                    onTap: _authenticate,
                                  )
                                : const SizedBox(width: 72, height: 72),
                            _buildKeypadButton(
                              child: const Text('0',
                                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w500)),
                              onTap: () => _onKeyPress('0'),
                            ),
                            _buildKeypadButton(
                              child: const Icon(
                                Icons.backspace_outlined,
                                size: 24,
                              ),
                              onTap: _onBackspace,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Unlock Action Button
                  SizedBox(
                    width: 200,
                    height: 44,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                      ),
                      onPressed: (_lockoutSeconds > 0 || _enteredPin.length < 6)
                          ? null
                          : () => _verifyPin(_enteredPin),
                      child: Text(
                        _lockoutSeconds > 0 ? 'Locked (${_lockoutSeconds}s)' : 'Unlock',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ],

                if (fingerprintEnabled && !_twoStepEnabled) ...[
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    onPressed: _authenticate,
                    icon: const Icon(Icons.fingerprint_rounded),
                    label: const Text(
                      'Unlock with Biometrics',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
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
