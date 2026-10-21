import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:livocal/features/chat/models/attachement.dart';
import 'package:livocal/shared/models/messages.dart';
import 'package:livocal/shared/repositories/download_service.dart';
import 'package:livocal/shared/repositories/isar_db.dart';
import 'package:livocal/shared/utils/snackbars.dart';
import 'package:livocal/shared/utils/storage_paths.dart';
import 'package:livocal/theme/app_colors.dart';
import 'package:open_file_plus/open_file_plus.dart';

class ChatMediaViewerScreen extends ConsumerStatefulWidget {
  final String chatId;
  final String contactName;

  const ChatMediaViewerScreen({
    super.key,
    required this.chatId,
    required this.contactName,
  });

  @override
  ConsumerState<ChatMediaViewerScreen> createState() =>
      _ChatMediaViewerScreenState();
}

class _ChatMediaViewerScreenState extends ConsumerState<ChatMediaViewerScreen> {
  List<StoredMessage> _mediaMessages = [];
  List<StoredMessage> _docMessages = [];
  List<StoredMessage> _linkMessages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllMedia();
  }

  Future<void> _loadAllMedia() async {
    setState(() => _isLoading = true);
    try {
      final messages = await IsarDb.getChatMediaMessages(widget.chatId);

      final List<StoredMessage> media = [];
      final List<StoredMessage> docs = [];

      for (final msg in messages) {
        final type = msg.attachment?.type;
        if (type == AttachmentType.image || type == AttachmentType.video) {
          media.add(msg);
        } else if (type == AttachmentType.document || type == AttachmentType.audio) {
          docs.add(msg);
        }
      }

      // Check for links in all messages of this chat
      final isarInstance = IsarDb.instance;
      List<StoredMessage> links = [];
      if (isarInstance != null) {
        final allMsgs = await isarInstance.storedMessages
            .filter()
            .chatIdEqualTo(widget.chatId)
            .sortByTimestampDesc()
            .findAll();
        final urlRegex = RegExp(r'https?://[^\s]+');
        links = allMsgs.where((m) => urlRegex.hasMatch(m.content)).toList();
      }

      if (mounted) {
        setState(() {
          _mediaMessages = media;
          _docMessages = docs;
          _linkMessages = links;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[ChatMediaViewer] _loadData error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatFileSize(int? bytes) {
    if (bytes == null || bytes <= 0) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryColor = AppColors.primary;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: isDark ? AppColors.darkSurface : AppColors.primary,
          foregroundColor: Colors.white,
          scrolledUnderElevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          actionsIconTheme: const IconThemeData(color: Colors.white),
          title: Text(
            widget.contactName,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: 'Media'),
              Tab(text: 'Docs'),
              Tab(text: 'Links'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  // 1. Media Tab (Grid with CachedNetworkImage + Hero + Pull-to-refresh)
                  RefreshIndicator(
                    color: primaryColor,
                    onRefresh: _loadAllMedia,
                    child: _mediaMessages.isEmpty
                        ? _buildEmptyState(
                            icon: Icons.photo_library_outlined,
                            title: 'No media',
                            subtitle:
                                'Photos and videos sent to ${widget.contactName} will appear here.',
                          )
                        : GridView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(4),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 4,
                              mainAxisSpacing: 4,
                            ),
                            itemCount: _mediaMessages.length,
                            itemBuilder: (context, index) {
                              final msg = _mediaMessages[index];
                              final fileUrl = msg.attachment?.url ?? '';
                              final isLocal = fileUrl.startsWith('/') ||
                                  !fileUrl.startsWith('http');
                              final file = File(fileUrl);
                              final heroTag = 'media_${msg.messageId}';

                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => _FullScreenMediaViewer(
                                        msg: msg,
                                        contactName: widget.contactName,
                                        heroTag: heroTag,
                                      ),
                                    ),
                                  );
                                },
                                child: Hero(
                                  tag: heroTag,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        isLocal && file.existsSync()
                                            ? Image.file(file, fit: BoxFit.cover)
                                            : CachedNetworkImage(
                                                imageUrl: fileUrl,
                                                fit: BoxFit.cover,
                                                fadeInDuration:
                                                    const Duration(milliseconds: 200),
                                                placeholder: (_, __) => Container(
                                                  color: isDark
                                                      ? Colors.white10
                                                      : Colors.black12,
                                                ),
                                                errorWidget: (_, __, ___) =>
                                                    Container(
                                                  color: Colors.grey.shade900,
                                                  child: const Icon(
                                                    Icons.broken_image,
                                                    color: Colors.white54,
                                                  ),
                                                ),
                                              ),
                                        if (msg.attachment?.type ==
                                            AttachmentType.video)
                                          const Center(
                                            child: CircleAvatar(
                                              radius: 16,
                                              backgroundColor: Colors.black54,
                                              child: Icon(Icons.play_arrow,
                                                  color: Colors.white, size: 20),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),

                  // 2. Docs Tab (Pull-to-refresh)
                  RefreshIndicator(
                    color: primaryColor,
                    onRefresh: _loadAllMedia,
                    child: _docMessages.isEmpty
                        ? _buildEmptyState(
                            icon: Icons.insert_drive_file_outlined,
                            title: 'No documents',
                            subtitle:
                                'Documents and audio files shared in this chat will appear here.',
                          )
                        : ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: _docMessages.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final msg = _docMessages[index];
                              final isAudio =
                                  msg.attachment?.type == AttachmentType.audio;
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isAudio
                                      ? Colors.orange.shade800
                                      : primaryColor,
                                  child: Icon(
                                    isAudio
                                        ? Icons.audiotrack
                                        : Icons.insert_drive_file,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  msg.attachment?.fileName ?? 'File',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                                subtitle: Text(
                                  '${_formatFileSize(msg.attachment?.fileSize)} • ${DateFormat('MMM d, yyyy').format(msg.timestamp)}',
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.open_in_new_rounded),
                                  tooltip: 'Open document',
                                  onPressed: () => _openDocument(msg),
                                ),
                                onTap: () => _openDocument(msg),
                              );
                            },
                          ),
                  ),

                  // 3. Links Tab (Pull-to-refresh)
                  RefreshIndicator(
                    color: primaryColor,
                    onRefresh: _loadAllMedia,
                    child: _linkMessages.isEmpty
                        ? _buildEmptyState(
                            icon: Icons.link_rounded,
                            title: 'No links',
                            subtitle:
                                'Links shared in this conversation will be listed here.',
                          )
                        : ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: _linkMessages.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final msg = _linkMessages[index];
                              final urlMatch = RegExp(r'https?://[^\s]+')
                                  .firstMatch(msg.content);
                              final url = urlMatch?.group(0) ?? '';

                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      primaryColor.withValues(alpha: 0.15),
                                  child: const Icon(Icons.link,
                                      color: primaryColor, size: 20),
                                ),
                                title: Text(
                                  url,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.blueAccent,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                                subtitle: Text(
                                  DateFormat('MMM d, h:mm a')
                                      .format(msg.timestamp),
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                ),
                                onTap: () async {
                                  final uri = Uri.tryParse(url);
                                  if (uri != null) {
                                    try {
                                      await launchUrl(uri,
                                          mode: LaunchMode.externalApplication);
                                    } catch (e) {
                                      debugPrint('ChatMediaViewerScreen.launchUrl error: $e');
                                      if (context.mounted) {
                                        showSnackBar(
                                          context: context,
                                          content: 'Could not open URL: $url',
                                          type: SnacBarType.error,
                                        );
                                      }
                                    }
                                  }
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

  Future<void> _openDocument(StoredMessage msg) async {
    final fileName = msg.attachment?.fileName;
    if (fileName == null || fileName.isEmpty) {
      showSnackBar(
        context: context,
        content: 'File information not available',
        type: SnacBarType.error,
      );
      return;
    }

    try {
      final localPath = DeviceStorage.getMediaFilePath(fileName);
      final file = File(localPath);

      if (await file.exists()) {
        final result = await OpenFile.open(localPath);
        if (result.type != ResultType.done && mounted) {
          showSnackBar(
            context: context,
            content: result.message.isNotEmpty
                ? result.message
                : 'No app found to open this file',
            type: SnacBarType.info,
          );
        }
      } else {
        final remoteUrl = msg.attachment?.url;
        if (remoteUrl != null && remoteUrl.isNotEmpty) {
          if (mounted) {
            showSnackBar(
              context: context,
              content: 'Downloading $fileName...',
              type: SnacBarType.info,
            );
          }
          await DownloadService.download(
            taskId: msg.messageId,
            url: remoteUrl,
            path: localPath,
            onDownloadComplete: (snapshot) async {
              if (mounted) {
                final result = await OpenFile.open(localPath);
                if (result.type != ResultType.done && mounted) {
                  showSnackBar(
                    context: context,
                    content: result.message.isNotEmpty
                        ? result.message
                        : 'No app found to open this file',
                    type: SnacBarType.info,
                  );
                }
              }
            },
            onDownloadError: () {
              if (mounted) {
                showSnackBar(
                  context: context,
                  content: 'Failed to download file',
                  type: SnacBarType.error,
                );
              }
            },
          );
        } else {
          if (mounted) {
            showSnackBar(
              context: context,
              content: 'File not found on device',
              type: SnacBarType.error,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('[ChatMediaViewerScreen] _openDocument error: $e');
      if (mounted) {
        showSnackBar(
          context: context,
          content: 'Could not open file: $e',
          type: SnacBarType.error,
        );
      }
    }
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 72, color: Colors.grey.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-screen high-performance media viewer with Hero transition and InteractiveViewer
class _FullScreenMediaViewer extends StatelessWidget {
  final StoredMessage msg;
  final String contactName;
  final String heroTag;

  const _FullScreenMediaViewer({
    required this.msg,
    required this.contactName,
    required this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    final fileUrl = msg.attachment?.url ?? '';
    final isLocal = fileUrl.startsWith('/') || !fileUrl.startsWith('http');
    final file = File(fileUrl);
    final dateStr = DateFormat('MMM d, yyyy • h:mm a').format(msg.timestamp);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.85),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              contactName,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            Text(
              dateStr,
              style: const TextStyle(color: Colors.white60, fontSize: 12),
            ),
          ],
        ),
      ),
      body: Center(
        child: Hero(
          tag: heroTag,
          child: InteractiveViewer(
            minScale: 0.8,
            maxScale: 4.0,
            child: isLocal && file.existsSync()
                ? Image.file(file)
                : CachedNetworkImage(
                    imageUrl: fileUrl,
                    placeholder: (_, __) => const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                    errorWidget: (_, __, ___) => const Center(
                      child: Icon(Icons.broken_image, size: 64, color: Colors.white54),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
