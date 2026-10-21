import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../features/environment/domain/environment_model.dart';

class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.dark,
    this.languageCode = 'pt_BR',
    this.timeoutSeconds = 30,
    this.followRedirects = true,
    this.verifySslCertificates = true,
    this.compactDensity = false,
    this.textScale = 1,
    this.environmentProfiles = const [],
  });

  final ThemeMode themeMode;
  final String languageCode;
  final int timeoutSeconds;
  final bool followRedirects;
  final bool verifySslCertificates;
  final bool compactDensity;
  final double textScale;
  final List<EnvironmentProfile> environmentProfiles;

  AppSettings copyWith({
    ThemeMode? themeMode,
    String? languageCode,
    int? timeoutSeconds,
    bool? followRedirects,
    bool? verifySslCertificates,
    bool? compactDensity,
    double? textScale,
    List<EnvironmentProfile>? environmentProfiles,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      languageCode: languageCode ?? this.languageCode,
      timeoutSeconds: timeoutSeconds ?? this.timeoutSeconds,
      followRedirects: followRedirects ?? this.followRedirects,
      verifySslCertificates:
          verifySslCertificates ?? this.verifySslCertificates,
      compactDensity: compactDensity ?? this.compactDensity,
      textScale: textScale ?? this.textScale,
      environmentProfiles: environmentProfiles ?? this.environmentProfiles,
    );
  }

  Map<String, dynamic> toJson() => {
        'themeMode': themeMode.name,
        'languageCode': languageCode,
        'timeoutSeconds': timeoutSeconds,
        'followRedirects': followRedirects,
        'verifySslCertificates': verifySslCertificates,
        'compactDensity': compactDensity,
        'textScale': textScale,
        'environmentProfiles':
            environmentProfiles.map((profile) => profile.toJson()).toList(),
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final timeout = json['timeoutSeconds'];
    final scale = json['textScale'];
    final rawProfiles = json['environmentProfiles'];
    return AppSettings(
      themeMode: ThemeMode.values.firstWhere(
        (mode) => mode.name == json['themeMode'],
        orElse: () => ThemeMode.dark,
      ),
      languageCode: json['languageCode'] == 'en' ? 'en' : 'pt_BR',
      timeoutSeconds: timeout is int && timeout >= 1 && timeout <= 300
          ? timeout
          : 30,
      followRedirects:
          json['followRedirects'] is bool ? json['followRedirects'] as bool : true,
      verifySslCertificates: json['verifySslCertificates'] is bool
          ? json['verifySslCertificates'] as bool
          : true,
      compactDensity:
          json['compactDensity'] is bool ? json['compactDensity'] as bool : false,
      textScale: scale is num && scale >= 0.8 && scale <= 1.4
          ? scale.toDouble()
          : 1,
      environmentProfiles: rawProfiles is List
          ? rawProfiles
              .whereType<Map>()
              .map((item) => EnvironmentProfile.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .where((profile) => profile.id.isNotEmpty)
              .toList()
          : const [],
    );
  }
}

abstract interface class AppSettingsStore {
  Future<AppSettings> load();
  Future<void> save(AppSettings settings);
}

class FileAppSettingsStore implements AppSettingsStore {
  Future<File> _settingsFile() async {
    final directory = await getApplicationSupportDirectory();
    return File('${directory.path}${Platform.pathSeparator}settings.json');
  }

  @override
  Future<AppSettings> load() async {
    final file = await _settingsFile();
    if (!await file.exists()) return const AppSettings();
    final content = await file.readAsString();
    final decoded = jsonDecode(content);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('O ficheiro de configurações é inválido.');
    }
    return AppSettings.fromJson(decoded);
  }

  @override
  Future<void> save(AppSettings settings) async {
    final file = await _settingsFile();
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(settings.toJson()), flush: true);
  }
}

class AppSettingsState {
  const AppSettingsState({
    this.settings = const AppSettings(),
    this.isLoading = true,
    this.loadError,
  });

  final AppSettings settings;
  final bool isLoading;
  final String? loadError;

  AppSettingsState copyWith({
    AppSettings? settings,
    bool? isLoading,
    String? loadError,
    bool clearLoadError = false,
  }) {
    return AppSettingsState(
      settings: settings ?? this.settings,
      isLoading: isLoading ?? this.isLoading,
      loadError: clearLoadError ? null : loadError ?? this.loadError,
    );
  }
}

class AppSettingsNotifier extends StateNotifier<AppSettingsState> {
  AppSettingsNotifier(this._store) : super(const AppSettingsState()) {
    _ready = _load();
  }

  final AppSettingsStore _store;
  late final Future<void> _ready;

  Future<void> _load() async {
    try {
      final settings = await _store.load();
      state = state.copyWith(
        settings: settings,
        isLoading: false,
        clearLoadError: true,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        loadError: 'Não foi possível carregar as configurações: $error',
      );
    }
  }

  Future<void> save(AppSettings settings) async {
    await _ready;
    await _store.save(settings);
    state = state.copyWith(
      settings: settings,
      clearLoadError: true,
    );
  }
}

final appSettingsStoreProvider = Provider<AppSettingsStore>(
  (ref) => FileAppSettingsStore(),
);

final appSettingsProvider =
    StateNotifierProvider<AppSettingsNotifier, AppSettingsState>(
  (ref) => AppSettingsNotifier(ref.watch(appSettingsStoreProvider)),
);
