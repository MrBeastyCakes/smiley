import 'dart:async';
import 'dart:convert';

import '../../core/errors/exceptions.dart';
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
    final completer = Completer<List<ChatMessageModel>>();

    late StreamSubscription<Map<String, dynamic>> sub;
    sub = client.messageStream.listen(
      (json) {
        if (json['type'] == 'message_list' && json['sessionId'] == sessionId) {
          sub.cancel();
          final rawList = json['messages'] as List<dynamic>?;
          final models = rawList
                  ?.map((e) => ChatMessageModel.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              [];
          if (!completer.isCompleted) {
            completer.complete(models);
          }
        }
      },
      onError: (Object error) {
        if (!completer.isCompleted) {
          completer.completeError(
            GatewayException('Failed to list messages: \$error'),
          );
        }
      },
    );

    await client.send({
      'type': 'list_messages',
      'sessionId': sessionId,
    });

    return completer.future;
  }

  @override
  Future<ChatMessageModel> sendMessage(String sessionId, String text) async {
    final completer = Completer<ChatMessageModel>();

    late StreamSubscription<Map<String, dynamic>> sub;
    sub = client.messageStream.listen(
      (json) {
        if (json['type'] == 'message_sent' && json['sessionId'] == sessionId) {
          sub.cancel();
          final model = ChatMessageModel.fromJson(
            json['message'] as Map<String, dynamic>,
          );
          if (!completer.isCompleted) {
            completer.complete(model);
          }
        }
      },
      onError: (Object error) {
        if (!completer.isCompleted) {
          completer.completeError(
            GatewayException('Failed to send message: \$error'),
          );
        }
      },
    );

    await client.send({
      'type': 'send_message',
      'sessionId': sessionId,
      'text': text,
    });

    return completer.future;
  }

  @override
  Stream<ChatMessageModel> watchNewMessages(String sessionId) {
    return client.messageStream
        .where(
          (json) => json['type'] == 'message' && json['sessionId'] == sessionId,
        )
        .map(
          (json) => ChatMessageModel.fromJson(
            json['message'] as Map<String, dynamic>,
          ),
        );
  }

  @override
  Stream<Map<String, dynamic>> watchMessageEvents() {
    return client.messageStream;
  }
}
