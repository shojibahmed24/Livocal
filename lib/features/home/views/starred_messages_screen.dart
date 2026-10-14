import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:livocal/shared/models/messages.dart';
import 'package:livocal/shared/repositories/isar_db.dart';
import 'package:livocal/shared/utils/shared_pref.dart';

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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _unstarMessage(String messageId) async {
    final list = SharedPref.instance.getStringList('starred_message_ids') ?? [];
    list.remove(messageId);
    await SharedPref.instance.setStringList('starred_message_ids', list);
    _loadStarredMessages();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Starred messages'),
        actions: [
          if (_starredMessages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {
                showMenu<String>(
                  context: context,
                  position: const RelativeRect.fromLTRB(100, 80, 0, 0),
                  items: [
                    const PopupMenuItem(
                      value: 'unstar_all',
                      child: Text('Unstar all'),
                    ),
                  ],
                ).then((value) async {
                  if (value == 'unstar_all') {
                    await SharedPref.instance
                        .setStringList('starred_message_ids', []);
                    _loadStarredMessages();
                  }
                });
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
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
                                ? const Color(0xFF1F2C34)
                                : const Color(0xFFE9EDEF),
                          ),
                          child: const Icon(
                            Icons.star_rounded,
                            size: 64,
                            color: Color(0xFF00A884),
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
                                ? const Color(0xFF8696A0)
                                : const Color(0xFF667781),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  itemCount: _starredMessages.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final msg = _starredMessages[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFF00A884),
                        child: Icon(Icons.star, color: Colors.white, size: 20),
                      ),
                      title: Text(
                        msg.content.isNotEmpty
                            ? msg.content
                            : (msg.attachment?.fileName ?? 'Attachment'),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        DateFormat('MMM d, h:mm a').format(msg.timestamp),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.star, color: Colors.amber),
                        tooltip: 'Unstar',
                        onPressed: () => _unstarMessage(msg.messageId),
                      ),
                    );
                  },
                ),
    );
  }
}
