import 'package:livocal/features/calls/views/widgets/different_language_call_sheet.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livocal/features/calls/controllers/call_controller.dart';
import 'package:livocal/features/calls/models/call_language.dart';
import 'package:livocal/features/calls/views/widgets/direct_dial_sheet.dart';
import 'package:livocal/features/calls/views/widgets/minute_recharge_sheet.dart';
import 'package:livocal/features/chat/views/contact_profile_screen.dart';
import 'package:livocal/features/home/views/contacts.dart';
import 'package:livocal/shared/models/user.dart';
import 'package:livocal/shared/models/user_wallet.dart';
import 'package:livocal/shared/repositories/wallet_repository.dart';
import 'package:livocal/shared/utils/app_localizations.dart';
import 'package:livocal/theme/app_colors.dart';
import 'package:livocal/theme/theme.dart';

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

    initiateSmartCall(
      context,
      ref,
      caller: widget.user,
      callee: callee,
      calleeDisplayName: peerName,
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final callState = ref.watch(callControllerProvider);
    final customTheme = Theme.of(context).custom;
    final colorTheme = customTheme.colorTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final myLang = callState.myLanguage;
    final peerLang = callState.peerLanguage;
    final history = callState.callHistory;

    return ListView(
      padding: const EdgeInsets.only(bottom: 92),
      children: [
        // Freelancer Prepaid Minute Wallet & Trial Badge
        Consumer(
          builder: (context, ref, _) {
            final walletAsync = ref.watch(walletStreamProvider(widget.user.id));
            final wallet = walletAsync.value ?? UserWallet.newTrial();
            final isTrial = wallet.trialActive && !wallet.isTrialExpired;
            final isExhausted = !wallet.hasMinutes;

            return Container(
              margin: const EdgeInsets.fromLTRB(14, 12, 14, 2),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isExhausted
                    ? Colors.amber.withValues(alpha: 0.12)
                    : (isDark
                        ? (isTrial ? const Color(0xFF0D2820) : const Color(0xFF131F2E))
                        : (isTrial ? const Color(0xFFE8F5F0) : const Color(0xFFE3F4FD))),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isExhausted
                      ? Colors.amber.withValues(alpha: 0.5)
                      : (isTrial ? AppColors.primary.withValues(alpha: 0.4) : const Color(0xFF06B6D4).withValues(alpha: 0.4)),
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: (isExhausted ? Colors.amber : (isTrial ? AppColors.primary : const Color(0xFF06B6D4)))
                          .withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isExhausted ? Icons.warning_amber_rounded : (isTrial ? Icons.timer_outlined : Icons.diamond_outlined),
                      color: isExhausted ? Colors.amber : (isTrial ? AppColors.primary : const Color(0xFF06B6D4)),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isTrial
                              ? AppStrings.trParams(ref, 'trialRemainingBadge', {'minutes': '${wallet.trialMinutes}'})
                              : (isExhausted
                                  ? AppStrings.tr(ref, 'balanceExhaustedBadge')
                                  : AppStrings.trParams(ref, 'balanceMinutesBadge', {'minutes': '${wallet.balanceMinutes}'})),
                          style: TextStyle(
                            color: isExhausted
                                ? Colors.amber[700]
                                : (isDark ? Colors.white : Colors.black87),
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                          ),
                        ),
                        Text(
                          isTrial
                              ? AppStrings.trParams(ref, 'trialDaysLeftNotice', {'days': '${wallet.daysRemainingInTrial}'})
                              : (isExhausted
                                  ? AppStrings.tr(ref, 'rechargeForTranslationNotice')
                                  : AppStrings.tr(ref, 'translationRateNotice')),
                          style: TextStyle(
                            color: isExhausted
                                ? Colors.amber[600]
                                : (isDark ? Colors.white60 : Colors.black54),
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isExhausted ? Colors.amber[700] : AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () => showMinuteRechargeSheet(context, user: widget.user),
                    child: Text(
                      isExhausted ? AppStrings.tr(ref, 'recharge') : AppStrings.tr(ref, 'rechargePlus'),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            );
          },
        ),

        // Quick Call Actions
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 1,
                  ),
                  icon: const Icon(Icons.dialpad_rounded, size: 20),
                  label: Text(
                    AppStrings.tr(ref, 'dialNumber'),
                    style: const TextStyle(
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
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.contacts_rounded, size: 20),
                  label: Text(
                    AppStrings.tr(ref, 'contacts'),
                    style: const TextStyle(
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
            AppStrings.tr(ref, 'recentCallsHeader'),
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
                AppStrings.tr(ref, 'noRecentCalls'),
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
                // Tapping name/row opens profile (call icon in trailing redials)
                final otherUser = User(
                  id: record.peerId,
                  name: record.peerName,
                  avatarUrl: record.peerAvatar,
                  phone: Phone(
                    code: '+880',
                    number: record.peerPhone,
                    formattedNumber: record.peerPhone,
                  ),
                  activityStatus: UserActivityStatus.offline,
                );
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ContactProfileScreen(
                      self: widget.user,
                      other: otherUser,
                      contactName: record.peerName,
                    ),
                  ),
                );
              },
              leading: GestureDetector(
                onTap: () {
                  final otherUser = User(
                    id: record.peerId,
                    name: record.peerName,
                    avatarUrl: record.peerAvatar,
                    phone: Phone(
                      code: '+880',
                      number: record.peerPhone,
                      formattedNumber: record.peerPhone,
                    ),
                    activityStatus: UserActivityStatus.offline,
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ContactProfileScreen(
                        self: widget.user,
                        other: otherUser,
                        contactName: record.peerName,
                      ),
                    ),
                  );
                },
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFF1F2C34),
                  backgroundImage: record.peerAvatar.isNotEmpty
                      ? CachedNetworkImageProvider(record.peerAvatar)
                      : null,
                  child: record.peerAvatar.isEmpty
                      ? const Icon(Icons.person, color: Colors.white70)
                      : null,
                ),
              ),
              title: Text(
                record.peerName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
                            : AppColors.primary,
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
                  if (record.isTranslatedCall) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '🌐 $pairBadge',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.teal.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '🗣️ Free Call',
                        style: TextStyle(
                          color: Colors.teal,
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
                  color: AppColors.primary,
                ),
                onPressed: () {
                  final otherUser = User(
                    id: record.peerId,
                    name: record.peerName,
                    avatarUrl: record.peerAvatar,
                    phone: Phone(
                      code: '+880',
                      number: record.peerPhone,
                      formattedNumber: record.peerPhone,
                    ),
                    activityStatus: UserActivityStatus.offline,
                    spokenLanguage: record.peerLangCode,
                  );
                  initiateSmartCall(
                    context,
                    ref,
                    caller: widget.user,
                    callee: otherUser,
                    calleeDisplayName: record.peerName,
                  );
                },
              ),
            );
          }),
      ],
    );
  }
}
