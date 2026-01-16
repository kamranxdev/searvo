import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../entities/agent/agent_tool.dart';

class CurrencyConverterTool extends AgentTool {
  CurrencyConverterTool()
    : super(
        id: 'currency_converter',
        name: 'Currency Converter',
        description:
            'Convert between different currencies using real-time exchange rates.',
      );

  @override
  Future<bool> get isAvailable async => true;

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'from': {
        'type': 'string',
        'description': 'The source currency code (e.g., "USD", "EUR", "JPY").',
      },
      'to': {
        'type': 'string',
        'description': 'The target currency code (e.g., "USD", "EUR", "JPY").',
      },
      'amount': {
        'type': 'number',
        'description': 'The amount to convert. Defaults to 1.0.',
      },
    },
    'required': ['from', 'to'],
  };

  @override
  Future<dynamic> execute(Map<String, dynamic> input) async {
    final from = (input['from'] as String).toUpperCase();
    final to = (input['to'] as String).toUpperCase();
    final amount = (input['amount'] as num?)?.toDouble() ?? 1.0;

    try {
      // 1. Fetch rates for base currency 'from'
      final url = Uri.parse('https://open.er-api.com/v6/latest/$from');
      final response = await http.get(url);

      if (response.statusCode != 200) {
        return {'error': 'Failed to fetch exchange rates'};
      }

      final data = json.decode(response.body);

      if (data['result'] == 'error') {
        return {'error': 'Invalid currency code: $from'};
      }

      final rates = data['rates'] as Map<String, dynamic>;

      if (!rates.containsKey(to)) {
        return {'error': 'Target currency not supported: $to'};
      }

      final rate = (rates[to] as num).toDouble();
      final convertedAmount = amount * rate;
      final lastUpdate = data['time_last_update_utc'];

      return {
        'from': from,
        'to': to,
        'amount': amount,
        'rate': rate,
        'convertedAmount': convertedAmount, // Keep precise for internal usage
        'display':
            '${amount.toStringAsFixed(2)} $from = ${convertedAmount.toStringAsFixed(2)} $to',
        'lastUpdated': lastUpdate,
      };
    } catch (e) {
      return {'error': 'Currency conversion error: $e'};
    }
  }
}
