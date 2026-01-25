import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Service for handling voice input and text-to-speech functionality across the app
class VoiceService extends ChangeNotifier {
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  VoiceService._internal();

  final SpeechToText _speech = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();

  // Voice input state
  bool _isInitialized = false;
  bool _isListening = false;
  bool _isAvailable = false;
  String _recognizedText = '';
  String _errorMessage = '';
  double _confidenceLevel = 0.0;

  // Text-to-Speech state
  bool _isTtsInitialized = false;
  bool _isSpeaking = false;
  double _ttsVolume = 1.0;
  double _ttsPitch = 1.0;
  double _ttsRate = 1.75;

  // Stream controllers for real-time updates
  final StreamController<String> _textStreamController =
      StreamController<String>.broadcast();
  final StreamController<VoiceInputState> _stateStreamController =
      StreamController<VoiceInputState>.broadcast();

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isListening => _isListening;
  bool get isAvailable => _isAvailable;
  String get recognizedText => _recognizedText;
  String get errorMessage => _errorMessage;
  double get confidenceLevel => _confidenceLevel;

  // TTS Getters
  bool get isTtsInitialized => _isTtsInitialized;
  bool get isSpeaking => _isSpeaking;
  double get ttsVolume => _ttsVolume;
  double get ttsPitch => _ttsPitch;
  double get ttsRate => _ttsRate;

  // Streams
  Stream<String> get textStream => _textStreamController.stream;
  Stream<VoiceInputState> get stateStream => _stateStreamController.stream;

