import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:livocal/features/chat/views/chat.dart';
import 'package:livocal/shared/models/messages.dart';
import 'package:livocal/shared/repositories/isar_db.dart';
import 'package:livocal/shared/utils/app_dialog.dart';
import 'package:livocal/shared/utils/shared_pref.dart';
import 'package:livocal/shared/utils/snackbars.dart';
import 'package:livocal/shared/widgets/shimmer_skeleton.dart';
import 'package:livocal/theme/app_colors.dart';
import 'package:livocal/theme/app_tokens.dart';

class StarredMessagesScreen extends ConsumerStatefulWidget {
  const StarredMessagesScreen({super.key});

  @override
  ConsumerState<StarredMessagesScreen> createState() =>
      _StarredMessagesScreenState();
}

class _StarredMessagesScreenState extends ConsumerState<StarredMessagesScreen> {
  List<StoredMessage> _starredMessages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStarredMessages();
  }

  Future<void> _loadStarredMessages() async {
    setState(() => _isLoading = true);
    try {
      final starredIds =
          SharedPref.instance.getStringList('starred_message_ids') ?? [];
      if (starredIds.isEmpty) {
        setState(() {
          _starredMessages = [];
          _isLoading = false;
        });
        return;
      }

      final messages = await IsarDb.getStarredMessagesByIds(starredIds);
      if (mounted) {
        setState(() {
          _starredMessages = messages;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[StarredMessages] _loadStarredMessages error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _unstarMessage(String messageId) async {
    final list = SharedPref.instance.getStringList('starred_message_ids') ?? [];
    list.remove(messageId);
    await SharedPref.instance.setStringList('starred_message_ids', list);
    _loadStarredMessages();
  }

  void _confirmUnstarAll(BuildContext context) {
    showAppDialog(
      context: context,
      title: 'Unstar all messages?',
      icon: Icons.star_border_rounded,
      iconColor: Colors.amber,
      contentText:
          'Are you sure you want to unstar all messages? This will remove all starred items from your list.',
      actions: [
        AppDialogAction(
          label: 'CANCEL',
          onPressed: () => Navigator.pop(context),
        ),
        AppDialogAction(
          label: 'UNSTAR ALL',
          isDestructive: true,
          onPressed: () async {
            Navigator.pop(context);
            await SharedPref.instance.setStringList('starred_message_ids', []);
            await _loadStarredMessages();
            if (context.mounted) {
              showSnackBar(
                context: context,
                content: 'All messages have been unstarred.',
                type: SnacBarType.info,
              );
            }
          },
        ),
      ],
    );
  }

  Future<void> _navigateToMessageChat(StoredMessage msg) async {
    try {
      final currentUid = fb.FirebaseAuth.instance.currentUser?.uid;
      if (currentUid == null) return;

      final self = await IsarDb.getUserById(currentUid);
      final peerId = (msg.senderId == currentUid) ? msg.receiverId : msg.senderId;
      final other = await IsarDb.getUserById(peerId);

      if (self != null && other != null && mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChatPage(
              self: self,
              other: other,
              otherUserContactName: other.name,
            ),
          ),
        );
      } else if (mounted) {
        showSnackBar(
          context: context,
          content: 'Could not locate contact conversation for this message.',
          type: SnacBarType.error,
        );
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(
          context: context,
          content: 'Error opening chat: $e',
          type: SnacBarType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.primary,
        foregroundColor: Colors.white,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Starred messages',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_starredMessages.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'unstar_all') {
                  _confirmUnstarAll(context);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'unstar_all',
                  child: Text('Unstar all'),
                ),
              ],
            ),
        ],
      ),
      body: _isLoading
          ? const StarredMessagesShimmerSkeleton()
          : _starredMessages.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark
                                ? AppColors.darkSurface
                                : AppColors.lightSurfaceContainerHigh,
                          ),
                          child: const Icon(
                            Icons.star_rounded,
                            size: 64,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'No starred messages',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Tap and hold on any message in a chat to star it, so you can easily find it later.',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: _starredMessages.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final msg = _starredMessages[index];
                    return InkWell(
                      onTap: () => _navigateToMessageChat(msg),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.md,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primary.withValues(alpha: 0.15),
                              ),
                              child: const Icon(
                                Icons.star_rounded,
                                color: Colors.amber,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    msg.content.isNotEmpty
                                        ? msg.content
                                        : (msg.attachment?.fileName ?? 'Attachment'),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        DateFormat('MMM d, h:mm a').format(msg.timestamp),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark
                                              ? AppColors.darkTextSecondary
                                              : AppColors.lightTextSecondary,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text('•', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Go to chat',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.star, color: Colors.amber),
                              tooltip: 'Unstar',
                              onPressed: () => _unstarMessage(msg.messageId),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
