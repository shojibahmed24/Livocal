import 'dart:io';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:livocal/shared/models/user.dart';
import 'package:livocal/shared/utils/app_dialog.dart';
import 'package:livocal/shared/utils/snackbars.dart';
import 'package:livocal/theme/app_colors.dart';

class LinkedDevicesScreen extends StatelessWidget {
  final User user;
  const LinkedDevicesScreen({super.key, required this.user});

  Future<void> _startQrScanner(BuildContext context) async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (context.mounted) {
          showSnackBar(
            context: context,
            content: 'No camera available to scan QR code.',
            type: SnacBarType.error,
          );
        }
        return;
      }

      if (context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DeviceQrScanScreen(cameras: cameras, userId: user.id),
          ),
        );
      }
    } catch (e) {
      debugPrint('LinkedDevicesScreen camera init error: $e');
      if (context.mounted) {
        showSnackBar(
          context: context,
          content: 'Failed to initialize camera scanner: $e',
          type: SnacBarType.error,
        );
      }
    }
  }

  void _showUnlinkDialog(BuildContext context, String deviceId, String deviceName) {
    showAppDialog(
      context: context,
      title: 'Log out from $deviceName?',
      contentText: 'This device will be disconnected from your Livocal account immediately.',
      actions: [
        AppDialogAction(
          label: 'Cancel',
          onPressed: () => Navigator.pop(context),
        ),
        AppDialogAction(
          label: 'LOG OUT',
          isDestructive: true,
          onPressed: () async {
            Navigator.pop(context);
            try {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.id)
                  .collection('linked_devices')
                  .doc(deviceId)
                  .delete();
              if (context.mounted) {
                showSnackBar(
                  context: context,
                  content: 'Successfully disconnected $deviceName',
                  type: SnacBarType.info,
                );
              }
            } catch (e) {
              debugPrint('LinkedDevicesScreen disconnect device error: $e');
              if (context.mounted) {
                showSnackBar(
                  context: context,
                  content: 'Failed to disconnect device: $e',
                  type: SnacBarType.error,
                );
              }
            }
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1F2C34) : Colors.white;

    final primaryPlatform = Platform.isAndroid
        ? 'Android Device'
        : (Platform.isIOS
            ? 'iPhone / iOS'
            : (Platform.isWindows ? 'Windows PC' : 'Local Device'));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.primary,
        foregroundColor: Colors.white,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Linked devices',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        children: [
          // Banner / Graphic
          Container(
            color: cardBg,
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.12),
                  ),
                  child: const Icon(
                    Icons.devices_rounded,
                    size: 54,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Use Livocal on other devices',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Link up to 4 companion devices to access your chats and live translated voice calls anywhere.',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? const Color(0xFF8696A0) : const Color(0xFF667781),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    onPressed: () => _startQrScanner(context),
                    icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                    label: const Text(
                      'Link a device',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Device status list
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'DEVICE STATUS',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
                color: isDark ? const Color(0xFF8696A0) : const Color(0xFF667781),
              ),
            ),
          ),

          Container(
            color: cardBg,
            child: Column(
              children: [
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: Icon(Icons.phone_android, color: Colors.white),
                  ),
                  title: Text(
                    'This device ($primaryPlatform)',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'Active now • Primary Device • Encrypted',
                    style: TextStyle(color: AppColors.primary, fontSize: 13),
                  ),
                  trailing: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                // Real Firestore stream for companion linked devices
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.id)
                      .collection('linked_devices')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: snapshot.data!.docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final deviceName = data['deviceName'] ?? 'Web Browser';
                        final browser = data['browser'] ?? 'Chrome';
                        final lastActive = data['lastActive'] != null
                            ? 'Recently active'
                            : 'Connected';

                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Divider(height: 1, indent: 72),
                            ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isDark
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.black.withValues(alpha: 0.06),
                                child: Icon(
                                  deviceName.toString().toLowerCase().contains('mac') ||
                                          deviceName.toString().toLowerCase().contains('windows')
                                      ? Icons.computer
                                      : Icons.laptop_chromebook,
                                  color: isDark ? Colors.white70 : Colors.black87,
                                ),
                              ),
                              title: Text(
                                deviceName,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                '$browser • $lastActive',
                                style: TextStyle(
                                  color: isDark
                                      ? const Color(0xFF8696A0)
                                      : const Color(0xFF667781),
                                  fontSize: 13,
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.logout_rounded, color: Color(0xFFE53935), size: 20),
                                tooltip: 'Log out',
                                onPressed: () => _showUnlinkDialog(context, doc.id, deviceName),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Security banner
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock, size: 14, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Your personal chats and live translations are end-to-end encrypted across all linked devices.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? const Color(0xFF8696A0) : const Color(0xFF667781),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class DeviceQrScanScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  final String userId;
  const DeviceQrScanScreen({super.key, required this.cameras, required this.userId});

  @override
  State<DeviceQrScanScreen> createState() => _DeviceQrScanScreenState();
}

class _DeviceQrScanScreenState extends State<DeviceQrScanScreen> {
  CameraController? _controller;
  bool _isInit = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final backCamera = widget.cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => widget.cameras.first,
    );

    final controller = CameraController(
      backCamera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await controller.initialize();
      if (mounted) {
        setState(() {
          _controller = controller;
          _isInit = true;
        });
      }
    } catch (e) {
      debugPrint('[DeviceQrScanScreen] Camera init error: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR code'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: _isInit && _controller != null
          ? Stack(
              children: [
                Positioned.fill(
                  child: CameraPreview(_controller!),
                ),
                // Semi-transparent overlay with viewfinder cutout
                Positioned.fill(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 250,
                        height: 250,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.primary, width: 3),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: null,
                      ),
                      const SizedBox(height: 28),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white24, width: 1),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Scan Livocal Web QR Code',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Visit web.livocal.app on your computer. Point your phone to scan the QR code and link your browser session securely.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontSize: 12.5,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
    );
  }
}
