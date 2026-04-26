import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openclaw_client/src/domain/entities/gateway_settings.dart';
import 'package:openclaw_client/src/presentation/blocs/connection/connection_bloc.dart';

void main() {
  group('ConnectionBloc', () {
    const settings = GatewaySettings(host: '127.0.0.1', port: 18789, token: 'test');

    blocTest<ConnectionBloc, ConnectionState>(
      'emits [ConnectionLoading, ConnectionConnected] on ConnectRequested',
      build: ConnectionBloc.new,
      act: (bloc) => bloc.add(const ConnectRequested(settings)),
      expect: () => [
        isA<ConnectionLoading>(),
        isA<ConnectionConnected>().having((s) => (s as ConnectionConnected).settings, 'settings', settings),
      ],
    );

    blocTest<ConnectionBloc, ConnectionState>(
      'emits [ConnectionInitial] on DisconnectRequested',
      build: ConnectionBloc.new,
      seed: () => const ConnectionConnected(settings: settings),
      act: (bloc) => bloc.add(const DisconnectRequested()),
      expect: () => [isA<ConnectionInitial>()],
    );

    test('initial state is ConnectionInitial', () {
      final bloc = ConnectionBloc();
      expect(bloc.state, isA<ConnectionInitial>());
      bloc.close();
    });
  });
}
