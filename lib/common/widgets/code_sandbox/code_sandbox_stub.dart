import 'package:flutter/material.dart';

import 'code_sandbox_interface.dart';

class CodeSandboxStub implements CodeSandboxImplementation {
  @override
  Widget build(
    BuildContext context,
    String htmlCode,
    String cssCode,
    String jsCode,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.code_off, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Preview not supported on this platform',
            style: TextStyle(
              color: Colors.grey.shade800,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Switch to code view to see source.',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {}
}

CodeSandboxImplementation getImplementation() => CodeSandboxStub();
