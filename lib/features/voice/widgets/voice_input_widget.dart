import 'package:flutter/material.dart';
import 'package:searvo/features/voice/services/voice_service.dart';
import 'dart:async';

/// Reusable voice input widget that can be integrated into various UI components
class VoiceInputWidget extends StatefulWidget {
  final Function(String)? onTextReceived;
  final Function(VoiceInputState)? onStateChanged;
  final Function(String)? onError;
  final Widget? customIcon;
  final Color? activeColor;
  final Color? inactiveColor;
  final double? iconSize;
  final String? locale;
  final Duration? listenDuration;
  final bool showVisualFeedback;
  final bool autoStop;

  const VoiceInputWidget({
    super.key,
    this.onTextReceived,
    this.onStateChanged,
    this.onError,
    this.customIcon,
    this.activeColor,
    this.inactiveColor,
    this.iconSize,
    this.locale,
    this.listenDuration,
    this.showVisualFeedback = true,
    this.autoStop = true,
  });

  @override
  State<VoiceInputWidget> createState() => _VoiceInputWidgetState();
}

class _VoiceInputWidgetState extends State<VoiceInputWidget>
    with TickerProviderStateMixin {
  final VoiceService _voiceService = VoiceService();
  StreamSubscription<String>? _textSubscription;
  StreamSubscription<VoiceInputState>? _stateSubscription;
  
  late AnimationController _pulseController;
  late AnimationController _scaleController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;
  
  VoiceInputState _currentState = VoiceInputState.idle;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeVoiceService();
    _setupStreams();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _initializeVoiceService() async {
    final success = await _voiceService.initialize();
    setState(() {
      _isInitialized = success;
    });
    
    if (!success && _voiceService.errorMessage.isNotEmpty) {
      widget.onError?.call(_voiceService.errorMessage);
    }
  }

  void _setupStreams() {
    _textSubscription = _voiceService.textStream.listen((text) {
      widget.onTextReceived?.call(text);
    });
    
    _stateSubscription = _voiceService.stateStream.listen((state) {
      setState(() {
        _currentState = state;
      });
      
      _handleStateChange(state);
      widget.onStateChanged?.call(state);
    });
  }

  void _handleStateChange(VoiceInputState state) {
    switch (state) {
      case VoiceInputState.listening:
        if (widget.showVisualFeedback) {
          _pulseController.repeat(reverse: true);
        }
        break;
      case VoiceInputState.processing:
        if (widget.showVisualFeedback) {
          _pulseController.stop();
          _scaleController.forward();
        }
        break;
      case VoiceInputState.completed:
      case VoiceInputState.stopped:
      case VoiceInputState.cancelled:
        if (widget.showVisualFeedback) {
          _pulseController.stop();
          _scaleController.reverse();
        }
        break;
      case VoiceInputState.error:
        if (widget.showVisualFeedback) {
          _pulseController.stop();
          _scaleController.reverse();
        }
        if (_voiceService.errorMessage.isNotEmpty) {
          widget.onError?.call(_voiceService.errorMessage);
        }
        break;
      case VoiceInputState.idle:
        if (widget.showVisualFeedback) {
          _pulseController.stop();
          _scaleController.reverse();
        }
        break;
    }
  }

  Future<void> _toggleVoiceInput() async {
    if (!_isInitialized) {
      await _initializeVoiceService();
      if (!_isInitialized) return;
    }

    if (_voiceService.isListening) {
      await _voiceService.stopListening();
    } else {
      await _voiceService.startListening(
        localeId: widget.locale,
        listenFor: widget.listenDuration,
        onResult: widget.onTextReceived,
        onError: widget.onError,
      );
    }
  }

  Color _getIconColor() {
    if (_currentState.isActive) {
      return widget.activeColor ?? const Color(0xFF00B4A6);
    }
    return widget.inactiveColor ?? Colors.white.withOpacity(0.4);
  }

  Widget _buildIcon() {
    if (widget.customIcon != null) {
      return widget.customIcon!;
    }

    IconData iconData;
    switch (_currentState) {
      case VoiceInputState.listening:
        iconData = Icons.mic;
        break;
      case VoiceInputState.processing:
        iconData = Icons.mic_none;
        break;
      case VoiceInputState.error:
        iconData = Icons.mic_off;
        break;
      default:
        iconData = Icons.mic;
    }

    return Icon(
      iconData,
      color: _getIconColor(),
      size: widget.iconSize ?? 20,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleVoiceInput,
      onTapDown: (_) => _scaleController.forward(),
      onTapUp: (_) => _scaleController.reverse(),
      onTapCancel: () => _scaleController.reverse(),
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseAnimation, _scaleAnimation]),
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: widget.showVisualFeedback && _currentState == VoiceInputState.listening
                ? Transform.scale(
                    scale: _pulseAnimation.value,
                    child: _buildIcon(),
                  )
                : _buildIcon(),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _textSubscription?.cancel();
    _stateSubscription?.cancel();
    _pulseController.dispose();
    _scaleController.dispose();
    super.dispose();
  }
}

/// A complete voice input button with visual feedback
class VoiceInputButton extends StatelessWidget {
  final Function(String)? onTextReceived;
  final Function(VoiceInputState)? onStateChanged;
  final Function(String)? onError;
  final String? locale;
  final Duration? listenDuration;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;
  final Color? backgroundColor;
  final EdgeInsets? padding;
  final BorderRadius? borderRadius;

  const VoiceInputButton({
    super.key,
    this.onTextReceived,
    this.onStateChanged,
    this.onError,
    this.locale,
    this.listenDuration,
    this.size = 32,
    this.activeColor,
    this.inactiveColor,
    this.backgroundColor,
    this.padding,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: padding ?? const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: backgroundColor ?? const Color(0xFF00B4A6),
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
      child: VoiceInputWidget(
        onTextReceived: onTextReceived,
        onStateChanged: onStateChanged,
        onError: onError,
        locale: locale,
        listenDuration: listenDuration,
        activeColor: activeColor ?? Colors.white,
        inactiveColor: inactiveColor ?? Colors.white,
        iconSize: size * 0.5,
      ),
    );
  }
}