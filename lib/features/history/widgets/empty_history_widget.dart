import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Widget shown when there are no conversations in history
class EmptyHistoryWidget extends StatelessWidget {
  const EmptyHistoryWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Icon(
              Icons.history,
              size: 80,
              color: Colors.grey[400],
            ),

            const SizedBox(height: 24),

            // Title
            Text(
              'No Conversations Yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            // Description
            Text(
              'Your search conversations will appear here. Start a new search to begin!',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // Action button
            ElevatedButton.icon(
              onPressed: () {
                context.go('/');
              },
              icon: const Icon(Icons.search),
              label: const Text('Start Searching'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Features info
            _buildFeatureItem(
              icon: Icons.auto_awesome,
              title: 'Smart Search',
              description: 'AI-powered answers to your questions',
            ),

            const SizedBox(height: 16),

            _buildFeatureItem(
              icon: Icons.history,
              title: 'Auto-Save',
              description: 'Conversations are saved automatically',
            ),

            const SizedBox(height: 16),

            _buildFeatureItem(
              icon: Icons.replay,
              title: 'Resume Anytime',
              description: 'Pick up right where you left off',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 24,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
