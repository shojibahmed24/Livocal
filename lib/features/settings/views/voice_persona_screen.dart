import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livocal/features/calls/repositories/call_repository.dart';
import 'package:livocal/features/calls/services/gemini_live_translator.dart';
import 'package:livocal/shared/constants/app_config.dart';
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
  });

  String getSampleText(String langCode) {
    final isMale = gender.toLowerCase() == 'male';

    switch (langCode) {
      case 'bn':
        return isMale
            ? 'নমস্কার! আমি $name। লাইভ ফোনে আপনার কথা বাংলায় গম্ভীর ও আত্মবিশ্বাসী কণ্ঠে অনুবাদ করে শোনাব।'
            : 'নমস্কার! আমি $name। লাইভ ফোনে আপনার কথা বাংলায় মিষ্টি ও সাবলীল কণ্ঠে অনুবাদ করে শোনাব।';
      case 'hi':
        return isMale
            ? 'नमस्ते! मैं $name हूँ। आपकी लाइव कॉल का अनुवाद गंभीर और स्पष्ट आवाज़ में करूँगा।'
            : 'नमस्ते! मैं $name हूँ। आपकी लाइव कॉल का अनुवाद मधुर और स्पष्ट आवाज़ में करूँगी।';
      case 'ar':
        return isMale
            ? 'مرحباً! أنا $name. سأقوم بترجمة مكالماتك بصوت واثق ورزين.'
            : 'مرحباً! أنا $name. سأقوم بترجمة مكالماتك بصوت واضح ولطيف.';
      case 'es':
        return isMale
            ? '¡Hola! Soy $name. Traduciré tus llamadas con una voz profunda y segura.'
            : '¡Hola! Soy $name. Traduciré tus llamadas con una voz cálida y natural.';
      case 'fr':
        return isMale
            ? 'Bonjour! Je suis $name. Je traduirai vos appels avec une voix posée et confiante.'
            : 'Bonjour! Je suis $name. Je traduirai vos appels avec une voix douce et naturelle.';
      case 'de':
        return isMale
            ? 'Hallo! Ich bin $name. Ich werde Ihre Anrufe mit einer tiefen Stimme übersetzen.'
            : 'Hallo! Ich bin $name. Ich werde Ihre Anrufe mit einer freundlichen Stimme übersetzen.';
      case 'en':
      default:
        return isMale
            ? 'Hello! I am $name. I will translate your live calls with a deep and confident voice.'
            : 'Hello! I am $name. I will translate your live calls with a clear and expressive voice.';
    }
  }
}

class VoicePersonaScreen extends ConsumerStatefulWidget {
  const VoicePersonaScreen({super.key});

  @override
  ConsumerState<VoicePersonaScreen> createState() => _VoicePersonaScreenState();
}

class _VoicePersonaScreenState extends ConsumerState<VoicePersonaScreen> {
  late String _selectedVoice;
  late String _selectedLangCode;
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentlyPlayingId;
  bool _isLoadingAudio = false;

  static const List<VoicePersonaItem> _femalePersonas = [
    VoicePersonaItem(
      id: 'Aoede',
      name: 'Aoede',
      gender: 'Female',
      toneEn: 'Warm & Expressive',
      toneBn: 'উষ্ণ এবং সাবলীল',
      descriptionEn:
          'Clear, conversational female voice with natural inflections. Ideal for everyday chats and emotional clarity.',
      descriptionBn:
          'প্রাকৃতিক ও স্পষ্ট নারী কণ্ঠস্বর। দৈনন্দিন স্বাভাবিক কথোপকথনের জন্য সবচেয়ে উপযুক্ত।',
      icon: Icons.woman_rounded,
      accentColor: Color(0xFFE5A93B),
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
          'পেশাদার এবং শান্তিপ্রিয় নারী কণ্ঠস্বর। অফিশিয়াল এবং ব্যবসায়িক আলোচনার জন্য আদর্শ।',
      icon: Icons.record_voice_over_rounded,
      accentColor: Color(0xFF7C83E5),
    ),
    VoicePersonaItem(
      id: 'Autonoe',
      name: 'Autonoe',
      gender: 'Female',
      toneEn: 'Bright & Expressive',
      toneBn: 'উজ্জ্বল এবং প্রকাশমুখর',
      descriptionEn:
          'Warm, trustworthy female voice with a natural flow. Great for friendly conversations and support interactions.',
      descriptionBn:
          'আন্তরিক এবং বিশ্বাসযোগ্য নারী কণ্ঠস্বর। বন্ধুত্বপূর্ণ কথোপকথনের জন্য দারুণ।',
      icon: Icons.spatial_audio_rounded,
      accentColor: Color(0xFFFF9A66),
    ),
  ];

