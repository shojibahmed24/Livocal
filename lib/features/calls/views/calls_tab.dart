import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatsapp_clone/features/calls/controllers/call_controller.dart';
import 'package:whatsapp_clone/features/calls/models/call_language.dart';
import 'package:whatsapp_clone/features/calls/views/incoming_call_screen.dart';
import 'package:whatsapp_clone/features/calls/views/outgoing_call_screen.dart';
import 'package:whatsapp_clone/features/calls/views/widgets/language_picker_sheet.dart';
import 'package:whatsapp_clone/features/calls/views/widgets/direct_dial_sheet.dart';
import 'package:whatsapp_clone/features/home/views/contacts.dart';
import 'package:whatsapp_clone/shared/models/user.dart';
import 'package:whatsapp_clone/theme/theme.dart';

class CallsTab extends ConsumerStatefulWidget {
  final User user;

  const CallsTab({
    super.key,
    required this.user,
  });

  @override
  ConsumerState<CallsTab> createState() => _CallsTabState();
}

class _CallsTabState extends ConsumerState<CallsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  String _formatCallTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';

    if (diff.inDays == 0 && now.day == time.day) {
      return 'Today, $hour:$minute $period';
    } else if (diff.inDays <= 1) {
      return 'Yesterday, $hour:$minute $period';
    } else {
      return '${time.day}/${time.month}/${time.year}, $hour:$minute $period';
    }
  }

  String _formatDuration(int seconds) {
    if (seconds <= 0) return '';
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    if (mins == 0) return '${secs}s';
    return '${mins}m ${secs}s';
  }

  void _startCallToPeer(
    BuildContext context,
    WidgetRef ref, {
    required String peerId,
    required String peerName,
    required String peerAvatar,
    required String peerPhone,
    String? myLangCode,
    String? peerLangCode,
    bool isSimulatedDemo = false,
  }) {
    final callee = User(
      id: peerId,
      name: peerName,
      avatarUrl: peerAvatar,
      phone: Phone(
        code: '+880',
        number: peerPhone,
        formattedNumber: peerPhone,
      ),
      activityStatus: UserActivityStatus.online,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OutgoingCallScreen(
          caller: widget.user,
          callee: callee,
          calleeDisplayName: peerName,
          overrideMyLangCode: myLangCode,
          overridePeerLangCode: peerLangCode,
          isSimulatedDemo: isSimulatedDemo,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final callState = ref.watch(callControllerProvider);
    final customTheme = Theme.of(context).custom;
    final colorTheme = customTheme.colorTheme;
    final myLang = callState.myLanguage;
    final peerLang = callState.peerLanguage;
    final history = callState.callHistory;

    return ListView(
      padding: const EdgeInsets.only(bottom: 92),
      children: [
        // Universal N x N Live Translation Hub Card
        Container(
          margin: const EdgeInsets.fromLTRB(14, 14, 14, 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0B2B24),
                Color(0xFF13222B),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFF00A884).withOpacity(0.45),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00A884).withOpacity(0.22),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.translate_rounded,
                      color: Color(0xFF00E5B0),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Gemini 3.5 Live Voice Translation',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          '${CallLanguageRegistry.allLanguages.length}+ Languages • Universal Any-to-Any Pair',
                          style: const TextStyle(
                            color: Color(0xFF00E5B0),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Language Pair Selector Row
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () async {
                        final picked = await showUniversalLanguagePicker(
                          context,
                          title: 'Select Your Language',
                          selectedCode: myLang.code,
                        );
                        if (picked != null) {
                          await ref
                              .read(callControllerProvider.notifier)
                              .setMyLanguage(picked.code);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'MY LANGUAGE (SPEAK & HEAR)',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  myLang.flagEmoji,
                                  style: const TextStyle(fontSize: 18),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    myLang.nativeName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: Colors.white54,
                                  size: 16,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        ref
                            .read(callControllerProvider.notifier)
                            .swapLanguages();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00A884).withOpacity(0.25),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.swap_horiz_rounded,
                          color: Color(0xFF00E5B0),
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () async {
                        final picked = await showUniversalLanguagePicker(
                          context,
                          title: 'Select Peer Language',
                          selectedCode: peerLang.code,
                        );
                        if (picked != null) {
                          await ref
                              .read(callControllerProvider.notifier)
                              .setPeerLanguage(picked.code);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'PEER LANGUAGE (SPEAK & HEAR)',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  peerLang.flagEmoji,
                                  style: const TextStyle(fontSize: 18),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    peerLang.nativeName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: Colors.white54,
                                  size: 16,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Quick Call Actions
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00A884),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 1,
                  ),
                  icon: const Icon(Icons.dialpad_rounded, size: 20),
                  label: const Text(
                    'Dial Number',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () => showDirectDialSheet(
                    context,
                    currentUser: widget.user,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF00A884),
                    side: const BorderSide(color: Color(0xFF00A884), width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.contacts_rounded, size: 20),
                  label: const Text(
                    'Contacts',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ContactsPage(user: widget.user),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // Section Header
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 6),
          child: Text(
            'Recent Translated & Voice Calls',
            style: TextStyle(
              color: colorTheme.greyColor,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),

        if (history.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Center(
              child: Text(
                'No recent calls yet. Tap a contact or "Start Live AI Call" above.',
                textAlign: TextAlign.center,
                style: TextStyle(color: colorTheme.greyColor),
              ),
            ),
          )
        else
          ...history.map((record) {
            final isMissed = record.isMissed;
            final pairBadge = CallLanguageRegistry.formatPairBadge(
              record.myLangCode,
              record.peerLangCode,
            );
            final durationStr = _formatDuration(record.durationSeconds);

            return ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              onTap: () {
                _startCallToPeer(
                  context,
                  ref,
                  peerId: record.peerId,
                  peerName: record.peerName,
                  peerAvatar: record.peerAvatar,
                  peerPhone: record.peerPhone,
                  myLangCode: record.myLangCode,
                  peerLangCode: record.peerLangCode,
                  isSimulatedDemo: record.peerId.startsWith('demo_'),
                );
              },
              leading: CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFF1F2C34),
                backgroundImage: record.peerAvatar.isNotEmpty
                    ? CachedNetworkImageProvider(record.peerAvatar)
                    : null,
                child: record.peerAvatar.isEmpty
                    ? const Icon(Icons.person, color: Colors.white70)
                    : null,
              ),
              title: Text(
                record.peerName,
                style: TextStyle(
                  color: isMissed ? Colors.redAccent : colorTheme.textColor1,
                  fontWeight: FontWeight.w600,
                  fontSize: 15.5,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(
                        record.isIncoming
                            ? (isMissed
                                ? Icons.call_missed_rounded
                                : Icons.call_received_rounded)
                            : Icons.call_made_rounded,
                        size: 15,
                        color: isMissed
                            ? Colors.redAccent
                            : const Color(0xFF00A884),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          '${_formatCallTime(record.timestamp)}${durationStr.isNotEmpty ? " • $durationStr" : ""}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colorTheme.greyColor,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (record.translationEnabled) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00A884).withOpacity(0.14),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '🌐 $pairBadge',
                        style: const TextStyle(
                          color: Color(0xFF00A884),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              trailing: IconButton(
                tooltip: 'Call with Live AI Translation',
                icon: const Icon(
                  Icons.call_rounded,
                  color: Color(0xFF00A884),
                ),
                onPressed: () {
                  _startCallToPeer(
                    context,
                    ref,
                    peerId: record.peerId,
                    peerName: record.peerName,
                    peerAvatar: record.peerAvatar,
                    peerPhone: record.peerPhone,
                    myLangCode: record.myLangCode,
                    peerLangCode: record.peerLangCode,
                    isSimulatedDemo: record.peerId.startsWith('demo_'),
                  );
                },
              ),
            );
          }),
      ],
    );
  }
}
