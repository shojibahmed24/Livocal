import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:livocal/features/status/models/status_model.dart';
import 'package:livocal/features/status/services/status_service.dart';
import 'package:livocal/features/status/views/status_view_screen.dart';
import 'package:livocal/features/status/views/text_status_composer_screen.dart';
import 'package:livocal/shared/models/user.dart';
import 'package:livocal/shared/utils/app_dialog.dart';
import 'package:livocal/shared/utils/snackbars.dart';
import 'package:livocal/shared/widgets/shimmer_skeleton.dart';
import 'package:livocal/theme/app_colors.dart';
import 'package:livocal/theme/app_tokens.dart';
import 'package:livocal/theme/theme.dart';

class StatusTab extends ConsumerStatefulWidget {
  final User user;
  const StatusTab({super.key, required this.user});

  @override
  ConsumerState<StatusTab> createState() => _StatusTabState();
}

class _StatusTabState extends ConsumerState<StatusTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  void _openTextStatusComposer() async {
    final posted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => TextStatusComposerScreen(user: widget.user),
      ),
    );
    if (posted == true && mounted) {
      setState(() {});
    }
  }

  Future<void> _pickAndUploadPhotoStatus(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, imageQuality: 80);
      if (picked == null) return;

      final file = File(picked.path);
      if (!mounted) return;

      final captionController = TextEditingController();
      final confirm = await showAppDialog<bool>(
        context: context,
        title: 'Add Status Caption',
        icon: Icons.add_photo_alternate_outlined,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(file, height: 160, fit: BoxFit.cover),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: captionController,
              decoration: const InputDecoration(
                hintText: 'Add a caption...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          AppDialogAction(
            label: 'CANCEL',
            onPressed: () => Navigator.pop(context, false),
          ),
          AppDialogAction(
            label: 'SEND',
            isPrimary: true,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      );

      if (confirm == true && mounted) {
        showSnackBar(
          context: context,
          content: 'Uploading status...',
          type: SnacBarType.info,
        );

        await StatusService.uploadPhotoStatus(
          userId: widget.user.id,
          userName: widget.user.name,
          userAvatar: widget.user.avatarUrl,
          imageFile: file,
          caption: captionController.text.trim(),
        );

        if (mounted) {
          setState(() {});
          showSnackBar(
            context: context,
            content: 'Status uploaded successfully',
            type: SnacBarType.info,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(
          context: context,
          content: 'Failed to upload status: $e',
          type: SnacBarType.error,
        );
      }
    }
  }

  void _showAddStatusOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.darkSurface
          : AppColors.lightBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.radiusLg)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUploadPhotoStatus(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.primary),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUploadPhotoStatus(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: AppColors.primary),
              title: const Text('Text status'),
              onTap: () {
                Navigator.pop(ctx);
                _openTextStatusComposer();
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    if (now.difference(dt).inMinutes < 60) {
      final mins = now.difference(dt).inMinutes;
      return mins <= 1 ? 'Just now' : '$mins minutes ago';
    }
    return DateFormat('h:mm a').format(dt);
  }

  Widget _buildStatusAvatar({
    required String name,
    required String avatarUrl,
    required bool isViewed,
    required bool isDark,
    double radius = 25,
  }) {
    final ringColor = isViewed
        ? (isDark ? Colors.white38 : Colors.grey.shade400)
        : AppColors.primary;
    final borderWidth = isViewed ? 2.0 : 2.5;

    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ringColor, width: borderWidth),
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: const Color(0xFF1F2C34),
        backgroundImage: avatarUrl.isNotEmpty
            ? CachedNetworkImageProvider(avatarUrl)
            : null,
        child: avatarUrl.isEmpty
            ? Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(
                  fontSize: radius * 0.8,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isDark
          ? const Color(0xFF1F2C34).withValues(alpha: 0.5)
          : Colors.grey.shade100,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: isDark ? const Color(0xFF8696A0) : const Color(0xFF667781),
        ),
      ),
    );
  }

  Widget _buildStatusTile({
    required StatusModel status,
    required bool isViewed,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: _buildStatusAvatar(
        name: status.userName,
        avatarUrl: status.userAvatar,
        isViewed: isViewed,
        isDark: isDark,
      ),
      title: Text(
        status.userName,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
      subtitle: Text(
        _formatTime(status.timestamp),
        style: const TextStyle(fontSize: 13, color: Colors.grey),
      ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final textTheme = Theme.of(context).custom.textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryColor = AppColors.primary;
    final viewedStatusIds = StatusService.getViewedStatusIds();

    return RefreshIndicator(
      onRefresh: () async {
        setState(() {});
      },
      child: ListView(
        children: [
          // Realtime My Status Stream
          StreamBuilder<StatusModel?>(
            stream: StatusService.getMyStatusStream(widget.user.id),
            builder: (context, snapshot) {
              final myStatus = snapshot.data ?? StatusService.getMyLocalStatus();

              return ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: GestureDetector(
                  onTap: () async {
                    if (myStatus != null) {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StatusViewScreen.single(status: myStatus),
                        ),
                      );
                      if (mounted) setState(() {});
                    } else {
                      _showAddStatusOptions();
                    }
                  },
                  child: Stack(
                    children: [
                      _buildStatusAvatar(
                        name: widget.user.name,
                        avatarUrl: widget.user.avatarUrl,
                        isViewed: myStatus == null,
                        isDark: isDark,
                        radius: 26,
                      ),
                      if (myStatus == null)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: primaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Theme.of(context).scaffoldBackgroundColor,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.add,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                title: Text(
                  'My status',
                  style: textTheme.titleMedium.copyWith(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  myStatus != null
                      ? 'Today, ${_formatTime(myStatus.timestamp)}'
                      : 'Tap to add status update',
                  style: TextStyle(
                    color: myStatus != null ? primaryColor : Colors.grey,
                    fontSize: 13,
                  ),
                ),
                trailing: myStatus != null
                    ? IconButton(
                        icon: const Icon(Icons.more_horiz, color: Colors.grey),
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            backgroundColor:
                                isDark ? const Color(0xFF1F2C34) : Colors.white,
                            builder: (ctx) => Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.visibility),
                                  title: const Text('View status'),
                                  onTap: () async {
                                    Navigator.pop(ctx);
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            StatusViewScreen.single(status: myStatus),
                                      ),
                                    );
                                    if (mounted) setState(() {});
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.add),
                                  title: const Text('Add new status'),
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    _showAddStatusOptions();
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      )
                    : null,
                onTap: () async {
                  if (myStatus != null) {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StatusViewScreen.single(status: myStatus),
                      ),
                    );
                    if (mounted) setState(() {});
                  } else {
                    _showAddStatusOptions();
                  }
                },
              );
            },
          ),

          // Contacts Status Updates Stream
          StreamBuilder<List<StatusModel>>(
            stream: StatusService.getRecentStatusesStream(widget.user.id),
            builder: (context, snapshot) {
              // 1. Shimmer Skeleton while loading (avoids "No recent updates" flash!)
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 110,
                        height: 14,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white12 : Colors.black12,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const StatusListShimmerSkeleton(),
                    ],
                  ),
                );
              }

              // 2. Error state with Retry button
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.cloud_off_rounded,
                          size: 48,
                          color: Colors.red.shade300,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "Couldn't load status updates",
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () => setState(() {}),
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final allStatuses = snapshot.data ?? [];
              if (allStatuses.isEmpty) {
                return Column(
                  children: [
                    _buildSectionHeader('Recent updates', isDark),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                      child: Column(
                        children: [
                          Icon(
                            Icons.motion_photos_on_outlined,
                            size: 64,
                            color: Colors.grey.withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No recent updates',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Status updates from your contacts will appear here. They disappear after 24 hours.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }

              final recentUpdates = allStatuses
                  .where((s) => !viewedStatusIds.contains(s.id))
                  .toList();
              final viewedUpdates = allStatuses
                  .where((s) => viewedStatusIds.contains(s.id))
                  .toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section: Recent Updates (Unviewed statuses with green ring)
                  if (recentUpdates.isNotEmpty) ...[
                    _buildSectionHeader('Recent updates', isDark),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: recentUpdates.length,
                      itemBuilder: (context, idx) {
                        final status = recentUpdates[idx];
                        return _buildStatusTile(
                          status: status,
                          isViewed: false,
                          isDark: isDark,
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => StatusViewScreen(
                                  statuses: recentUpdates,
                                  initialIndex: idx,
                                ),
                              ),
                            );
                            if (mounted) setState(() {});
                          },
                        );
                      },
                    ),
                  ],

                  // Section: Viewed Updates (Viewed statuses with grey ring)
                  if (viewedUpdates.isNotEmpty) ...[
                    _buildSectionHeader('Viewed updates', isDark),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: viewedUpdates.length,
                      itemBuilder: (context, idx) {
                        final status = viewedUpdates[idx];
                        return _buildStatusTile(
                          status: status,
                          isViewed: true,
                          isDark: isDark,
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => StatusViewScreen(
                                  statuses: viewedUpdates,
                                  initialIndex: idx,
                                ),
                              ),
                            );
                            if (mounted) setState(() {});
                          },
                        );
                      },
                    ),
                  ],
                ],
              );
            },
          ),

          const SizedBox(height: 24),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.privacy_tip_outlined, size: 13, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  'Your status updates are protected by your privacy settings',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