  static const List<VoicePersonaItem> _malePersonas = [
    VoicePersonaItem(
      id: 'Charon',
      name: 'Charon',
      gender: 'Male',
      toneEn: 'Deep & Authoritative',
      toneBn: 'গম্ভীর এবং আত্মবিশ্বাসী',
      descriptionEn:
          'Deep, steady, and composed male voice. Well-suited for business discussions and professional audio.',
      descriptionBn:
          'ভারী, শান্ত এবং গম্ভীর পুরুষ কণ্ঠস্বর। প্রফেশনাল ও অফিশিয়াল আলোচনার জন্য দারুণ।',
      icon: Icons.man_rounded,
      accentColor: Color(0xFF5B8DEF),
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
    ),
    VoicePersonaItem(
      id: 'Puck',
      name: 'Puck',
      gender: 'Male',
      toneEn: 'Playful & Youthful',
      toneBn: 'হাসিখুশি ও তারুণ্যদীপ্ত',
      descriptionEn:
          'Crisp, playful, and cheerful young male voice. Adds a modern, friendly personality to translated speech.',
      descriptionBn:
          'হাসিখুশি, উজ্জ্বল এবং প্রাণোচ্ছ্বল যুবক পুরুষ কণ্ঠস্বর। আধুনিক ও সহজ কথোপকথনের উপযোগী।',
      icon: Icons.man_2_rounded,
      accentColor: Color(0xFFA259FF),
    ),
    VoicePersonaItem(
      id: 'Orus',
      name: 'Orus',
      gender: 'Male',
      toneEn: 'Bold & Commanding',
      toneBn: 'দৃঢ় এবং শক্তিশালী',
      descriptionEn:
          'Bold, clear, and commanding male voice. Perfect for assertive communication and leadership-style conversations.',
      descriptionBn:
          'দৃঢ়, স্পষ্ট এবং শক্তিশালী পুরুষ কণ্ঠস্বর। নেতৃত্বমূলক কথোপকথনের জন্য আদর্শ।',
      icon: Icons.record_voice_over_rounded,
      accentColor: Color(0xFFE05C5C),
    ),
    VoicePersonaItem(
      id: 'Umbriel',
      name: 'Umbriel',
      gender: 'Male',
      toneEn: 'Relaxed & Approachable',
      toneBn: 'শান্ত ও আন্তরিক',
      descriptionEn:
          'Confident, natural, and clear male voice that feels approachable. Suitable for both formal and casual settings.',
      descriptionBn:
          'আত্মবিশ্বাসী, স্বাভাবিক এবং স্পষ্ট পুরুষ কণ্ঠস্বর। যেকোনো কথোপকথনের জন্য উপযুক্ত।',
      icon: Icons.person_rounded,
      accentColor: Color(0xFF3EB8A8),
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
    ),
  ];

  static const List<Map<String, String>> _previewLanguages = [
    {'code': 'bn', 'label': 'বাংলা', 'flag': '🇧🇩'},
    {'code': 'en', 'label': 'English', 'flag': '🇺🇸'},
    {'code': 'hi', 'label': 'हिन्दी', 'flag': '🇮🇳'},
    {'code': 'ar', 'label': 'العربية', 'flag': '🇸🇦'},
    {'code': 'es', 'label': 'Español', 'flag': '🇪🇸'},
    {'code': 'fr', 'label': 'Français', 'flag': '🇫🇷'},
    {'code': 'de', 'label': 'Deutsch', 'flag': '🇩🇪'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedVoice = GeminiLiveTranslator.getSavedVoiceName();
    _selectedLangCode = CallRepository.getMyLanguageCode();

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

  Future<void> _selectVoice(VoicePersonaItem persona) async {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedVoice = persona.id;
    });
    await GeminiLiveTranslator.saveVoiceName(persona.id);

    if (mounted) {
      showSnackBar(
        context: context,
        content: AppStrings.trParams(
            ref, 'voiceSetSuccess', {'voiceId': persona.name}),
        type: SnacBarType.info,
      );
    }
  }

