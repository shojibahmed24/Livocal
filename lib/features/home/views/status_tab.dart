import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:livocal/features/status/models/status_model.dart';
import 'package:livocal/features/status/services/status_service.dart';
import 'package:livocal/features/status/views/status_view_screen.dart';
import 'package:livocal/features/status/views/text_status_composer_screen.dart';
import 'package:livocal/shared/models/user.dart';
import 'package:livocal/shared/ui/livocal_avatar.dart';
import 'package:livocal/shared/utils/app_dialog.dart';
import 'package:livocal/shared/utils/app_localizations.dart';
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
      debugPrint('StatusTab upload status error: $e');
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
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.radiusLg)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: Text(AppStrings.tr(ref, 'takePhoto')),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUploadPhotoStatus(ImageSource.camera);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.photo_library, color: AppColors.primary),
              title: Text(AppStrings.tr(ref, 'chooseFromGallery')),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUploadPhotoStatus(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: AppColors.primary),
              title: Text(AppStrings.tr(ref, 'textStatus')),
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
    // Unviewed updates get the brand status ring; viewed ones go quiet.
    return LivocalAvatar(
      name: name,
      imageUrl: avatarUrl,
      size: radius * 2,
      ring: isViewed ? AvatarRing.none : AvatarRing.status,
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isDark
          ? const Color(0xFF16203A).withValues(alpha: 0.5)
          : Colors.grey.shade100,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: isDark ? const Color(0xFF8A96B2) : const Color(0xFF5B6785),
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
              final myStatus =
                  snapshot.data ?? StatusService.getMyLocalStatus();

              return ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: GestureDetector(
                  onTap: () async {
                    if (myStatus != null) {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              StatusViewScreen.single(status: myStatus),
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
                                color:
                                    Theme.of(context).scaffoldBackgroundColor,
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
                  AppStrings.tr(ref, 'myStatus'),
                  style: textTheme.titleMedium
                      .copyWith(fontWeight: FontWeight.bold),
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
                                isDark ? const Color(0xFF16203A) : Colors.white,
                            builder: (ctx) => Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.visibility),
                                  title: Text(AppStrings.tr(ref, 'viewStatus')),
                                  onTap: () async {
                                    Navigator.pop(ctx);
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => StatusViewScreen.single(
                                            status: myStatus),
                                      ),
                                    );
                                    if (mounted) setState(() {});
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.add),
                                  title:
                                      Text(AppStrings.tr(ref, 'addNewStatus')),
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
                        builder: (_) =>
                            StatusViewScreen.single(status: myStatus),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                  padding:
                      const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.cloud_off_rounded,
                          size: 48,
                          color: Colors.red.shade300,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          AppStrings.tr(ref, 'couldNotLoadStatus'),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () => setState(() {}),
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: Text(AppStrings.tr(ref, 'retryTooltip')),
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
                    _buildSectionHeader(
                      AppStrings.tr(ref, 'recentUpdates'),
                      isDark,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 40, horizontal: 24),
                      child: Column(
                        children: [
                          Icon(
                            Icons.motion_photos_on_outlined,
                            size: 64,
                            color: Colors.grey.withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            AppStrings.tr(ref, 'noRecentUpdates'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppStrings.tr(ref, 'statusUpdatesDesc'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
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
                    _buildSectionHeader(
                      AppStrings.tr(ref, 'recentUpdates'),
                      isDark,
                    ),
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
                const Icon(Icons.privacy_tip_outlined,
                    size: 13, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  AppStrings.tr(ref, 'statusPrivacyNote'),
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
