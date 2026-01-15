import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'code_sandbox_interface.dart';

class CodeSandboxMobile implements CodeSandboxImplementation {
  WebViewController? _controller;

  @override
  Widget build(
    BuildContext context,
    String htmlCode,
    String cssCode,
    String jsCode,
  ) {
    _controller ??= WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading bar.
          },
          onPageStarted: (String url) {},
          onPageFinished: (String url) {},
          onWebResourceError: (WebResourceError error) {},
        ),
      );

    final content = _buildFullHtml(htmlCode, cssCode, jsCode);
    _controller!.loadHtmlString(content);

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
        child: WebViewWidget(controller: _controller!),
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

CodeSandboxImplementation getImplementation() => CodeSandboxMobile();
