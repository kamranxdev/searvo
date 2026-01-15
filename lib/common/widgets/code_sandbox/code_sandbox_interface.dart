import 'package:flutter/material.dart';

abstract class CodeSandboxImplementation {
  Widget build(
    BuildContext context,
    String htmlCode,
    String cssCode,
    String jsCode,
  );
  void dispose() {}
}
