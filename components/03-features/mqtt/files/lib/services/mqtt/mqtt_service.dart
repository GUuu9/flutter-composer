import 'dart:async';
import 'dart:typed_data';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttService {
  MqttServerClient? _client;
  bool _connecting = false;
  bool _disposed = false;

  Future<void> connect(
    String host,
    int port,
    String clientId, {
    bool secure = true,
    String? username,
    String? password,
  }) async {
    if (_disposed || _client != null || _connecting)
      throw StateError('MQTT unavailable');
    if (host.trim().isEmpty ||
        port < 1 ||
        port > 65535 ||
        clientId.isEmpty ||
        (password != null && username == null))
      throw ArgumentError('MQTT configuration');
    final client =
        MqttServerClient.withPort(
            host,
            clientId,
            port,
            maxConnectionAttempts: 1,
          )
          ..secure = secure
          ..autoReconnect = false
          ..connectTimeoutPeriod = 15000
          ..keepAlivePeriod = 30
          ..logging(on: false);
    client.setProtocolV311();
    _client = client;
    _connecting = true;
    try {
      final connecting = client.connect(username, password).then((status) {
        // 제한시간 뒤 완료된 연결도 남기지 않습니다.
        if (_disposed || !identical(_client, client)) client.disconnect();
        return status;
      });
      await connecting.timeout(const Duration(seconds: 30));
      if (_disposed ||
          !identical(_client, client) ||
          client.connectionStatus?.state != MqttConnectionState.connected) {
        throw StateError('MQTT connection failed or cancelled');
      }
    } catch (_) {
      client.disconnect();
      if (identical(_client, client)) _client = null;
      rethrow;
    } finally {
      _connecting = false;
    }
  }

  MqttServerClient get _connected {
    final client = _client;
    if (_connecting ||
        client == null ||
        client.connectionStatus?.state != MqttConnectionState.connected) {
      throw StateError('MQTT disconnected');
    }
    return client;
  }

  Stream<List<MqttReceivedMessage<MqttMessage>>> get updates =>
      _connected.updates!;

  void subscribe(String topic, {MqttQos qos = MqttQos.atLeastOnce}) {
    if (topic.isEmpty) throw ArgumentError('MQTT topic');
    if (_connected.subscribe(topic, qos) == null)
      throw StateError('MQTT subscribe rejected');
  }

  void unsubscribe(String topic) => _connected.unsubscribe(topic);

  int publish(
    String topic,
    Uint8List bytes, {
    MqttQos qos = MqttQos.atLeastOnce,
  }) {
    if (topic.isEmpty ||
        topic.contains('#') ||
        topic.contains('+') ||
        bytes.length > 1024 * 1024) {
      throw ArgumentError('MQTT publish topic or size');
    }
    final payload = MqttClientPayloadBuilder();
    for (final byte in bytes) {
      payload.addByte(byte);
    }
    return _connected.publishMessage(topic, qos, payload.payload!);
  }

  void disconnect() {
    final client = _client;
    _client = null;
    client?.disconnect();
  }

  void dispose() {
    _disposed = true;
    disconnect();
  }
}
