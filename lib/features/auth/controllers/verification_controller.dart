import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livocal/features/auth/domain/auth_service.dart';
import 'package:livocal/features/auth/views/user_details.dart';
import 'package:livocal/shared/utils/app_dialog.dart';
import 'package:livocal/shared/utils/shared_pref.dart';
import 'package:livocal/shared/utils/snackbars.dart';

import '../../../shared/models/user.dart';

const _resendFactor = 5;
const _resendInitial = 60;

final resendTimerControllerProvider =
    AutoDisposeStateNotifierProvider<ResendTimerController, int>(
  (ref) => ResendTimerController(ref),
);

class ResendTimerController extends StateNotifier<int> {
  ResendTimerController(this.ref) : super(_resendInitial);

  AutoDisposeStateNotifierProviderRef ref;
  int _resendCount = 1;
  Timer _resendTimer = Timer(Duration.zero, () {});
  int get resendCount => _resendCount;

  @override
  void dispose() {
    if (_resendTimer.isActive) {
      _resendTimer.cancel();
    }
    super.dispose();
  }

  bool get isTimerActive => _resendTimer.isActive;

  void updateTimer([bool saveTimestamp = true]) {
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state == 0) {
        timer.cancel();
        state = _resendCount * _resendInitial * _resendFactor;
      } else {
        state -= 1;
      }
    });

    if (saveTimestamp) {
      SharedPref.instance
        ..setInt('resendTime', state)
        ..setString(
          'resendTimestamp',
          DateTime.now().millisecondsSinceEpoch.toString(),
        );

      _resendCount++;
    }
  }

  void setState(int time) {
    state = time;
  }

  void setCount(int count) {
    _resendCount = count;
  }
}

final otpErrorProvider = StateProvider<String?>((ref) => null);

final verificationControllerProvider = Provider<VerificationController>(
  (ref) => VerificationController(ref),
);

class VerificationController {
  VerificationController(this.ref);

  ProviderRef ref;
  String _verificationCode = '';

  void init(BuildContext context, String phoneNumber) async {
    ref.read(otpErrorProvider.notifier).state = null;
    final resendTime = SharedPref.instance.getInt('resendTime');
    final resendTimestamp =
        int.parse(SharedPref.instance.getString('resendTimestamp') ?? '0') ~/
            1000;
    final elapsedTime =
        DateTime.now().millisecondsSinceEpoch ~/ 1000 - resendTimestamp;
    final remainingTime = (resendTime ?? 0) - elapsedTime;

    if (resendTime == null || remainingTime < 1 || _verificationCode.isEmpty) {
      if (resendTime != null && elapsedTime < 3600) {
        int count = resendTime ~/ (_resendFactor * _resendInitial) + 1;

        ref.read(resendTimerControllerProvider.notifier)
          ..setCount(count)
          ..setState(count * _resendFactor * _resendInitial);
      } else {
        ref.read(resendTimerControllerProvider.notifier)
          ..setCount(1)
          ..setState(_resendInitial);
      }

      await sendVerificationCode(context, phoneNumber);
      return;
    }

    int count = resendTime ~/ (_resendFactor * _resendInitial) + 1;

    ref.read(resendTimerControllerProvider.notifier)
      ..setState(remainingTime)
      ..setCount(count)
      ..updateTimer(false);
  }

  void updateVerificationCode(String verificationCode) {
    _verificationCode = verificationCode;
    ref.read(otpErrorProvider.notifier).state = null;
    ref.read(resendTimerControllerProvider.notifier).updateTimer();
  }

  void onResendPressed(BuildContext context, String phoneNumber) async {
    ref.read(otpErrorProvider.notifier).state = null;
    await sendVerificationCode(context, phoneNumber);
  }

  Future<void> sendVerificationCode(
    BuildContext context,
    String phoneNumber,
  ) async {
    showAppProgressDialog(
      context: context,
      message: 'Requesting verification code...',
    );

    try {
      final authController = ref.read(authControllerProvider);
      await authController.sendVerificationCode(
        context,
        phoneNumber,
        (code) {
          updateVerificationCode(code);
        },
      );
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        showSnackBar(
          context: context,
          content: 'Oops! An error occurred: $e',
          type: SnacBarType.error,
        );
      }
    }
  }

  void onFilled(BuildContext context, String smsCode, Phone phone) async {
    final authController = ref.read(authControllerProvider);

    if (_verificationCode.isEmpty) {
      ref.read(otpErrorProvider.notifier).state =
          'Verification session not initialized. Please request a new code.';
      showSnackBar(
        context: context,
        content: 'Verification session missing. Please tap Resend code.',
        type: SnacBarType.error,
      );
      return;
    }

    showAppProgressDialog(
      context: context,
      message: 'Verifying OTP...',
    );

    try {
      final success = await authController.verifyOtp(
        _verificationCode,
        smsCode,
      );

      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (success) {
        SharedPref.instance.setInt('resendTime', 0);
        if (context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => UserProfileCreationPage(phone: phone),
            ),
            (route) => false,
          );
        }
      } else {
        ref.read(otpErrorProvider.notifier).state = 'Invalid OTP! Please try again.';
        if (context.mounted) {
          showSnackBar(
            context: context,
            content: 'Invalid OTP! Please try again.',
            type: SnacBarType.error,
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      ref.read(otpErrorProvider.notifier).state = 'Verification failed. Please try again.';
      if (context.mounted) {
        showSnackBar(
          context: context,
          content: 'Verification failed: $e',
          type: SnacBarType.error,
        );
      }
    }
  }
}
