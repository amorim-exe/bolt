import 'package:bolt/features/history/data/datasources/request_history_datasource.dart';
import 'package:bolt/features/history/data/models/request_history_entity.dart';
import 'package:bolt/features/history/presentation/history_provider.dart';
import 'package:bolt/features/http_client/presentation/controllers/request_tabs_provider.dart';
import 'package:bolt/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _EmptyHistoryDatasource extends RequestHistoryDatasource {
  @override
  Future<List<RequestHistoryEntity>> getLatest({int limit = 100}) async => [];
}

void main() {
  testWidgets('home shows request tabs and code generation', (tester) async {
    tester.view.physicalSize = const Size(1300, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(
      overrides: [
        requestHistoryDatasourceProvider
            .overrideWithValue(_EmptyHistoryDatasource()),
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
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Response'), findsOneWidget);
    expect(find.text('Params'), findsOneWidget);

    await tester.tap(find.byTooltip('Nova aba'));
    await tester.pumpAndSettle();
    expect(container.read(requestTabsProvider).tabs, hasLength(2));

    await tester.tap(find.byTooltip('Generate Code'));
    await tester.pumpAndSettle();
    expect(find.text('Generate Code'), findsOneWidget);
    expect(find.text('cURL'), findsOneWidget);
    expect(find.text('JavaScript (Fetch)'), findsOneWidget);
    expect(find.text('Python (Requests)'), findsOneWidget);
    expect(find.text('Dart (Dio)'), findsOneWidget);

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Auth'));
    await tester.pumpAndSettle();
    expect(find.text('Authentication type'), findsOneWidget);
    expect(
      find.text('Esta requisição será enviada sem autenticação.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Tests').first);
    await tester.pumpAndSettle();
    expect(find.text('Assertions após a resposta'), findsOneWidget);

    await tester.tap(find.text('Tests').last);
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Sem testes executados. Adicione assertions na aba Tests e envie a requisição.',
      ),
      findsOneWidget,
    );
  });
}
