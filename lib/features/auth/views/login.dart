import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:livocal/features/auth/controllers/login_controller.dart';
import 'package:livocal/shared/ui/livocal_app_bar.dart';
import 'package:livocal/shared/ui/livocal_buttons.dart';
import 'package:livocal/shared/ui/livocal_card.dart';
import 'package:livocal/shared/utils/app_localizations.dart';
import 'package:livocal/shared/utils/shared_pref.dart';
import 'package:livocal/theme/app_colors.dart';
import 'package:livocal/theme/text_theme.dart';

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

  InputDecoration _fieldDecoration({
    required bool isDark,
    String? hint,
    String? prefix,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixText: prefix,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      filled: true,
      fillColor: isDark
          ? Colors.white.withValues(alpha: 0.05)
          : AppColors.lightSurfaceContainer,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppColors.lightDivider,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedCountry = ref.watch(loginControllerProvider);
    final controller = ref.read(loginControllerProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtitleColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      appBar: livocalAppBar(context),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? const [Color(0xFF0E1526), AppColors.darkBackground]
                : [
                    AppColors.primary.withValues(alpha: 0.10),
                    AppColors.accent.withValues(alpha: 0.06),
                    AppColors.lightBackground,
                  ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const LivocalWordmark(fontSize: 23, showAiPill: false),
                const SizedBox(height: 32),
                Text(
                  AppStrings.tr(ref, 'enterPhoneNumber'),
                  style: TextStyle(
                    fontFamily: CustomTextTheme.display,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                    height: 1.2,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Livocal will need to verify your phone number.',
                  style: TextStyle(
                    fontFamily: CustomTextTheme.body,
                    fontSize: 14,
                    height: 1.45,
                    color: subtitleColor,
                  ),
                ),
                const SizedBox(height: 22),
                LivocalCard(
                  elevated: true,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => controller.showCountryPage(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 13,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : AppColors.lightSurfaceContainer,
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : AppColors.lightDivider,
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                selectedCountry.flagEmoji,
                                style: const TextStyle(fontSize: 18),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  selectedCountry.displayNameNoCountryCode,
                                  style: TextStyle(
                                    fontFamily: CustomTextTheme.body,
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.lightTextPrimary,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.expand_more_rounded,
                                color: subtitleColor,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 94,
                            child: TextField(
                              onChanged: (value) =>
                                  controller.onPhoneCodeChanged(value),
                              keyboardType: TextInputType.phone,
                              textAlign: TextAlign.center,
                              cursorColor: AppColors.primary,
                              style: TextStyle(
                                fontFamily: CustomTextTheme.body,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                              ),
                              controller: controller.phoneCodeController,
                              decoration: _fieldDecoration(
                                  isDark: isDark, prefix: '+ '),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              autofocus: true,
                              keyboardType: TextInputType.phone,
                              cursorColor: AppColors.primary,
                              style: TextStyle(
                                fontFamily: CustomTextTheme.body,
                                fontSize: 15.5,
                                letterSpacing: 0.6,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                              ),
                              controller: controller.phoneNumberController,
                              decoration: _fieldDecoration(
                                isDark: isDark,
                                hint: 'Phone number',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 14,
                            color: subtitleColor,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              AppStrings.tr(ref, 'carrierCharges'),
                              style: TextStyle(
                                fontFamily: CustomTextTheme.body,
                                fontSize: 11.5,
                                color: subtitleColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: AppStrings.tr(ref, 'next'),
                  icon: Icons.arrow_forward_rounded,
                  onPressed: () => controller.onNextBtnPressed(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
