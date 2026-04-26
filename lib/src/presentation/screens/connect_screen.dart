import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/di/service_locator.dart';
import '../../core/theme/design_tokens.dart';
import '../../domain/entities/gateway_settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../blocs/connection/connection_bloc.dart';
import '../widgets/widgets.dart';
import 'qr_scan_sheet.dart';

class ConnectScreen extends StatefulWidget {
  const ConnectScreen({super.key});

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  final _hostController = TextEditingController(text: '127.0.0.1');
  final _portController = TextEditingController(text: '18789');
  final _tokenController = TextEditingController();

  bool _isConnecting = false;

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
        child: Padding(
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
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: AurumButton(
                  label: 'Connect',
                  variant: AurumButtonVariant.primary,
                  fullWidth: true,
                  isLoading: _isConnecting,
                  onPressed: _connect,
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
            ],
          ),
        ),
      ),
    );
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

  void _connect() async {
    final settings = GatewaySettings(
      host: _hostController.text,
      port: int.tryParse(_portController.text) ?? 18789,
      token: _tokenController.text,
    );

    setState(() => _isConnecting = true);

    final repo = ServiceLocator.get<SettingsRepository>();
    await repo.saveSettings(settings);

    if (mounted) {
      context.read<ConnectionBloc>().add(ConnectRequested(settings));
      setState(() => _isConnecting = false);
    }
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
