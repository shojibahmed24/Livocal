import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:livocal/features/status/models/status_model.dart';
import 'package:livocal/features/status/services/status_service.dart';
import 'package:livocal/features/status/views/status_view_screen.dart';
import 'package:livocal/features/status/views/text_status_composer_screen.dart';
import 'package:livocal/shared/models/user.dart';
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

  StatusModel? _myStatus;

  @override
  void initState() {
    super.initState();
    _refreshMyStatus();
  }

  void _refreshMyStatus() {
    setState(() {
      _myStatus = StatusService.getMyLocalStatus();
    });
  }

  void _openTextStatusComposer() async {
    final posted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => TextStatusComposerScreen(user: widget.user),
      ),
    );
    if (posted == true) {
      _refreshMyStatus();
    }
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    if (now.difference(dt).inMinutes < 60) {
      final mins = now.difference(dt).inMinutes;
      return mins <= 1 ? 'Just now' : '$mins minutes ago';
    }
    return DateFormat('h:mm a').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final textTheme = Theme.of(context).custom.textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF00A884);

    return ListView(
      children: [
        // My Status Tile
        ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: GestureDetector(
            onTap: () {
              if (_myStatus != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StatusViewScreen(status: _myStatus!),
                  ),
                );
              } else {
                _openTextStatusComposer();
              }
            },
            child: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: _myStatus != null
                        ? Border.all(color: primaryColor, width: 2.5)
                        : null,
                  ),
                  child: CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.grey[700],
                    backgroundImage: widget.user.avatarUrl.isNotEmpty
                        ? CachedNetworkImageProvider(widget.user.avatarUrl)
                        : null,
                    child: widget.user.avatarUrl.isEmpty
                        ? Text(
                            widget.user.name.isNotEmpty
                                ? widget.user.name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 22,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                ),
                if (_myStatus == null)
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
            _myStatus != null
                ? 'Today, ${_formatTime(_myStatus!.timestamp)}'
                : 'Tap to add status update',
            style: TextStyle(
              color: _myStatus != null ? primaryColor : Colors.grey,
              fontSize: 13,
            ),
          ),
          trailing: _myStatus != null
              ? IconButton(
                  icon: const Icon(Icons.more_horiz, color: Colors.grey),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (ctx) => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.visibility),
                            title: const Text('View status'),
                            onTap: () {
                              Navigator.pop(ctx);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      StatusViewScreen(status: _myStatus!),
                                ),
                              );
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.edit),
                            title: const Text('Add new status'),
                            onTap: () {
                              Navigator.pop(ctx);
                              _openTextStatusComposer();
                            },
                          ),
                        ],
                      ),
                    );
                  },
                )
              : null,
          onTap: () {
            if (_myStatus != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StatusViewScreen(status: _myStatus!),
                ),
              );
            } else {
              _openTextStatusComposer();
            }
          },
        ),

        // Section Divider Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: isDark
              ? const Color(0xFF1F2C34).withOpacity(0.5)
              : Colors.grey[200],
          child: const Text(
            'Recent updates',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),

        // Stream of recent statuses from other contacts
        StreamBuilder<List<StatusModel>>(
          stream: StatusService.getRecentStatusesStream(widget.user.id),
          builder: (context, snapshot) {
            final statuses = snapshot.data ?? [];
            if (statuses.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                child: Column(
                  children: [
                    Icon(
                      Icons.motion_photos_on_outlined,
                      size: 64,
                      color: Colors.grey.withOpacity(0.4),
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
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: statuses.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final status = statuses[index];
                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(2.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: primaryColor, width: 2.5),
                    ),
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.grey[700],
                      backgroundImage: status.userAvatar.isNotEmpty
                          ? CachedNetworkImageProvider(status.userAvatar)
                          : null,
                      child: status.userAvatar.isEmpty
                          ? Text(
                              status.userName.isNotEmpty
                                  ? status.userName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontSize: 20,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                  ),
                  title: Text(
                    status.userName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    _formatTime(status.timestamp),
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StatusViewScreen(status: status),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),

        const SizedBox(height: 24),
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock, size: 12, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                'Your status updates are end-to-end encrypted',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}
