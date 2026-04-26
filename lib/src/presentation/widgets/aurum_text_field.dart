import 'package:flutter/material.dart';
import '../../core/theme/design_tokens.dart';

/// Aurum-styled text field with elevated background and gold focus border.
///
/// Uses [DesignTokens.forBrightness] to adapt to the current theme.
class AurumTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final VoidCallback? onSubmitted;
  final ValueChanged<String>? onChanged;
  final bool autofocus;
  final int? maxLines;
  final FocusNode? focusNode;

  const AurumTextField({
    super.key,
    this.controller,
    this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.onSubmitted,
    this.onChanged,
    this.autofocus = false,
    this.maxLines = 1,
    this.focusNode,
  });

  @override
  State<AurumTextField> createState() => _AurumTextFieldState();
}

class _AurumTextFieldState extends State<AurumTextField> {
  late final FocusNode _focusNode;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() {
      _focused = _focusNode.hasFocus;
    });
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    } else {
      _focusNode.removeListener(_onFocusChange);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTokens.forBrightness(Theme.of(context).brightness);

    return TextField(
      controller: widget.controller,
      focusNode: _focusNode,
      obscureText: widget.obscureText,
      keyboardType: widget.keyboardType,
      autofocus: widget.autofocus,
      maxLines: widget.obscureText ? 1 : widget.maxLines,
      style: tokens.textTheme.bodyMedium?.copyWith(color: tokens.textPrimary),
      onSubmitted: widget.onSubmitted != null
          ? (_) => widget.onSubmitted!()
          : null,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        filled: true,
        fillColor: tokens.bgElevated,
        hintText: widget.hint,
        hintStyle: tokens.textTheme.bodyMedium?.copyWith(color: tokens.textMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.radiusMd),
          borderSide: BorderSide(
            color: tokens.textMuted.withValues(alpha: 0.2),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.radiusMd),
          borderSide: BorderSide(
            color: tokens.textMuted.withValues(alpha: 0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.radiusMd),
          borderSide: BorderSide(
            color: tokens.accentGold,
            width: 1.5,
          ),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: tokens.space4,
          vertical: tokens.space3,
        ),
      ),
    );
  }
}
