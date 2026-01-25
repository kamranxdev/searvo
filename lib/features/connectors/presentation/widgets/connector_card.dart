import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:searvo/features/connectors/domain/entities/connector.dart';

class ConnectorCard extends StatelessWidget {
  final Connector connector;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;
  final bool isLoading;

  const ConnectorCard({
    super.key,
    required this.connector,
    required this.onConnect,
    required this.onDisconnect,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    bool isConnected = connector.status == ConnectorStatus.connected;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: connector.iconPath.endsWith('.svg')
                ? SvgPicture.asset(
                    connector.iconPath,
                    width: 32,
                    height: 32,
                    placeholderBuilder: (_) =>
                        const Icon(Icons.extension, size: 24),
                  )
                : const Icon(Icons.extension, size: 24),
          ),
          const SizedBox(width: 16),

          // Text Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  connector.name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  connector.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (connector.errorMessage != null &&
                    connector.status == ConnectorStatus.error) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Error: ${connector.errorMessage}',
                    style: const TextStyle(color: Colors.red, fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Action Button
          SizedBox(
            height: 36,
            child: isConnected
                ? OutlinedButton(
                    onPressed: isLoading ? null : onDisconnect,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: Theme.of(context).dividerColor.withOpacity(0.2),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: const Text(
                      'Disconnect',
                    ), // Or "Manage" if appropriate
                  )
                : FilledButton.tonal(
                    onPressed: isLoading ? null : onConnect,
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF2D2D2D) // Dark gray for dark mode
                          : const Color(
                              0xFFF0F0F0,
                            ), // Light gray for light mode
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: const Text('Enable'),
                  ),
          ),
        ],
      ),
    );
  }
}
