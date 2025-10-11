import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:searvo/core/routing/app_router.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => AppRouter.goBack(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Searvo - Privacy Policy',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Last Updated: October 8, 2025',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 24.h),
            _buildSection(
              context,
              'Introduction',
              'Welcome to Searvo. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application. Please read this privacy policy carefully.',
            ),
            _buildSection(
              context,
              'Information We Collect',
              '',
              subsections: [
                _buildSubsection(
                  context,
                  'Personal Information',
                  'When you use Searvo, we may collect:\n• Email address (when using Google Sign-In)\n• Profile information (name, profile picture from Google account)\n• User preferences and settings',
                ),
                _buildSubsection(
                  context,
                  'Usage Data',
                  '• Search queries and history\n• Voice input recordings (processed locally and sent to speech recognition services)\n• App interaction data\n• Feature usage statistics',
                ),
                _buildSubsection(
                  context,
                  'Device Information',
                  '• Device type and model\n• Operating system version\n• Unique device identifiers\n• Network information',
                ),
                _buildSubsection(
                  context,
                  'Files and Media',
                  '• Documents uploaded for AI processing (PDFs, text files)\n• Files accessed through file picker functionality',
                ),
              ],
            ),
            _buildSection(
              context,
              'How We Use Your Information',
              'We use the collected information to:\n• Provide and maintain the Searvo service\n• Process search queries and generate AI responses\n• Authenticate users via Google Sign-In\n• Store user preferences and search history\n• Improve app performance and user experience\n• Analyze usage patterns and optimize features',
            ),
            _buildSection(
              context,
              'Third-Party Services',
              'Searvo integrates with the following third-party services:',
              subsections: [
                _buildSubsection(
                  context,
                  'Firebase (Google)',
                  '• Authentication\n• Cloud Firestore (data storage)\n• [Firebase Privacy Policy](https://firebase.google.com/support/privacy)',
                ),
                _buildSubsection(
                  context,
                  'AI Providers',
                  '• OpenAI (GPT models)\n• Google AI (Gemini)\n• Anthropic (Claude)\n• Ollama (local models)\n\nEach provider processes your queries according to their respective privacy policies.',
                ),
                _buildSubsection(
                  context,
                  'Search Providers',
                  '• SearXNG (self-hosted or third-party instances)\n• SerpAPI',
                ),
                _buildSubsection(
                  context,
                  'Google Sign-In',
                  '• Authentication and profile information\n• [Google Privacy Policy](https://policies.google.com/privacy)',
                ),
              ],
            ),
            _buildSection(
              context,
              'Data Storage and Security',
              '• Search history and user preferences are stored in Firebase Cloud Firestore\n• Data is encrypted in transit using HTTPS/TLS\n• Voice recordings are processed in real-time and not permanently stored\n• We implement industry-standard security measures to protect your data',
            ),
            _buildSection(
              context,
              'Data Retention',
              '• Search history: Retained until manually deleted by user\n• User preferences: Retained for the lifetime of your account\n• Voice data: Not stored permanently; processed in real-time only\n• Uploaded files: Processed temporarily and not stored on our servers',
            ),
            _buildSection(
              context,
              'Your Rights',
              'You have the right to:\n• Access your personal data\n• Correct inaccurate data\n• Delete your account and associated data\n• Export your search history\n• Opt-out of data collection (by not using the app)\n\nTo exercise these rights, contact us at the email below.',
            ),
            _buildSection(
              context,
              "Children's Privacy",
              "Searvo is not intended for children under 13 years of age. We do not knowingly collect personal information from children under 13.",
            ),
            _buildSection(
              context,
              'Data Sharing',
              'We do not sell your personal data. We may share data with:\n• Third-party AI providers (for query processing)\n• Firebase/Google (for authentication and storage)\n• Analytics services (anonymized usage data)',
            ),
            _buildSection(
              context,
              'Changes to This Privacy Policy',
              'We may update this privacy policy from time to time. We will notify you of any changes by:\n• Posting the new privacy policy in the app\n• Updating the "Last Updated" date',
            ),
            _buildSection(
              context,
              'Contact Us',
              'If you have questions about this Privacy Policy, please contact:\n\n**Email**: [Your Email]\n**GitHub**: https://github.com/Kamran1819G/Searvo',
            ),
            _buildSection(
              context,
              'Consent',
              'By using Searvo, you consent to this Privacy Policy and agree to its terms.',
            ),
            SizedBox(height: 24.h),
            Center(
              child: Text(
                '© 2025 Searvo. All rights reserved.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    String content, {
    List<Widget>? subsections,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 24.h),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8.h),
        if (content.isNotEmpty)
          Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        if (subsections != null) ...subsections,
      ],
    );
  }

  Widget _buildSubsection(
    BuildContext context,
    String title,
    String content,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 16.h),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          content,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}