  Future<void> _onLanguageChanged(String langCode) async {
    HapticFeedback.selectionClick();
    if (_currentlyPlayingId != null) {
      await _audioPlayer.stop();
    }
    setState(() {
      _selectedLangCode = langCode;
      _currentlyPlayingId = null;
      _isLoadingAudio = false;
    });
    await CallRepository.setMyLanguageCode(langCode);
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

    final sampleText = persona.getSampleText(_selectedLangCode);

    try {
      final apiKey = GeminiLiveTranslator.getSavedApiKey();
      final modelId =
          GeminiLiveTranslator.getSavedModelId().replaceAll('models/', '');
      bool playedAudio = false;

      // 1. Direct Gemini API Audio Synthesis (if API key is present)
      if (apiKey.isNotEmpty) {
        try {
          final url = Uri.parse(
              'https://generativelanguage.googleapis.com/v1beta/models/$modelId:generateContent?key=$apiKey');
          final response = await http
              .post(
                url,
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode({
                  'contents': [
                    {
                      'parts': [
                        {
                          'text':
                              'Say with natural ${persona.gender.toLowerCase()} tone: "$sampleText"'
                        }
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
              )
              .timeout(const Duration(seconds: 6));

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
              final tempFile =
                  File('${tempDir.path}/gemini_voice_${persona.id}.wav');
              await tempFile.writeAsBytes(audioBytes);
              await _audioPlayer.setPlaybackRate(1.0);
              await _audioPlayer.play(DeviceFileSource(tempFile.path));
              playedAudio = true;
            }
          }
        } catch (apiErr) {
          debugPrint('[VoicePersonaScreen] Direct Gemini TTS error: $apiErr');
        }
      }

      // 2. Try Backend Relay /api/voice-preview
      if (!playedAudio) {
        try {
          final relayUrl = AppConfig.liveCallWsUrl
              .replaceFirst('ws://', 'http://')
              .replaceFirst('wss://', 'https://')
              .replaceFirst('/ws/live-call', '/api/voice-preview');

          final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
          final relayRes = await http
              .post(
                Uri.parse(relayUrl),
                headers: {
                  'Content-Type': 'application/json',
                  if (idToken != null) 'Authorization': 'Bearer $idToken',
                },
                body: jsonEncode({
                  'voice': persona.id,
                  'text': sampleText,
                  'langCode': _selectedLangCode,
                  'model': GeminiLiveTranslator.getSavedModelId(),
                }),
              )
              .timeout(const Duration(seconds: 5));

          if (relayRes.statusCode == 200) {
            final data = jsonDecode(relayRes.body);
            final audioBase64 = data['audioBase64'] as String?;
            if (audioBase64 != null && audioBase64.isNotEmpty) {
              final audioBytes = base64Decode(audioBase64);
              final tempDir = await getTemporaryDirectory();
              final tempFile =
                  File('${tempDir.path}/relay_voice_${persona.id}.wav');
              await tempFile.writeAsBytes(audioBytes);
              await _audioPlayer.setPlaybackRate(1.0);
              await _audioPlayer.play(DeviceFileSource(tempFile.path));
              playedAudio = true;
            }
          }
        } catch (relayErr) {
          debugPrint('[VoicePersonaScreen] Relay preview note: $relayErr');
        }
      }

      // Fail cleanly if authentic Gemini voice synthesis was unavailable
      // Never deceive user with generic 3rd-party TTS (e.g. StreamElements Brian or Google TTS)
      if (!playedAudio) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Voice preview temporarily unavailable. Please check internet connection.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
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

  Widget _buildPersonaCard(
    VoicePersonaItem persona, {
    required bool isDark,
    required bool isBangla,
    required Color primary,
    required Color cardColor,
    required Color textColor,
    required Color subtitleColor,
  }) {
    final isSelected =
        _selectedVoice.toLowerCase() == persona.id.toLowerCase();
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
          onTap: () => _selectVoice(persona),
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
                                    borderRadius: BorderRadius.circular(10),
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
                                ? '${persona.gender == 'Female' ? 'নারী কণ্ঠ' : 'পুরুষ কণ্ঠ'} • ${persona.toneBn}'
                                : '${persona.gender} • ${persona.toneEn}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected ? primary : subtitleColor,
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
                        color: isSelected ? primary : Colors.transparent,
                        border: Border.all(
                          color: isSelected
                              ? primary
                              : (isDark ? Colors.white38 : Colors.black26),
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
                  isBangla ? persona.descriptionBn : persona.descriptionEn,
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
                          horizontal: 14,
                          vertical: 7,
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
                                : (isDark ? Colors.white12 : Colors.black12),
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
                              isPlaying
                                  ? (isBangla ? 'থামুন' : 'Stop')
                                  : (isBangla ? 'কণ্ঠ শুনুন' : 'Listen Voice'),
                              style: TextStyle(
                                fontSize: 12.5,
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
                      isSelected
                          ? AppStrings.tr(ref, 'selectedVoice')
                          : AppStrings.tr(ref, 'tapToSelect'),
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
          isBangla ? 'এআই ভয়েস পার্সোনা' : 'AI Voice Persona',
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
                        isBangla
                            ? 'লাইভ অডিও অনুবাদ কণ্ঠ'
                            : 'Live Audio Translation Voice',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isBangla
                            ? 'ফোন বা ভিওআইপি কলে অপর প্রান্তের কথা যে কণ্ঠস্বরে বাংলায় অনুবাদ শুনতে চান, তা পছন্দ করুন।'
                            : 'Select which voice persona speaks translated speech to you during live phone and VoIP calls.',
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

          // Language Selector Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isBangla
                      ? 'অনুবাদ শোনার ভাষা (PREVIEW LANGUAGE)'
                      : 'PREVIEW LANGUAGE',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: primary,
                  ),
                ),
                Text(
                  _previewLanguages.firstWhere(
                    (l) => l['code'] == _selectedLangCode,
                    orElse: () => {'label': _selectedLangCode, 'flag': '🌐'},
                  )['label']!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Horizontal Language Chips
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _previewLanguages.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final lang = _previewLanguages[index];
                final isSelected = lang['code'] == _selectedLangCode;

                return ChoiceChip(
                  label: Text('${lang['flag']} ${lang['label']}'),
                  selected: isSelected,
                  selectedColor: primary,
                  backgroundColor: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.04),
                  labelStyle: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.white70 : Colors.black87),
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 12.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected
                          ? primary
                          : (isDark ? Colors.white12 : Colors.black12),
                    ),
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      _onLanguageChanged(lang['code']!);
                    }
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 22),

          // Section 1: Female Voices
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                const Icon(Icons.female_rounded, color: Color(0xFFFF6B8B), size: 18),
                const SizedBox(width: 6),
                Text(
                  isBangla
                      ? 'নারী কণ্ঠস্বর (FEMALE VOICES)'
                      : 'FEMALE VOICES',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: Color(0xFFFF6B8B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          ..._femalePersonas.map((persona) => _buildPersonaCard(
                persona,
                isDark: isDark,
                isBangla: isBangla,
                primary: primary,
                cardColor: cardColor,
                textColor: textColor,
                subtitleColor: subtitleColor,
              )),

          const SizedBox(height: 16),

          // Section 2: Male Voices
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                const Icon(Icons.male_rounded, color: Color(0xFF5B8DEF), size: 18),
                const SizedBox(width: 6),
                Text(
                  isBangla
                      ? 'পুরুষ কণ্ঠস্বর (MALE VOICES)'
                      : 'MALE VOICES',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: Color(0xFF5B8DEF),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          ..._malePersonas.map((persona) => _buildPersonaCard(
                persona,
                isDark: isDark,
                isBangla: isBangla,
                primary: primary,
                cardColor: cardColor,
                textColor: textColor,
                subtitleColor: subtitleColor,
              )),

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
                    isBangla
                        ? 'আপনার পছন্দের এআই ভয়েস পার্সোনা এই ডিভাইসে সুরক্ষিতভাবে সংরক্ষিত হয়েছে এবং লাইভ অনুবাদ কলে স্বয়ংক্রিয়ভাবে কার্যকর হবে।'
                        : 'Your preferred voice persona is securely saved on your device and applied automatically to all live translated calls.',
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
