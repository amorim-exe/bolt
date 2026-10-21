class EnvironmentVariable {
  String key;
  String value;
  bool isEnabled;

  EnvironmentVariable({
    required this.key,
    required this.value,
    this.isEnabled = true,
  });

  Map<String, dynamic> toJson() => {
        'key': key,
        'value': value,
        'isEnabled': isEnabled,
      };

  factory EnvironmentVariable.fromJson(Map<String, dynamic> json) =>
      EnvironmentVariable(
        key: json['key']?.toString() ?? '',
        value: json['value']?.toString() ?? '',
        isEnabled: json['isEnabled'] != false,
      );
}

class EnvironmentProfile {
  const EnvironmentProfile({
    required this.id,
    required this.name,
    required this.variables,
  });

  final String id;
  final String name;
  final List<EnvironmentVariable> variables;

  EnvironmentProfile copyWith({
    String? id,
    String? name,
    List<EnvironmentVariable>? variables,
  }) =>
      EnvironmentProfile(
        id: id ?? this.id,
        name: name ?? this.name,
        variables: variables ?? this.variables,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'variables': variables.map((variable) => variable.toJson()).toList(),
      };

  factory EnvironmentProfile.fromJson(Map<String, dynamic> json) {
    final rawVariables = json['variables'];
    final variables = rawVariables is List
        ? rawVariables
            .whereType<Map>()
            .map((item) => EnvironmentVariable.fromJson(
                  Map<String, dynamic>.from(item),
                ))
            .toList()
        : <EnvironmentVariable>[];
    return EnvironmentProfile(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      variables: variables,
    );
  }
}