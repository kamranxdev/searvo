import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlighter/flutter_highlighter.dart';
import 'package:flutter_highlighter/themes/atom-one-dark.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:searvo/features/search/theme/search_theme.dart';
import 'package:searvo/common/widgets/code_sandbox.dart';

class CodeBlockView extends StatefulWidget {
  final String code;
  final String language;

  const CodeBlockView({super.key, required this.code, required this.language});

  @override
  State<CodeBlockView> createState() => _CodeBlockViewState();
}

class _CodeBlockViewState extends State<CodeBlockView> {
  bool _showPreview = false;

  bool get _canPreview {
    final lang = widget.language.toLowerCase();
    return lang == 'html' || lang == 'htm';
    // We could extend this to support combinations if we parse multiple blocks
    // But for a single block, usually just HTML is standalone previewable if it contains styles/scripts
  }

  Future<void> _copyToClipboard(SearchColors colors) async {
    await Clipboard.setData(ClipboardData(text: widget.code));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Code copied to clipboard'),
          backgroundColor: colors.surfaceContainerHighest,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          width: 200,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = SearchTheme.colors(context);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF282C34), // Atom One Dark bg
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outline.withOpacity(0.3)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white.withOpacity(0.05),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.language.isEmpty ? 'text' : widget.language,
                  style: GoogleFonts.jetBrainsMono(
                    color: Colors.grey[400],
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    if (_canPreview) ...[
                      _HeaderButton(
                        icon: _showPreview ? Icons.code : Icons.preview,
                        label: _showPreview ? 'Code' : 'Preview',
                        onTap: () =>
                            setState(() => _showPreview = !_showPreview),
                      ),
                      const SizedBox(width: 12),
                    ],
                    _HeaderButton(
                      icon: Icons.copy_rounded,
                      label: 'Copy',
                      onTap: () => _copyToClipboard(colors),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (_showPreview)
            CodeSandbox(htmlCode: widget.code)
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: HighlightView(
                widget.code,
                language: widget.language.isEmpty
                    ? 'plaintext'
                    : widget.language,
                theme: atomOneDarkTheme,
                padding: EdgeInsets.zero,
                textStyle: GoogleFonts.jetBrainsMono(fontSize: 13, height: 1.5),
              ),
            ),
        ],
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _HeaderButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.grey[400]),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
