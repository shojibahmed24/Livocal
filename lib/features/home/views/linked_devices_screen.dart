import 'package:flutter/material.dart';
import 'package:livocal/shared/models/user.dart';

class LinkedDevicesScreen extends StatelessWidget {
  final User user;
  const LinkedDevicesScreen({super.key, required this.user});

  void _showLinkDeviceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1F2C34)
            : Colors.white,
        title: const Row(
          children: [
            Icon(Icons.qr_code_scanner, color: Color(0xFF00A884)),
            SizedBox(width: 10),
            Text('Link a Device'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'To use Livocal on Web or Desktop:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text('1. Open livocal.web.app on your computer browser.'),
            const SizedBox(height: 6),
            const Text('2. Point your phone camera at the screen to capture the QR code.'),
            const SizedBox(height: 16),
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                ),
                child: const Icon(
                  Icons.qr_code_2,
                  size: 140,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
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
                    onPressed: () => _showLinkDeviceDialog(context),
                    icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                    label: const Text(
                      'Link a device',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00A884),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Device status section
          Container(
            color: cardBg,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Device status',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFF8696A0) : const Color(0xFF667781),
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF00A884),
                    child: Icon(Icons.phone_android, color: Colors.white, size: 20),
                  ),
                  title: const Text(
                    'This device (Primary)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'Active now • Android • End-to-End Encrypted',
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
                    'Your personal chats and live translations are end-to-end encrypted on all devices.',
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
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
