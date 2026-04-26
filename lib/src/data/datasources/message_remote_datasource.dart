import '../../services/gateway_websocket.dart';
import '../models/chat_message_model.dart';

abstract class MessageRemoteDataSource {
  Future<List<ChatMessageModel>> listMessages(String sessionId);
  Future<ChatMessageModel> sendMessage(String sessionId, String text);
  Stream<ChatMessageModel> watchNewMessages(String sessionId);
  Stream<Map<String, dynamic>> watchMessageEvents();
}

class MessageRemoteDataSourceImpl implements MessageRemoteDataSource {
  final GatewayWebSocketClient client;

  const MessageRemoteDataSourceImpl({required this.client});

  @override
  Future<List<ChatMessageModel>> listMessages(String sessionId) async {
    final response = await client.sendRequest({
      'type': 'list_messages',
      'sessionId': sessionId,
    });
    final rawList = response['messages'] as List<dynamic>?;
    return rawList
            ?.map((e) => ChatMessageModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
  }

  @override
  Future<ChatMessageModel> sendMessage(String sessionId, String text) async {
    final response = await client.sendRequest({
      'type': 'send_message',
      'sessionId': sessionId,
      'text': text,
    });
    return ChatMessageModel.fromJson(
      response['message'] as Map<String, dynamic>,
    );
  }

  @override
  Stream<ChatMessageModel> watchNewMessages(String sessionId) {
    return client.eventStream
        .where((json) => json['type'] == 'message' && json['sessionId'] == sessionId)
        .map((json) => ChatMessageModel.fromJson(
          json['message'] as Map<String, dynamic>,
        ));
  }

  @override
  Stream<Map<String, dynamic>> watchMessageEvents() {
    return client.eventStream;
  }
}
