import 'package:bolt/features/history/data/datasources/request_history_datasource.dart';
import 'package:bolt/features/history/data/models/request_history_entity.dart';
import 'package:bolt/features/history/presentation/history_provider.dart';
import 'package:bolt/core/settings/app_settings.dart';
import 'package:bolt/features/http_client/presentation/controllers/request_tabs_provider.dart';
import 'package:bolt/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _EmptyHistoryDatasource extends RequestHistoryDatasource {
  @override
  Future<List<RequestHistoryEntity>> getLatest({int limit = 100}) async => [];
}

class _MemoryAppSettingsStore implements AppSettingsStore {
  AppSettings settings = const AppSettings();

  @override
  Future<AppSettings> load() async => settings;

  @override
  Future<void> save(AppSettings settings) async {
    this.settings = settings;
  }
}

void main() {
  testWidgets('home shows request tabs and code generation', (tester) async {
    tester.view.physicalSize = const Size(1300, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final settingsStore = _MemoryAppSettingsStore();
    final container = ProviderContainer(
      overrides: [
        requestHistoryDatasourceProvider
            .overrideWithValue(_EmptyHistoryDatasource()),
        appSettingsStoreProvider.overrideWithValue(settingsStore),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const BoltApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Collections'), findsNWidgets(2));
    expect(find.text('Histórico'), findsOneWidget);
    expect(find.text('Resposta'), findsOneWidget);
    expect(find.text('Parâmetros'), findsOneWidget);

    await tester.tap(find.byTooltip('Nova aba'));
    await tester.pumpAndSettle();
    expect(container.read(requestTabsProvider).tabs, hasLength(2));

    await tester.tap(find.byTooltip('Gerar código'));
    await tester.pumpAndSettle();
    expect(find.text('Gerar código'), findsOneWidget);
    expect(find.text('cURL'), findsOneWidget);
    expect(find.text('JavaScript (Fetch)'), findsOneWidget);
    expect(find.text('Python (Requests)'), findsOneWidget);
    expect(find.text('Dart (Dio)'), findsOneWidget);

    await tester.tap(find.text('Fechar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Auth'));
    await tester.pumpAndSettle();
    expect(find.text('Tipo de autenticação'), findsOneWidget);
    expect(
      find.text('Esta requisição será enviada sem autenticação.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Tests').first);
    await tester.pumpAndSettle();
    expect(find.text('Asserções após a resposta'), findsOneWidget);

    await tester.tap(find.text('Tests').last);
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Sem testes executados. Adicione asserções na aba Tests e envie a requisição.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Configurações'));
    await tester.pumpAndSettle();
    expect(find.text('Configurações'), findsOneWidget);
    expect(find.text('Timeout'), findsOneWidget);
    expect(find.text('Seguir redirecionamentos'), findsOneWidget);
    expect(find.text('Validar certificados SSL'), findsOneWidget);
    expect(find.text('Tamanho do texto'), findsOneWidget);
    expect(find.text('Densidade compacta'), findsOneWidget);

    await tester.tap(find.text('Densidade compacta'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('language-dropdown')));
    await tester.tap(find.byKey(const ValueKey('language-dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(settingsStore.settings.compactDensity, isTrue);
    expect(settingsStore.settings.languageCode, 'en');
    expect(container.read(appSettingsProvider).settings.compactDensity, isTrue);
    expect(find.text('Response'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
  });
}
