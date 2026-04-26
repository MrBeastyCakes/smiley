import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:openclaw_client/src/core/errors/exceptions.dart';
import 'package:openclaw_client/src/data/datasources/gateway_ping_datasource.dart';
import 'package:openclaw_client/src/domain/entities/gateway_settings.dart';
import 'package:openclaw_client/src/presentation/blocs/connection/connection_bloc.dart';
import 'package:openclaw_client/src/services/gateway_websocket.dart';

class MockGatewayWebSocketClient extends Mock implements GatewayWebSocketClient {}
class MockGatewayPingDataSource extends Mock implements GatewayPingDataSource {}
class FakeGatewaySettings extends Fake implements GatewaySettings {}

void main() {
  late MockGatewayWebSocketClient mockClient;
  late MockGatewayPingDataSource mockPing;

  setUpAll(() {
    registerFallbackValue(FakeGatewaySettings());
  });

  setUp(() {
    mockClient = MockGatewayWebSocketClient();
    mockPing = MockGatewayPingDataSource();
    when(() => mockClient.statusStream).thenAnswer((_) => const Stream.empty());
    when(() => mockClient.retryCountStream).thenAnswer((_) => const Stream.empty());
    when(() => mockClient.connect(any())).thenAnswer((_) async {});
    when(() => mockClient.disconnect()).thenAnswer((_) async {});
    when(() => mockClient.isConnected).thenReturn(false);
    when(() => mockPing.ping(any(), any())).thenAnswer((_) async {});
  });

  group('ConnectionBloc', () {
    blocTest<ConnectionBloc, ConnectionState>(
      'emits [ConnectionLoading, ConnectionError] on ping failure',
      build: () {
        when(() => mockPing.ping(any(), any())).thenThrow(
          const GatewayException('Connection refused', code: 'PING_FAILED_10061'),
        );
        return ConnectionBloc(client: mockClient, ping: mockPing);
      },
      act: (bloc) => bloc.add(const ConnectRequested(GatewaySettings(
        host: '192.168.1.999',
        port: 18789,
        token: 'test',
      ))),
      expect: () => [
        isA<ConnectionLoading>(),
        isA<ConnectionError>().having(
          (e) => e.code,
          'code',
          ConnectionErrorCode.connectionRefused,
        ),
      ],
    );

    blocTest<ConnectionBloc, ConnectionState>(
      'emits ConnectionInitial as initial state',
      build: () => ConnectionBloc(client: mockClient, ping: mockPing),
      expect: () => const [],
      verify: (bloc) => expect(bloc.state, const ConnectionInitial()),
    );

    blocTest<ConnectionBloc, ConnectionState>(
      'emits [ConnectionLoading] on valid settings',
      build: () => ConnectionBloc(client: mockClient, ping: mockPing),
      act: (bloc) => bloc.add(const ConnectRequested(GatewaySettings(
        host: '127.0.0.1',
        port: 18789,
        token: 'test',
      ))),
      expect: () => [
        isA<ConnectionLoading>(),
      ],
    );

    blocTest<ConnectionBloc, ConnectionState>(
      'emits ConnectionInitial on DisconnectRequested',
      build: () => ConnectionBloc(client: mockClient, ping: mockPing),
      act: (bloc) => bloc.add(const DisconnectRequested()),
      expect: () => [isA<ConnectionInitial>()],
    );

    blocTest<ConnectionBloc, ConnectionState>(
      'shows reconnecting banner after grace period when disconnected',
      build: () {
        when(() => mockClient.statusStream).thenAnswer((_) => const Stream.empty());
        when(() => mockClient.retryCountStream).thenAnswer((_) => const Stream.empty());
        when(() => mockClient.isConnected).thenReturn(true);
        return ConnectionBloc(
          client: mockClient,
          ping: mockPing,
          reconnectingBannerDelay: const Duration(milliseconds: 20),
        );
      },
      act: (bloc) async {
        const settings = GatewaySettings(host: '127.0.0.1', port: 18789, token: 'test');
        bloc.add(const ConnectRequested(settings));
        await Future<void>.delayed(const Duration(milliseconds: 5));
        bloc.add(const ConnectionStatusChanged(ConnectionStatus.disconnected));
      },
      wait: const Duration(milliseconds: 60),
      expect: () => [
        isA<ConnectionLoading>(),
        isA<ConnectionConnected>(),
        isA<ConnectionReconnecting>(),
      ],
    );

    blocTest<ConnectionBloc, ConnectionState>(
      'does not show reconnecting banner for brief disconnects',
      build: () {
        when(() => mockClient.statusStream).thenAnswer((_) => const Stream.empty());
        when(() => mockClient.retryCountStream).thenAnswer((_) => const Stream.empty());
        when(() => mockClient.isConnected).thenReturn(true);
        return ConnectionBloc(
          client: mockClient,
          ping: mockPing,
          reconnectingBannerDelay: const Duration(milliseconds: 40),
        );
      },
      act: (bloc) async {
        const settings = GatewaySettings(host: '127.0.0.1', port: 18789, token: 'test');
        bloc.add(const ConnectRequested(settings));
        await Future<void>.delayed(const Duration(milliseconds: 5));
        bloc.add(const ConnectionStatusChanged(ConnectionStatus.disconnected));
        await Future<void>.delayed(const Duration(milliseconds: 10));
        bloc.add(const ConnectionStatusChanged(ConnectionStatus.connected));
      },
      wait: const Duration(milliseconds: 80),
      expect: () => [
        isA<ConnectionLoading>(),
        isA<ConnectionConnected>(),
      ],
    );
  });
}
