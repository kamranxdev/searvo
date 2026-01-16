import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../entities/agent/agent_tool.dart';

class CryptoPriceTool extends AgentTool {
  CryptoPriceTool()
    : super(
        id: 'crypto_price',
        name: 'Crypto Price',
        description:
            'Get current price and market data for cryptocurrencies (Bitcoin, Ethereum, etc).',
      );

  @override
  Future<bool> get isAvailable async => true;

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'coin_id': {
        'type': 'string',
        'description':
            'The ID of the coin (e.g., "bitcoin", "ethereum", "dogecoin"). Use lowercase names.',
      },
      'currency': {
        'type': 'string',
        'description': 'Target currency (default: usd).',
      },
    },
    'required': ['coin_id'],
  };

  @override
  Future<dynamic> execute(Map<String, dynamic> input) async {
    final coinId = (input['coin_id'] as String).toLowerCase();
    final currency = (input['currency'] as String? ?? 'usd').toLowerCase();

    try {
      // Use efficient 'coins/markets' endpoint for richer data
      final url = Uri.parse(
        'https://api.coingecko.com/api/v3/coins/markets?vs_currency=$currency&ids=$coinId&order=market_cap_desc&per_page=1&page=1&sparkline=false',
      );

      final response = await http.get(
        url,
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode != 200) {
        return {
          'error':
              'Failed to fetch crypto data (Status: ${response.statusCode})',
        };
      }

      final List<dynamic> data = json.decode(response.body);

      if (data.isEmpty) {
        return {'error': 'Coin not found or no data available for: $coinId'};
      }

      final coin = data[0];

      return {
        'id': coin['id'],
        'symbol': coin['symbol'].toString().toUpperCase(),
        'name': coin['name'],
        'current_price': coin['current_price'],
        'currency': currency.toUpperCase(),
        'market_cap': coin['market_cap'],
        'market_cap_rank': coin['market_cap_rank'],
        'fully_diluted_valuation': coin['fully_diluted_valuation'],
        'total_volume': coin['total_volume'],
        'high_24h': coin['high_24h'],
        'low_24h': coin['low_24h'],
        'price_change_24h': coin['price_change_24h'],
        'price_change_percentage_24h': coin['price_change_percentage_24h'],
        'ath': coin['ath'],
        'ath_change_percentage': coin['ath_change_percentage'],
        'ath_date': coin['ath_date'],
        'atl': coin['atl'],
        'atl_change_percentage': coin['atl_change_percentage'],
        'atl_date': coin['atl_date'],
        'last_updated': coin['last_updated'],
        'image': coin['image'],
        // Provides a summary string to help the LLM if it hallucinates key details
        'summary':
            '${coin['name']} (${coin['symbol'].toString().toUpperCase()}) is trading at $currency ${coin['current_price']}. 24h Range: ${coin['low_24h']} - ${coin['high_24h']}.',
      };
    } catch (e) {
      return {'error': 'Crypto tool error: $e'};
    }
  }
}
