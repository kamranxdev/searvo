import 'package:flutter/material.dart';
import '../../theme/search_theme.dart';

class StockWidget extends StatelessWidget {
  final Map<String, dynamic> data;

  const StockWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final searchColors = SearchTheme.colors(context);
    final symbol = data['symbol'] ?? '';
    final price = data['price'] is num
        ? (data['price'] as num).toDouble()
        : 0.0;
    final change = data['change'] is num
        ? (data['change'] as num).toDouble()
        : 0.0;
    final changePercent = data['change_percent'] is num
        ? (data['change_percent'] as num).toDouble()
        : 0.0;
    final currency = data['currency'] ?? '';
    final isPositive = change >= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: searchColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: searchColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    symbol,
                    style: TextStyle(
                      color: searchColors.onSurface,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    data['longName'] ?? data['exchange'] ?? '',
                    style: TextStyle(
                      color: searchColors.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$currency ${price.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: searchColors.onSurface,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        isPositive
                            ? Icons.arrow_drop_up
                            : Icons.arrow_drop_down,
                        color: isPositive ? Colors.green : Colors.red,
                        size: 20,
                      ),
                      Text(
                        '${change.abs().toStringAsFixed(2)} (${changePercent.abs().toStringAsFixed(2)}%)',
                        style: TextStyle(
                          color: isPositive ? Colors.green : Colors.red,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          _buildDetails(searchColors),
        ],
      ),
    );
  }

  Widget _buildDetails(SearchColors searchColors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildDetailItem(
          searchColors,
          'Range',
          '${_formatVal(data['day_range']['low'])} - ${_formatVal(data['day_range']['high'])}',
        ),
        _buildDetailItem(
          searchColors,
          '52W Range',
          '${_formatVal(data['52_week_range']['low'])} - ${_formatVal(data['52_week_range']['high'])}',
        ),
        _buildDetailItem(searchColors, 'Volume', _formatVolume(data['volume'])),
      ],
    );
  }

  String _formatVal(dynamic val) {
    if (val is num) return val.toStringAsFixed(2);
    return '--';
  }

  String _formatVolume(dynamic volume) {
    if (volume == null || volume is! num) return '--';
    if (volume > 1000000000)
      return '${(volume / 1000000000).toStringAsFixed(1)}B';
    if (volume > 1000000) return '${(volume / 1000000).toStringAsFixed(1)}M';
    if (volume > 1000) return '${(volume / 1000).toStringAsFixed(1)}K';
    return volume.toString();
  }

  Widget _buildDetailItem(
    SearchColors searchColors,
    String label,
    String value,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: searchColors.onSurfaceVariant, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: searchColors.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
