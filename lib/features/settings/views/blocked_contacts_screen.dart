import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livocal/features/home/controllers/contacts_controller.dart';
import 'package:livocal/features/settings/services/block_service.dart';
import 'package:livocal/shared/models/contact.dart';
import 'package:livocal/shared/repositories/firebase_firestore.dart';
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
      try {
        await BlockService.unblockContact(contact.id);
        _loadBlockedContacts();
        if (mounted) {
          showSnackBar(
            context: context,
            content: 'Unblocked ${contact.name}',
            type: SnacBarType.info,
          );
        }
      } catch (e) {
        if (mounted) {
          showSnackBar(
            context: context,
            content: 'Failed to unblock ${contact.name}. Please check connection.',
            type: SnacBarType.error,
          );
        }
      }
    }
  }

  Future<void> _pickContactToBlock() async {
    ref.read(contactPickerControllerProvider.notifier).init();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final selectedContact = await showModalBottomSheet<Contact>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1F2C34) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, _) {
            final allContacts = ref.watch(contactPickerControllerProvider);
            final blockedIds = BlockService.getBlockedIds();
            final availableContacts = allContacts
                .where((c) =>
                    !blockedIds.contains(c.userId) &&
                    !blockedIds.contains(c.phoneNumber))
                .toList();

            return DraggableScrollableSheet(
              initialChildSize: 0.75,
              maxChildSize: 0.95,
              minChildSize: 0.5,
              expand: false,
              builder: (context, scrollController) {
                return Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Text(
                        'Select contact to block',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    Expanded(
                      child: availableContacts.isEmpty
                          ? Center(
                              child: Text(
                                'No contacts available to block',
                                style: TextStyle(
                                  color: isDark ? Colors.white60 : Colors.black54,
                                ),
                              ),
                            )
                          : ListView.separated(
                              controller: scrollController,
                              itemCount: availableContacts.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1, indent: 64),
                              itemBuilder: (context, index) {
                                final c = availableContacts[index];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor:
                                        AppColors.primary.withValues(alpha: 0.15),
                                    child: Text(
                                      c.displayName.isNotEmpty
                                          ? c.displayName[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(c.displayName,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  subtitle: Text(c.phoneNumber,
                                      style: const TextStyle(fontSize: 12)),
                                  onTap: () => Navigator.pop(ctx, c),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );

    if (selectedContact != null && mounted) {
      final confirmed = await showAppDialog<bool>(
        context: context,
        title: 'Block ${selectedContact.displayName}?',
        icon: Icons.block_flipped,
        iconColor: Colors.redAccent,
        contentText:
            'Blocked contacts will no longer be able to call you or send you messages.',
        actions: [
          AppDialogAction(
            label: AppStrings.tr(ref, 'cancel'),
            onPressed: () => Navigator.pop(context, false),
          ),
          AppDialogAction(
            label: 'BLOCK',
            isDestructive: true,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      );

      if (confirmed == true && mounted) {
        try {
          String contactId = selectedContact.userId ?? '';
          if (contactId.isEmpty && selectedContact.phoneNumber.isNotEmpty) {
            try {
              final user = await ref
                  .read(firebaseFirestoreRepositoryProvider)
                  .getUserByPhone(selectedContact.phoneNumber);
              if (user != null && user.id.isNotEmpty) {
                contactId = user.id;
              }
            } catch (e) {
              debugPrint('[BlockedContacts] Error resolving user by phone: $e');
            }
          }
          if (contactId.isEmpty) {
            contactId = selectedContact.phoneNumber;
          }

          await BlockService.blockContact(
            contactId: contactId,
            contactName: selectedContact.displayName,
            phone: selectedContact.phoneNumber,
          );
          _loadBlockedContacts();
          if (mounted) {
            showSnackBar(
              context: context,
              content: '${selectedContact.displayName} has been blocked',
              type: SnacBarType.info,
            );
          }
        } catch (e) {
          if (mounted) {
            showSnackBar(
              context: context,
              content: 'Failed to block ${selectedContact.displayName}. Please check connection.',
              type: SnacBarType.error,
            );
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.tr(ref, 'blockedContacts')),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_rounded),
            tooltip: 'Add blocked contact',
            onPressed: _pickContactToBlock,
          ),
        ],
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
