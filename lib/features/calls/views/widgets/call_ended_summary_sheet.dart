import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livocal/features/calls/views/widgets/different_language_call_sheet.dart';
import 'package:livocal/features/calls/views/widgets/minute_recharge_sheet.dart';
import 'package:livocal/features/chat/views/chat.dart';
import 'package:livocal/shared/models/user.dart';
import 'package:livocal/shared/repositories/wallet_repository.dart';
import 'package:livocal/theme/app_colors.dart';

class CallEndedSummarySheet extends ConsumerWidget {
  final User peerUser;
  final User currentUser;
  final int durationSeconds;
  final bool isMissed;
  final bool isTranslated;
  final bool isIncoming;

  const CallEndedSummarySheet({
    super.key,
    required this.peerUser,
    required this.currentUser,
    required this.durationSeconds,
    this.isMissed = false,
    this.isTranslated = false,
    this.isIncoming = false,
  });

  /// Displays the Call Ended Summary bottom sheet on any active context
  static Future<void> show(
    BuildContext context, {
    required User peerUser,
    required User currentUser,
    required int durationSeconds,
    bool isMissed = false,
    bool isTranslated = false,
    bool isIncoming = false,
  }) async {
    HapticFeedback.mediumImpact();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (_) => CallEndedSummarySheet(
        peerUser: peerUser,
        currentUser: currentUser,
        durationSeconds: durationSeconds,
        isMissed: isMissed,
        isTranslated: isTranslated,
        isIncoming: isIncoming,
      ),
    );
  }

  static String toBengaliNum(int n) {
    const bnDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    return n.toString().split('').map((d) {
      final idx = int.tryParse(d);
      return idx != null ? bnDigits[idx] : d;
    }).join('');
  }

  static String formatDurationBengali(int seconds) {
    if (seconds <= 0) return '০ সেকেন্ড';
    final mins = seconds ~/ 60;
    final secs = seconds % 60;

    if (mins > 0 && secs > 0) {
      return '${toBengaliNum(mins)} মিনিট ${toBengaliNum(secs)} সেকেন্ড';
    } else if (mins > 0) {
      return '${toBengaliNum(mins)} মিনিট';
    } else {
      return '${toBengaliNum(secs)} সেকেন্ড';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasDuration = durationSeconds > 0 && !isMissed;
    final durationStr = formatDurationBengali(durationSeconds);
    final walletAsync = ref.watch(walletStreamProvider(currentUser.id));

    final int billedMinutes = (hasDuration && isTranslated)
        ? ((durationSeconds + 59) ~/ 60)
        : 0;
    final String costStr = isMissed
        ? '০ মিনিট (সংযোগ হয়নি)'
        : (!isTranslated
            ? '০ মিনিট (সাধারণ কল)'
            : '${toBengaliNum(billedMinutes)} মিনিট কর্তন');

    // Dynamic positive message
    String messageText;
    if (isMissed) {
      messageText = isIncoming
          ? 'আপনি একটি ইনকামিং কল মিস করেছেন। চাইলে এখন কল ব্যাক করতে পারেন বা মেসেজ পাঠাতে পারেন।'
          : 'অপর প্রান্ত থেকে কলের উত্তর মেলেনি। অনুগ্রহ করে কিছুক্ষণ পর আবার চেষ্টা করুন।';
    } else if (isTranslated) {
      messageText =
          '🌐 লাইভ এআই ভয়েস অনুবাদ সহ আপনার কথোপকথনটি সফলভাবে সম্পন্ন হয়েছে। Livocal ব্যবহার করার জন্য ধন্যবাদ!';
    } else {
      messageText =
          'আপনার কথোপকথনটি সফলভাবে সম্পন্ন হয়েছে। চমৎকার আলাপের জন্য ধন্যবাদ!';
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131D24) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Grab handle
              Container(
                width: 44,
                height: 4.5,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 18),

              // Status Icon Badge
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isMissed
                      ? Colors.redAccent.withValues(alpha: 0.15)
                      : AppColors.primary.withValues(alpha: 0.15),
                  border: Border.all(
                    color: isMissed
                        ? Colors.redAccent.withValues(alpha: 0.35)
                        : AppColors.primary.withValues(alpha: 0.35),
                    width: 2,
                  ),
                ),
                child: Icon(
                  isMissed
                      ? Icons.phone_missed_rounded
                      : Icons.call_end_rounded,
                  size: 32,
                  color: isMissed ? Colors.redAccent : AppColors.primary,
                ),
              ),
              const SizedBox(height: 14),

              // Title
              Text(
                isMissed ? 'কলটি সংযোগ করা যায়নি' : 'কল সমাপ্ত হয়েছে',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 16),

              // User Info Card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1B2831)
                      : const Color(0xFFF3F5F7),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.06),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: isDark
                          ? const Color(0xFF263843)
                          : Colors.grey.shade300,
                      backgroundImage: peerUser.avatarUrl.isNotEmpty
                          ? CachedNetworkImageProvider(peerUser.avatarUrl)
                          : null,
                      child: peerUser.avatarUrl.isEmpty
                          ? Text(
                              peerUser.name.isNotEmpty
                                  ? peerUser.name[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            peerUser.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            peerUser.phone.getFormattedNumber(),
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isTranslated) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '🌐 AI Call',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Cost & Wallet Balance Breakdown Card
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1B2831) : const Color(0xFFF3F5F7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.07),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 16,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'কল সময়কাল',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          hasDuration ? durationStr : '০ সেকেন্ড',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.monetization_on_outlined,
                              size: 16,
                              color: isDark ? Colors.amberAccent : Colors.orange.shade800,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'ব্যবহৃত মিনিট / খরচ',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          costStr,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.amberAccent : Colors.orange.shade800,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.account_balance_wallet_outlined,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'অবশিষ্ট মিনিট ব্যালেন্স',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                        walletAsync.when(
                          data: (w) => Text(
                            '${toBengaliNum(w.effectiveRemainingMinutes)} মিনিট',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          loading: () => const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          error: (_, __) => const Text(
                            '-- মিনিট',
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                    walletAsync.maybeWhen(
                      data: (w) {
                        if (w.effectiveRemainingMinutes <= 2) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: AppColors.primary),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                icon: const Icon(Icons.add_card_rounded, size: 16, color: AppColors.primary),
                                label: const Text(
                                  'মিনিট রিচার্জ করুন',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  showMinuteRechargeSheet(context, user: currentUser);
                                },
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                      orElse: () => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Inspirational Bengali Text
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  messageText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.45,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 22),

              // Action Buttons Row
              Row(
                children: [
                  // Call Again Button
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.call_rounded, size: 20),
                      label: const Text(
                        'আবার কল করুন',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        initiateSmartCall(
                          context,
                          ref,
                          caller: currentUser,
                          callee: peerUser,
                          calleeDisplayName: peerUser.name,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Send Message Button
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark ? Colors.white : Colors.black87,
                        side: BorderSide(
                          color: isDark ? Colors.white24 : Colors.grey.shade400,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.chat_bubble_outline_rounded, size: 19),
                      label: const Text(
                        'মেসেজ পাঠান',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ChatPage(
                              self: currentUser,
                              other: peerUser,
                              otherUserContactName: peerUser.name,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Dismiss Text Button
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'ঠিক আছে',
                  style: TextStyle(
                    color: isDark ? Colors.white54 : Colors.black54,
                    fontSize: 13.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
