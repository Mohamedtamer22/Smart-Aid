import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../config/app_config.dart';

/// Authenticated STOMP transport for confirmed incident updates.
/// REST remains authoritative after reconnecting or a missed message.
class IncidentSocket {
  StompClient connect({required String accessToken}) {
    final endpoint = Uri.parse(AppConfig.apiBaseUrl)
        .replace(
          scheme: AppConfig.apiBaseUrl.startsWith('https') ? 'wss' : 'ws',
          path: '/ws',
        )
        .toString();
    return StompClient(
      config: StompConfig(
        url: endpoint,
        stompConnectHeaders: {'Authorization': 'Bearer $accessToken'},
        webSocketConnectHeaders: {'Authorization': 'Bearer $accessToken'},
        reconnectDelay: const Duration(seconds: 5),
        onConnect: (_) {},
        onWebSocketError: (_) {},
      ),
    );
  }
}
