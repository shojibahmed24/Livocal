import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:livocal/features/status/models/status_model.dart';

class StatusViewScreen extends StatefulWidget {
  final StatusModel status;
  const StatusViewScreen({super.key, required this.status});

  @override
  State<StatusViewScreen> createState() => _StatusViewScreenState();
}

class _StatusViewScreenState extends State<StatusViewScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    _progressController.forward();
    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) Navigator.pop(context);
      }
    });
  }

  void _pause() {
    if (!_isPaused) {
      _progressController.stop();
      setState(() => _isPaused = true);
    }
  }

  void _resume() {
    if (_isPaused) {
      _progressController.forward();
      setState(() => _isPaused = false);
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
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
    final status = widget.status;
    final bgColor = Color(status.colorValue);

    return Scaffold(
      backgroundColor: status.mediaUrl != null ? Colors.black : bgColor,
      body: GestureDetector(
        onLongPressStart: (_) => _pause(),
        onLongPressEnd: (_) => _resume(),
        onTapUp: (details) {
          final width = MediaQuery.of(context).size.width;
          if (details.globalPosition.dx < width / 3) {
            Navigator.pop(context);
          } else {
            Navigator.pop(context);
          }
        },
        child: SafeArea(
          child: Stack(
            children: [
              // Media / Text Body
              Center(
                child: status.mediaUrl != null && status.mediaUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: status.mediaUrl!,
                        fit: BoxFit.contain,
                        placeholder: (_, __) =>
                            const CircularProgressIndicator(color: Colors.white),
                        errorWidget: (_, __, ___) => const Icon(
                          Icons.broken_image,
                          size: 64,
                          color: Colors.white54,
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          status.text,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            height: 1.3,
                          ),
                        ),
                      ),
              ),

              // Top overlay: Progress Bar & User Header
              Positioned(
                top: 8,
                left: 12,
                right: 12,
                child: Column(
                  children: [
                    // Progress Indicator
                    AnimatedBuilder(
                      animation: _progressController,
                      builder: (context, _) => LinearProgressIndicator(
                        value: _progressController.value,
                        backgroundColor: Colors.white24,
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(Colors.white),
                        minHeight: 2.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Header Row
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.white24,
                          backgroundImage: status.userAvatar.isNotEmpty
                              ? CachedNetworkImageProvider(status.userAvatar)
                              : null,
                          child: status.userAvatar.isEmpty
                              ? Text(
                                  status.userName.isNotEmpty
                                      ? status.userName[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                status.userName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _formatTime(status.timestamp),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Caption overlay if media
              if (status.mediaUrl != null &&
                  status.mediaUrl!.isNotEmpty &&
                  status.text.isNotEmpty)
                Positioned(
                  bottom: 24,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status.text,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
