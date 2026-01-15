import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:searvo/core/theme/theme.dart';
import 'package:searvo/features/onboarding/models/setup_models.dart';
import 'package:url_launcher/url_launcher.dart';

/// API Key Entry Step - Third page of the setup wizard
/// Allows users to enter their API key or configuration
/// Responsive design with side-by-side layout on desktop
class ApiKeyStep extends StatefulWidget {
  final AIProviderOption? provider;
  final TextEditingController controller;
  final bool isLoading;
  final String? errorMessage;
  final Function(String) onSave;
  final VoidCallback onBack;
  final VoidCallback onSkip;
  final bool isDesktop;
  final bool isTablet;

  const ApiKeyStep({
    super.key,
    this.provider,
    required this.controller,
    this.isLoading = false,
    this.errorMessage,
    required this.onSave,
    required this.onBack,
    required this.onSkip,
    this.isDesktop = false,
    this.isTablet = false,
  });

  @override
  State<ApiKeyStep> createState() => _ApiKeyStepState();
}

class _ApiKeyStepState extends State<ApiKeyStep>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isObscured = true;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _launchGetKeyUrl() async {
    final url = widget.provider?.getKeyUrl;
    if (url != null) {
      try {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } catch (e) {
        debugPrint('Failed to launch URL: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;
    final provider = widget.provider;

    if (provider == null) {
      return const Center(child: Text('No provider selected'));
    }

    final isUrlInput = provider.requiresBaseUrl;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          // Scrollable content
          Expanded(
            child: widget.isDesktop 
                ? _buildDesktopLayout(context, colorScheme, textTheme, provider, isUrlInput)
                : _buildMobileTabletLayout(context, colorScheme, textTheme, provider, isUrlInput),
          ),

          // Bottom actions
          _buildBottomActions(colorScheme),
        ],
      ),
    );
  }
  
  Widget _buildDesktopLayout(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
    AIProviderOption provider,
    bool isUrlInput,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 32),

          // Header
          _buildHeader(colorScheme, textTheme, provider, isUrlInput, isDesktop: true),

          const SizedBox(height: 40),

          // Content in constrained width
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Input field
                _buildInputField(colorScheme, provider, isUrlInput, isDesktop: true),

                // Error message
                if (widget.errorMessage != null) ...[
                  const SizedBox(height: 8),
                  _buildErrorMessage(colorScheme),
                ],

                const SizedBox(height: 16),

                // Helper text
                if (provider.apiKeyHint != null)
                  Text(
                    provider.apiKeyHint!,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                    ),
                  ),

                // Get key link
                if (provider.getKeyUrl != null) ...[
                  const SizedBox(height: 20),
                  _buildGetKeyLink(colorScheme, provider, isDesktop: true),
                ],

                const SizedBox(height: 24),

                // Info card for Ollama
                if (provider.id == 'ollama') _buildOllamaInfoCard(colorScheme, isDesktop: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMobileTabletLayout(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
    AIProviderOption provider,
    bool isUrlInput,
  ) {
    final horizontalPadding = widget.isTablet ? 40.0 : 32.w;
    
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding.toDouble()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: widget.isTablet ? 24.0 : 16.h),

          // Header
          _buildHeader(colorScheme, textTheme, provider, isUrlInput, isDesktop: false),

          SizedBox(height: widget.isTablet ? 36.0 : 32.h),

          // Input field
          _buildInputField(colorScheme, provider, isUrlInput, isDesktop: false),

          // Error message
          if (widget.errorMessage != null) ...[
            SizedBox(height: 8.h),
            _buildErrorMessage(colorScheme),
          ],

          SizedBox(height: 16.h),

          // Helper text
          if (provider.apiKeyHint != null)
            Text(
              provider.apiKeyHint!,
              style: TextStyle(
                fontSize: 13.sp,
                color: colorScheme.onSurfaceVariant.withOpacity(0.7),
              ),
            ),

          // Get key link
          if (provider.getKeyUrl != null) ...[
            SizedBox(height: 16.h),
            _buildGetKeyLink(colorScheme, provider, isDesktop: false),
          ],

          SizedBox(height: 24.h),

          // Info card for Ollama
          if (provider.id == 'ollama') _buildOllamaInfoCard(colorScheme, isDesktop: false),
        ],
      ),
    );
  }
  
  Widget _buildHeader(
    ColorScheme colorScheme,
    TextTheme textTheme,
    AIProviderOption provider,
    bool isUrlInput,
    {required bool isDesktop}
  ) {
    final iconSize = isDesktop ? 64.0 : 72.w;
    final iconFontSize = isDesktop ? 32.0 : 36.sp;
    final titleStyle = isDesktop ? textTheme.headlineMedium : textTheme.headlineSmall;
    
    return Center(
      child: Column(
        children: [
          // Provider icon
          Container(
            width: iconSize.toDouble(),
            height: iconSize.toDouble(),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(isDesktop ? 16 : 20.r),
            ),
            child: Icon(
              provider.icon,
              color: colorScheme.primary,
              size: iconFontSize.toDouble(),
            ),
          ),
          SizedBox(height: isDesktop ? 20.0 : 16.h),
          Text(
            'Configure ${provider.name}',
            style: titleStyle?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isDesktop ? 10.0 : 8.h),
          Text(
            isUrlInput
                ? 'Enter your ${provider.name} server URL'
                : 'Enter your ${provider.name} API key to enable AI features',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildInputField(
    ColorScheme colorScheme,
    AIProviderOption provider,
    bool isUrlInput,
    {required bool isDesktop}
  ) {
    final inputLabel = isUrlInput ? 'Server URL' : 'API Key';
    final labelFontSize = isDesktop ? 14.0 : 14.sp;
    final inputFontSize = isDesktop ? 15.0 : 15.sp;
    final borderRadius = isDesktop ? 10.0 : 12.r;
    final contentPadding = isDesktop 
        ? const EdgeInsets.symmetric(horizontal: 16, vertical: 16)
        : EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          inputLabel,
          style: TextStyle(
            fontSize: labelFontSize.toDouble(),
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        SizedBox(height: isDesktop ? 8.0 : 8.h),
        TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          obscureText: !isUrlInput && _isObscured,
          autocorrect: false,
          enableSuggestions: false,
          style: TextStyle(
            fontSize: inputFontSize.toDouble(),
            fontFamily: isUrlInput ? null : 'monospace',
          ),
          decoration: InputDecoration(
            hintText: provider.apiKeyPlaceholder,
            hintStyle: TextStyle(
              color: colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
            filled: true,
            fillColor: colorScheme.surfaceContainerLow,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius.toDouble()),
              borderSide: BorderSide(
                color: colorScheme.outline.withOpacity(0.2),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius.toDouble()),
              borderSide: BorderSide(
                color: colorScheme.outline.withOpacity(0.2),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius.toDouble()),
              borderSide: BorderSide(
                color: colorScheme.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius.toDouble()),
              borderSide: BorderSide(
                color: colorScheme.error,
              ),
            ),
            contentPadding: contentPadding,
            prefixIcon: Icon(
              isUrlInput ? Icons.link_rounded : Icons.key_rounded,
              color: colorScheme.onSurfaceVariant,
            ),
            suffixIcon: isUrlInput
                ? null
                : IconButton(
                    icon: Icon(
                      _isObscured
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    onPressed: () {
                      setState(() {
                        _isObscured = !_isObscured;
                      });
                    },
                  ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildErrorMessage(ColorScheme colorScheme) {
    return Row(
      children: [
        Icon(
          Icons.error_outline_rounded,
          color: colorScheme.error,
          size: widget.isDesktop ? 16 : 16.sp,
        ),
        SizedBox(width: widget.isDesktop ? 6 : 6.w),
        Expanded(
          child: Text(
            widget.errorMessage!,
            style: TextStyle(
              fontSize: widget.isDesktop ? 13 : 13.sp,
              color: colorScheme.error,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildBottomActions(ColorScheme colorScheme) {
    final padding = widget.isDesktop ? 32.0 : 24.w;
    final buttonPaddingH = widget.isDesktop ? 24.0 : 24.w;
    final buttonPaddingV = widget.isDesktop ? 12.0 : 12.h;
    final borderRadius = widget.isDesktop ? 10.0 : 12.r;
    
    return Container(
      padding: EdgeInsets.all(padding.toDouble()),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outline.withOpacity(0.1),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Back button
            TextButton.icon(
              onPressed: widget.isLoading ? null : widget.onBack,
              icon: Icon(Icons.arrow_back_rounded, size: widget.isDesktop ? 18 : 18.sp),
              label: const Text('Back'),
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.onSurfaceVariant,
              ),
            ),

            const Spacer(),

            // Skip button
            TextButton(
              onPressed: widget.isLoading ? null : widget.onSkip,
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.onSurfaceVariant,
              ),
              child: const Text('Skip for now'),
            ),

            SizedBox(width: widget.isDesktop ? 12 : 12.w),

            // Save button
            FilledButton(
              onPressed: widget.isLoading
                  ? null
                  : () {
                      final value = widget.controller.text.trim();
                      if (value.isNotEmpty) {
                        widget.onSave(value);
                      }
                    },
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: EdgeInsets.symmetric(
                  horizontal: buttonPaddingH.toDouble(),
                  vertical: buttonPaddingV.toDouble(),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(borderRadius.toDouble()),
                ),
              ),
              child: widget.isLoading
                  ? SizedBox(
                      width: widget.isDesktop ? 20 : 20.w,
                      height: widget.isDesktop ? 20 : 20.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          colorScheme.onPrimary,
                        ),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Save & Continue'),
                        SizedBox(width: widget.isDesktop ? 8 : 8.w),
                        Icon(Icons.arrow_forward_rounded, size: widget.isDesktop ? 18 : 18.sp),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGetKeyLink(ColorScheme colorScheme, AIProviderOption provider, {required bool isDesktop}) {
    final padding = isDesktop ? 16.0 : 16.w;
    final borderRadius = isDesktop ? 10.0 : 12.r;
    final iconSize = isDesktop ? 20.0 : 20.sp;
    final fontSize = isDesktop ? 13.0 : 13.sp;
    
    return Container(
      padding: EdgeInsets.all(padding.toDouble()),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.15),
        borderRadius: BorderRadius.circular(borderRadius.toDouble()),
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: colorScheme.primary,
            size: iconSize.toDouble(),
          ),
          SizedBox(width: isDesktop ? 12 : 12.w),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: fontSize.toDouble(),
                  color: colorScheme.onSurface,
                ),
                children: [
                  const TextSpan(text: "Don't have an API key? "),
                  TextSpan(
                    text: 'Get one here',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = _launchGetKeyUrl,
                  ),
                ],
              ),
            ),
          ),
          Icon(
            Icons.open_in_new_rounded,
            color: colorScheme.primary,
            size: isDesktop ? 16 : 16.sp,
          ),
        ],
      ),
    );
  }

  Widget _buildOllamaInfoCard(ColorScheme colorScheme, {required bool isDesktop}) {
    final padding = isDesktop ? 16.0 : 16.w;
    final borderRadius = isDesktop ? 10.0 : 12.r;
    final iconSize = isDesktop ? 20.0 : 20.sp;
    final titleFontSize = isDesktop ? 14.0 : 14.sp;
    final contentFontSize = isDesktop ? 13.0 : 13.sp;
    
    return Container(
      padding: EdgeInsets.all(padding.toDouble()),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer.withOpacity(0.2),
        borderRadius: BorderRadius.circular(borderRadius.toDouble()),
        border: Border.all(
          color: colorScheme.tertiary.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.computer_rounded,
                color: colorScheme.tertiary,
                size: iconSize.toDouble(),
              ),
              SizedBox(width: isDesktop ? 8 : 8.w),
              Text(
                'Local AI Setup',
                style: TextStyle(
                  fontSize: titleFontSize.toDouble(),
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: isDesktop ? 12 : 12.h),
          Text(
            '1. Install Ollama from ollama.com\n'
            '2. Run: ollama pull llama3.2\n'
            '3. Start Ollama (usually auto-starts)\n'
            '4. Use default URL: http://localhost:11434',
            style: TextStyle(
              fontSize: contentFontSize.toDouble(),
              color: colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
