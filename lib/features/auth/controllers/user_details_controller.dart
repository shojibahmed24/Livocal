import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livocal/features/auth/domain/auth_service.dart';
import 'package:livocal/features/auth/views/auth_complete.dart';

import 'package:livocal/shared/models/user.dart';
import 'package:livocal/shared/utils/abc.dart';
import 'package:livocal/shared/utils/app_dialog.dart';
import 'package:livocal/shared/utils/attachment_utils.dart';
// import 'package:livocal/shared/widgets/emoji_picker.dart';
import 'package:livocal/shared/widgets/gallery.dart';
import 'package:livocal/theme/app_colors.dart';

import '../../../shared/repositories/compression_service.dart';

final userDetailsControllerProvider =
    StateNotifierProvider.autoDispose<UserDetailsController, File?>(
        (ref) => UserDetailsController(ref));

class UserDetailsController extends StateNotifier<File?> {
  UserDetailsController(this.ref) : super(null);

  final AutoDisposeStateNotifierProviderRef ref;
  late final TextEditingController _usernameController;

  void init() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    _usernameController = TextEditingController();
    // ref
    //     .read(emojiPickerControllerProvider.notifier)
    //     .init(keyboardVisibility: true);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    _usernameController.dispose();
    super.dispose();
  }

  TextEditingController get usernameController => _usernameController;

  void deleteImage(BuildContext context) {
    state = null;
    Navigator.of(context).pop();
  }

  void setImageFromCamera(BuildContext context) async {
    final image = await capturePhoto();
    if (image == null) return;
    state = await CompressionService.compressImage(image);
  }

  Future<void> setImageFromGallery(BuildContext context) async {
    if (Platform.isAndroid) {
      final file = await Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => const Gallery(
          title: 'Pick a photo',
          returnFiles: true,
        ),
        settings: const RouteSettings(name: "/gallery"),
      ));

      state = await CompressionService.compressImage(file);
      return;
    }

    final image = await pickImageFromGallery();
    if (image == null) return;
    state = await CompressionService.compressImage(image);
  }

  void onNextBtnPressed(
    BuildContext context,
    WidgetRef ref,
    Phone phone,
  ) async {
    bool internetConnActive = await isConnected();

    final username = ref
        .read(userDetailsControllerProvider.notifier)
        .usernameController
        .text;

    String errorMsg = '';
    if (username.isEmpty) {
      errorMsg = 'Please type your name';
    } else if (!internetConnActive) {
      errorMsg = 'Unable to connect. Please check your '
          'internet connection and try again';
    }

    if (!mounted) return;

    if (errorMsg.isNotEmpty) {
      return showAppDialog(
        context: context,
        title: 'Network Error',
        icon: Icons.wifi_off_rounded,
        iconColor: Theme.of(context).colorScheme.error,
        contentText: errorMsg,
        actions: [
          AppDialogAction(
            label: 'OK',
            isPrimary: true,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      );
    }

    final authController = ref.read(authControllerProvider);

    showAppDialog(
      context: context,
      barrierDismissible: false,
      content: FutureBuilder<User>(
        future: authController.saveUserData(
          context,
          ref,
          username,
          phone,
          state,
        ),
        builder: (context, snapshot) {
          String? text;
          Widget? widget;

          if (snapshot.hasData) {
            text = 'You\'re all set!';
            widget = const Icon(
              Icons.check_circle,
              color: AppColors.primary,
              size: 38.0,
            );

            Future.delayed(const Duration(seconds: 2), () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => AuthCompletePage(
                    user: snapshot.data!,
                  ),
                ),
                (route) => false,
              );
            });
          } else if (snapshot.hasError) {
            text = 'Oops! An error occurred';
            widget = const Icon(
              Icons.cancel,
              color: Color(0xFFE53935),
              size: 38.0,
            );

            Future.delayed(const Duration(seconds: 2), () {
              Navigator.of(context).pop();
            });
          }

          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Row(
            children: [
              widget ??
                  const CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
              const SizedBox(width: 24.0),
              Expanded(
                child: Text(
                  text ?? 'Connecting...',
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
