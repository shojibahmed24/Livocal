import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:livocal/shared/constants/app_config.dart';

void main() {
  group('Relay domain resolution', () {
    tearDown(() async {
      // Restore the custom domain for the tests that run after this file.
      await AppConfig.resolveRelay(
        client: MockClient((_) async => http.Response('{}', 200)),
      );
    });

    test('custom domain is the default base url', () {
      expect(AppConfig.primaryRelayUrl, 'https://livocal.app');
      expect(AppConfig.fallbackRelayUrl, 'https://livocal-relay.onrender.com');
    });

    test('healthy domain keeps the custom base url', () async {
      await AppConfig.resolveRelay(
        client: MockClient((_) async => http.Response('{}', 200)),
      );

      expect(AppConfig.relayHttpBaseUrl, 'https://livocal.app');
      expect(AppConfig.relayWsBaseUrl, 'wss://livocal.app');
      expect(AppConfig.usingCustomDomain, isTrue);
    });

    test('unhealthy domain falls back to the render host', () async {
      await AppConfig.resolveRelay(
        client: MockClient((_) async => http.Response('not found', 404)),
      );

      expect(AppConfig.relayHttpBaseUrl, AppConfig.fallbackRelayUrl);
      expect(AppConfig.relayWsBaseUrl, 'wss://livocal-relay.onrender.com');
      expect(AppConfig.usingCustomDomain, isFalse);
    });

    test('dns failure falls back to the render host', () async {
      await AppConfig.resolveRelay(
        client: MockClient((_) async => throw http.ClientException('dns')),
      );
      expect(AppConfig.relayHttpBaseUrl, AppConfig.fallbackRelayUrl);
    });

    test('cold start timeout keeps the custom domain', () async {
      await AppConfig.resolveRelay(
        client: MockClient((_) async => http.Response('{}', 200)),
      );
      await AppConfig.resolveRelay(
        client: MockClient((_) async => throw TimeoutException('cold start')),
      );

      expect(AppConfig.relayHttpBaseUrl, AppConfig.primaryRelayUrl);
    });
  });
}
