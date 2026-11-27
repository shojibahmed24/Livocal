import 'dart:async';

import 'package:http/http.dart' as http;

class AppConfig {
  /// Base HTTP URL for the Livocal backend relay server.
  ///
  /// Primary host is the custom domain. If the domain is not reachable the app
  /// falls back to the Render host so calls, chat and links never break.
  /// Override at build time with `--dart-define=RELAY_URL=...`.
  static const String _envBase = String.fromEnvironment('RELAY_URL');

  static const String primaryRelayUrl =
      _envBase == '' ? 'https://livocal.app' : _envBase;

  static const String fallbackRelayUrl =
      _envBase == '' ? 'https://livocal-relay.onrender.com' : _envBase;

  static String _baseUrl = primaryRelayUrl;

  static String get relayHttpBaseUrl => _baseUrl;

  /// True once the custom domain answered a health check.
  static bool get usingCustomDomain => _baseUrl == primaryRelayUrl;

  /// Pings the custom domain once. A cold Render start times out, which is not
  /// a reason to abandon the domain; a DNS or HTTP failure is.
  static Future<void> resolveRelay({http.Client? client}) async {
    if (primaryRelayUrl == fallbackRelayUrl) return;
    final httpClient = client ?? http.Client();
    try {
      final response = await httpClient
          .get(Uri.parse('$primaryRelayUrl/health'))
          .timeout(const Duration(seconds: 6));
      _baseUrl =
          response.statusCode == 200 ? primaryRelayUrl : fallbackRelayUrl;
    } on TimeoutException {
      // Likely a sleeping free instance – keep the custom domain.
    } catch (_) {
      _baseUrl = fallbackRelayUrl;
    } finally {
      if (client == null) httpClient.close();
    }
  }

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
    return 'wss://livocal.app';
  }

  /// Specific REST endpoints
  static String get callNotifyIncomingUrl =>
      '$relayHttpBaseUrl/api/call/notify-incoming';

  static String get chatNotifyMessageUrl =>
      '$relayHttpBaseUrl/api/notify/chat-message';

  static String get deleteMessageNotifyUrl =>
      '$relayHttpBaseUrl/api/notify/delete-message';

  static String get matchContactsUrl => '$relayHttpBaseUrl/api/contacts/match';

  static String get iceServersUrl => '$relayHttpBaseUrl/api/webrtc/ice-servers';

  static String get liveCallWsUrl => '$relayWsBaseUrl/ws/live-call';

  static String get translateUrl => '$relayHttpBaseUrl/api/translate';

  static String get callSummaryUrl => '$relayHttpBaseUrl/api/call/summary';

  static String get callReviewUrl => '$relayHttpBaseUrl/api/call/review';

  static String get proposalUrl => '$relayHttpBaseUrl/api/ai/proposal';

  static String get changeUsernameUrl =>
      '$relayHttpBaseUrl/api/profile/username';

  static String get shareInvoiceUrl => '$relayHttpBaseUrl/api/share/invoice';

  static String publicUserUrl(String username) =>
      '$relayHttpBaseUrl/api/public/uid/$username';

  static String get shareProposalUrl => '$relayHttpBaseUrl/api/share/proposal';

  static String get privacyPolicyUrl => '$relayHttpBaseUrl/privacy-policy';

  static String get termsOfServiceUrl => '$relayHttpBaseUrl/terms-of-service';

  static String get missingContactsHelpUrl =>
      '$relayHttpBaseUrl/help/missing-contacts';

  static String get walletInitOrGetUrl =>
      '$relayHttpBaseUrl/api/wallet/init-or-get';

  static String get walletBalanceUrl => '$relayHttpBaseUrl/api/wallet/balance';

  static String get walletDeductMinuteUrl =>
      '$relayHttpBaseUrl/api/wallet/deduct-minute';

  static String get walletCallEndUrl => '$relayHttpBaseUrl/api/wallet/call-end';

  static String get walletRechargeUrl =>
      '$relayHttpBaseUrl/api/wallet/recharge';

  static String get walletPaymentRequestUrl =>
      '$relayHttpBaseUrl/api/wallet/payment-request';

  static String get walletDepositInfoUrl =>
      '$relayHttpBaseUrl/api/wallet/deposit-info';

  static String get walletP2pTransferUrl =>
      '$relayHttpBaseUrl/api/wallet/p2p-transfer';

  static String get walletRecipientPaymentSettingsUrl =>
      '$relayHttpBaseUrl/api/wallet/recipient-payment-settings';

  static String get walletMyPaymentSettingsUrl =>
      '$relayHttpBaseUrl/api/wallet/my-payment-settings';

  /// Full account erasure (Firestore + Storage + Firebase Auth) via Admin SDK.
  static String get accountDeleteUrl => '$relayHttpBaseUrl/api/account/delete';
}
