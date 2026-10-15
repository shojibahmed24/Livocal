import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:livocal/features/status/models/status_model.dart';
import 'package:livocal/features/status/services/status_service.dart';

class StatusViewScreen extends StatefulWidget {
  final List<StatusModel> statuses;
  final int initialIndex;

  const StatusViewScreen({
    super.key,
    required this.statuses,
    this.initialIndex = 0,
  });

  StatusViewScreen.single({
    super.key,
    required StatusModel status,
  })  : statuses = [status],
        initialIndex = 0;

  @override
  State<StatusViewScreen> createState() => _StatusViewScreenState();
}

class _StatusViewScreenState extends State<StatusViewScreen>
    with SingleTickerProviderStateMixin {
  late int _currentIndex;
  late AnimationController _progressController;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.statuses.length - 1);

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _onProgressCompleted();
      }
    });

    _markCurrentAsViewed();
    _progressController.forward();
  }

  void _markCurrentAsViewed() {
    if (widget.statuses.isNotEmpty && _currentIndex < widget.statuses.length) {
      StatusService.markStatusAsViewed(widget.statuses[_currentIndex].id);
    }
  }

  void _onProgressCompleted() {
    if (_currentIndex < widget.statuses.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _markCurrentAsViewed();
      _progressController.reset();
      _progressController.forward();
    } else {
      if (mounted) Navigator.pop(context);
    }
  }

  void _goToPreviousStatus() {
    HapticFeedback.selectionClick();
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
      _markCurrentAsViewed();
      _progressController.reset();
      _progressController.forward();
    } else {
      _progressController.reset();
      _progressController.forward();
    }
  }

  void _goToNextStatus() {
    HapticFeedback.selectionClick();
    if (_currentIndex < widget.statuses.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _markCurrentAsViewed();
      _progressController.reset();
      _progressController.forward();
    } else {
      if (mounted) Navigator.pop(context);
    }
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

  Widget _buildAvatar(StatusModel status) {
    if (status.userAvatar.isNotEmpty) {
      return CircleAvatar(
        radius: 18,
        backgroundColor: Colors.white24,
        backgroundImage: CachedNetworkImageProvider(status.userAvatar),
      );
    }
    return CircleAvatar(
      radius: 18,
      backgroundColor: const Color(0xFF00B386),
      child: Text(
        status.userName.isNotEmpty ? status.userName[0].toUpperCase() : '?',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.statuses.isEmpty) {
      return const Scaffold(backgroundColor: Colors.black);
    }

    final status = widget.statuses[_currentIndex];
    final isMedia = status.mediaUrl != null && status.mediaUrl!.isNotEmpty;
    final bgColor = Color(status.colorValue);

    return Scaffold(
      backgroundColor: isMedia ? Colors.black : bgColor,
      body: GestureDetector(
        onLongPressStart: (_) => _pause(),
        onLongPressEnd: (_) => _resume(),
        onTapUp: (details) {
          final width = MediaQuery.of(context).size.width;
          if (details.globalPosition.dx < width * 0.3) {
            _goToPreviousStatus();
          } else {
            _goToNextStatus();
          }
        },
        child: SafeArea(
          child: Stack(
            children: [
              // Main Media or Text Status Body
              Center(
                child: isMedia
                    ? CachedNetworkImage(
                        imageUrl: status.mediaUrl!,
                        fit: BoxFit.contain,
                        placeholder: (_, __) =>
                            const CircularProgressIndicator(color: Colors.white),
                        errorWidget: (_, __, ___) => const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.broken_image, size: 64, color: Colors.white54),
                              SizedBox(height: 8),
                              Text(
                                'Failed to load media',
                                style: TextStyle(color: Colors.white54),
                              ),
                            ],
                          ),
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

              // Bottom Caption for Media Status (if present)
              if (isMedia && status.text.isNotEmpty)
                Positioned(
                  bottom: 24,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      status.text,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

              // Top Overlay: Segmented Progress Bar & User Header
              Positioned(
                top: 8,
                left: 12,
                right: 12,
                child: Column(
                  children: [
                    // Segmented WhatsApp-Style Progress Bar
                    Row(
                      children: List.generate(widget.statuses.length, (index) {
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2.0),
                            child: AnimatedBuilder(
                              animation: _progressController,
                              builder: (context, _) {
                                double progress;
                                if (index < _currentIndex) {
                                  progress = 1.0;
                                } else if (index == _currentIndex) {
                                  progress = _progressController.value;
                                } else {
                                  progress = 0.0;
                                }

                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(2.0),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    backgroundColor: Colors.white30,
                                    valueColor: const AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                    minHeight: 2.5,
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 10),

                    // Header Row: Avatar, Name, Time, and Close Button
                    Row(
                      children: [
                        _buildAvatar(status),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                status.userName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
            ],
          ),
        ),
      ),
    );
  }
}
