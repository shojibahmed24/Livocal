import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:livocal/features/chat/models/attachement.dart';
import 'package:livocal/shared/models/messages.dart';
import 'package:livocal/shared/repositories/isar_db.dart';
import 'package:livocal/theme/app_colors.dart';

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
    final primaryColor = AppColors.primary;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.contactName),
          bottom: TabBar(
            indicatorColor: primaryColor,
            labelColor: primaryColor,
            unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
            tabs: [
              Tab(text: 'Media (${_mediaMessages.length})'),
              Tab(text: 'Docs (${_docMessages.length})'),
              Tab(text: 'Links (${_linkMessages.length})'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  // Media Tab
                  _mediaMessages.isEmpty
                      ? _buildEmptyState(
                          icon: Icons.photo_library_outlined,
                          title: 'No media',
                          subtitle: 'Photos and videos sent to ${widget.contactName} will appear here.',
                        )
                      : GridView.builder(
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

                            return GestureDetector(
                              onTap: () {
                                if (msg.attachment != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => Scaffold(
                                        backgroundColor: Colors.black,
                                        appBar: AppBar(
                                          backgroundColor: Colors.black,
                                          iconTheme: const IconThemeData(color: Colors.white),
                                          title: Text(widget.contactName, style: const TextStyle(color: Colors.white)),
                                        ),
                                        body: Center(
                                          child: InteractiveViewer(
                                            child: isLocal && file.existsSync()
                                                ? Image.file(file)
                                                : CachedNetworkImage(
                                                    imageUrl: fileUrl,
                                                    placeholder: (_, __) => const CircularProgressIndicator(color: Colors.white),
                                                    errorWidget: (_, __, ___) => const Icon(Icons.broken_image, size: 64, color: Colors.white54),
                                                  ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  isLocal && file.existsSync()
                                      ? Image.file(file, fit: BoxFit.cover)
                                      : Image.network(
                                          fileUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Container(
                                            color: Colors.grey[800],
                                            child: const Icon(Icons.broken_image, color: Colors.white54),
                                          ),
                                        ),
                                  if (msg.attachment?.type == AttachmentType.video)
                                    const Center(
                                      child: CircleAvatar(
                                        radius: 16,
                                        backgroundColor: Colors.black54,
                                        child: Icon(Icons.play_arrow, color: Colors.white, size: 20),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),

                  // Docs Tab
                  _docMessages.isEmpty
                      ? _buildEmptyState(
                          icon: Icons.insert_drive_file_outlined,
                          title: 'No documents',
                          subtitle: 'Documents and audio files shared in this chat will appear here.',
                        )
                      : ListView.separated(
                          itemCount: _docMessages.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final msg = _docMessages[index];
                            final isAudio = msg.attachment?.type == AttachmentType.audio;
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isAudio
                                    ? Colors.orange[800]
                                    : primaryColor.withOpacity(0.2),
                                child: Icon(
                                  isAudio ? Icons.audiotrack : Icons.insert_drive_file,
                                  color: isAudio ? Colors.white : primaryColor,
                                ),
                              ),
                              title: Text(
                                msg.attachment?.fileName ?? 'Document',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              subtitle: Text(
                                '${_formatFileSize(msg.attachment?.fileSize)} • ${DateFormat('MMM d, yyyy').format(msg.timestamp)}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            );
                          },
                        ),

                  // Links Tab
                  _linkMessages.isEmpty
                      ? _buildEmptyState(
                          icon: Icons.link_outlined,
                          title: 'No links',
                          subtitle: 'Links shared in this chat will appear here.',
                        )
                      : ListView.separated(
                          itemCount: _linkMessages.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final msg = _linkMessages[index];
                            final urlRegex = RegExp(r'https?://[^\s]+');
                            final match = urlRegex.firstMatch(msg.content);
                            final url = match?.group(0) ?? '';

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: primaryColor.withOpacity(0.15),
                                child: Icon(Icons.link, color: primaryColor),
                              ),
                              title: Text(
                                url,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: primaryColor,
                                  decoration: TextDecoration.underline,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              subtitle: Text(
                                '${DateFormat('MMM d, yyyy').format(msg.timestamp)} • ${msg.content}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              onTap: () async {
                                final uri = Uri.tryParse(url);
                                if (uri != null && await canLaunchUrl(uri)) {
                                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                                }
                              },
                            );
                          },
                        ),
                ],
              ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 72, color: Colors.grey.withOpacity(0.4)),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? const Color(0xFF8696A0) : const Color(0xFF667781),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
