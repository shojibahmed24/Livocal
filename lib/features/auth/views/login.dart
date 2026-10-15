import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:livocal/features/auth/controllers/login_controller.dart';
import 'package:livocal/shared/utils/shared_pref.dart';
import 'package:livocal/theme/app_colors.dart';
import 'package:livocal/theme/theme.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  bool gotKeyboardHeight = false;

  @override
  void initState() {
    ref.read(loginControllerProvider.notifier).init(() async {
      if (gotKeyboardHeight) return;

      double keyboardSize = MediaQuery.of(context).viewInsets.bottom;

      SharedPref.instance.setDouble('keyboardHeight', keyboardSize);

      if (keyboardSize < 300) return;
      gotKeyboardHeight = true;
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final selectedCountry = ref.watch(loginControllerProvider);
    final colorTheme = Theme.of(context).custom.colorTheme;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: colorTheme.statusBarColor,
          statusBarIconBrightness:
              Theme.of(context).brightness == Brightness.dark
                  ? Brightness.light
                  : Brightness.dark,
          systemNavigationBarColor: colorTheme.navigationBarColor,
          systemNavigationBarDividerColor: colorTheme.navigationBarColor,
        ),
        backgroundColor: colorTheme.backgroundColor,
        iconTheme: IconThemeData(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : AppColors.lightIcon,
        ),
        actionsIconTheme: IconThemeData(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : AppColors.lightIcon,
        ),
        title: Text(
          'Enter your phone number',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          Icon(
            Icons.more_vert_rounded,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : AppColors.lightIcon,
          ),
          const SizedBox(width: 16)
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 25),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 29.0),
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: TextStyle(color: colorTheme.textColor1),
                children: [
                  const TextSpan(
                    text: 'Livocal will need to verify your phone number. ',
                  ),
                  TextSpan(
                    text: 'What\'s my number?',
                    style: TextStyle(color: colorTheme.blueColor),
                  ),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: () => ref
                .read(loginControllerProvider.notifier)
                .showCountryPage(context),
            child: Container(
              padding: const EdgeInsets.only(top: 18.0),
              width: 0.60 * screenWidth,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: colorTheme.greenColor,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      selectedCountry.displayNameNoCountryCode,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => ref
                        .read(loginControllerProvider.notifier)
                        .showCountryPage(context),
                    child: Icon(
                      Icons.arrow_drop_down,
                      color: colorTheme.greenColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            width: 0.75 * screenWidth,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 0.25 * (screenWidth * 0.60),
                  child: TextField(
                    onChanged: (value) {
                      ref
                          .read(loginControllerProvider.notifier)
                          .onPhoneCodeChanged(value);
                    },
                    keyboardType: TextInputType.phone,
                    textAlign: TextAlign.center,
                    cursorColor: colorTheme.greenColor,
                    controller: ref
                        .read(loginControllerProvider.notifier)
                        .phoneCodeController,
                    decoration: InputDecoration(
                      prefixText: '+ ',
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: colorTheme.greenColor,
                          width: 1,
                        ),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: colorTheme.greenColor,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 0.05 * (screenWidth * 0.60),
                ),
                SizedBox(
                  width: 0.70 * (screenWidth * 0.60),
                  child: TextField(
                    autofocus: true,
                    keyboardType: TextInputType.phone,
                    cursorColor: colorTheme.greenColor,
                    controller: ref
                        .read(loginControllerProvider.notifier)
                        .phoneNumberController,
                    decoration: InputDecoration(
                      hintText: 'Phone number',
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: colorTheme.greenColor,
                          width: 1,
                        ),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: colorTheme.greenColor,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Text(
              'Carrier charges may apply.',
              style: TextStyle(color: colorTheme.textColor2),
            ),
          ),
          const Expanded(
            child: SizedBox(
              height: double.infinity,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24.0),
                  ),
                ),
                onPressed: () => ref
                    .read(loginControllerProvider.notifier)
                    .onNextBtnPressed(context),
                child: const Text(
                  'Next',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
