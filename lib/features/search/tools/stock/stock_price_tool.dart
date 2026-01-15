import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../agent/models/agent_tool.dart';

class StockPriceTool extends AgentTool {
  StockPriceTool()
    : super(
        id: 'stock_price',
        name: 'Stock Price',
        description:
            'Get real-time stock price and data for US and global equities (e.g., AAPL, GOOGL, TSLA).',
      );

  @override
  Future<bool> get isAvailable async => true;

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'symbol': {
        'type': 'string',
        'description':
            'The stock ticker symbol (e.g., "AAPL", "MSFT", "TSLA").',
      },
    },
    'required': ['symbol'],
  };

  @override
  Future<dynamic> execute(Map<String, dynamic> input) async {
    final symbol = (input['symbol'] as String).toUpperCase();

    try {
      // Yahoo Finance Chart API is commonly used as a free unofficial endpoint
      final url = Uri.parse(
        'https://query1.finance.yahoo.com/v8/finance/chart/$symbol?interval=1d&range=1d',
      );

      final response = await http.get(
        url,
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
        },
      );

      if (response.statusCode != 200) {
        return {
          'error':
              'Failed to fetch stock data (Status: ${response.statusCode})',
        };
      }

      final data = json.decode(response.body);
      final result = data['chart']['result'];

      if (result == null || (result as List).isEmpty) {
        return {'error': 'Symbol not found: $symbol'};
      }

      final meta = result[0]['meta'];
      final price = meta['regularMarketPrice'];
      final prevClose = meta['chartPreviousClose'];
      final currency = meta['currency'];
      final exchange = meta['exchangeName']; // "NASDAQ"
      final instrumentType = meta['instrumentType']; // "EQUITY"

      double change = 0.0;
      double changePercent = 0.0;

      if (price != null && prevClose != null) {
        change = (price as num).toDouble() - (prevClose as num).toDouble();
        changePercent = (change / prevClose) * 100;
      }

      return {
        'symbol': symbol,
        'longName':
            meta['longName'] ??
            symbol, // often absent in simple chart calls, but check
        'currency': currency,
        'exchange': exchange,
        'instrumentType': instrumentType,
        'price': price,
        'previous_close': prevClose,
        'change': change,
        'change_percent': changePercent,
        'day_range': {
          'high': meta['regularMarketDayHigh'],
          'low': meta['regularMarketDayLow'],
        },
        '52_week_range': {
          'high': meta['fiftyTwoWeekHigh'],
          'low': meta['fiftyTwoWeekLow'],
        },
        'volume': meta['regularMarketVolume'],
        'market_cap': meta['marketCap'], // Sometimes present
        'timestamp': meta['regularMarketTime'],
        'timezone': meta['timezone'],
        'trading_periods': meta['currentTradingPeriod'], // Market hours info
        'display':
            '$symbol: $currency $price (${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)} / ${changePercent.toStringAsFixed(2)}%)',
      };
    } catch (e) {
      return {'error': 'Stock tool error: $e'};
    }
  }
}
