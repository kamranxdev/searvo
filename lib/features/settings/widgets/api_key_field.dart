import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:searvo/core/theme/theme.dart';
import 'package:searvo/features/settings/theme/settings_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class ApiKeyField extends StatefulWidget {
  final String label;
  final String placeholder;
  final String description;
  final String value;
  final String obscuredValue;
  final Function(String) onChanged;
  final VoidCallback? onClear;
  final bool showClearButton;

  const ApiKeyField({
    super.key,
    required this.label,
    required this.placeholder,
    required this.description,
    required this.value,
    this.obscuredValue = '',
    required this.onChanged,
    this.onClear,
    this.showClearButton = true,
  });

  @override
  State<ApiKeyField> createState() => _ApiKeyFieldState();
}

class _ApiKeyFieldState extends State<ApiKeyField> {
  late TextEditingController _controller;
  bool _isObscured = true;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _updateControllerValue();
  }

  @override
  void didUpdateWidget(ApiKeyField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value ||
        oldWidget.obscuredValue != widget.obscuredValue) {
      _updateControllerValue();
    }
  }

  void _updateControllerValue() {
    if (!_isEditing) {
      if (widget.value.isNotEmpty &&
          widget.obscuredValue.isNotEmpty &&
          _isObscured) {
        _controller.text = widget.obscuredValue;
      } else {
        _controller.text = widget.value;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildDescription() {
    final settingsColors = SettingsTheme.colors(context);
    final text = widget.description;
    final urlRegex = RegExp(r'https?://[^\s]+');
    final match = urlRegex.firstMatch(text);

    if (match != null) {
      final url = match.group(0)!;
      final before = text.substring(0, match.start);
      final after = text.substring(match.end);

      return RichText(
        text: TextSpan(
          style: TextStyle(
            fontSize: 12,
            color: settingsColors.subtitle.withOpacity(0.6),
          ),
          children: [
            if (before.isNotEmpty) TextSpan(text: before),
            TextSpan(
              text: url,
              style: TextStyle(
                color: settingsColors.accent,
                decoration: TextDecoration.underline,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () async {
                  try {
                    final uri = Uri.parse(url);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    } else {
                      // Fallback for desktop platforms
                      await launchUrl(uri, mode: LaunchMode.platformDefault);
                    }
                  } catch (e) {
                    // If URL launching fails, show a snackbar with the URL
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Unable to open URL. Please visit: $url',
                          ),
                          action: SnackBarAction(
                            label: 'Copy',
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: url));
                            },
                          ),
                        ),
                      );
                    }
                  }
                },
            ),
            if (after.isNotEmpty) TextSpan(text: after),
          ],
        ),
      );
    } else {
      return Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: settingsColors.subtitle.withOpacity(0.6),
        ),
      );
    }
  }

  void _toggleObscured() {
    setState(() {
      _isObscured = !_isObscured;
      _updateControllerValue();
    });
  }

  void _onEditingStarted() {
    setState(() {
      _isEditing = true;
      if (_isObscured && widget.value.isNotEmpty) {
        _controller.text = widget.value;
        _isObscured = false;
      }
    });
  }

  void _onEditingComplete() {
    setState(() {
      _isEditing = false;
    });
    widget.onChanged(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final settingsColors = SettingsTheme.colors(context);
    final hasStoredValue = widget.value.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(widget.label, style: SettingsTheme.inputLabel(context)),
            if (hasStoredValue) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: settingsColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: settingsColors.success.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  'Configured',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: settingsColors.success,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _controller,
          obscureText: _isObscured && !_isEditing,
          onTap: _onEditingStarted,
          onChanged: (value) {
            if (_isEditing) {
              widget.onChanged(value);
            }
          },
          onSubmitted: (_) => _onEditingComplete(),
          decoration: InputDecoration(
            hintText: hasStoredValue
                ? 'API key is configured'
                : widget.placeholder,
            hintStyle: TextStyle(
              color: hasStoredValue
                  ? settingsColors.success
                  : settingsColors.subtitle,
              fontSize: 14,
            ),
            filled: true,
            fillColor: settingsColors.inputBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: hasStoredValue
                    ? settingsColors.success.withValues(alpha: 0.3)
                    : settingsColors.border,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: hasStoredValue
                    ? settingsColors.success.withValues(alpha: 0.3)
                    : settingsColors.border,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: hasStoredValue
                    ? settingsColors.success.withValues(alpha: 0.6)
                    : settingsColors.accent,
                width: 2,
              ),
            ),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasStoredValue && !_isEditing) ...[
                  IconButton(
                    icon: Icon(
                      _isObscured ? Icons.visibility : Icons.visibility_off,
                      size: 18,
                      color: settingsColors.icon,
                    ),
                    onPressed: _toggleObscured,
                    tooltip: _isObscured ? 'Show API key' : 'Hide API key',
                  ),
                ],
                if (hasStoredValue &&
                    widget.showClearButton &&
                    widget.onClear != null) ...[
                  IconButton(
                    icon: Icon(
                      Icons.clear,
                      size: 18,
                      color: settingsColors.error,
                    ),
                    onPressed: () {
                      widget.onClear!();
                      _controller.clear();
                    },
                    tooltip: 'Clear API key',
                  ),
                ],
              ],
            ),
          ),
          style: SettingsTheme.inputText(context),
        ),
        const SizedBox(height: 4),
        _buildDescription(),
      ],
    );
  }
}
