import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:livocal/shared/models/user.dart';
import 'package:livocal/shared/utils/snackbars.dart';

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
            builder: (_) => DeviceQrScanScreen(cameras: cameras),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        showSnackBar(
          context: context,
          content: 'Failed to initialize camera scanner: $e',
          type: SnacBarType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1F2C34) : Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Linked devices'),
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
                    color: const Color(0xFF00A884).withOpacity(0.12),
                  ),
                  child: const Icon(
                    Icons.devices_rounded,
                    size: 54,
                    color: Color(0xFF00A884),
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
                  'Link up to 4 devices to access your chats and live translated voice calls anywhere.',
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
                      backgroundColor: const Color(0xFF00A884),
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
                    backgroundColor: Color(0xFF00A884),
                    child: Icon(Icons.phone_android, color: Colors.white),
                  ),
                  title: const Text(
                    'This device (Primary)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'Active now • Android • Authenticated Session',
                    style: TextStyle(color: Color(0xFF00A884), fontSize: 13),
                  ),
                  trailing: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Color(0xFF00A884),
                      shape: BoxShape.circle,
                    ),
                  ),
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
                    'Your personal chats and live translations are protected with authenticated encryption on all devices.',
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
        ],
      ),
    );
  }
}

class DeviceQrScanScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  const DeviceQrScanScreen({super.key, required this.cameras});

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
                          border: Border.all(color: const Color(0xFF00A884), width: 3),
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Point camera at QR code on Livocal Web',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00A884)),
              ),
            ),
    );
  }
}
