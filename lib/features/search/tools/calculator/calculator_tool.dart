import '../../agent/models/agent_tool.dart';

class CalculatorTool extends AgentTool {
  CalculatorTool()
    : super(
        id: 'calculator',
        name: 'Calculator',
        description:
            'Evaluates mathematical expressions. Supports basic arithmetic (+, -, *, /), parentheses, and common functions.',
      );

  @override
  Future<bool> get isAvailable async => true;

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'expression': {
        'type': 'string',
        'description':
            'The mathematical expression to evaluate (e.g., "2 + 2 * (3 - 1)")',
      },
    },
    'required': ['expression'],
  };

  @override
  Future<dynamic> execute(Map<String, dynamic> input) async {
    final expression = input['expression'] as String;

    try {
      final result = _evaluate(expression);
      return {'result': result};
    } catch (e) {
      return {'error': 'Failed to evaluate expression: $e'};
    }
  }

  num _evaluate(String expression) {
    // Remove spaces
    expression = expression.replaceAll(' ', '');
    // Basic parser implementation
    // This is a simplified Shunting-yard algorithm or similar would be better,
    // but for now let's implement a recursive descent parser for basic arithmetic.

    // Tokens: numbers, operators, parens
    final tokens = _tokenize(expression);
    final parser = _Parser(tokens);
    return parser.parseexpression();
  }

  List<String> _tokenize(String expression) {
    final tokens = <String>[];
    String currentNumber = '';

    for (int i = 0; i < expression.length; i++) {
      final char = expression[i];
      if ('0123456789.'.contains(char)) {
        currentNumber += char;
      } else {
        if (currentNumber.isNotEmpty) {
          tokens.add(currentNumber);
          currentNumber = '';
        }
        tokens.add(char);
      }
    }
    if (currentNumber.isNotEmpty) tokens.add(currentNumber);
    return tokens;
  }
}

class _Parser {
  final List<String> tokens;
  int pos = 0;

  _Parser(this.tokens);

  String get currentToken => pos < tokens.length ? tokens[pos] : '';

  void eat(String token) {
    if (currentToken == token) {
      pos++;
    } else {
      throw Exception('Expected $token but found $currentToken');
    }
  }

  num parseexpression() {
    var result = parseTerm();
    while (currentToken == '+' || currentToken == '-') {
      if (currentToken == '+') {
        eat('+');
        result += parseTerm();
      } else {
        eat('-');
        result -= parseTerm();
      }
    }
    return result;
  }

  num parseTerm() {
    var result = parseFactor();
    while (currentToken == '*' || currentToken == '/') {
      if (currentToken == '*') {
        eat('*');
        result *= parseFactor();
      } else {
        eat('/');
        result /= parseFactor();
      }
    }
    return result;
  }

  num parseFactor() {
    final token = currentToken;
    if (token == '(') {
      eat('(');
      final result = parseexpression();
      eat(')');
      return result;
    } else if (double.tryParse(token) != null) {
      pos++;
      return double.parse(token);
    } else if (token == '-') {
      eat('-');
      return -parseFactor();
    } else {
      throw Exception('Unexpected token: $token');
    }
  }
}
