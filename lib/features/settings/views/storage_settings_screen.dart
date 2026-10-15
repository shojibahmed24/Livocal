import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:livocal/shared/utils/network_tracker.dart';
import 'package:livocal/shared/utils/shared_pref.dart';
import 'package:livocal/shared/utils/snackbars.dart';

class StorageSettingsScreen extends ConsumerStatefulWidget {
  const StorageSettingsScreen({super.key});

  @override
  ConsumerState<StorageSettingsScreen> createState() =>
      _StorageSettingsScreenState();
}

class _StorageSettingsScreenState extends ConsumerState<StorageSettingsScreen> {
  bool _lessDataForCalls = false;
  String _mobileDataAuto = 'Photos';
  String _wifiAuto = 'All media';
  String _roamingAuto = 'No media';

  int _dbBytes = 0;
  int _cacheBytes = 0;
  bool _isLoadingSizes = true;

  @override
  void initState() {
    super.initState();
    _lessDataForCalls =
        SharedPref.instance.getBool('storage_less_data_calls') ?? false;
    _mobileDataAuto =
        SharedPref.instance.getString('storage_mobile_auto') ?? 'Photos';
    _wifiAuto =
        SharedPref.instance.getString('storage_wifi_auto') ?? 'All media';
    _roamingAuto =
        SharedPref.instance.getString('storage_roaming_auto') ?? 'No media';

    _loadRealStorageSizes();
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  Future<int> _calculateDirSize(Directory dir) async {
    int total = 0;
    try {
      if (await dir.exists()) {
        final entities = dir.listSync(recursive: true, followLinks: false);
        for (final entity in entities) {
          if (entity is File) {
            try {
              total += entity.lengthSync();
            } catch (_) {}
          }
        }
      }
    } catch (e) {
      debugPrint('[StorageSettings] Error computing dir size: $e');
    }
    return total;
  }

  Future<void> _loadRealStorageSizes() async {
    setState(() => _isLoadingSizes = true);
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final tempDir = await getTemporaryDirectory();

      final dbSize = await _calculateDirSize(docDir);
      final cacheSize = await _calculateDirSize(tempDir);

      if (mounted) {
        setState(() {
          _dbBytes = dbSize;
          _cacheBytes = cacheSize;
          _isLoadingSizes = false;
        });
      }
    } catch (e) {
      debugPrint('[StorageSettings] Failed to calculate storage: $e');
      if (mounted) {
        setState(() => _isLoadingSizes = false);
      }
    }
  }

  Future<void> _clearCache() async {
    try {
      final tempDir = await getTemporaryDirectory();
      int freed = 0;
      if (await tempDir.exists()) {
        final entities = tempDir.listSync(recursive: true, followLinks: false);
        for (final entity in entities) {
          if (entity is File) {
            try {
              final len = entity.lengthSync();
              entity.deleteSync();
              freed += len;
            } catch (_) {}
          }
        }
      }

      await _loadRealStorageSizes();

      if (mounted) {
        showSnackBar(
          context: context,
          content: 'Cache cleared successfully (${_formatBytes(freed)} freed)',
          type: SnacBarType.info,
        );
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(
          context: context,
          content: 'Failed to clear cache: $e',
          type: SnacBarType.error,
        );
      }
    }
  }

