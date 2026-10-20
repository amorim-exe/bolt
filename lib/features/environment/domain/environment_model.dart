class EnvironmentVariable {
  String key;
  String value;
  bool isEnabled;

  EnvironmentVariable({
    required this.key,
    required this.value,
    this.isEnabled = true,
  });
}