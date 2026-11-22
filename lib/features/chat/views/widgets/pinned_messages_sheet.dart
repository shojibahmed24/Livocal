import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:livocal/features/chat/models/message.dart';
import 'package:livocal/shared/models/user.dart';
import 'package:livocal/shared/repositories/isar_db.dart';
import 'package:livocal/shared/utils/abc.dart';
import 'package:livocal/shared/utils/app_localizations.dart';
import 'package:livocal/shared/utils/shared_pref.dart';
import 'package:livocal/shared/utils/snackbars.dart';
import 'package:livocal/theme/app_colors.dart';
import 'package:livocal/theme/app_tokens.dart';

/// Bottom sheet listing locally pinned messages for one conversation.
void showPinnedMessagesSheet(
  BuildContext context, {
  required User self,
  required User other,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor:
        isDark ? AppColors.darkSurface : AppColors.lightBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.radiusLg)),
    ),
    builder: (_) => _PinnedMessagesSheet(self: self, other: other),
  );
}

class _PinnedMessagesSheet extends StatelessWidget {
  final User self;
  final User other;

  const _PinnedMessagesSheet({required this.self, required this.other});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final langCode = Localizations.localeOf(context).languageCode;
    final chatId = getChatId(self.id, other.id);
    final pinnedIds =
        SharedPref.instance.getStringList('pinned_$chatId') ?? const [];
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.72,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.grey.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 8, 8),
              child: Row(
                children: [
                  const Icon(Icons.push_pin_rounded, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppStrings.get('pinnedMessages', langCode),
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            if (pinnedIds.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  AppStrings.get('noPinnedMessages', langCode),
                  style: TextStyle(color: textSecondary, fontSize: 14),
                ),
              )
            else
              Flexible(
                child: StreamBuilder<List<Message>>(
                  stream: IsarDb.getChatStream(chatId, limit: 5000),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    final pinned = snapshot.data!
                        .where((m) => pinnedIds.contains(m.id))
                        .toList();
                    if (pinned.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          AppStrings.get('noPinnedMessages', langCode),
                          style:
                              TextStyle(color: textSecondary, fontSize: 14),
                        ),
                      );
                    }
                    return ListView.separated(
                      shrinkWrap: true,
                      itemCount: pinned.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        color: isDark
                            ? AppColors.darkDivider
                            : AppColors.lightDivider,
                      ),
                      itemBuilder: (context, index) {
                        final message = pinned[index];
                        final isMe = message.senderId == self.id;
                        final time = DateFormat('dd MMM, HH:mm')
                            .format(message.timestamp.toDate());
                        final preview = message.attachment != null &&
                                (message.attachment?.fileName ?? '').isNotEmpty
                            ? message.attachment!.fileName
                            : message.content;
                        return ListTile(
                          leading: const Icon(
                            Icons.push_pin_rounded,
                            color: AppColors.primary,
                            size: 18,
                          ),
                          title: Text(
                            preview,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                              fontSize: 13.5,
                            ),
                          ),
                          subtitle: Text(
                            '${isMe ? 'You' : other.name} • $time',
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 11,
                            ),
                          ),
                          onTap: () {
                            Clipboard.setData(
                              ClipboardData(text: message.content),
                            );
                            showSnackBar(
                              context: context,
                              content: AppStrings.get(
                                'messageCopied',
                                langCode,
                              ),
                              type: SnacBarType.info,
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
