import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/search_theme.dart';

class CryptoWidget extends StatelessWidget {
  final Map<String, dynamic> data;

  const CryptoWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final searchColors = SearchTheme.colors(context);
    final name = data['name'] ?? '';
    final symbol = data['symbol'] ?? '';
    final imageUrl = data['image'];
    final currentPrice = data['current_price'];
    final currency = data['currency'] ?? 'USD';
    final priceChangePercent = data['price_change_percentage_24h'];
    final isPositive = (priceChangePercent ?? 0) >= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: searchColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: searchColors.divider),
      ),
      child: Column(
        children: [
          Row(
            children: [
              if (imageUrl != null)
                CachedNetworkImage(
                  imageUrl: imageUrl,
                  width: 48,
                  height: 48,
                  placeholder: (context, url) =>
                      const CircularProgressIndicator(),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        color: searchColors.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      symbol,
                      style: TextStyle(
                        color: searchColors.onSurfaceVariant,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$currency ${currentPrice?.toString() ?? '--'}',
                    style: TextStyle(
                      color: searchColors.onSurface,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (priceChangePercent != null)
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
                          '${priceChangePercent.toStringAsFixed(2)}%',
                          style: TextStyle(
                            color: isPositive ? Colors.green : Colors.red,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStat(searchColors, 'High 24h', data['high_24h']),
              _buildStat(searchColors, 'Low 24h', data['low_24h']),
              _buildStat(
                searchColors,
                'Market Cap Rank',
                '#${data['market_cap_rank']}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(SearchColors searchColors, String label, dynamic value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(color: searchColors.onSurfaceVariant, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value?.toString() ?? '--',
          style: TextStyle(
            color: searchColors.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
