import '../models/response_result.dart';

class ResponseTestRunner {
  static List<ResponseTestResult> run(
    String script,
    ResponseResult response,
  ) {
    final lines = script
        .split(RegExp(r'[\r\n;]+'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty && !line.startsWith('//'))
        .toList();
    return [
      for (var index = 0; index < lines.length; index++)
        _runLine(lines[index], response, index + 1),
    ];
  }

  static ResponseTestResult _runLine(
    String line,
    ResponseResult response,
    int lineNumber,
  ) {
    final assertion =
        line.replaceFirst(RegExp(r'^assert\s+', caseSensitive: false), '');
    final named = RegExp(r'^([^:]+):\s*(.+)$').firstMatch(assertion);
    final name = named?.group(1)?.trim() ?? 'Assertion $lineNumber';
    final expression = named?.group(2)?.trim() ?? assertion;
    try {
      final passed = _evaluate(expression, response);
      return ResponseTestResult(
        name: name,
        passed: passed,
        message: passed ? 'Passed' : 'Assertion evaluated to false',
      );
    } on FormatException catch (error) {
      return ResponseTestResult(
        name: name,
        passed: false,
        message: error.message,
      );
    }
  }

  static bool _evaluate(String expression, ResponseResult response) {
    final alternatives = expression.split('||');
    return alternatives.any((alternative) {
      final conditions = alternative.split('&&');
      return conditions
          .every((condition) => _compare(condition.trim(), response));
    });
  }

  static bool _compare(String expression, ResponseResult response) {
    final match = RegExp(r'^(.*?)\s*(===|!==|==|!=|<=|>=|<|>)\s*(.*?)$')
        .firstMatch(expression);
    if (match == null) {
      final value = _resolve(expression.trim(), response);
      if (value is bool) return value;
      throw FormatException('Expected a comparison in "$expression"');
    }

    final left = _resolve(match.group(1)!.trim(), response);
    final right = _literal(match.group(3)!.trim());
    final operator = match.group(2)!;
    if (operator == '==' || operator == '===') return left == right;
    if (operator == '!=' || operator == '!==') return left != right;
    final leftNumber = _asNumber(left);
    final rightNumber = _asNumber(right);
    if (leftNumber == null || rightNumber == null) {
      throw FormatException('Numeric comparison required in "$expression"');
    }
    return switch (operator) {
      '<' => leftNumber < rightNumber,
      '<=' => leftNumber <= rightNumber,
      '>' => leftNumber > rightNumber,
      '>=' => leftNumber >= rightNumber,
      _ => false,
    };
  }

  static dynamic _resolve(String source, ResponseResult response) {
    final path = source
        .replaceFirst(RegExp(r'^(pm\.response|response)\.'), '')
        .split('.');
    dynamic value = switch (path.first) {
      'code' || 'status' || 'statusCode' => response.statusCode,
      'time' || 'responseTimeMs' || 'responseTime' => response.responseTimeMs,
      'size' || 'responseSizeBytes' => response.responseSizeBytes,
      'data' => response.data,
      'statusMessage' => response.statusMessage,
      _ => throw FormatException('Unsupported value "$source"'),
    };
    for (final key in path.skip(1)) {
      if (value is Map) {
        value = value[key];
      } else if (value is List) {
        final index = int.tryParse(key);
        if (index == null) return null;
        value = index >= 0 && index < value.length ? value[index] : null;
      } else {
        return null;
      }
    }
    return value;
  }

  static dynamic _literal(String source) {
    final value = source.trim();
    if ((value.startsWith('"') && value.endsWith('"')) ||
        (value.startsWith("'") && value.endsWith("'"))) {
      return value.substring(1, value.length - 1);
    }
    if (value == 'true') return true;
    if (value == 'false') return false;
    if (value == 'null') return null;
    return num.tryParse(value) ??
        (throw FormatException('Unsupported literal "$source"'));
  }

  static num? _asNumber(dynamic value) {
    if (value is num) return value;
    if (value is String) return num.tryParse(value);
    return null;
  }
}
