import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:livocal/features/chat/models/message.dart';
import 'package:livocal/shared/models/user.dart';
import 'package:livocal/shared/repositories/isar_db.dart';
import 'package:livocal/shared/ui/pill_chip.dart';
import 'package:livocal/shared/utils/abc.dart';
import 'package:livocal/shared/utils/app_localizations.dart';
import 'package:livocal/shared/utils/snackbars.dart';
import 'package:livocal/theme/app_colors.dart';

/// In-thread message search. Searches text and attachment file names locally
/// (Isar) so it works offline and never sends chat content to a server.
class ChatSearchScreen extends StatefulWidget {
  final User self;
  final User other;

  const ChatSearchScreen({
    super.key,
    required this.self,
    required this.other,
  });

  @override
  State<ChatSearchScreen> createState() => _ChatSearchScreenState();
}

class _ChatSearchScreenState extends State<ChatSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final langCode = Localizations.localeOf(context).languageCode;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.primary,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        title: TextField(
          controller: _controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          cursorColor: Colors.white,
          decoration: InputDecoration(
            hintText: AppStrings.get('searchMessages', langCode),
            hintStyle: const TextStyle(color: Colors.white60, fontSize: 15),
            border: InputBorder.none,
          ),
          onChanged: (value) =>
              setState(() => _query = value.trim().toLowerCase()),
        ),
        actions: [
          if (_query.isNotEmpty)
            IconButton(
              tooltip: 'Clear',
              icon: const Icon(Icons.close_rounded),
              onPressed: () {
                _controller.clear();
                setState(() => _query = '');
              },
            ),
        ],
      ),
      body: StreamBuilder<List<Message>>(
        stream: IsarDb.getChatStream(
          getChatId(widget.self.id, widget.other.id),
          limit: 5000,
        ),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_query.isEmpty) {
            return EmptyState(
              icon: Icons.search_rounded,
              title: AppStrings.get('searchInChat', langCode),
            );
          }

          final results = snapshot.data!.where((message) {
            final content = message.content.toLowerCase();
            final fileName = (message.attachment?.fileName ?? '').toLowerCase();
            return content.contains(_query) || fileName.contains(_query);
          }).toList();

          if (results.isEmpty) {
            return EmptyState(
              icon: Icons.search_off_rounded,
              title: AppStrings.get(
                'noResultsFor',
                langCode,
                args: {'query': _query},
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 4),
            itemCount: results.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
            ),
            itemBuilder: (context, index) {
              final message = results[index];
              final isMe = message.senderId == widget.self.id;
              final time = DateFormat('dd MMM, HH:mm')
                  .format(message.timestamp.toDate());
              final preview = message.attachment != null &&
                      (message.attachment?.fileName ?? '').isNotEmpty
                  ? message.attachment!.fileName
                  : message.content;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  child: Icon(
                    isMe ? Icons.person_rounded : Icons.person_outline_rounded,
                    color: AppColors.primary,
                  ),
                ),
                title: Text(
                  preview,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  '${isMe ? 'You' : widget.other.name} • $time',
                  style: TextStyle(color: textSecondary, fontSize: 11.5),
                ),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: message.content));
                  showSnackBar(
                    context: context,
                    content: AppStrings.get('messageCopied', langCode),
                    type: SnacBarType.info,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
