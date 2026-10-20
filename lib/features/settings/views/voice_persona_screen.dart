import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livocal/features/calls/services/gemini_live_translator.dart';
import 'package:livocal/shared/utils/app_localizations.dart';
import 'package:livocal/shared/utils/snackbars.dart';
import 'package:livocal/theme/app_colors.dart';

class VoicePersonaItem {
  final String id;
  final String name;
  final String gender;
  final String toneEn;
  final String toneBn;
  final String descriptionEn;
  final String descriptionBn;
  final IconData icon;
  final Color accentColor;
  final String samplePreviewText;

  const VoicePersonaItem({
    required this.id,
    required this.name,
    required this.gender,
    required this.toneEn,
    required this.toneBn,
    required this.descriptionEn,
    required this.descriptionBn,
    required this.icon,
    required this.accentColor,
    required this.samplePreviewText,
  });
}

class VoicePersonaScreen extends ConsumerStatefulWidget {
  const VoicePersonaScreen({super.key});

  @override
  ConsumerState<VoicePersonaScreen> createState() => _VoicePersonaScreenState();
}

class _VoicePersonaScreenState extends ConsumerState<VoicePersonaScreen> {
  late String _selectedVoice;
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentlyPlayingId;
  bool _isLoadingAudio = false;

  static const List<VoicePersonaItem> _personas = [
    // ── Female Voices ──────────────────────────────────────────────
    VoicePersonaItem(
      id: 'Aoede',
      name: 'Aoede',
      gender: 'Female',
      toneEn: 'Warm & Expressive',
      toneBn: 'উষ্ণ এবং সাবলীল',
      descriptionEn:
          'Clear, conversational female voice with natural inflections. Ideal for everyday chats and emotional clarity.',
      descriptionBn:
          'প্রাকৃতিক স্পষ্ট নারী কণ্ঠস্বর। দৈনন্দিন স্বাভাবিক কথোপকথনের জন্য সবচেয়ে উপযুক্ত।',
      icon: Icons.woman_rounded,
      accentColor: Color(0xFFE5A93B),
      samplePreviewText:
          'Hello! I am Aoede. I will translate your calls with a warm and expressive voice.',
    ),
    VoicePersonaItem(
      id: 'Kore',
      name: 'Kore',
      gender: 'Female',
      toneEn: 'Gentle & Melodious',
      toneBn: 'কোমল এবং মিষ্টি',
      descriptionEn:
          'Soothing, soft, and relaxed female voice. Perfect for patient, calm, and friendly dialogue.',
      descriptionBn:
          'কোমল, শান্ত এবং মিষ্টি নারী কণ্ঠস্বর। ধৈর্যশীল এবং বন্ধুত্বপূর্ণ আলোচনার জন্য সেরা।',
      icon: Icons.woman_2_rounded,
      accentColor: Color(0xFFFF6B8B),
      samplePreviewText:
          'Hello! I am Kore. I will translate your calls with a gentle and soothing voice.',
    ),
    VoicePersonaItem(
      id: 'Leda',
      name: 'Leda',
      gender: 'Female',
      toneEn: 'Calm & Professional',
      toneBn: 'শান্ত এবং পেশাদার',
      descriptionEn:
          'Composed, calm, and natural female voice with a professional tone. Ideal for formal calls and business meetings.',
      descriptionBn:
          'পেশাদার এবং শান্তিপ্রিয় নারী কণ্ঠস্বর। অফিশিয়াল এবং ব্যবসায়িক আলোচনার জন্য আদর্শ।',
      icon: Icons.record_voice_over_rounded,
      accentColor: Color(0xFF7C83E5),
      samplePreviewText:
          'Hello! I am Leda. I will translate your calls with a calm and professional tone.',
    ),
    VoicePersonaItem(
      id: 'Sularis',
      name: 'Sularis',
      gender: 'Female',
      toneEn: 'Warm & Reliable',
      toneBn: 'আন্তরিক এবং নির্ভরযোগ্য',
      descriptionEn:
          'Warm, trustworthy female voice with a natural flow. Great for friendly conversations and support interactions.',
      descriptionBn:
          'আন্তরিক এবং বিশ্বাসযোগ্য নারী কণ্ঠস্বর। বন্ধুত্বপূর্ণ কথোপকথনের জন্য দারুণ।',
      icon: Icons.spatial_audio_rounded,
      accentColor: Color(0xFFFF9A66),
      samplePreviewText:
          'Hello! I am Sularis. I will translate your calls with a warm and reliable voice.',
    ),
    // ── Male Voices ────────────────────────────────────────────────
    VoicePersonaItem(
      id: 'Charon',
      name: 'Charon',
      gender: 'Male',
      toneEn: 'Deep & Authoritative',
      toneBn: 'গম্ভীর এবং আত্মবিশ্বাসী',
      descriptionEn:
          'Deep, steady, and composed male voice. Well-suited for business discussions and professional audio.',
      descriptionBn:
          'ভারী, শান্ত এবং গম্ভীর পুরুষ কণ্ঠস্বর। প্রফেশনাল ও অফিশিয়াল আলোচনার জন্য দারুণ।',
      icon: Icons.man_rounded,
      accentColor: Color(0xFF5B8DEF),
      samplePreviewText:
          'Hello! I am Charon. I will translate your calls with a deep and composed tone.',
    ),
    VoicePersonaItem(
      id: 'Fenrir',
      name: 'Fenrir',
      gender: 'Male',
      toneEn: 'Energetic & Crisp',
      toneBn: 'প্রাণবন্ত এবং স্পষ্ট',
      descriptionEn:
          'Fast-paced, articulate, and confident male voice. Great for fast callers and dynamic conversations.',
      descriptionBn:
          'দ্রুত, স্পষ্ট এবং প্রাণবন্ত পুরুষ কণ্ঠস্বর। উদ্দীপনাময় এবং দ্রুত কথোপকথনের জন্য চমৎকার।',
      icon: Icons.graphic_eq_rounded,
      accentColor: Color(0xFF00C896),
      samplePreviewText:
          'Hello! I am Fenrir. I will translate your calls with an energetic and dynamic voice.',
    ),
    VoicePersonaItem(
      id: 'Puck',
      name: 'Puck',
      gender: 'Male',
      toneEn: 'Playful & Youthful',
      toneBn: 'উচ্ছ্বল এবং প্রাণোচ্ছ্বল',
      descriptionEn:
          'Crisp, playful, and cheerful young male voice. Adds a modern, friendly personality to translated speech.',
      descriptionBn:
          'হাসিখুশি, উজ্জ্বল এবং প্রাণোচ্ছ্বল যুবক পুরুষ কণ্ঠস্বর। আধুনিক ও সহজ কথোপকথনের উপযোগী।',
      icon: Icons.man_2_rounded,
      accentColor: Color(0xFFA259FF),
      samplePreviewText:
          'Hello! I am Puck. I will translate your calls with a playful and friendly tone.',
    ),
    VoicePersonaItem(
      id: 'Orus',
      name: 'Orus',
      gender: 'Male',
      toneEn: 'Bold & Commanding',
      toneBn: 'দৃঢ় এবং কর্তৃত্বপরায়ণ',
      descriptionEn:
          'Bold, clear, and commanding male voice. Perfect for assertive communication and leadership-style conversations.',
      descriptionBn:
          'দৃঢ়, স্পষ্ট এবং শক্তিশালী পুরুষ কণ্ঠস্বর। নেতৃত্বমূলক কথোপকথনের জন্য আদর্শ।',
      icon: Icons.record_voice_over_rounded,
      accentColor: Color(0xFFE05C5C),
      samplePreviewText:
          'Hello! I am Orus. I will translate your calls with a bold and commanding voice.',
    ),
    VoicePersonaItem(
      id: 'Perseus',
      name: 'Perseus',
      gender: 'Male',
      toneEn: 'Confident & Natural',
      toneBn: 'আত্মবিশ্বাসী এবং স্বাভাবিক',
      descriptionEn:
          'Confident, natural, and clear male voice that feels approachable. Suitable for both formal and casual settings.',
      descriptionBn:
          'আত্মবিশ্বাসী, স্বাভাবিক এবং স্পষ্ট পুরুষ কণ্ঠস্বর। আনুষ্ঠানিক ও অনানুষ্ঠানিক উভয় পরিবেশে উপযুক্ত।',
      icon: Icons.person_rounded,
      accentColor: Color(0xFF3EB8A8),
      samplePreviewText:
          'Hello! I am Perseus. I will translate your calls with a confident and natural voice.',
    ),
    VoicePersonaItem(
      id: 'Zephyr',
      name: 'Zephyr',
      gender: 'Male',
      toneEn: 'Bright & Lively',
      toneBn: 'উজ্জ্বল এবং সজীব',
      descriptionEn:
          'Bright, lively, and expressive male voice. Excellent for energetic conversations and casual interactions.',
      descriptionBn:
          'উজ্জ্বল, সজীব এবং প্রকাশমুখর পুরুষ কণ্ঠস্বর। প্রাণোচ্ছ্বল কথোপকথনের জন্য চমৎকার।',
      icon: Icons.air_rounded,
      accentColor: Color(0xFF00BCD4),
      samplePreviewText:
          'Hello! I am Zephyr. I will translate your calls with a bright and lively voice.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedVoice = GeminiLiveTranslator.getSavedVoiceName();

    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _currentlyPlayingId = null;
          _isLoadingAudio = false;
        });
      }
    });

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.stopped || state == PlayerState.paused) {
        if (mounted && _currentlyPlayingId != null) {
          setState(() {
            _currentlyPlayingId = null;
            _isLoadingAudio = false;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _selectVoice(String voiceId) async {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedVoice = voiceId;
    });
    await GeminiLiveTranslator.saveVoiceName(voiceId);

    if (mounted) {
      showSnackBar(
        context: context,
        content: AppStrings.trParams(ref, 'voiceSetSuccess', {'voiceId': voiceId}),
        type: SnacBarType.info,
      );
    }
  }

  Future<void> _previewVoice(VoicePersonaItem persona) async {
    HapticFeedback.selectionClick();

    if (_currentlyPlayingId == persona.id) {
      await _audioPlayer.stop();
      setState(() {
        _currentlyPlayingId = null;
        _isLoadingAudio = false;
      });
      return;
    }

    await _audioPlayer.stop();
    setState(() {
      _currentlyPlayingId = persona.id;
      _isLoadingAudio = true;
    });

    try {
      final apiKey = GeminiLiveTranslator.getSavedApiKey();
      bool playedGemini = false;

      // 1. Try real Gemini 2.0 Flash Audio synthesis with the EXACT prebuilt voice if API key exists
      if (apiKey.isNotEmpty) {
        try {
          final url = Uri.parse(
              'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey');
          final response = await http.post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {'text': 'Say with natural tone: "${persona.samplePreviewText}"'}
                  ]
                }
              ],
              'generationConfig': {
                'responseModalities': ['AUDIO'],
                'speechConfig': {
                  'voiceConfig': {
                    'prebuiltVoiceConfig': {
                      'voiceName': persona.id,
                    }
                  }
                }
              }
            }),
          ).timeout(const Duration(seconds: 5));

          if (response.statusCode == 200) {
            final json = jsonDecode(response.body);
            final parts = json['candidates']?[0]?['content']?['parts'] as List?;
            final inlineData = parts?.firstWhere(
                (p) => p['inlineData'] != null,
                orElse: () => null)?['inlineData'];
            final base64Audio = inlineData?['data'] as String?;
            if (base64Audio != null && base64Audio.isNotEmpty) {
              final audioBytes = base64Decode(base64Audio);
              final tempDir = await getTemporaryDirectory();
              final tempFile = File('${tempDir.path}/gemini_voice_${persona.id}.wav');
              await tempFile.writeAsBytes(audioBytes);
              await _audioPlayer.setPlaybackRate(1.0);
              await _audioPlayer.play(DeviceFileSource(tempFile.path));
              playedGemini = true;
            }
          }
        } catch (apiErr) {
          debugPrint('[VoicePersonaScreen] Direct Gemini TTS note: $apiErr');
        }
      }

      // 2. Fallback to gender-accurate pitch audio so Male is distinctly deep male & Female is melodious female
      if (!playedGemini) {
        final isMale = persona.gender.toLowerCase() == 'male';
        // Distinct pitch/speed for male vs female:
        await _audioPlayer.setPlaybackRate(isMale ? 0.80 : 1.06);

        final sampleUrl =
            'https://translate.google.com/translate_tts?ie=UTF-8&client=tw-ob&tl=en&q=${Uri.encodeComponent(persona.samplePreviewText)}';
        await _audioPlayer.play(UrlSource(sampleUrl));
      }

      if (mounted) {
        setState(() {
          _isLoadingAudio = false;
        });
      }
    } catch (e) {
      debugPrint('[VoicePersonaScreen] Audio preview error: $e');
      if (mounted) {
        setState(() {
          _currentlyPlayingId = null;
          _isLoadingAudio = false;
        });
        showSnackBar(
          context: context,
          content: AppStrings.tr(ref, 'voicePreviewOffline'),
          type: SnacBarType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isBangla = ref.watch(appLocaleProvider).languageCode == 'bn';
    const primary = AppColors.primary;

    final bgColor =
        isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final cardColor = isDark
        ? AppColors.darkSurfaceContainer
        : AppColors.lightSurfaceContainer;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor =
        isDark ? const Color(0xFF8696A0) : const Color(0xFF667781);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          AppStrings.tr(ref, 'geminiVoiceEngine'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        elevation: 0,
        backgroundColor:
            isDark ? AppColors.darkBackground : AppColors.lightBackground,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        physics: const BouncingScrollPhysics(),
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        primary.withValues(alpha: 0.18),
                        const Color(0xFF0D251D),
                      ]
                    : [
                        primary.withValues(alpha: 0.12),
                        const Color(0xFFE8F5E9),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: primary.withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: primary,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.tr(ref, 'liveAudioTranslationVoice'),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppStrings.tr(ref, 'liveAudioTranslationVoiceDesc'),
                        style: TextStyle(
                          fontSize: 12.5,
                          color: subtitleColor,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Section Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              AppStrings.tr(ref, 'availableVoicePersonas'),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
                color: primary,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Persona Cards
          ..._personas.map((persona) {
            final isSelected = _selectedVoice.toLowerCase() == persona.id.toLowerCase();
            final isPlaying = _currentlyPlayingId == persona.id;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark
                        ? primary.withValues(alpha: 0.12)
                        : primary.withValues(alpha: 0.08))
                    : cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? primary
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.06)),
                  width: isSelected ? 2.0 : 1.0,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: primary.withValues(alpha: 0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : null,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _selectVoice(persona.id),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row 1: Avatar, Name, Tone tag, Radio check
                        Row(
                          children: [
                            // Avatar Icon with Persona Accent
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: persona.accentColor.withValues(alpha: 0.18),
                                border: Border.all(
                                  color: persona.accentColor.withValues(alpha: 0.5),
                                  width: 1.5,
                                ),
                              ),
                              child: Icon(
                                persona.icon,
                                color: persona.accentColor,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Name & Tag
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        persona.name,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        ),
                                      ),
                                      if (isSelected) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 7,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: primary,
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            AppStrings.tr(ref, 'activeBadge'),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    isBangla
                                        ? '${persona.gender} • ${persona.toneBn}'
                                        : '${persona.gender} • ${persona.toneEn}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isSelected
                                          ? primary
                                          : subtitleColor,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Selection Checkmark / Radio
                            Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected
                                    ? primary
                                    : Colors.transparent,
                                border: Border.all(
                                  color: isSelected
                                      ? primary
                                      : (isDark
                                          ? Colors.white38
                                          : Colors.black26),
                                  width: 2,
                                ),
                              ),
                              child: isSelected
                                  ? const Icon(
                                      Icons.check,
                                      size: 16,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Description
                        Text(
                          isBangla
                              ? persona.descriptionBn
                              : persona.descriptionEn,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: subtitleColor,
                            height: 1.35,
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Action Bar: Preview Voice button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Audio Preview Button
                            InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () => _previewVoice(persona),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isPlaying
                                      ? persona.accentColor.withValues(alpha: 0.2)
                                      : (isDark
                                          ? Colors.white.withValues(alpha: 0.06)
                                          : Colors.black.withValues(alpha: 0.04)),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isPlaying
                                        ? persona.accentColor
                                        : (isDark
                                            ? Colors.white12
                                            : Colors.black12),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isPlaying && _isLoadingAudio)
                                      SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: persona.accentColor,
                                        ),
                                      )
                                    else
                                      Icon(
                                        isPlaying
                                            ? Icons.stop_rounded
                                            : Icons.play_arrow_rounded,
                                        size: 18,
                                        color: isPlaying
                                            ? persona.accentColor
                                            : textColor,
                                      ),
                                    const SizedBox(width: 6),
                                    Text(
                                      isPlaying ? AppStrings.tr(ref, 'stopPreview') : AppStrings.tr(ref, 'listenVoice'),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isPlaying
                                            ? persona.accentColor
                                            : textColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Tap to select indicator
                            Text(
                              isSelected ? AppStrings.tr(ref, 'selectedVoice') : AppStrings.tr(ref, 'tapToSelect'),
                              style: TextStyle(
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                                color: isSelected ? primary : subtitleColor,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 16),

          // Safe Note at bottom
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.verified_user_outlined,
                  size: 18,
                  color: primary.withValues(alpha: 0.85),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    AppStrings.tr(ref, 'voicePreferenceSavedNotice'),
                    style: TextStyle(
                      fontSize: 11.5,
                      color: subtitleColor,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