  void _showAutoDownloadDialog({
    required String title,
    required String current,
    required ValueChanged<String> onSelected,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1F2C34)
            : Colors.white,
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['No media', 'Photos', 'Photos, Audio', 'All media']
              .map(
                (opt) => RadioListTile<String>(
                  title: Text(opt),
                  value: opt,
                  groupValue: current,
                  activeColor: const Color(0xFF00A884),
                  onChanged: (val) {
                    if (val != null) {
                      onSelected(val);
                      Navigator.pop(ctx);
                    }
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF00A884);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final sentBytes = NetworkTracker.getSentBytes();
    final recvBytes = NetworkTracker.getReceivedBytes();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Storage and data'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.folder_outlined, color: primaryColor),
            title: const Text('Manage storage'),
            subtitle: Text(
              _isLoadingSizes
                  ? 'Calculating real disk usage...'
                  : 'Database: ${_formatBytes(_dbBytes)} • Cache: ${_formatBytes(_cacheBytes)}',
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: isDark ? const Color(0xFF1F2C34) : Colors.white,
                  title: const Text('Storage Breakdown'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('• App Database (Isar): ${_formatBytes(_dbBytes)}'),
                      const SizedBox(height: 8),
                      Text('• Cached Media & Temporary Audio: ${_formatBytes(_cacheBytes)}'),
                      const SizedBox(height: 8),
                      Text(
                        'Total App Footprint: ${_formatBytes(_dbBytes + _cacheBytes)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('CLOSE'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00A884),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _clearCache();
                      },
                      child: const Text('CLEAR CACHE'),
                    ),
                  ],
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.data_usage, color: primaryColor),
            title: const Text('Network usage'),
            subtitle: Text('${_formatBytes(sentBytes)} sent • ${_formatBytes(recvBytes)} received'),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: isDark ? const Color(0xFF1F2C34) : Colors.white,
                  title: const Text('Network Usage Details'),
                  content: (sentBytes == 0 && recvBytes == 0)
                      ? const Text('No network usage recorded yet.')
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('• Total Traffic: ${_formatBytes(sentBytes + recvBytes)}'),
                            const SizedBox(height: 6),
                            Text('• Sent: ${_formatBytes(sentBytes)}'),
                            const SizedBox(height: 6),
                            Text('• Received: ${_formatBytes(recvBytes)}'),
                          ],
                        ),
                  actions: [
                    if (sentBytes > 0 || recvBytes > 0)
                      TextButton(
                        onPressed: () {
                          NetworkTracker.resetUsage();
                          Navigator.pop(ctx);
                          setState(() {});
                        },
                        child: const Text('RESET USAGE', style: TextStyle(color: Colors.redAccent)),
                      ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('CLOSE'),
                    ),
                  ],
                ),
              );
            },
          ),
          SwitchListTile(
            secondary: Icon(Icons.phone_in_talk_outlined, color: primaryColor),
            title: const Text('Use less data for calls'),
            subtitle: const Text('Optimizes Opus codec audio bitrate during low network connectivity'),
            value: _lessDataForCalls,
            activeColor: primaryColor,
            onChanged: (val) {
              setState(() => _lessDataForCalls = val);
              SharedPref.instance.setBool('storage_less_data_calls', val);
            },
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
            child: Text(
              'Media auto-download',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isDark ? const Color(0xFF8696A0) : const Color(0xFF667781),
              ),
            ),
          ),
          ListTile(
            title: const Text('When using mobile data'),
            subtitle: Text(_mobileDataAuto, style: const TextStyle(color: Colors.grey)),
            onTap: () => _showAutoDownloadDialog(
              title: 'When using mobile data',
              current: _mobileDataAuto,
              onSelected: (val) {
                setState(() => _mobileDataAuto = val);
                SharedPref.instance.setString('storage_mobile_auto', val);
              },
            ),
          ),
          ListTile(
            title: const Text('When connected to Wi-Fi'),
            subtitle: Text(_wifiAuto, style: const TextStyle(color: Colors.grey)),
            onTap: () => _showAutoDownloadDialog(
              title: 'When connected to Wi-Fi',
              current: _wifiAuto,
              onSelected: (val) {
                setState(() => _wifiAuto = val);
                SharedPref.instance.setString('storage_wifi_auto', val);
              },
            ),
          ),
          ListTile(
            title: const Text('When roaming'),
            subtitle: Text(_roamingAuto, style: const TextStyle(color: Colors.grey)),
            onTap: () => _showAutoDownloadDialog(
              title: 'When roaming',
              current: _roamingAuto,
              onSelected: (val) {
                setState(() => _roamingAuto = val);
                SharedPref.instance.setString('storage_roaming_auto', val);
              },
            ),
          ),
        ],
      ),
    );
  }
}
