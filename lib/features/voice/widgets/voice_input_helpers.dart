import 'package:flutter/material.dart';
import 'package:searvo/features/voice/services/voice_service.dart';
import 'dart:async';
import 'voice_input_widget.dart';

/// A status widget that shows the current voice input state
class VoiceInputStatus extends StatefulWidget {
  final VoiceService? voiceService;
  final EdgeInsets? padding;
  final TextStyle? textStyle;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final Duration? animationDuration;
  final bool showOnlyWhenActive;

  const VoiceInputStatus({
    super.key,
    this.voiceService,
    this.padding,
    this.textStyle,
    this.backgroundColor,
    this.borderRadius,
    this.animationDuration,
    this.showOnlyWhenActive = false,
  });

  @override
  State<VoiceInputStatus> createState() => _VoiceInputStatusState();
}

class _VoiceInputStatusState extends State<VoiceInputStatus>
    with SingleTickerProviderStateMixin {
  late VoiceService _voiceService;
  StreamSubscription<VoiceInputState>? _stateSubscription;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  VoiceInputState _currentState = VoiceInputState.idle;

  @override
  void initState() {
    super.initState();
    _voiceService = widget.voiceService ?? VoiceService();
    _initializeAnimation();
    _setupStateListener();
  }

  void _initializeAnimation() {
    _animationController = AnimationController(
      duration: widget.animationDuration ?? const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  void _setupStateListener() {
    _stateSubscription = _voiceService.stateStream.listen((state) {
      setState(() {
        _currentState = state;
      });
      
      if (_shouldShowStatus(state)) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  bool _shouldShowStatus(VoiceInputState state) {
    if (!widget.showOnlyWhenActive) return true;
    return state.isActive || state == VoiceInputState.error;
  }

  Color _getStatusColor() {
    switch (_currentState) {
      case VoiceInputState.listening:
        return Colors.green;
      case VoiceInputState.processing:
        return Colors.blue;
      case VoiceInputState.error:
        return Colors.red;
      case VoiceInputState.completed:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    switch (_currentState) {
      case VoiceInputState.listening:
        return Icons.mic;
      case VoiceInputState.processing:
        return Icons.hourglass_empty;
      case VoiceInputState.error:
        return Icons.error;
      case VoiceInputState.completed:
        return Icons.check_circle;
      case VoiceInputState.cancelled:
        return Icons.cancel;
      default:
        return Icons.mic_none;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.showOnlyWhenActive && !_shouldShowStatus(_currentState)) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: widget.showOnlyWhenActive ? _fadeAnimation.value : 1.0,
          child: Container(
            padding: widget.padding ?? const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: widget.backgroundColor ?? _getStatusColor().withOpacity(0.1),
              borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
              border: Border.all(
                color: _getStatusColor().withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getStatusIcon(),
                  size: 16,
                  color: _getStatusColor(),
                ),
                const SizedBox(width: 6),
                Text(
                  _currentState.description,
                  style: widget.textStyle ?? TextStyle(
                    color: _getStatusColor(),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _stateSubscription?.cancel();
    _animationController.dispose();
    super.dispose();
  }
}

/// A floating voice input button that can be placed anywhere
class FloatingVoiceButton extends StatelessWidget {
  final Function(String)? onTextReceived;
  final Function(VoiceInputState)? onStateChanged;
  final Function(String)? onError;
  final String? locale;
  final Duration? listenDuration;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;
  final double? elevation;
  final VoidCallback? onPressed;

  const FloatingVoiceButton({
    super.key,
    this.onTextReceived,
    this.onStateChanged,
    this.onError,
    this.locale,
    this.listenDuration,
    this.size = 56,
    this.activeColor,
    this.inactiveColor,
    this.elevation,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: FloatingActionButton(
        onPressed: onPressed,
        elevation: elevation ?? 4,
        backgroundColor: const Color(0xFF00B4A6),
        child: VoiceInputWidget(
          onTextReceived: onTextReceived,
          onStateChanged: onStateChanged,
          onError: onError,
          locale: locale,
          listenDuration: listenDuration,
          activeColor: activeColor ?? Colors.white,
          inactiveColor: inactiveColor ?? Colors.white,
          iconSize: size * 0.4,
        ),
      ),
    );
  }
}

/// A voice input dialog that can be shown as a modal
class VoiceInputDialog extends StatefulWidget {
  final String? locale;
  final Duration? listenDuration;
  final String title;
  final String? subtitle;

  const VoiceInputDialog({
    super.key,
    this.locale,
    this.listenDuration,
    this.title = 'Voice Input',
    this.subtitle,
  });

  @override
  State<VoiceInputDialog> createState() => _VoiceInputDialogState();

  /// Show the voice input dialog
  static Future<String?> show(
    BuildContext context, {
    String? locale,
    Duration? listenDuration,
    String title = 'Voice Input',
    String? subtitle,
  }) async {
    return await showDialog<String>(
      context: context,
      builder: (context) => VoiceInputDialog(
        locale: locale,
        listenDuration: listenDuration,
        title: title,
        subtitle: subtitle,
      ),
    );
  }
}

class _VoiceInputDialogState extends State<VoiceInputDialog> {
  String _recognizedText = '';
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF2A2A2A),
      title: Text(
        widget.title,
        style: const TextStyle(color: Colors.white),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.subtitle != null) ...[
            Text(
              widget.subtitle!,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Voice Input Widget
          VoiceInputButton(
            size: 80,
            onTextReceived: (text) {
              setState(() {
                _recognizedText = text;
                _errorMessage = null;
              });
            },
            onStateChanged: (state) {
              // Auto-close on completion if we have text
              if (state == VoiceInputState.completed && _recognizedText.isNotEmpty) {
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (mounted) {
                    Navigator.of(context).pop(_recognizedText);
                  }
                });
              }
            },
            onError: (error) {
              setState(() {
                _errorMessage = error;
              });
            },
            locale: widget.locale,
            listenDuration: widget.listenDuration,
          ),
          
          const SizedBox(height: 16),
          
          // Status
          VoiceInputStatus(
            showOnlyWhenActive: false,
            backgroundColor: Colors.transparent,
          ),
          
          const SizedBox(height: 16),
          
          // Recognized text
          if (_recognizedText.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF333333),
                  width: 1,
                ),
              ),
              child: Text(
                _recognizedText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Error message
          if (_errorMessage != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.red.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                _errorMessage!,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Cancel',
            style: TextStyle(color: Colors.white54),
          ),
        ),
        if (_recognizedText.isNotEmpty)
          TextButton(
            onPressed: () => Navigator.of(context).pop(_recognizedText),
            child: const Text(
              'Use Text',
              style: TextStyle(color: Color(0xFF00B4A6)),
            ),
          ),
      ],
    );
  }
}