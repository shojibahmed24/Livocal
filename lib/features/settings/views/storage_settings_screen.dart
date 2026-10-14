import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    final primaryColor = const Color(0xFF00A884);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Storage and data'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.folder_outlined, color: primaryColor),
            title: const Text('Manage storage'),
            subtitle: const Text('Local Isar database: 14.2 MB • Cache: 4.8 MB'),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: isDark ? const Color(0xFF1F2C34) : Colors.white,
                  title: const Text('Storage Details'),
                  content: const Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('• Message DB: 14.2 MB (Isar Engine)'),
                      SizedBox(height: 6),
                      Text('• Cached Media & Waveforms: 4.8 MB'),
                      SizedBox(height: 6),
                      Text('• Translation Audio Cache: 1.2 MB'),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('OK'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00A884),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        showSnackBar(
                          context: context,
                          content: 'Temporary audio cache cleared (6.0 MB freed)',
                          type: SnacBarType.info,
                        );
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
            subtitle: const Text('42.8 MB sent • 128.4 MB received'),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: isDark ? const Color(0xFF1F2C34) : Colors.white,
                  title: const Text('Network Usage'),
                  content: const Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('• Calls: 34.5 MB sent • 98.2 MB received'),
                      SizedBox(height: 6),
                      Text('• Messages: 5.2 MB sent • 18.6 MB received'),
                      SizedBox(height: 6),
                      Text('• Media: 3.1 MB sent • 11.6 MB received'),
                    ],
                  ),
                  actions: [
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
