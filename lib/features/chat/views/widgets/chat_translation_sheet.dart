import 'package:flutter/material.dart';
import 'package:livocal/features/calls/models/call_language.dart';
import 'package:livocal/shared/services/translation_service.dart';
import 'package:livocal/shared/utils/snackbars.dart';

void showInChatTranslationSheet({
  required BuildContext context,
  required String peerName,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1F2C34)
        : Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _ChatTranslationSheetContent(peerName: peerName),
  );
}

class _ChatTranslationSheetContent extends StatefulWidget {
  const _ChatTranslationSheetContent({required this.peerName});
  final String peerName;

  @override
  State<_ChatTranslationSheetContent> createState() =>
      _ChatTranslationSheetContentState();
}

class _ChatTranslationSheetContentState
    extends State<_ChatTranslationSheetContent> {
  bool _liveTranslationEnabled = true;
  bool _autoTranslateIncoming = true;
  bool _autoTranscribeVoiceNotes = true;
  CallLanguage _myLanguage = CallLanguageRegistry.allLanguages[0]; // bn
  CallLanguage _peerLanguage = CallLanguageRegistry.allLanguages[2]; // en

  final TextEditingController _testController = TextEditingController();
  String _translatedPreview = '';
  bool _isTranslating = false;

  void _runQuickTest() async {
    final text = _testController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isTranslating = true;
      _translatedPreview = '';
    });

    try {
      final translated = await TranslationService.translateText(
        text: text,
        targetLangName: _peerLanguage.englishName,
        sourceLangName: _myLanguage.englishName,
      );
      if (mounted) {
        setState(() {
          _isTranslating = false;
          _translatedPreview =
              'AI Translated (${_peerLanguage.nativeName}): "$translated"';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTranslating = false;
          _translatedPreview =
              'Translation error: ${e.toString().replaceAll('Exception: ', '')}';
        });
      }
    }
  }

  @override
  void dispose() {
    _testController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF00E5B0);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: primaryColor.withOpacity(0.15),
                  child: Icon(Icons.translate_rounded, color: primaryColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'In-Chat AI Live Translation',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Powered by Gemini Live API for ${widget.peerName}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _liveTranslationEnabled,
                  activeColor: primaryColor,
                  onChanged: (val) {
                    setState(() {
                      _liveTranslationEnabled = val;
                    });
                    showSnackBar(
                      context: context,
                      content: val
                          ? 'In-Chat Live Translation Enabled'
                          : 'In-Chat Live Translation Disabled',
                      type: SnacBarType.info,
                    );
                  },
                ),
              ],
            ),
            const Divider(height: 24),
            const Text(
              'Language Preferences',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('My Language', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        const SizedBox(height: 4),
                        DropdownButton<CallLanguage>(
                          value: _myLanguage,
                          isExpanded: true,
                          underline: const SizedBox(),
                          items: CallLanguageRegistry.allLanguages
                              .map(
                                (l) => DropdownMenuItem(
                                  value: l,
                                  child: Text('${l.flagEmoji} ${l.nativeName}', style: const TextStyle(fontSize: 14)),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _myLanguage = val);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: IconButton(
                    icon: const Icon(Icons.swap_horiz, color: Color(0xFF00A884)),
                    onPressed: () {
                      setState(() {
                        final temp = _myLanguage;
                        _myLanguage = _peerLanguage;
                        _peerLanguage = temp;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("${widget.peerName}'s Language",
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        DropdownButton<CallLanguage>(
                          value: _peerLanguage,
                          isExpanded: true,
                          underline: const SizedBox(),
                          items: CallLanguageRegistry.allLanguages
                              .map(
                                (l) => DropdownMenuItem(
                                  value: l,
                                  child: Text('${l.flagEmoji} ${l.nativeName}', style: const TextStyle(fontSize: 14)),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _peerLanguage = val);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Auto-translate incoming messages', style: TextStyle(fontSize: 14)),
              subtitle: const Text('Automatically displays translations below received messages', style: TextStyle(fontSize: 12)),
              value: _autoTranslateIncoming,
              activeColor: const Color(0xFF00A884),
              onChanged: (val) => setState(() => _autoTranslateIncoming = val ?? true),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Live Voice Note Transcription', style: TextStyle(fontSize: 14)),
              subtitle: const Text('Transcribe and translate incoming audio voice messages', style: TextStyle(fontSize: 12)),
              value: _autoTranscribeVoiceNotes,
              activeColor: const Color(0xFF00A884),
              onChanged: (val) => setState(() => _autoTranscribeVoiceNotes = val ?? true),
            ),
            const Divider(height: 20),
            const Text(
              'Test Realtime Translation',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _testController,
                    decoration: InputDecoration(
                      hintText: 'Enter text to test...',
                      hintStyle: const TextStyle(fontSize: 13),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00A884),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isTranslating ? null : _runQuickTest,
                  child: _isTranslating
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Translate'),
                ),
              ],
            ),
            if (_translatedPreview.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2A3942) : const Color(0xFFE7FCE3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _translatedPreview,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00A884),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(46),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              onPressed: () {
                Navigator.pop(context);
                showSnackBar(
                  context: context,
                  content: 'Translation settings applied: ${_myLanguage.flagEmoji} ⇄ ${_peerLanguage.flagEmoji}',
                  type: SnacBarType.info,
                );
              },
              child: const Text('Save & Apply Settings'),
            ),
          ],
        ),
      ),
    );
  }
}
