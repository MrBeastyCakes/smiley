import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/service_locator.dart';
import '../../core/theme/design_tokens.dart';
import '../../domain/entities/gateway_settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../blocs/connection/connection_bloc.dart' as conn;
import '../widgets/widgets.dart';
import 'qr_scan_sheet.dart';

class ConnectScreen extends StatefulWidget {
  const ConnectScreen({super.key});

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  final _hostController = TextEditingController(text: '192.168.92.79');
  final _portController = TextEditingController(text: '18789');
  final _tokenController = TextEditingController(text: 'F6fTiO8Lugn5');

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTokens.forBrightness(Brightness.dark);

    return Scaffold(
      backgroundColor: tokens.bgDeep,
      body: SafeArea(
        child: BlocListener<conn.ConnectionBloc, conn.ConnectionState>(
          listener: _onStateChange,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(tokens.space5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: tokens.space6),
                Text('OpenClaw', style: tokens.textTheme.displayMedium?.copyWith(color: tokens.accentGold)),
                SizedBox(height: tokens.space2),
                Text('Connect to your gateway', style: tokens.textTheme.bodyLarge?.copyWith(color: tokens.textSecondary)),
                SizedBox(height: tokens.space6),
                _buildField('Host', _hostController, tokens),
                SizedBox(height: tokens.space4),
                _buildField('Port', _portController, tokens, keyboardType: TextInputType.number),
                SizedBox(height: tokens.space4),
                _buildField('Token', _tokenController, tokens, obscure: true),
                SizedBox(height: tokens.space4),
                _ErrorBanner(),
                SizedBox(height: tokens.space6),
                SizedBox(
                  width: double.infinity,
                  child: BlocBuilder<conn.ConnectionBloc, conn.ConnectionState>(
                    builder: (context, state) {
                      final isLoading = state is conn.ConnectionLoading;
                      return AurumButton(
                        label: isLoading ? 'Connecting…' : 'Connect',
                        variant: AurumButtonVariant.primary,
                        fullWidth: true,
                        isLoading: isLoading,
                        onPressed: isLoading ? null : _connect,
                      );
                    },
                  ),
                ),
                SizedBox(height: tokens.space3),
                SizedBox(
                  width: double.infinity,
                  child: AurumButton(
                    label: 'Scan QR Code',
                    variant: AurumButtonVariant.secondary,
                    fullWidth: true,
                    icon: Icons.qr_code_scanner,
                    onPressed: _scanQR,
                  ),
                ),
                SizedBox(height: tokens.space4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onStateChange(BuildContext context, conn.ConnectionState state) {
    if (state is conn.ConnectionConnected) {
      context.pushReplacement('/home');
    }
  }

  Widget _buildField(String label, TextEditingController controller, DesignTokens tokens, {bool obscure = false, TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: tokens.textTheme.labelMedium?.copyWith(color: tokens.textSecondary)),
        SizedBox(height: tokens.space2),
        AurumTextField(
          controller: controller,
          hint: label,
          obscureText: obscure,
          keyboardType: keyboardType,
          onSubmitted: _connect,
        ),
      ],
    );
  }

  void _connect() {
    final settings = GatewaySettings(
      host: _hostController.text,
      port: int.tryParse(_portController.text) ?? 18789,
      token: _tokenController.text,
    );

    final repo = ServiceLocator.get<SettingsRepository>();
    repo.saveSettings(settings);

    context.read<conn.ConnectionBloc>().add(conn.ConnectRequested(settings));
  }

  void _scanQR() {
    final tokens = DesignTokens.forBrightness(Brightness.dark);
    showModalBottomSheet(
      context: context,
      backgroundColor: tokens.bgSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(tokens.radiusXl)),
      ),
      builder: (_) => QRScanSheet(
        onScanned: (settings) {
          _hostController.text = settings.host;
          _portController.text = settings.port.toString();
          _tokenController.text = settings.token;
          _connect();
        },
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<conn.ConnectionBloc, conn.ConnectionState>(
      builder: (context, state) {
        if (state is conn.ConnectionError) {
          return Padding(
            padding: const EdgeInsets.only(top: 8),
            child: AurumErrorBanner(
              message: state.message,
              onDismiss: () {
                context.read<conn.ConnectionBloc>().add(const conn.DisconnectRequested());
              },
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
