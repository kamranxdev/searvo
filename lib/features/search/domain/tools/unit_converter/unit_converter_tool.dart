import '../../entities/agent/agent_tool.dart';

class UnitConverterTool extends AgentTool {
  UnitConverterTool()
    : super(
        id: 'unit_converter',
        name: 'Unit Converter',
        description:
            'Convert between common physical units (length, mass, temperature, volume).',
      );

  @override
  Future<bool> get isAvailable async => true;

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'value': {
        'type': 'number',
        'description': 'The numerical value to convert.',
      },
      'from_unit': {
        'type': 'string',
        'description': 'The unit to convert from (e.g., m, ft, kg, lb, c, f).',
      },
      'to_unit': {'type': 'string', 'description': 'The unit to convert to.'},
    },
    'required': ['value', 'from_unit', 'to_unit'],
  };

  @override
  Future<dynamic> execute(Map<String, dynamic> input) async {
    final value = (input['value'] as num).toDouble();
    final from = (input['from_unit'] as String).toLowerCase().trim();
    final to = (input['to_unit'] as String).toLowerCase().trim();

    try {
      final category = _getCategory(from);
      if (category == null) {
        return {'error': 'Unknown unit: $from'};
      }
      if (_getCategory(to) != category) {
        return {'error': 'Cannot convert $from to $to (incompatible types)'};
      }

      final result = _convert(value, from, to, category);
      return {
        'from': from,
        'to': to,
        'original_value': value,
        'converted_value': result,
        'display': '$value $from = ${result.toStringAsFixed(4)} $to',
      };
    } catch (e) {
      return {'error': 'Conversion failed: $e'};
    }
  }

  String? _getCategory(String unit) {
    if ({'m', 'km', 'cm', 'mm', 'mi', 'yd', 'ft', 'in'}.contains(unit))
      return 'length';
    if ({'kg', 'g', 'mg', 'lb', 'oz'}.contains(unit)) return 'mass';
    if ({'c', 'f', 'k'}.contains(unit)) return 'temperature';
    if ({'l', 'ml', 'gal', 'qt', 'pt', 'fl_oz'}.contains(unit)) return 'volume';
    return null;
  }

  double _convert(double value, String from, String to, String category) {
    // Convert to base unit then to target
    // Base units: Length (m), Mass (kg), Temp (C - special), Volume (l)

    if (from == to) return value;

    if (category == 'temperature') {
      return _convertTemp(value, from, to);
    }

    final baseValue = _toBase(value, from, category);
    return _fromBase(baseValue, to, category);
  }

  double _convertTemp(double value, String from, String to) {
    // To Celsius
    double c;
    if (from == 'c')
      c = value;
    else if (from == 'f')
      c = (value - 32) * 5 / 9;
    else if (from == 'k')
      c = value - 273.15;
    else
      throw Exception('Unknown temp unit $from');

    // From Celsius
    if (to == 'c') return c;
    if (to == 'f') return c * 9 / 5 + 32;
    if (to == 'k') return c + 273.15;
    throw Exception('Unknown temp unit $to');
  }

  double _toBase(double value, String unit, String category) {
    switch (category) {
      case 'length': // Base: meters
        switch (unit) {
          case 'm':
            return value;
          case 'km':
            return value * 1000;
          case 'cm':
            return value / 100;
          case 'mm':
            return value / 1000;
          case 'mi':
            return value * 1609.344;
          case 'yd':
            return value * 0.9144;
          case 'ft':
            return value * 0.3048;
          case 'in':
            return value * 0.0254;
        }
        break;
      case 'mass': // Base: kg
        switch (unit) {
          case 'kg':
            return value;
          case 'g':
            return value / 1000;
          case 'mg':
            return value / 1e6;
          case 'lb':
            return value * 0.45359237;
          case 'oz':
            return value * 0.02834952;
        }
        break;
      case 'volume': // Base: liters
        switch (unit) {
          case 'l':
            return value;
          case 'ml':
            return value / 1000;
          case 'gal':
            return value * 3.78541; // US gal
          case 'qt':
            return value * 0.946353;
          case 'pt':
            return value * 0.473176;
          case 'fl_oz':
            return value * 0.0295735;
        }
        break;
    }
    throw Exception('Unknown unit $unit');
  }

  double _fromBase(double value, String unit, String category) {
    switch (category) {
      case 'length':
        switch (unit) {
          case 'm':
            return value;
          case 'km':
            return value / 1000;
          case 'cm':
            return value * 100;
          case 'mm':
            return value * 1000;
          case 'mi':
            return value / 1609.344;
          case 'yd':
            return value / 0.9144;
          case 'ft':
            return value / 0.3048;
          case 'in':
            return value / 0.0254;
        }
        break;
      case 'mass':
        switch (unit) {
          case 'kg':
            return value;
          case 'g':
            return value * 1000;
          case 'mg':
            return value * 1e6;
          case 'lb':
            return value / 0.45359237;
          case 'oz':
            return value / 0.02834952;
        }
        break;
      case 'volume':
        switch (unit) {
          case 'l':
            return value;
          case 'ml':
            return value * 1000;
          case 'gal':
            return value / 3.78541;
          case 'qt':
            return value / 0.946353;
          case 'pt':
            return value / 0.473176;
          case 'fl_oz':
            return value / 0.0295735;
        }
        break;
    }
    throw Exception('Unknown unit $unit');
  }
}
