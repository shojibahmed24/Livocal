import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatsapp_clone/shared/models/user.dart';
import 'package:whatsapp_clone/shared/utils/snackbars.dart';
import 'package:whatsapp_clone/theme/theme.dart';

class StatusTab extends ConsumerWidget {
  final User user;
  const StatusTab({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).custom.textTheme;

    return ListView(
      children: [
        // My Status Tile
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Stack(
            children: [
              CircleAvatar(
                radius: 27,
                backgroundColor: Colors.grey[700],
                backgroundImage: user.avatarUrl.isNotEmpty
                    ? CachedNetworkImageProvider(user.avatarUrl)
                    : null,
                child: user.avatarUrl.isEmpty
                    ? Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                        style: const TextStyle(
                          fontSize: 22,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: const Color(0xFF25D366),
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
          title: Text(
            'My status',
            style: textTheme.titleMedium.copyWith(fontWeight: FontWeight.bold),
          ),
          subtitle: const Text(
            'Tap to add status update',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          onTap: () {
            showSnackBar(
              context: context,
              content: 'Status feature: Tap the camera button below to take a photo',
              type: SnacBarType.info,
            );
          },
        ),

        // Section Divider Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Theme.of(context).brightness == Brightness.dark
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

        // Empty Status Placeholder Card
        Padding(
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
      ],
    );
  }
}
