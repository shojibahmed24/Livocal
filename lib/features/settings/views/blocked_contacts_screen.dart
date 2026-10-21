import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livocal/features/settings/services/block_service.dart';
import 'package:livocal/shared/utils/app_dialog.dart';
import 'package:livocal/shared/utils/app_localizations.dart';
import 'package:livocal/shared/utils/snackbars.dart';
import 'package:livocal/theme/app_colors.dart';

class BlockedContactsScreen extends ConsumerStatefulWidget {
  const BlockedContactsScreen({super.key});

  @override
  ConsumerState<BlockedContactsScreen> createState() =>
      _BlockedContactsScreenState();
}

class _BlockedContactsScreenState extends ConsumerState<BlockedContactsScreen> {
  List<BlockedContactInfo> _blockedList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBlockedContacts();
  }

  void _loadBlockedContacts() {
    setState(() {
      _blockedList = BlockService.getBlockedContacts();
      _isLoading = false;
    });
  }

  Future<void> _handleUnblock(BlockedContactInfo contact) async {
    final confirmed = await showAppDialog<bool>(
      context: context,
      title: 'Unblock contact',
      icon: Icons.lock_open_rounded,
      contentText: 'Unblock ${contact.name}? They will be able to send you messages and call you.',
      actions: [
        AppDialogAction(
          label: AppStrings.tr(ref, 'cancel'),
          onPressed: () => Navigator.pop(context, false),
        ),
        AppDialogAction(
          label: 'Unblock',
          isPrimary: true,
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
    );

    if (confirmed == true && mounted) {
      await BlockService.unblockContact(contact.id);
      _loadBlockedContacts();
      if (mounted) {
        showSnackBar(
          context: context,
          content: 'Unblocked ${contact.name}',
          type: SnacBarType.info,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.tr(ref, 'blockedContacts')),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _blockedList.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1F2C34)
                                : const Color(0xFFF0F2F5),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.block_flipped,
                            size: 64,
                            color: isDark ? Colors.white38 : Colors.grey.shade400,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          AppStrings.tr(ref, 'noBlockedContacts'),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Blocked contacts will no longer be able to call you or send you messages.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        'Tap a contact to unblock them.',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        itemCount: _blockedList.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1, indent: 72),
                        itemBuilder: (context, index) {
                          final item = _blockedList[index];
                          return ListTile(
                            leading: CircleAvatar(
                              radius: 22,
                              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                              backgroundImage: item.avatarUrl.isNotEmpty
                                  ? NetworkImage(item.avatarUrl)
                                  : null,
                              child: item.avatarUrl.isEmpty
                                  ? Text(
                                      item.name.isNotEmpty
                                          ? item.name[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    )
                                  : null,
                            ),
                            title: Text(
                              item.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: item.phone.isNotEmpty
                                ? Text(
                                    item.phone,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark ? Colors.white54 : Colors.black45,
                                    ),
                                  )
                                : null,
                            trailing: TextButton(
                              onPressed: () => _handleUnblock(item),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.primary,
                              ),
                              child: const Text(
                                'Unblock',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                            onTap: () => _handleUnblock(item),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}
