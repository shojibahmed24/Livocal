import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import 'package:livocal/shared/constants/app_config.dart';

/// In-app host for the browser guest room.
///
/// The relay page (`/room/<handle>`) does the WebRTC work; the app only shows
/// it and exposes the same guest link so it can be sent from the phone without
/// opening a desktop browser.
class GuestCallScreen extends StatefulWidget {
  final String handle;
  final String displayName;
  final String Function(String key) t;

  const GuestCallScreen({
    super.key,
    required this.handle,
    required this.displayName,
    required this.t,
  });

  @override
  State<GuestCallScreen> createState() => _GuestCallScreenState();
}

class _GuestCallScreenState extends State<GuestCallScreen> {
  WebViewController? _web;
  String? _guestUrl;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  String get _apiUrl =>
      '${AppConfig.relayHttpBaseUrl}/api/public/room/'
      '${Uri.encodeComponent(widget.handle)}';

  Future<void> _prepare() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response =
          await http.get(Uri.parse(_apiUrl)).timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) {
        throw Exception('room ${response.statusCode}');
      }
      final data = jsonDecode(response.body);
      final map = data is Map ? data : const <String, dynamic>{};
      final hostUrl = (map['hostUrl'] ?? '').toString();
      final guestUrl = (map['guestUrl'] ?? '').toString();
      if (hostUrl.isEmpty) throw Exception('no host url');

      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0xFF04070D));

      if (controller.platform is AndroidWebViewController) {
        await (controller.platform as AndroidWebViewController)
            .setOnPlatformPermissionRequest((request) async {
          request.grant();
        });
      }
      await controller.loadRequest(Uri.parse(hostUrl));

      if (!mounted) return;
      setState(() {
        _web = controller;
        _guestUrl = guestUrl;
        _loading = false;
      });
    } catch (e) {
      debugPrint('[GuestCall] room setup failed: $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = widget.t('guestCallUnavailable');
      });
    }
  }

  Future<void> _copy() async {
    final url = _guestUrl;
    if (url == null) return;
    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(widget.t('guestLinkCopied'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final guestUrl = _guestUrl;
    return Scaffold(
      backgroundColor: const Color(0xFF04070D),
      appBar: AppBar(
        title: Text(
          '${widget.t('guestCall')} · ${widget.displayName}',
          style: const TextStyle(fontSize: 15),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.t('guestCallIntro'),
                  style: const TextStyle(fontSize: 11.5, color: Colors.white70),
                ),
                if (guestUrl != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A1220),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            guestUrl,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          tooltip: widget.t('copyGuestLink'),
                          onPressed: _copy,
                          icon: const Icon(Icons.copy_rounded, size: 17),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: () => Share.share(
                            guestUrl,
                            subject: widget.displayName,
                          ),
                          icon: const Icon(Icons.share_outlined, size: 17),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final error = _error;
    if (error != null || _web == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                error ?? widget.t('guestCallUnavailable'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 12.5),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _prepare,
                child: Text(widget.t('retry')),
              ),
            ],
          ),
        ),
      );
    }
    return WebViewWidget(controller: _web!);
  }
}
