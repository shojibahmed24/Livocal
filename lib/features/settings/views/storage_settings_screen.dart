import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:livocal/shared/utils/app_dialog.dart';
import 'package:livocal/shared/utils/app_localizations.dart';
import 'package:livocal/shared/utils/network_tracker.dart';
import 'package:livocal/shared/utils/shared_pref.dart';
import 'package:livocal/shared/utils/snackbars.dart';
import 'package:livocal/shared/widgets/settings_row.dart';
import 'package:livocal/theme/app_colors.dart';

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

  String _localizeOption(String opt) {
    switch (opt) {
      case 'No media':
        return AppStrings.tr(ref, 'noMedia');
      case 'Photos':
        return AppStrings.tr(ref, 'photos');
      case 'Photos, Audio':
        return AppStrings.tr(ref, 'photosAudio');
      case 'All media':
        return AppStrings.tr(ref, 'allMedia');
      default:
        return opt;
    }
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
            } catch (e) {
              debugPrint('[StorageSettings] File length error: $e');
            }
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
            } catch (e) {
              debugPrint('[StorageSettings] Temp file deletion error: $e');
            }
          }
        }
      }

      await _loadRealStorageSizes();

      if (mounted) {
        showSnackBar(
          context: context,
          content: '${AppStrings.tr(ref, 'cacheClearedSuccess')} (${_formatBytes(freed)})',
          type: SnacBarType.info,
        );
      }
    } catch (e) {
      debugPrint('StorageSettingsScreen clearCache error: $e');
      if (mounted) {
        showSnackBar(
          context: context,
          content: '${AppStrings.tr(ref, 'failedToClearCache')}: $e',
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
    showAppDialog(
      context: context,
      title: title,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: ['No media', 'Photos', 'Photos, Audio', 'All media']
            .map(
              (opt) => RadioListTile<String>(
                title: Text(_localizeOption(opt)),
                value: opt,
                groupValue: current,
                activeColor: AppColors.primary,
                onChanged: (val) {
                  if (val != null) {
                    onSelected(val);
                    Navigator.pop(context);
                  }
                },
              ),
            )
            .toList(),
      ),
      actions: [
        AppDialogAction(
          label: AppStrings.tr(ref, 'cancel').toUpperCase(),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final sentBytes = NetworkTracker.getSentBytes();
    final recvBytes = NetworkTracker.getReceivedBytes();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.primary,
        foregroundColor: Colors.white,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          AppStrings.tr(ref, 'storage'),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        children: [
          SettingsSectionHeader(title: AppStrings.tr(ref, 'storageAndNetworkUsage')),
          SettingsRow(
            icon: Icons.folder_outlined,
            title: AppStrings.tr(ref, 'manageStorage'),
            subtitle: _isLoadingSizes
                ? AppStrings.tr(ref, 'calculatingStorage')
                : '${AppStrings.tr(ref, 'databaseLabel')}${_formatBytes(_dbBytes)} • ${AppStrings.tr(ref, 'cacheLabel')}${_formatBytes(_cacheBytes)}',
            onTap: () {
              showAppDialog(
                context: context,
                title: AppStrings.tr(ref, 'storageBreakdown'),
                icon: Icons.pie_chart_outline_rounded,
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${AppStrings.tr(ref, 'appDatabaseIsar')}${_formatBytes(_dbBytes)}'),
                    const SizedBox(height: 8),
                    Text(
                        '${AppStrings.tr(ref, 'cachedMediaTemp')}${_formatBytes(_cacheBytes)}'),
                    const SizedBox(height: 8),
                    Text(
                      '${AppStrings.tr(ref, 'totalAppFootprint')}${_formatBytes(_dbBytes + _cacheBytes)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                actions: [
                  AppDialogAction(
                    label: AppStrings.tr(ref, 'clearCache'),
                    isDestructive: true,
                    onPressed: () {
                      Navigator.pop(context);
                      _clearCache();
                    },
                  ),
                  AppDialogAction(
                    label: AppStrings.tr(ref, 'close'),
                    isPrimary: true,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              );
            },
          ),
          const Divider(height: 1),
          SettingsRow(
            icon: Icons.data_usage_rounded,
            title: AppStrings.tr(ref, 'networkUsage'),
            subtitle:
                '${_formatBytes(sentBytes)} ${AppStrings.tr(ref, 'sent')} • ${_formatBytes(recvBytes)} ${AppStrings.tr(ref, 'received')}',
            onTap: () {
              showAppDialog(
                context: context,
                title: AppStrings.tr(ref, 'networkUsageDetails'),
                icon: Icons.network_check_rounded,
                content: (sentBytes == 0 && recvBytes == 0)
                    ? Text(AppStrings.tr(ref, 'noNetworkUsage'))
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              '${AppStrings.tr(ref, 'totalTraffic')}${_formatBytes(sentBytes + recvBytes)}'),
                          const SizedBox(height: 6),
                          Text('${AppStrings.tr(ref, 'sentTraffic')}${_formatBytes(sentBytes)}'),
                          const SizedBox(height: 6),
                          Text('${AppStrings.tr(ref, 'receivedTraffic')}${_formatBytes(recvBytes)}'),
                        ],
                      ),
                actions: [
                  if (sentBytes > 0 || recvBytes > 0)
                    AppDialogAction(
                      label: AppStrings.tr(ref, 'resetUsage'),
                      isDestructive: true,
                      onPressed: () {
                        NetworkTracker.resetUsage();
                        Navigator.pop(context);
                        setState(() {});
                      },
                    ),
                  AppDialogAction(
                    label: AppStrings.tr(ref, 'close'),
                    isPrimary: true,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              );
            },
          ),
          const Divider(height: 1),
          SettingsSectionHeader(title: AppStrings.tr(ref, 'callSettings')),
          SettingsRow(
            icon: Icons.phone_in_talk_outlined,
            title: AppStrings.tr(ref, 'useLessDataCalls'),
            subtitle: AppStrings.tr(ref, 'useLessDataCallsSub'),
            showChevron: false,
            trailing: Switch(
              value: _lessDataForCalls,
              activeTrackColor: AppColors.primary,
              activeThumbColor: Colors.white,
              onChanged: (val) {
                setState(() => _lessDataForCalls = val);
                SharedPref.instance.setBool('storage_less_data_calls', val);
              },
            ),
          ),
          const Divider(height: 1),
          SettingsSectionHeader(title: AppStrings.tr(ref, 'mediaAutoDownload')),
          SettingsRow(
            icon: Icons.signal_cellular_alt_rounded,
            title: AppStrings.tr(ref, 'whenUsingMobileData'),
            subtitle: _localizeOption(_mobileDataAuto),
            onTap: () => _showAutoDownloadDialog(
              title: AppStrings.tr(ref, 'whenUsingMobileData'),
              current: _mobileDataAuto,
              onSelected: (val) {
                setState(() => _mobileDataAuto = val);
                SharedPref.instance.setString('storage_mobile_auto', val);
              },
            ),
          ),
          const Divider(height: 1),
          SettingsRow(
            icon: Icons.wifi_rounded,
            title: AppStrings.tr(ref, 'whenConnectedWifi'),
            subtitle: _localizeOption(_wifiAuto),
            onTap: () => _showAutoDownloadDialog(
              title: AppStrings.tr(ref, 'whenConnectedWifi'),
              current: _wifiAuto,
              onSelected: (val) {
                setState(() => _wifiAuto = val);
                SharedPref.instance.setString('storage_wifi_auto', val);
              },
            ),
          ),
          const Divider(height: 1),
          SettingsRow(
            icon: Icons.public_rounded,
            title: AppStrings.tr(ref, 'whenRoaming'),
            subtitle: _localizeOption(_roamingAuto),
            onTap: () => _showAutoDownloadDialog(
              title: AppStrings.tr(ref, 'whenRoaming'),
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
