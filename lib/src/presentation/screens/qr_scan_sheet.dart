import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/theme/design_tokens.dart';
import '../../domain/entities/gateway_settings.dart';

/// Modal bottom sheet for scanning a gateway QR code.
class QRScanSheet extends StatefulWidget {
  final void Function(GatewaySettings settings)? onScanned;

  const QRScanSheet({super.key, this.onScanned});

  @override
  State<QRScanSheet> createState() => _QRScanSheetState();
}

class _QRScanSheetState extends State<QRScanSheet> {
  bool _hasScanned = false;

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    final settings = _parseQR(barcode.rawValue!);
    if (settings != null) {
      setState(() => _hasScanned = true);
      widget.onScanned?.call(settings);
      if (mounted) Navigator.of(context).pop();
    }
  }

  GatewaySettings? _parseQR(String rawValue) {
    try {
      final json = jsonDecode(rawValue) as Map<String, dynamic>;
      final host = json['host'] as String?;
      final port = json['port'] as int?;
      final token = json['token'] as String?;
      if (host == null || port == null || token == null) return null;
      return GatewaySettings(host: host, port: port, token: token);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTokens.forBrightness(Brightness.dark);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: EdgeInsets.only(top: tokens.space4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: tokens.textMuted.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(tokens.radiusPill),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(tokens.space5),
            child: Text(
              'Scan Gateway QR',
              style: tokens.textTheme.titleLarge,
            ),
          ),
          SizedBox(
            height: 300,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(tokens.radiusXl),
              child: MobileScanner(
                onDetect: _onDetect,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(tokens.space4),
            child: Text(
              'Point camera at the QR code shown in your OpenClaw gateway dashboard.',
              style: tokens.textTheme.bodySmall?.copyWith(color: tokens.textMuted),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: tokens.space4),
        ],
      ),
    );
  }
}

/// Parses a gateway QR code JSON string into [GatewaySettings].
/// Returns null if the data is invalid.
GatewaySettings? parseGatewayQR(String rawValue) {
  try {
    final json = jsonDecode(rawValue) as Map<String, dynamic>;
    final host = json['host'] as String?;
    final port = json['port'] as int?;
    final token = json['token'] as String?;
    if (host == null || port == null || token == null) return null;
    return GatewaySettings(host: host, port: port, token: token);
  } catch (_) {
    return null;
  }
}
