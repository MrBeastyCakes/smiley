import 'package:equatable/equatable.dart';

class GatewaySettings extends Equatable {
  final String host;
  final int port;
  final String token;
  final String? password;
  final bool useTls;

  const GatewaySettings({
    required this.host, required this.port, required this.token,
    this.password, this.useTls = false,
  });

  GatewaySettings copyWith({String? host, int? port, String? token, String? password, bool? useTls}) => GatewaySettings(
    host: host ?? this.host, port: port ?? this.port, token: token ?? this.token,
    password: password ?? this.password, useTls: useTls ?? this.useTls,
  );

  @override List<Object?> get props => [host, port, token, password, useTls];
}
