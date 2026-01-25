import 'package:math_expressions/math_expressions.dart';
import 'package:searvo/features/search/domain/entities/agent/agent_tool.dart';

class CalculatorTool extends AgentTool {
  CalculatorTool()
    : super(
        id: 'calculator',
        name: 'Calculator',
        description:
            'Perform mathematical calculations (usage: "5 + 5", "sqrt(144)").',
      );

  @override
  Future<bool> get isAvailable async => true;

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'expression': {
        'type': 'string',
        'description': 'The math expression to evaluate',
      },
    },
    'required': ['expression'],
  };

  @override
  Future<dynamic> execute(Map<String, dynamic> input) async {
    final expressionStr = input['expression'] as String;
    try {
      final cm = ContextModel();
      final parser = GrammarParser();
      final expression = parser.parse(expressionStr);
      final result = expression.evaluate(EvaluationType.REAL, cm);

      return {'success': true, 'result': result.toString()};
    } catch (e) {
      return {'success': false, 'error': "Math error: $e"};
    }
  }
}
