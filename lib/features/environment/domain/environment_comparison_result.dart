import '../../http_client/domain/models/response_result.dart';

class EnvironmentComparisonResult {
  const EnvironmentComparisonResult({
    required this.environmentName,
    required this.response,
  });

  final String environmentName;
  final ResponseResult response;
}
