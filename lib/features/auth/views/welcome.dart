import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:livocal/features/auth/views/login.dart';
import 'package:livocal/features/settings/views/app_language_screen.dart';
import 'package:livocal/shared/constants/app_config.dart';
import 'package:livocal/shared/ui/livocal_buttons.dart';
import 'package:livocal/shared/utils/app_dialog.dart';
import 'package:livocal/shared/utils/app_localizations.dart';
import 'package:livocal/shared/utils/snackbars.dart';
import 'package:livocal/theme/app_colors.dart';
import 'package:livocal/theme/theme.dart';

class WelcomePage extends ConsumerStatefulWidget {
  const WelcomePage({super.key});

  @override
  ConsumerState<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends ConsumerState<WelcomePage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  List<_OnboardingSlide> get _slides => [
        _OnboardingSlide(
          icon: Icons.bolt_rounded,
          badge: AppStrings.tr(ref, 'welcomeBadge1'),
          title: AppStrings.tr(ref, 'welcomeTitle1'),
          description: AppStrings.tr(ref, 'welcomeDesc1'),
          accentColor: AppColors.primary,
        ),
        _OnboardingSlide(
          icon: Icons.translate_rounded,
          badge: AppStrings.tr(ref, 'welcomeBadge2'),
          title: AppStrings.tr(ref, 'welcomeTitle2'),
          description: AppStrings.tr(ref, 'welcomeDesc2'),
          accentColor: const Color(0xFF00B0FF),
        ),
        _OnboardingSlide(
          icon: Icons.shield_outlined,
          badge: AppStrings.tr(ref, 'welcomeBadge3'),
          title: AppStrings.tr(ref, 'welcomeTitle3'),
          description: AppStrings.tr(ref, 'welcomeDesc3'),
          accentColor: AppColors.primary,
        ),
      ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _navigateToLoginPage(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        showSnackBar(
          context: context,
          content: 'Could not open link: $url',
          type: SnacBarType.error,
        );
      }
    } catch (e) {
      debugPrint('WelcomeScreen._openUrl error: $e');
      if (mounted) {
        showSnackBar(
          context: context,
          content: 'Error opening browser: $e',
          type: SnacBarType.error,
        );
      }
    }
  }

  Future<void> _showTermsDialog() async {
    final uri = Uri.parse(AppConfig.termsOfServiceUrl);
    try {
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (launched) return;
    } catch (e) {
      debugPrint('[Welcome] Failed to launch terms URL: $e');
    }

    if (!mounted) return;
    bool isBnSelected = ref.read(appLocaleProvider).languageCode == 'bn';
    await showAppDialog(
      context: context,
      title: 'Terms of Service',
      icon: Icons.description_outlined,
      iconColor: AppColors.primary,
      content: StatefulBuilder(
        builder: (ctx, setContentState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ChoiceChip(
                    label:
                        const Text('English', style: TextStyle(fontSize: 12)),
                    selected: !isBnSelected,
                    onSelected: (val) =>
                        setContentState(() => isBnSelected = !val),
                    selectedColor: AppColors.primary.withValues(alpha: 0.15),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('বাংলা', style: TextStyle(fontSize: 12)),
                    selected: isBnSelected,
                    onSelected: (val) =>
                        setContentState(() => isBnSelected = val),
                    selectedColor: AppColors.primary.withValues(alpha: 0.15),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                isBnSelected
                    ? 'Livocal ব্যবহার করার মাধ্যমে আপনি নিম্নলিখিত শর্তাবলী মেনে নিচ্ছেন:\n\n'
                        '১. আপনার অ্যাকাউন্টের তথ্যের সুরক্ষার দায়িত্ব আপনার নিজের।\n\n'
                        '২. যোগাযোগের গোপনীয়তাকে শ্রদ্ধা করুন এবং যেকোনো প্রকার হয়রানি থেকে বিরত থাকুন।\n\n'
                        '৩. লাইভ ভয়েস অনুবাদ সুবিধাটি এআই ইনফারেন্সের মাধ্যমে দুই ভাষার মধ্যে সংযোগ স্থাপন করতে সহায়তা করে।\n\n'
                        '৪. Livocal কখনোই আপনার ব্যক্তিগত কন্টাক্ট বা মেসেজ ডেটা তৃতীয় পক্ষের কাছে বিক্রি করে না।'
                    : 'By using Livocal, you agree to:\n\n'
                        '1. Accept responsibility for your account activity.\n\n'
                        '2. Respect communication privacy and refrain from harassment.\n\n'
                        '3. Understand that real-time voice translation uses AI inference to assist cross-language communication.\n\n'
                        '4. Acknowledge that Livocal does not sell your private contact or message data to third parties.',
                style: const TextStyle(fontSize: 13.5, height: 1.45),
              ),
            ],
          );
        },
      ),
      actions: [
        AppDialogAction(
          label: 'Close',
          isPrimary: true,
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  static String _languageLabel(String code) {
    switch (code) {
      case 'bn':
        return 'বাংলা (Bangla)';
      case 'hi':
        return 'हिन्दी (Hindi)';
      case 'ar':
        return 'العربية (Arabic)';
      case 'es':
        return 'Español (Spanish)';
      case 'fr':
        return 'Français (French)';
      case 'de':
        return 'Deutsch (German)';
      default:
        return 'English';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorTheme = Theme.of(context).custom.colorTheme;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : AppColors.lightIcon,
        ),
        actionsIconTheme: IconThemeData(
          color: isDark ? Colors.white : AppColors.lightIcon,
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          systemNavigationBarColor: colorTheme.navigationBarColor,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.language_rounded),
            tooltip: 'App Language',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AppLanguageScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Onboarding 3-Slide Carousel
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28.0),
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Decorative glowing icon container
                          Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: slide.accentColor.withValues(alpha: 0.12),
                              border: Border.all(
                                color:
                                    slide.accentColor.withValues(alpha: 0.35),
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: index == 0
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(40),
                                      child: Image.asset(
                                        'assets/images/logo.png',
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.contain,
                                      ),
                                    )
                                  : Icon(
                                      slide.icon,
                                      size: 72,
                                      color: slide.accentColor,
                                    ),
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Badge Pill
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: slide.accentColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              slide.badge,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                                color: slide.accentColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Title
                          Text(
                            slide.title,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Description
                          Text(
                            slide.description,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.45,
                              color: isDark
                                  ? const Color(0xFF8A96B2)
                                  : const Color(0xFF536471),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Page Indicator Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_slides.length, (index) {
                final isSelected = _currentPage == index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isSelected ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: isSelected
                        ? AppColors.primary
                        : (isDark ? Colors.white24 : Colors.black12),
                  ),
                );
              }),
            ),

            const SizedBox(height: 24),

            // Legal notice with tappable links (localized sentence + links)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                children: [
                  Text(
                    AppStrings.tr(ref, 'legalConsentShort'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.4,
                      color: isDark
                          ? const Color(0xFF8A96B2)
                          : const Color(0xFF5B6785),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 16,
                    children: [
                      InkWell(
                        onTap: () => _openUrl(AppConfig.privacyPolicyUrl),
                        child: Text(
                          AppStrings.tr(ref, 'legalPrivacyPolicy'),
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: _showTermsDialog,
                        child: Text(
                          AppStrings.tr(ref, 'legalTermsOfService'),
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Full-width CTA Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: PrimaryButton(
                label: AppStrings.tr(ref, 'agreeAndContinue'),
                icon: Icons.arrow_forward_rounded,
                onPressed: () => _navigateToLoginPage(context),
              ),
            ),

            const SizedBox(height: 14),

            // Language Switcher Chip
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AppLanguageScreen()),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 6.0,
                  horizontal: 14.0,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.language_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _languageLabel(
                        ref.watch(appLocaleProvider).languageCode,
                      ),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_drop_down,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _OnboardingSlide {
  final IconData icon;
  final String badge;
  final String title;
  final String description;
  final Color accentColor;

  const _OnboardingSlide({
    required this.icon,
    required this.badge,
    required this.title,
    required this.description,
    required this.accentColor,
  });
}