  /// Check if permission handler is available (handles MissingPluginException)
  Future<bool> _isPermissionHandlerAvailable() async {
    try {
      await Permission.microphone.status;
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('VoiceService: Permission handler not available: $e');
      }
      return false;
    }
  }

  /// Check permissions for microphone access
  /// Returns true if permission is granted or unknown (fallback)
  Future<bool> checkMicrophonePermission() async {
    if (await _isPermissionHandlerAvailable()) {
      try {
        final status = await Permission.microphone.status;
        return status == PermissionStatus.granted;
      } catch (e) {
        if (kDebugMode) {
          print('VoiceService: Error checking permission: $e');
        }
        return true; // Fallback to assuming permission is available
      }
    } else {
      if (kDebugMode) {
        print(
          'VoiceService: Permission handler not available, assuming permission granted',
        );
      }
      return true; // Fallback when permission handler is not available
    }
  }

  /// Request microphone permission
  /// Returns true if permission is granted or plugin is not available
  Future<bool> requestMicrophonePermission() async {
    if (await _isPermissionHandlerAvailable()) {
      try {
        final status = await Permission.microphone.request();
        return status == PermissionStatus.granted;
      } catch (e) {
        if (kDebugMode) {
          print('VoiceService: Error requesting permission: $e');
        }
        return true; // Fallback to assuming permission is available
      }
    } else {
      if (kDebugMode) {
        print(
          'VoiceService: Permission handler not available, assuming permission granted',
        );
      }
      return true; // Fallback when permission handler is not available
    }
  }

  /// Initialize the voice service
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    // Speech recognition is strictly mobile/web for now with this package
    if (!kIsWeb && !(Platform.isAndroid || Platform.isIOS)) {
      _setError('Speech recognition not supported on this platform');
      return false;
    }

    try {
      if (kDebugMode) {
        print('VoiceService: Starting initialization...');
      }

      // Try to check permissions, but handle missing plugin gracefully
      bool permissionGranted = false;

      if (await _isPermissionHandlerAvailable()) {
        try {
          final currentStatus = await Permission.microphone.status;
          if (kDebugMode) {
            print(
              'VoiceService: Current microphone permission status: $currentStatus',
            );
          }

          if (currentStatus == PermissionStatus.granted) {
            permissionGranted = true;
          } else if (currentStatus == PermissionStatus.permanentlyDenied) {
            _setError(
              'Microphone permission permanently denied. Please enable it in device settings.',
            );
            return false;
          } else if (currentStatus == PermissionStatus.restricted) {
            _setError('Microphone access restricted on this device.');
            return false;
          } else {
            // Request permission
            final permissionStatus = await Permission.microphone.request();
            if (kDebugMode) {
              print(
                'VoiceService: Permission request result: $permissionStatus',
              );
            }
            permissionGranted = (permissionStatus == PermissionStatus.granted);
          }
        } catch (e) {
          if (kDebugMode) {
            print('VoiceService: Permission check failed: $e');
          }
          // Continue anyway - speech recognition might handle permissions internally
          permissionGranted = true;
        }
      } else {
        if (kDebugMode) {
          print(
            'VoiceService: Permission handler not available, relying on speech recognition for permissions',
          );
        }
        // Permission handler plugin not available - let speech recognition handle it
        permissionGranted = true;
      }

      if (!permissionGranted) {
        _setError(
          'Microphone permission not granted. Please grant microphone access in device settings.',
        );
        return false;
      }

      if (kDebugMode) {
        print(
          'VoiceService: Permission checks passed, initializing speech recognition...',
        );
      }

      // Initialize speech recognition
      _isAvailable = await _speech.initialize(
        onError: _onError,
        onStatus: _onStatus,
        debugLogging: kDebugMode,
      );

      if (kDebugMode) {
        print('VoiceService: Speech recognition available: $_isAvailable');
      }

      if (_isAvailable) {
        _isInitialized = true;
        _clearError();

        // Get available locales for debugging
        if (kDebugMode) {
          try {
            final locales = await _speech.locales();
            print('VoiceService: Available locales: ${locales.length}');
            if (locales.isNotEmpty) {
              print(
                'VoiceService: System locale: ${await _speech.systemLocale()}',
              );
            }
          } catch (e) {
            print('VoiceService: Error getting locales: $e');
          }
        }

        notifyListeners();
        return true;
      } else {
        _setError(
          'Speech recognition not available on this device. Please check if your device supports speech-to-text.',
        );
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('VoiceService: Exception during initialization: $e');
      }
      _setError('Failed to initialize voice service: $e');
      return false;
    }
  }

  /// Start listening for voice input
  Future<void> startListening({
    String? localeId,
    Duration? listenFor,
    Duration? pauseFor,
    bool partialResults = true,
    Function(String)? onResult,
    Function(String)? onError,
  }) async {
    if (kDebugMode) {
      print('VoiceService: startListening called');
    }

    if (!_isInitialized || !_isAvailable) {
      if (kDebugMode) {
        print(
          'VoiceService: Not initialized or available, attempting to initialize...',
        );
      }
      final success = await initialize();
      if (!success) {
        final errorMsg =
            'Cannot start listening: ${_errorMessage.isNotEmpty ? _errorMessage : 'Initialization failed'}';
        onError?.call(errorMsg);
        return;
      }
    }

    if (!_isAvailable) {
      const errorMsg = 'Speech recognition is not available on this device';
      onError?.call(errorMsg);
      return;
    }

    if (_isListening) {
      if (kDebugMode) {
        print('VoiceService: Already listening, ignoring request');
      }
      return;
    }

    try {
      if (kDebugMode) {
        print('VoiceService: Starting to listen with locale: $localeId');
      }

      await _speech.listen(
        onResult: (result) => _onSpeechResult(result, onResult),
        localeId: localeId,
        listenFor: listenFor ?? const Duration(seconds: 30),
        pauseFor: pauseFor ?? const Duration(seconds: 3),
        partialResults: partialResults,
        cancelOnError: true,
        listenMode: ListenMode.confirmation,
      );

      _isListening = true;
      _clearError();
      _emitState(VoiceInputState.listening);
      notifyListeners();

      if (kDebugMode) {
        print('VoiceService: Successfully started listening');
      }
    } catch (e) {
      final errorMsg = 'Failed to start listening: $e';
      if (kDebugMode) {
        print('VoiceService: $errorMsg');
      }
      _setError(errorMsg);
      onError?.call(errorMsg);
    }
  }

  /// Stop listening for voice input
  Future<void> stopListening() async {
    if (!_isListening) return;

    try {
      await _speech.stop();
      _isListening = false;
      _emitState(VoiceInputState.stopped);
      notifyListeners();
    } catch (e) {
      _setError('Failed to stop listening: $e');
    }
  }

  /// Cancel current listening session
  Future<void> cancelListening() async {
    if (!_isListening) return;

    try {
      await _speech.cancel();
      _isListening = false;
      _recognizedText = '';
      _emitState(VoiceInputState.cancelled);
      notifyListeners();
    } catch (e) {
      _setError('Failed to cancel listening: $e');
    }
  }

  /// Get available locales for speech recognition
  Future<List<LocaleName>> getLocales() async {
    if (!_isInitialized || !_isAvailable) {
      await initialize();
    }

    if (_isAvailable) {
      return await _speech.locales();
    }
    return [];
  }

  /// Check if microphone permission is granted
  Future<bool> checkPermission() async {
    final status = await Permission.microphone.status;
    return status == PermissionStatus.granted;
  }

  /// Request microphone permission
  Future<bool> requestPermission() async {
    final status = await Permission.microphone.request();
    return status == PermissionStatus.granted;
  }

  /// Get system locale for speech recognition
  Future<String?> getSystemLocale() async {
    if (!_isInitialized || !_isAvailable) {
      await initialize();
    }

    if (_isAvailable) {
      final locale = await _speech.systemLocale();
      return locale?.localeId;
    }
    return null;
  }

  /// Comprehensive diagnostics for troubleshooting voice input issues
  Future<Map<String, dynamic>> runDiagnostics() async {
    final diagnostics = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'isInitialized': _isInitialized,
      'isAvailable': _isAvailable,
      'isListening': _isListening,
      'lastError': _errorMessage,
    };

    try {
      // Check permission status
      final permissionStatus = await Permission.microphone.status;
      diagnostics['permissionStatus'] = permissionStatus.toString();
      diagnostics['permissionGranted'] =
          permissionStatus == PermissionStatus.granted;

      // Check if we can request permission
      final canRequestPermission =
          permissionStatus == PermissionStatus.denied ||
          permissionStatus.toString() == 'PermissionStatus.undetermined';
      diagnostics['canRequestPermission'] = canRequestPermission;

      // Try to initialize if not already done
      if (!_isInitialized) {
        diagnostics['initializationAttempted'] = true;
        final success = await initialize();
        diagnostics['initializationSuccess'] = success;
      } else {
        diagnostics['initializationAttempted'] = false;
        diagnostics['initializationSuccess'] = true;
      }

      // Get speech recognition status
      diagnostics['speechRecognitionAvailable'] = await _speech.hasPermission;

      // Get available locales
      if (_isAvailable) {
        try {
          final locales = await getLocales();
          diagnostics['availableLocales'] = locales.length;
          diagnostics['localesList'] = locales
              .map((l) => '${l.name} (${l.localeId})')
              .toList();

          final systemLocale = await getSystemLocale();
          diagnostics['systemLocale'] = systemLocale;
        } catch (e) {
          diagnostics['localeError'] = e.toString();
        }
      }

      // Platform information
      if (kIsWeb) {
        diagnostics['platform'] = 'web';
      } else if (Platform.isAndroid) {
        diagnostics['platform'] = 'android';
      } else if (Platform.isIOS) {
        diagnostics['platform'] = 'ios';
      } else {
        diagnostics['platform'] = 'other';
      }
    } catch (e) {
      diagnostics['diagnosticsError'] = e.toString();
    }

    return diagnostics;
  }

  /// Print detailed diagnostics to console (debug mode only)
  Future<void> printDiagnostics() async {
    if (!kDebugMode) return;

    final diagnostics = await runDiagnostics();
    print('\n=== VoiceService Diagnostics ===');
    diagnostics.forEach((key, value) {
      print('$key: $value');
    });
    print('=== End Diagnostics ===\n');
  }

  // Private methods
  void _onSpeechResult(
    SpeechRecognitionResult result,
    Function(String)? onResult,
  ) {
    _recognizedText = result.recognizedWords;
    _confidenceLevel = result.confidence;

    // Emit to stream
    _textStreamController.add(_recognizedText);

    // Call callback if provided
    onResult?.call(_recognizedText);

    if (result.finalResult) {
      _emitState(VoiceInputState.completed);
    } else {
      _emitState(VoiceInputState.processing);
    }

    notifyListeners();
  }

  void _onError(SpeechRecognitionError error) {
    _setError('Speech recognition error: ${error.errorMsg}');
    _isListening = false;
    _emitState(VoiceInputState.error);
    notifyListeners();
  }

  void _onStatus(String status) {
    switch (status) {
      case 'listening':
        _emitState(VoiceInputState.listening);
        break;
      case 'notListening':
        _isListening = false;
        _emitState(VoiceInputState.stopped);
        break;
      case 'done':
        _isListening = false;
        _emitState(VoiceInputState.completed);
        break;
    }
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    if (kDebugMode) {
      print('VoiceService Error: $message');
    }
  }

  void _clearError() {
    _errorMessage = '';
  }

  void _emitState(VoiceInputState state) {
    _stateStreamController.add(state);
  }

  // ============================================================================
  // TEXT-TO-SPEECH METHODS
  // ============================================================================

  /// Initialize Text-to-Speech
  Future<bool> initializeTts() async {
    if (_isTtsInitialized) return true;

    try {
      if (kDebugMode) {
        print('VoiceService: Initializing TTS...');
      }

      // Configure TTS
      await _flutterTts.setVolume(_ttsVolume);
      await _flutterTts.setSpeechRate(_ttsRate);
      await _flutterTts.setPitch(_ttsPitch);

      // Set language to English (US) for natural voice
      // Set language to English (US) for natural voice
      if (kIsWeb) {
        await _flutterTts.setLanguage("en-US");
      } else if (Platform.isIOS) {
        await _flutterTts.setLanguage("en-US");
        await _flutterTts.setVoice({"name": "Alex", "locale": "en-US"});
      } else if (Platform.isAndroid) {
        await _flutterTts.setLanguage("en-US");
        // Android uses system TTS engine, quality depends on installed voices
      } else if (Platform.isLinux) {
        await _flutterTts.setLanguage("en-US");
      }

      // Set up handlers
      _flutterTts.setStartHandler(() {
        _isSpeaking = true;
        notifyListeners();
        if (kDebugMode) {
          print('VoiceService: TTS started speaking');
        }
      });

      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
        notifyListeners();
        if (kDebugMode) {
          print('VoiceService: TTS completed');
        }
      });

      _flutterTts.setErrorHandler((msg) {
        _isSpeaking = false;
        notifyListeners();
        if (kDebugMode) {
          print('VoiceService: TTS error: $msg');
        }
      });

      _flutterTts.setCancelHandler(() {
        _isSpeaking = false;
        notifyListeners();
        if (kDebugMode) {
          print('VoiceService: TTS cancelled');
        }
      });

      _isTtsInitialized = true;

      if (kDebugMode) {
        print('VoiceService: TTS initialized successfully');
        // List available voices
        final voices = await _flutterTts.getVoices;
        print('VoiceService: Available voices: $voices');
      }

      notifyListeners();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('VoiceService: Failed to initialize TTS: $e');
      }
      return false;
    }
  }

  /// Speak the given text
  Future<void> speak(String text) async {
    if (!_isTtsInitialized) {
      final success = await initializeTts();
      if (!success) {
        if (kDebugMode) {
          print('VoiceService: Cannot speak - TTS initialization failed');
        }
        return;
      }
    }

    if (_isSpeaking) {
      // Stop current speech before starting new one
      await stop();
    }

    try {
      if (kDebugMode) {
        print('VoiceService: Speaking text (${text.length} chars)');
      }
      await _flutterTts.speak(text);
    } catch (e) {
      if (kDebugMode) {
        print('VoiceService: Error speaking: $e');
      }
    }
  }

  /// Stop speaking
  Future<void> stop() async {
    if (_isSpeaking) {
      try {
        await _flutterTts.stop();
        _isSpeaking = false;
        notifyListeners();
      } catch (e) {
        if (kDebugMode) {
          print('VoiceService: Error stopping TTS: $e');
        }
      }
    }
  }

  /// Pause speaking (if supported by platform)
  Future<void> pause() async {
    if (_isSpeaking) {
      try {
        await _flutterTts.pause();
      } catch (e) {
        if (kDebugMode) {
          print('VoiceService: Error pausing TTS: $e');
        }
      }
    }
  }

  /// Set TTS volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    _ttsVolume = volume.clamp(0.0, 1.0);
    if (_isTtsInitialized) {
      await _flutterTts.setVolume(_ttsVolume);
    }
    notifyListeners();
  }

  /// Set TTS speech rate (0.0 to 1.0, default 0.5)
  Future<void> setSpeechRate(double rate) async {
    _ttsRate = rate.clamp(0.0, 1.0);
    if (_isTtsInitialized) {
      await _flutterTts.setSpeechRate(_ttsRate);
    }
    notifyListeners();
  }

  /// Set TTS pitch (0.5 to 2.0, default 1.0)
  Future<void> setPitch(double pitch) async {
    _ttsPitch = pitch.clamp(0.5, 2.0);
    if (_isTtsInitialized) {
      await _flutterTts.setPitch(_ttsPitch);
    }
    notifyListeners();
  }

  /// Get available voices
  Future<List<dynamic>> getAvailableVoices() async {
    if (!_isTtsInitialized) {
      await initializeTts();
    }
    try {
      return await _flutterTts.getVoices;
    } catch (e) {
      if (kDebugMode) {
        print('VoiceService: Error getting voices: $e');
      }
      return [];
    }
  }

  /// Set voice by name (platform specific)
  Future<void> setVoice(Map<String, String> voice) async {
    if (!_isTtsInitialized) {
      await initializeTts();
    }
    try {
      await _flutterTts.setVoice(voice);
    } catch (e) {
      if (kDebugMode) {
        print('VoiceService: Error setting voice: $e');
      }
    }
  }

  // ============================================================================

  /// Clean up resources
  @override
  void dispose() {
    _flutterTts.stop();
    _textStreamController.close();
    _stateStreamController.close();
    super.dispose();
  }
}

/// Enum representing different voice input states
enum VoiceInputState {
  idle,
  listening,
  processing,
  completed,
  stopped,
  cancelled,
  error,
}

/// Extension to get human-readable state descriptions
extension VoiceInputStateExtension on VoiceInputState {
  String get description {
    switch (this) {
      case VoiceInputState.idle:
        return 'Ready to listen';
      case VoiceInputState.listening:
        return 'Listening...';
      case VoiceInputState.processing:
        return 'Processing...';
      case VoiceInputState.completed:
        return 'Voice input completed';
      case VoiceInputState.stopped:
        return 'Stopped listening';
      case VoiceInputState.cancelled:
        return 'Voice input cancelled';
      case VoiceInputState.error:
        return 'Voice input error';
    }
  }

  bool get isActive {
    return this == VoiceInputState.listening ||
        this == VoiceInputState.processing;
  }
}
