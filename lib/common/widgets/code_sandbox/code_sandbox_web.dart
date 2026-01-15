// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'code_sandbox_interface.dart';

class CodeSandboxWeb implements CodeSandboxImplementation {
  String? _viewId;

  @override
  Widget build(
    BuildContext context,
    String htmlCode,
    String cssCode,
    String jsCode,
  ) {
    _viewId ??= 'code-sandbox-${DateTime.now().millisecondsSinceEpoch}';
    final content = _buildFullHtml(htmlCode, cssCode, jsCode);

    // ignore: avoid_web_libraries_in_flutter
    ui_web.platformViewRegistry.registerViewFactory(_viewId!, (int viewId) {
      final iframe = html.IFrameElement()
        ..style.border = 'none'
        ..style.height = '100%'
        ..style.width = '100%'
        ..srcdoc = content;
      return iframe;
    });

    return Container(
      height: 400,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: HtmlElementView(viewType: _viewId!),
      ),
    );
  }

  String _buildFullHtml(String htmlCode, String cssCode, String jsCode) {
    return '''
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
          body { margin: 0; padding: 16px; font-family: sans-serif; }
          $cssCode
        </style>
      </head>
      <body>
        $htmlCode
        <script>
          $jsCode
        </script>
      </body>
      </html>
    ''';
  }

  @override
  void dispose() {}
}

CodeSandboxImplementation getImplementation() => CodeSandboxWeb();
