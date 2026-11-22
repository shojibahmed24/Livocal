import 'dart:ui';
import 'package:livocal/theme/app_colors.dart';
export 'package:livocal/theme/app_colors.dart';

class AppColorsDark {
  static const iconColor = Color.fromRGBO(138, 150, 178, 1);
  static const textColor1 = Color.fromRGBO(232, 236, 247, 1);
  static const textColor2 = Color.fromRGBO(201, 210, 232, 1);
  static const appBarColor = Color.fromRGBO(18, 26, 43, 1);
  static const dividerColor = Color.fromRGBO(34, 48, 77, 1);
  static const backgroundColor = Color.fromRGBO(10, 15, 30, 1);
  static const errorSnackBarColor = Color.fromRGBO(217, 45, 78, 1);
  static const incomingMessageBubbleColor = Color.fromRGBO(22, 32, 58, 1);
  static const outgoingMessageBubbleColor = Color.fromRGBO(63, 78, 216, 1);
  static const incomingEmbedColor = Color.fromRGBO(17, 26, 48, 1);
  static const outgoingEmbedColor = Color.fromRGBO(46, 58, 176, 1);
  static const selectedLabelColor = AppColors.primary;
  static const unselectedLabelColor = Color.fromRGBO(138, 150, 178, 1);
  static const indicatorColor = AppColors.primary;
  static const statusBarColor = appBarColor;
  static const navigationBarColor = Color.fromRGBO(14, 21, 38, 1);

  static const blueColor = Color.fromRGBO(76, 195, 255, 1);
  static const greenColor = AppColors.primary;
  static const yellowColor = Color.fromRGBO(255, 176, 32, 1);
  static const greyColor = Color.fromRGBO(138, 150, 178, 1);
}

class AppColorsLight {
  static const iconColor = AppColors.lightIcon;
  static const textColor1 = Color.fromRGBO(15, 23, 42, 1);
  static const textColor2 = Color.fromRGBO(15, 23, 42, 1);
  static const appBarColor = AppColors.primary;
  static const dividerColor = AppColors.lightDivider;
  static const backgroundColor = Color.fromRGBO(247, 248, 252, 1);
  static const errorSnackBarColor = Color.fromRGBO(217, 45, 78, 1);
  static const incomingMessageBubbleColor = Color.fromRGBO(255, 255, 255, 1);
  static const outgoingMessageBubbleColor = Color.fromRGBO(221, 226, 255, 1);
  static const incomingEmbedColor = Color.fromRGBO(242, 244, 250, 1);
  static const outgoingEmbedColor = Color.fromRGBO(201, 208, 255, 1);
  static const selectedLabelColor = Color.fromRGBO(228, 231, 255, 1);
  static const unselectedLabelColor = Color.fromRGBO(138, 150, 178, 1);
  static const indicatorColor = Color.fromRGBO(255, 255, 255, 1);
  static const statusBarColor = Color.fromARGB(255, 243, 244, 248);
  static const navigationBarColor = Color.fromARGB(255, 244, 245, 250);

  static const blueColor = Color.fromRGBO(76, 195, 255, 1);
  static const greenColor = AppColors.primary;
  static const yellowColor = Color.fromRGBO(255, 176, 32, 1);
  static const greyColor = Color.fromRGBO(91, 103, 133, 1);
}

class ColorTheme {
  final Color iconColor;
  final Color textColor1;
  final Color textColor2;
  final Color appBarColor;
  final Color dividerColor;
  final Color backgroundColor;
  final Color errorSnackBarColor;
  final Color incomingMessageBubbleColor;
  final Color outgoingMessageBubbleColor;
  final Color incomingEmbedColor;
  final Color outgoingEmbedColor;
  final Color selectedLabelColor;
  final Color unselectedLabelColor;
  final Color indicatorColor;
  final Color statusBarColor;
  final Color navigationBarColor;

  final Color blueColor;
  final Color greenColor;
  final Color yellowColor;
  final Color greyColor;

  ColorTheme({
    required this.iconColor,
    required this.textColor1,
    required this.textColor2,
    required this.appBarColor,
    required this.dividerColor,
    required this.backgroundColor,
    required this.errorSnackBarColor,
    required this.incomingMessageBubbleColor,
    required this.outgoingMessageBubbleColor,
    required this.incomingEmbedColor,
    required this.outgoingEmbedColor,
    required this.selectedLabelColor,
    required this.unselectedLabelColor,
    required this.indicatorColor,
    required this.statusBarColor,
    required this.navigationBarColor,
    required this.blueColor,
    required this.greenColor,
    required this.yellowColor,
    required this.greyColor,
  });
}
