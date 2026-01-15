import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'code_sandbox/code_sandbox_interface.dart';
import 'code_sandbox/code_sandbox_stub.dart'
    if (dart.library.js_interop) 'code_sandbox/code_sandbox_web.dart';

// We can't easily conditionally import based on mobile vs desktop in Dart
// So we'll use runtime checks for non-web platforms.
// Ideally we would have a 'code_sandbox_io.dart' that does this check to avoid importing webview_flutter on desktop if it was problematic,
// but webview_flutter support for desktop is just missing, not necessarily crashing if imported but not used?
// Actually, importing webview_flutter on desktop might be fine as long as we don't try to use it if it's not supported.
// However, to be safe and clean, let's create a `code_sandbox_io.dart` that handles the mobile vs desktop check.

import 'code_sandbox/code_sandbox_mobile.dart' as mobile;
import 'code_sandbox/code_sandbox_stub.dart' as stub;

class CodeSandbox extends StatefulWidget {
  final String htmlCode;
  final String cssCode;
  final String jsCode;

  const CodeSandbox({
    super.key,
    required this.htmlCode,
    this.cssCode = '',
    this.jsCode = '',
  });

  @override
  State<CodeSandbox> createState() => _CodeSandboxState();
}

class _CodeSandboxState extends State<CodeSandbox> {
  late CodeSandboxImplementation _implementation;

  @override
  void initState() {
    super.initState();
    _implementation = _getImplementation();
  }

  CodeSandboxImplementation _getImplementation() {
    if (kIsWeb) {
      // access the substituted implementation from conditional import
      return getImplementation();
    } else if (Platform.isAndroid || Platform.isIOS) {
      return mobile.CodeSandboxMobile();
    } else {
      return stub.CodeSandboxStub();
    }
  }

  @override
  void dispose() {
    _implementation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _implementation.build(
      context,
      widget.htmlCode,
      widget.cssCode,
      widget.jsCode,
    );
  }
}
