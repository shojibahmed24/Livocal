class AppConfig {
  /// Base HTTP URL for the Livocal backend relay server.
  /// Can be overridden at build or runtime with `--dart-define=RELAY_URL=...`.
  static const String relayHttpBaseUrl = String.fromEnvironment(
    'RELAY_URL',
    defaultValue: 'https://livocal-relay.onrender.com',
  );

  /// Base WebSocket URL for real-time live translation relay.
  /// Can be overridden at build or runtime with `--dart-define=RELAY_WS_URL=...`.
  static String get relayWsBaseUrl {
    const rawWs = String.fromEnvironment('RELAY_WS_URL');
    if (rawWs.isNotEmpty) return rawWs;
    if (relayHttpBaseUrl.startsWith('https://')) {
      return relayHttpBaseUrl.replaceFirst('https://', 'wss://');
    } else if (relayHttpBaseUrl.startsWith('http://')) {
      return relayHttpBaseUrl.replaceFirst('http://', 'ws://');
    }
    return 'wss://livocal-relay.onrender.com';
  }

  /// Specific REST endpoints
  static String get callNotifyIncomingUrl =>
      '$relayHttpBaseUrl/api/call/notify-incoming';

  static String get chatNotifyMessageUrl =>
      '$relayHttpBaseUrl/api/notify/chat-message';

  static String get matchContactsUrl =>
      '$relayHttpBaseUrl/api/contacts/match';

  static String get iceServersUrl =>
      '$relayHttpBaseUrl/api/webrtc/ice-servers';

  static String get liveCallWsUrl =>
      '$relayWsBaseUrl/ws/live-call';

  static String get translateUrl =>
      '$relayHttpBaseUrl/api/translate';

  static String get privacyPolicyUrl =>
      '$relayHttpBaseUrl/privacy-policy';

  static String get termsOfServiceUrl =>
      '$relayHttpBaseUrl/terms-of-service';

  static String get missingContactsHelpUrl =>
      '$relayHttpBaseUrl/help/missing-contacts';

  static String get walletInitOrGetUrl =>
      '$relayHttpBaseUrl/api/wallet/init-or-get';

  static String get walletBalanceUrl =>
      '$relayHttpBaseUrl/api/wallet/balance';

  static String get walletDeductMinuteUrl =>
      '$relayHttpBaseUrl/api/wallet/deduct-minute';

  static String get walletCallEndUrl =>
      '$relayHttpBaseUrl/api/wallet/call-end';

  static String get walletRechargeUrl =>
      '$relayHttpBaseUrl/api/wallet/recharge';

  static String get walletPaymentRequestUrl =>
      '$relayHttpBaseUrl/api/wallet/payment-request';
}
