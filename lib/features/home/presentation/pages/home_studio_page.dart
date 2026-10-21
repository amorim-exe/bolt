import 'dart:convert';
import 'dart:typed_data';

import 'package:bolt/core/constants/app_colors.dart';
import 'package:bolt/core/localization/app_localizations.dart';
import 'package:bolt/core/settings/app_settings.dart';
import 'package:bolt/features/environment/presentation/environment_dialog.dart';
import 'package:bolt/features/environment/presentation/environment_comparison_dialog.dart';
import 'package:bolt/features/history/data/models/request_history_entity.dart';
import 'package:bolt/features/history/presentation/history_provider.dart';
import 'package:bolt/features/http_client/domain/models/request_params.dart';
import 'package:bolt/features/http_client/domain/models/request_params_codec.dart';
import 'package:bolt/features/http_client/domain/models/response_result.dart';
import 'package:bolt/features/http_client/presentation/controllers/http_client_provider.dart';
import 'package:bolt/features/http_client/presentation/controllers/request_tabs_provider.dart';
import 'package:bolt/features/http_client/presentation/widgets/auth_editor_view.dart';
import 'package:bolt/features/http_client/presentation/widgets/code_editor_widget.dart';
import 'package:bolt/features/http_client/presentation/widgets/code_generation_dialog.dart';
import 'package:bolt/features/http_client/presentation/widgets/headers_editor_view.dart';
import 'package:bolt/features/http_client/presentation/widgets/params_editor_view.dart';
import 'package:bolt/features/settings/presentation/settings_dialog.dart';
import 'package:bolt/features/workspace/data/models/request_entity.dart';
import 'package:bolt/features/workspace/data/models/workspace_entity.dart';
import 'package:bolt/features/workspace/data/services/collection_transfer_service.dart';
import 'package:bolt/features/workspace/presentation/workspace_provider.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart' show ValueListenable, ValueNotifier;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeStudioPage extends ConsumerStatefulWidget {
  const HomeStudioPage({super.key});

  @override
  ConsumerState<HomeStudioPage> createState() => _HomeStudioPageState();
}

class _HomeStudioPageState extends ConsumerState<HomeStudioPage>
    with TickerProviderStateMixin {
  late final TextEditingController _urlController;
  late final TabController _requestController;
  late final TabController _responseController;
  bool _showHistory = false;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(
      text: ref.read(httpClientProvider).params.url,
    );
    _requestController = TabController(length: 5, vsync: this);
    _responseController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _urlController.dispose();
    _requestController.dispose();
    _responseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final http = ref.watch(httpClientProvider);
    final tabs = ref.watch(requestTabsProvider);
    final workspaces = ref.watch(workspaceProvider);
    final history = ref.watch(requestHistoryProvider);
    final settings = ref.watch(appSettingsProvider).settings;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final canvas = dark ? const Color(0xFF101116) : const Color(0xFFF2F3F7);
    final panel = dark ? const Color(0xFF191A22) : Colors.white;
    final elevated = dark ? const Color(0xFF20212B) : const Color(0xFFF9FAFC);
    final border = dark ? const Color(0xFF2D2E3A) : const Color(0xFFE5E7EF);
    final ink = dark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final muted =
        dark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Scaffold(
      backgroundColor: canvas,
      body: SafeArea(
        child: Row(
          children: [
            _StudioRail(
              historySelected: _showHistory,
              languageCode: settings.languageCode,
              onCollections: () => setState(() => _showHistory = false),
              onHistory: () => setState(() => _showHistory = true),
              onSettings: () => showDialog<void>(
                context: context,
                builder: (_) => const SettingsDialog(),
              ),
              onEnvironment: () => showDialog<void>(
                context: context,
                builder: (_) => const EnvironmentDialog(),
              ),
              onToggleTheme: () => _toggleTheme(dark),
              onToggleLanguage: () => _toggleLanguage(settings.languageCode),
            ),
            SizedBox(
              width: 278,
              child: _CollectionSidebar(
                panelColor: panel,
                elevatedColor: elevated,
                borderColor: border,
                inkColor: ink,
                mutedColor: muted,
                historyMode: _showHistory,
                workspaceState: workspaces,
                historyState: history,
                onHistoryMode: (value) => setState(() => _showHistory = value),
                onCreateWorkspace: _createWorkspace,
                onCreateRequest: _createRequest,
                onImport: () =>
                    _importCollection(workspaces.selectedWorkspace?.id),
                onExport: () => _exportCollection(workspaces.selectedWorkspace),
                onSelectWorkspace: (id) =>
                    ref.read(workspaceProvider.notifier).selectWorkspace(id),
                onToggleWorkspace: (id) => ref
                    .read(workspaceProvider.notifier)
                    .toggleWorkspaceExpanded(id),
                onOpenRequest: _openSavedRequest,
                onRenameWorkspace: _renameWorkspace,
                onDeleteWorkspace: _deleteWorkspace,
                onRenameRequest: _renameRequest,
                onOpenHistory: _openHistoryEntry,
                onDeleteHistory: () =>
                    ref.read(requestHistoryProvider.notifier).clear(),
                onDeleteRequest: (id) =>
                    ref.read(workspaceProvider.notifier).deleteRequest(id),
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  _StudioTopBar(
                    panelColor: panel,
                    borderColor: border,
                    inkColor: ink,
                    mutedColor: muted,
                    workspaceName:
                        workspaces.selectedWorkspace?.name ?? 'Workspace',
                    requestTabs: tabs,
                    onOpenTab: _openTab,
                    onSelectTab: _selectTab,
                    onCloseTab: _closeTab,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                      child: Column(
                        children: [
                          _RequestCommandBar(
                            params: http.params,
                            urlController: _urlController,
                            panelColor: panel,
                            elevatedColor: elevated,
                            borderColor: border,
                            inkColor: ink,
                            isLoading: http.isLoading,
                            onMethod: ref
                                .read(httpClientProvider.notifier)
                                .updateMethod,
                            onUrlChanged:
                                ref.read(httpClientProvider.notifier).updateUrl,
                            onSend: _sendRequest,
                            onCode: () => showDialog<void>(
                              context: context,
                              builder: (_) =>
                                  CodeGenerationDialog(params: http.params),
                            ),
                            onCompare: () => showDialog<void>(
                              context: context,
                              builder: (_) =>
                                  const EnvironmentComparisonDialog(),
                            ),
                            onSave: _saveRequest,
                          ),
                          const SizedBox(height: 14),
                          Expanded(
                            child: _ResizableResponseSplit(
                              key: const ValueKey('response-resize-split'),
                              borderColor: border,
                              editor: _RequestEditor(
                                controller: _requestController,
                                params: http.params,
                                activeTabId: tabs.activeTabId,
                                dark: dark,
                                panelColor: panel,
                                borderColor: border,
                                mutedColor: muted,
                                onBodyChanged: ref
                                    .read(httpClientProvider.notifier)
                                    .updateBody,
                                onBodyModeChanged: ref
                                    .read(httpClientProvider.notifier)
                                    .updateBodyMode,
                                onTestsChanged: ref
                                    .read(httpClientProvider.notifier)
                                    .updateTestScript,
                              ),
                              response: _ResponseStudio(
                                controller: _responseController,
                                response: http.response,
                                isLoading: http.isLoading,
                                dark: dark,
                                panelColor: panel,
                                borderColor: border,
                                inkColor: ink,
                                mutedColor: muted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleTheme(bool dark) async {
    final settings = ref.read(appSettingsProvider).settings;
    try {
      await ref.read(appSettingsProvider.notifier).save(
            settings.copyWith(
              themeMode: dark ? ThemeMode.light : ThemeMode.dark,
            ),
          );
    } catch (error) {
      if (mounted) {
        _showMessage(context.tr(
          'Could not update theme: $error',
          'Não foi possível atualizar o tema: $error',
        ));
      }
    }
  }

  Future<void> _toggleLanguage(String currentLanguage) async {
    final settings = ref.read(appSettingsProvider).settings;
    try {
      await ref.read(appSettingsProvider.notifier).save(
            settings.copyWith(
              languageCode: currentLanguage == 'en' ? 'pt_BR' : 'en',
            ),
          );
    } catch (error) {
      if (mounted) {
        _showMessage(context.tr(
          'Could not change language: $error',
          'Não foi possível alterar o idioma: $error',
        ));
      }
    }
  }

  void _openTab() {
    ref.read(httpClientProvider.notifier).openTab();
    _syncUrl();
  }

  void _selectTab(int id) {
    ref.read(httpClientProvider.notifier).selectTab(id);
    _syncUrl();
  }

  void _closeTab(int id) {
    ref.read(httpClientProvider.notifier).closeTab(id);
    _syncUrl();
  }

  void _syncUrl() {
    final url = ref.read(httpClientProvider).params.url;
    _urlController.value = TextEditingValue(
      text: url,
      selection: TextSelection.collapsed(offset: url.length),
    );
    setState(() {});
  }

  Future<void> _sendRequest() async {
    try {
      await ref.read(httpClientProvider.notifier).sendRequest();
    } catch (error) {
      if (!mounted) return;
      _showMessage(context.tr(
        'Request failed: $error',
        'A requisição falhou: $error',
      ));
    }
  }

  Future<void> _saveRequest() async {
    final workspace = ref.read(workspaceProvider).selectedWorkspace;
    if (workspace == null) {
      _showMessage(context.tr(
        'Choose a collection before saving this request.',
        'Selecione uma collection antes de salvar a requisição.',
      ));
      return;
    }
    try {
      final params = ref.read(httpClientProvider).params;
      final tab = ref.read(requestTabsProvider).activeTab;
      final segments = Uri.tryParse(params.url)?.pathSegments ?? const [];
      final name = tab.name == 'New Request'
          ? (segments.isEmpty ? 'Request' : segments.last)
          : tab.name;
      final saved = await ref.read(workspaceProvider.notifier).saveRequest(
            id: tab.savedRequestId,
            name: name.isEmpty ? 'Request' : name,
            url: params.url,
            method: params.method.name,
            headersJson: jsonEncode([
              for (final item in params.headers)
                {
                  'key': item.key,
                  'value': item.value,
                  'isEnabled': item.isEnabled,
                }
            ]),
            queryParamsJson: jsonEncode([
              for (final item in params.queryParams)
                {
                  'key': item.key,
                  'value': item.value,
                  'isEnabled': item.isEnabled,
                  'isAutoDetected': item.isAutoDetected,
                }
            ]),
            body: RequestParamsCodec.encodeBody(params),
          );
      if (saved == null || !mounted) return;
      ref.read(httpClientProvider.notifier).setTabMetadata(
            name: saved.name,
            savedRequestId: saved.id,
          );
      _showMessage(context.tr('Request saved', 'Requisição salva'));
    } catch (error) {
      if (mounted) {
        _showMessage(context.tr(
          'Could not save request: $error',
          'Não foi possível salvar a request: $error',
        ));
      }
    }
  }

  Future<void> _createWorkspace() async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _NamePromptDialog(
        title: context.tr('New collection', 'Nova collection'),
        submitLabel: context.tr('Create', 'Criar'),
      ),
    );
    if (name == null || name.isEmpty) return;
    try {
      await ref.read(workspaceProvider.notifier).createWorkspace(name);
    } catch (error) {
      if (mounted) {
        _showMessage(context.tr(
          'Could not create collection: $error',
          'Não foi possível criar a collection: $error',
        ));
      }
    }
  }

  Future<void> _createRequest() async {
    final state = ref.read(httpClientProvider);
    ref.read(httpClientProvider.notifier).openTab(
          params: RequestParams(
            url: state.params.url,
            method: HttpMethod.get,
          ),
        );
    _syncUrl();
  }

  Future<void> _renameWorkspace(WorkspaceEntity workspace) async {
    final name = await _askForName(
      title: context.tr('Rename collection', 'Renomear collection'),
      initialValue: workspace.name,
    );
    if (name == null || name.isEmpty) return;
    try {
      await ref.read(workspaceProvider.notifier).renameWorkspace(
            workspace.id,
            name,
          );
    } catch (error) {
      if (mounted) {
        _showMessage(context.tr(
          'Could not rename collection: $error',
          'Não foi possível renomear a collection: $error',
        ));
      }
    }
  }

  Future<void> _deleteWorkspace(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('Delete collection?', 'Excluir collection?')),
        content: Text(context.tr(
          'This also deletes its saved requests.',
          'Isso também excluirá as requests salvas nela.',
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('Cancel', 'Cancelar')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.tr('Delete', 'Excluir')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(workspaceProvider.notifier).deleteWorkspace(id);
    } catch (error) {
      if (mounted) {
        _showMessage(context.tr(
          'Could not delete collection: $error',
          'Não foi possível excluir a collection: $error',
        ));
      }
    }
  }

  Future<void> _renameRequest(RequestEntity request) async {
    final name = await _askForName(
      title: context.tr('Rename request', 'Renomear request'),
      initialValue: request.name,
    );
    if (name == null || name.isEmpty) return;
    try {
      await ref.read(workspaceProvider.notifier).renameRequest(
            request.id,
            name,
          );
    } catch (error) {
      if (mounted) {
        _showMessage(context.tr(
          'Could not rename request: $error',
          'Não foi possível renomear a request: $error',
        ));
      }
    }
  }

  Future<String?> _askForName({
    required String title,
    String initialValue = '',
  }) async {
    return showDialog<String>(
      context: context,
      builder: (_) => _NamePromptDialog(
        title: title,
        initialValue: initialValue,
        submitLabel: context.tr('Save', 'Salvar'),
      ),
    );
  }

  void _openSavedRequest(RequestEntity request) {
    final method = HttpMethod.values.firstWhere(
      (item) => item.name.toUpperCase() == request.method.toUpperCase(),
      orElse: () => HttpMethod.get,
    );
    final body = RequestParamsCodec.decodeBody(request.body);
    final params = RequestParams(
      url: request.url,
      method: method,
      headers: _decodeItems(
          request.headersJson,
          (item) => HeaderItem(
                key: item['key']?.toString() ?? '',
                value: item['value']?.toString() ?? '',
                isEnabled: item['isEnabled'] != false,
              )),
      queryParams: _decodeItems(
        request.queryParamsJson,
        (item) => QueryParamItem(
          key: item['key']?.toString() ?? '',
          value: item['value']?.toString() ?? '',
          isEnabled: item['isEnabled'] != false,
          isAutoDetected: item['isAutoDetected'] == true,
        ),
      ),
      body: body.text,
      bodyMode: body.mode,
      formFields: body.fields,
      auth: body.auth,
      testScript: body.testScript,
    );
    ref.read(httpClientProvider.notifier).openTab(
          params: params,
          name: request.name,
          savedRequestId: request.id,
        );
    _syncUrl();
  }

  void _openHistoryEntry(RequestHistoryEntity entry) {
    final method = HttpMethod.values.firstWhere(
      (item) => item.name.toUpperCase() == entry.method.toUpperCase(),
      orElse: () => HttpMethod.get,
    );
    final body = RequestParamsCodec.decodeBody(entry.body);
    ref.read(httpClientProvider.notifier).openTab(
          name: '${entry.method.toUpperCase()} · ${entry.url}',
          params: RequestParams(
            url: entry.url,
            method: method,
            headers: _decodeItems(
                entry.headersJson,
                (item) => HeaderItem(
                      key: item['key']?.toString() ?? '',
                      value: item['value']?.toString() ?? '',
                      isEnabled: item['isEnabled'] != false,
                    )),
            queryParams: _decodeItems(
              entry.queryParamsJson,
              (item) => QueryParamItem(
                key: item['key']?.toString() ?? '',
                value: item['value']?.toString() ?? '',
                isEnabled: item['isEnabled'] != false,
                isAutoDetected: item['isAutoDetected'] == true,
              ),
            ),
            body: body.text,
            bodyMode: body.mode,
            formFields: body.fields,
            auth: body.auth,
            testScript: body.testScript,
          ),
        );
    _syncUrl();
  }

  List<T> _decodeItems<T>(
    String source,
    T Function(Map<String, dynamic>) create,
  ) {
    try {
      final decoded = jsonDecode(source);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((item) => create(Map<String, dynamic>.from(item)))
            .toList();
      }
    } on FormatException {
      return [];
    }
    return [];
  }

  Future<void> _importCollection(int? workspaceId) async {
    if (workspaceId == null) {
      _showMessage(context.tr(
          'Create a collection first.', 'Crie uma collection primeiro.'));
      return;
    }
    final file = await openFile(
      acceptedTypeGroups: [
        const XTypeGroup(
          label: 'Postman, OpenAPI or Bruno',
          extensions: ['json', 'yaml', 'yml', 'bru'],
        ),
      ],
    );
    if (file == null) return;
    try {
      final count = await CollectionTransferService.importCollection(
        source: file.name,
        workspaceId: workspaceId,
        content: await file.readAsString(),
      );
      await ref.read(workspaceProvider.notifier).selectWorkspace(workspaceId);
      if (mounted) {
        _showMessage(context.tr(
          '$count requests imported.',
          '$count requests importadas.',
        ));
      }
    } catch (error) {
      if (mounted) {
        _showMessage(context.tr(
          'Could not import collection: $error',
          'Não foi possível importar a collection: $error',
        ));
      }
    }
  }

  Future<void> _exportCollection(WorkspaceEntity? workspace) async {
    if (workspace == null) {
      _showMessage(context.tr(
        'Select a collection before exporting.',
        'Selecione uma collection antes de exportar.',
      ));
      return;
    }
    final location = await getSaveLocation(
      suggestedName: '${workspace.name}.postman_collection.json',
      acceptedTypeGroups: [
        const XTypeGroup(label: 'JSON', extensions: ['json']),
      ],
    );
    if (location == null) return;
    try {
      final content =
          await CollectionTransferService.exportPostmanCollection(workspace);
      await XFile.fromData(
        utf8.encode(content),
        mimeType: 'application/json',
        name: location.path.split('/').last,
      ).saveTo(location.path);
      if (mounted) {
        _showMessage(context.tr(
          'Collection exported.',
          'Collection exportada.',
        ));
      }
    } catch (error) {
      if (mounted) {
        _showMessage(context.tr(
          'Could not export collection: $error',
          'Não foi possível exportar a collection: $error',
        ));
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _StudioRail extends StatelessWidget {
  const _StudioRail({
    required this.historySelected,
    required this.languageCode,
    required this.onCollections,
    required this.onHistory,
    required this.onSettings,
    required this.onEnvironment,
    required this.onToggleTheme,
    required this.onToggleLanguage,
  });

  final bool historySelected;
  final String languageCode;
  final VoidCallback onCollections;
  final VoidCallback onHistory;
  final VoidCallback onSettings;
  final VoidCallback onEnvironment;
  final VoidCallback onToggleTheme;
  final VoidCallback onToggleLanguage;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final railColor = dark ? const Color(0xFF15161D) : const Color(0xFFE9EAF0);
    return Container(
      width: 66,
      color: railColor,
      child: Column(
        children: [
          const SizedBox(height: 16),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF9B76FF), Color(0xFF6840D8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(13),
            ),
            child:
                const Icon(Icons.bolt_rounded, color: Colors.white, size: 25),
          ),
          const SizedBox(height: 28),
          _RailButton(
            icon: Icons.layers_rounded,
            tooltip: context.tr('Collections', 'Collections'),
            selected: !historySelected,
            onTap: onCollections,
          ),
          const SizedBox(height: 8),
          _RailButton(
            icon: Icons.history_rounded,
            tooltip: context.tr('History', 'Histórico'),
            selected: historySelected,
            onTap: onHistory,
          ),
          const Spacer(),
          _RailButton(
            icon: Icons.tune_rounded,
            tooltip: context.tr('Environment', 'Ambiente'),
            onTap: onEnvironment,
          ),
          _RailButton(
            icon: dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            tooltip: context.tr('Toggle theme', 'Alternar tema'),
            onTap: onToggleTheme,
          ),
          _RailButton(
            icon: Icons.settings_outlined,
            tooltip: context.tr('Settings', 'Configurações'),
            onTap: onSettings,
          ),
          const SizedBox(height: 8),
          _LanguageToggle(
            languageCode: languageCode,
            onTap: onToggleLanguage,
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }
}

class _RailButton extends StatelessWidget {
  const _RailButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 20,
              color: selected ? AppColors.primary : null,
            ),
          ),
        ),
      );
}

class _LanguageToggle extends StatelessWidget {
  const _LanguageToggle({
    required this.languageCode,
    required this.onTap,
  });

  final String languageCode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isEnglish = languageCode == 'en';
    return Tooltip(
      message: context.tr('Switch language', 'Alternar idioma'),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const ValueKey('language-toggle'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(9),
          child: Container(
            width: 50,
            height: 28,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF252631)
                  : const Color(0xFFE2E3EA),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Row(
              children: [
                _LanguageOption(label: 'PT', selected: !isEnglish),
                _LanguageOption(label: 'EN', selected: isEnglish),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.label,
    required this.selected,
  });

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) => Expanded(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : null,
              fontSize: 8,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
        ),
      );
}

class _CollectionSidebar extends StatelessWidget {
  const _CollectionSidebar({
    required this.panelColor,
    required this.elevatedColor,
    required this.borderColor,
    required this.inkColor,
    required this.mutedColor,
    required this.historyMode,
    required this.workspaceState,
    required this.historyState,
    required this.onHistoryMode,
    required this.onCreateWorkspace,
    required this.onCreateRequest,
    required this.onImport,
    required this.onExport,
    required this.onSelectWorkspace,
    required this.onToggleWorkspace,
    required this.onOpenRequest,
    required this.onRenameWorkspace,
    required this.onDeleteWorkspace,
    required this.onRenameRequest,
    required this.onOpenHistory,
    required this.onDeleteHistory,
    required this.onDeleteRequest,
  });

  final Color panelColor;
  final Color elevatedColor;
  final Color borderColor;
  final Color inkColor;
  final Color mutedColor;
  final bool historyMode;
  final WorkspaceState workspaceState;
  final AsyncValue<List<RequestHistoryEntity>> historyState;
  final ValueChanged<bool> onHistoryMode;
  final VoidCallback onCreateWorkspace;
  final VoidCallback onCreateRequest;
  final VoidCallback onImport;
  final VoidCallback onExport;
  final ValueChanged<int> onSelectWorkspace;
  final ValueChanged<int> onToggleWorkspace;
  final ValueChanged<RequestEntity> onOpenRequest;
  final ValueChanged<WorkspaceEntity> onRenameWorkspace;
  final ValueChanged<int> onDeleteWorkspace;
  final ValueChanged<RequestEntity> onRenameRequest;
  final ValueChanged<RequestHistoryEntity> onOpenHistory;
  final VoidCallback onDeleteHistory;
  final ValueChanged<int> onDeleteRequest;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: panelColor,
        border: Border(right: BorderSide(color: borderColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 21, 14, 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('API WORKSPACE', 'ESPAÇO DE API'),
                        style: TextStyle(
                          color: mutedColor,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.tr('Explorer', 'Explorer'),
                        style: TextStyle(
                          color: inkColor,
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                _MiniAction(
                  icon: Icons.add,
                  tooltip: context.tr('New collection', 'Nova collection'),
                  onTap: onCreateWorkspace,
                ),
                _MiniAction(
                  icon: Icons.more_horiz,
                  tooltip:
                      context.tr('Import or export', 'Importar ou exportar'),
                  onTap: () => showMenu<void>(
                    context: context,
                    position: const RelativeRect.fromLTRB(280, 54, 0, 0),
                    items: [
                      PopupMenuItem<void>(
                        onTap: onImport,
                        child: Text(context.tr(
                            'Import collection', 'Importar collection')),
                      ),
                      PopupMenuItem<void>(
                        onTap: onExport,
                        child: Text(context.tr(
                            'Export collection', 'Exportar collection')),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Container(
              height: 34,
              decoration: BoxDecoration(
                color: elevatedColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  _ModeChip(
                    label: context.tr('Collections', 'Collections'),
                    selected: !historyMode,
                    onTap: () => onHistoryMode(false),
                  ),
                  _ModeChip(
                    label: context.tr('History', 'Histórico'),
                    selected: historyMode,
                    onTap: () => onHistoryMode(true),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 13),
          Expanded(
            child: historyMode
                ? _HistoryList(
                    historyState: historyState,
                    inkColor: inkColor,
                    mutedColor: mutedColor,
                    onOpen: onOpenHistory,
                    onClear: onDeleteHistory,
                  )
                : _WorkspaceList(
                    state: workspaceState,
                    inkColor: inkColor,
                    mutedColor: mutedColor,
                    onSelect: onSelectWorkspace,
                    onToggle: onToggleWorkspace,
                    onOpenRequest: onOpenRequest,
                    onRenameWorkspace: onRenameWorkspace,
                    onDeleteWorkspace: onDeleteWorkspace,
                    onRenameRequest: onRenameRequest,
                    onCreateRequest: onCreateRequest,
                    onDeleteRequest: onDeleteRequest,
                  ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: borderColor)),
            ),
            child: Row(
              children: [
                Icon(Icons.cloud_done_outlined,
                    size: 16, color: AppColors.accent),
                const SizedBox(width: 8),
                Text(
                  context.tr('Local workspace', 'Workspace local'),
                  style: TextStyle(color: mutedColor, fontSize: 11),
                ),
                const Spacer(),
                Text(
                  'BETA',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniAction extends StatelessWidget {
  const _MiniAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: tooltip,
        visualDensity: VisualDensity.compact,
        onPressed: onTap,
        icon: Icon(icon, size: 18),
      );
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            alignment: Alignment.center,
            margin: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : null,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 11,
              ),
            ),
          ),
        ),
      );
}

class _WorkspaceList extends StatelessWidget {
  const _WorkspaceList({
    required this.state,
    required this.inkColor,
    required this.mutedColor,
    required this.onSelect,
    required this.onToggle,
    required this.onOpenRequest,
    required this.onRenameWorkspace,
    required this.onDeleteWorkspace,
    required this.onRenameRequest,
    required this.onCreateRequest,
    required this.onDeleteRequest,
  });

  final WorkspaceState state;
  final Color inkColor;
  final Color mutedColor;
  final ValueChanged<int> onSelect;
  final ValueChanged<int> onToggle;
  final ValueChanged<RequestEntity> onOpenRequest;
  final ValueChanged<WorkspaceEntity> onRenameWorkspace;
  final ValueChanged<int> onDeleteWorkspace;
  final ValueChanged<RequestEntity> onRenameRequest;
  final VoidCallback onCreateRequest;
  final ValueChanged<int> onDeleteRequest;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.workspaces.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            context.tr('Create a collection to get started.',
                'Crie uma collection para começar.'),
            textAlign: TextAlign.center,
            style: TextStyle(color: mutedColor),
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 14),
      children: [
        for (final workspace in state.workspaces) ...[
          Material(
            color: Colors.transparent,
            child: ListTile(
              dense: true,
              visualDensity: VisualDensity.compact,
              contentPadding: const EdgeInsets.symmetric(horizontal: 9),
              leading: IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () => onToggle(workspace.id),
                icon: Icon(
                  state.expandedWorkspaces.contains(workspace.id)
                      ? Icons.keyboard_arrow_down
                      : Icons.chevron_right,
                  size: 18,
                ),
              ),
              title: Text(
                workspace.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: inkColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: context.tr(
                        'Select collection', 'Selecionar collection'),
                    onPressed: () => onSelect(workspace.id),
                    icon: Icon(
                      state.selectedWorkspace?.id == workspace.id
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      size: 16,
                      color: state.selectedWorkspace?.id == workspace.id
                          ? AppColors.primary
                          : mutedColor,
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip:
                        context.tr('Collection actions', 'Ações da collection'),
                    onSelected: (action) {
                      if (action == 'rename') {
                        onRenameWorkspace(workspace);
                      } else {
                        onDeleteWorkspace(workspace.id);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'rename',
                        child: Text(context.tr('Rename', 'Renomear')),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(context.tr('Delete', 'Excluir')),
                      ),
                    ],
                    icon: const Icon(Icons.more_vert, size: 17),
                  ),
                ],
              ),
              onTap: () => onSelect(workspace.id),
            ),
          ),
          if (state.expandedWorkspaces.contains(workspace.id))
            for (final request
                in state.workspaceRequests[workspace.id] ?? const [])
              Padding(
                padding: const EdgeInsets.only(left: 25),
                child: Material(
                  color: Colors.transparent,
                  child: ListTile(
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    leading: Text(
                      request.method.toUpperCase(),
                      style: TextStyle(
                        color: _methodColor(request.method),
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    title: Text(
                      request.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: inkColor, fontSize: 12),
                    ),
                    trailing: PopupMenuButton<String>(
                      tooltip:
                          context.tr('Request actions', 'Ações da request'),
                      onSelected: (action) {
                        if (action == 'rename') {
                          onRenameRequest(request);
                        } else {
                          onDeleteRequest(request.id);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'rename',
                          child: Text(context.tr('Rename', 'Renomear')),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text(context.tr('Delete', 'Excluir')),
                        ),
                      ],
                      icon: const Icon(Icons.more_horiz, size: 16),
                    ),
                    onTap: () => onOpenRequest(request),
                  ),
                ),
              ),
        ],
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: onCreateRequest,
          icon: const Icon(Icons.add, size: 15),
          label: Text(context.tr('New request', 'Nova request')),
        ),
      ],
    );
  }

  Color _methodColor(String method) {
    switch (method.toUpperCase()) {
      case 'POST':
        return AppColors.primary;
      case 'PUT':
      case 'PATCH':
        return Colors.orange;
      case 'DELETE':
        return AppColors.error;
      default:
        return AppColors.accent;
    }
  }
}

class _HistoryList extends StatelessWidget {
  const _HistoryList({
    required this.historyState,
    required this.inkColor,
    required this.mutedColor,
    required this.onOpen,
    required this.onClear,
  });

  final AsyncValue<List<RequestHistoryEntity>> historyState;
  final Color inkColor;
  final Color mutedColor;
  final ValueChanged<RequestHistoryEntity> onOpen;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => historyState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              context.tr('Could not load history: $error',
                  'Não foi possível carregar o histórico: $error'),
              style: TextStyle(color: mutedColor),
            ),
          ),
        ),
        data: (entries) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      context.tr('LATEST', 'RECENTES'),
                      style: TextStyle(
                        color: mutedColor,
                        letterSpacing: 1.2,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: context.tr('Clear history', 'Limpar histórico'),
                    onPressed: entries.isEmpty ? null : onClear,
                    icon: const Icon(Icons.delete_sweep_outlined, size: 17),
                  ),
                ],
              ),
            ),
            Expanded(
              child: entries.isEmpty
                  ? Center(
                      child: Text(
                        context.tr(
                            'No requests yet.', 'Ainda não há requests.'),
                        style: TextStyle(color: mutedColor),
                      ),
                    )
                  : ListView.builder(
                      itemCount: entries.length,
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        return Material(
                          color: Colors.transparent,
                          child: ListTile(
                            dense: true,
                            leading: Text(
                              entry.method.toUpperCase(),
                              style: TextStyle(
                                color: _methodColor(entry.method),
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            title: Text(
                              entry.url,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: inkColor, fontSize: 11),
                            ),
                            subtitle: Text(
                              '${entry.statusCode ?? '-'} · ${entry.timestamp.toLocal()}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: mutedColor, fontSize: 9),
                            ),
                            onTap: () => onOpen(entry),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      );

  Color _methodColor(String method) {
    switch (method.toUpperCase()) {
      case 'POST':
        return AppColors.primary;
      case 'PUT':
      case 'PATCH':
        return Colors.orange;
      case 'DELETE':
        return AppColors.error;
      default:
        return AppColors.accent;
    }
  }
}

class _StudioTopBar extends StatelessWidget {
  const _StudioTopBar({
    required this.panelColor,
    required this.borderColor,
    required this.inkColor,
    required this.mutedColor,
    required this.workspaceName,
    required this.requestTabs,
    required this.onOpenTab,
    required this.onSelectTab,
    required this.onCloseTab,
  });

  final Color panelColor;
  final Color borderColor;
  final Color inkColor;
  final Color mutedColor;
  final String workspaceName;
  final RequestTabsState requestTabs;
  final VoidCallback onOpenTab;
  final ValueChanged<int> onSelectTab;
  final ValueChanged<int> onCloseTab;

  @override
  Widget build(BuildContext context) => Container(
        height: 66,
        decoration: BoxDecoration(
          color: panelColor,
          border: Border(bottom: BorderSide(color: borderColor)),
        ),
        child: Row(
          children: [
            const SizedBox(width: 21),
            Icon(Icons.grid_view_rounded, size: 15, color: mutedColor),
            const SizedBox(width: 9),
            Text(
              workspaceName,
              style: TextStyle(
                color: inkColor,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            Icon(Icons.chevron_right, color: mutedColor, size: 16),
            Text(
              context.tr('Requests', 'Requests'),
              style: TextStyle(color: mutedColor, fontSize: 12),
            ),
            const SizedBox(width: 22),
            Container(width: 1, height: 24, color: borderColor),
            const SizedBox(width: 10),
            Expanded(
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: requestTabs.tabs.length,
                separatorBuilder: (_, __) => const SizedBox(width: 3),
                itemBuilder: (context, index) {
                  final tab = requestTabs.tabs[index];
                  final active = requestTabs.activeTabId == tab.id;
                  final path = Uri.tryParse(tab.params.url)?.pathSegments;
                  final label = tab.name == 'New Request'
                      ? (path != null && path.isNotEmpty
                          ? path.last
                          : context.tr('New request', 'Nova request'))
                      : tab.name;
                  return InkWell(
                    onTap: () => onSelectTab(tab.id),
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 190),
                      padding: const EdgeInsets.only(left: 11, right: 5),
                      decoration: BoxDecoration(
                        color: active
                            ? (Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF242530)
                                : const Color(0xFFF1F0FA))
                            : Colors.transparent,
                        border: Border(
                          bottom: BorderSide(
                            color:
                                active ? AppColors.primary : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            tab.params.method.name.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: _methodColor(tab.params.method),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: inkColor, fontSize: 11),
                            ),
                          ),
                          IconButton(
                            tooltip: context.tr('Close tab', 'Fechar aba'),
                            visualDensity: VisualDensity.compact,
                            onPressed: () => onCloseTab(tab.id),
                            icon:
                                Icon(Icons.close, size: 13, color: mutedColor),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            IconButton(
              tooltip: context.tr('New request tab', 'Nova aba de request'),
              onPressed: onOpenTab,
              icon: const Icon(Icons.add, size: 18),
            ),
            const SizedBox(width: 9),
          ],
        ),
      );

  Color _methodColor(HttpMethod method) {
    switch (method) {
      case HttpMethod.post:
        return AppColors.primary;
      case HttpMethod.put:
      case HttpMethod.patch:
        return Colors.orange;
      case HttpMethod.delete:
        return AppColors.error;
      default:
        return AppColors.accent;
    }
  }
}

class _RequestCommandBar extends StatelessWidget {
  const _RequestCommandBar({
    required this.params,
    required this.urlController,
    required this.panelColor,
    required this.elevatedColor,
    required this.borderColor,
    required this.inkColor,
    required this.isLoading,
    required this.onMethod,
    required this.onUrlChanged,
    required this.onSend,
    required this.onCode,
    required this.onCompare,
    required this.onSave,
  });

  final RequestParams params;
  final TextEditingController urlController;
  final Color panelColor;
  final Color elevatedColor;
  final Color borderColor;
  final Color inkColor;
  final bool isLoading;
  final ValueChanged<HttpMethod> onMethod;
  final ValueChanged<String> onUrlChanged;
  final VoidCallback onSend;
  final VoidCallback onCode;
  final VoidCallback onCompare;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: panelColor,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: elevatedColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<HttpMethod>(
                  value: params.method,
                  items: [
                    for (final method in HttpMethod.values)
                      DropdownMenuItem(
                        value: method,
                        child: Text(
                          method.name.toUpperCase(),
                          style: TextStyle(
                            color: _methodColor(method),
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                      ),
                  ],
                  onChanged: (method) {
                    if (method != null) onMethod(method);
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: urlController,
                onChanged: onUrlChanged,
                style: TextStyle(color: inkColor, fontSize: 13),
                decoration: InputDecoration(
                  hintText: context.tr(
                    'Paste a URL or use {{variables}}',
                    'Cole uma URL ou use {{variáveis}}',
                  ),
                  prefixIcon: const Icon(Icons.link_rounded, size: 18),
                  filled: true,
                  fillColor: elevatedColor,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: isLoading ? null : onSend,
              icon: isLoading
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.play_arrow_rounded, size: 18),
              label: Text(context.tr('Send', 'Enviar')),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 17, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              tooltip: context.tr('Generate code', 'Gerar código'),
              onPressed: onCode,
              icon: const Icon(Icons.code_rounded, size: 19),
            ),
            IconButton(
              tooltip: context.tr(
                'Compare environments',
                'Comparar ambientes',
              ),
              onPressed: onCompare,
              icon: const Icon(Icons.compare_arrows_rounded, size: 19),
            ),
            IconButton(
              tooltip: context.tr('Save request', 'Salvar request'),
              onPressed: onSave,
              icon: const Icon(Icons.bookmark_add_outlined, size: 19),
            ),
          ],
        ),
      );

  Color _methodColor(HttpMethod method) {
    switch (method) {
      case HttpMethod.post:
        return AppColors.primary;
      case HttpMethod.put:
      case HttpMethod.patch:
        return Colors.orange;
      case HttpMethod.delete:
        return AppColors.error;
      default:
        return AppColors.accent;
    }
  }
}

class _ResizableResponseSplit extends StatefulWidget {
  const _ResizableResponseSplit({
    super.key,
    required this.editor,
    required this.response,
    required this.borderColor,
  });

  final Widget editor;
  final Widget response;
  final Color borderColor;

  @override
  State<_ResizableResponseSplit> createState() =>
      _ResizableResponseSplitState();
}

class _ResizableResponseSplitState extends State<_ResizableResponseSplit> {
  static const _handleHeight = 18.0;
  static const _minResponseRatio = 0.22;
  static const _maxResponseRatio = 0.78;
  final ValueNotifier<double> _responseRatio = ValueNotifier(0.4);

  @override
  void dispose() {
    _responseRatio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final availableHeight = (constraints.maxHeight - _handleHeight)
              .clamp(0.0, double.infinity);
          return CustomMultiChildLayout(
            delegate: _ResponseSplitLayoutDelegate(
              responseRatio: _responseRatio,
              handleHeight: _handleHeight,
            ),
            children: [
              LayoutId(
                id: _ResponseSplitSlot.editor,
                child: widget.editor,
              ),
              LayoutId(
                id: _ResponseSplitSlot.handle,
                child: Tooltip(
                  message: context.tr(
                    'Drag to resize response',
                    'Arraste para redimensionar a resposta',
                  ),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.resizeUpDown,
                    child: GestureDetector(
                      key: const ValueKey('response-resize-handle'),
                      behavior: HitTestBehavior.opaque,
                      onVerticalDragUpdate: (details) {
                        if (availableHeight <= 0) return;
                        final minimumEditorHeight =
                            (availableHeight * 0.65).clamp(0.0, 180.0);
                        final maxRatio =
                            (1 - minimumEditorHeight / availableHeight)
                                .clamp(_minResponseRatio, _maxResponseRatio)
                                .toDouble();
                        final currentRatio = _responseRatio.value
                            .clamp(_minResponseRatio, maxRatio)
                            .toDouble();
                        _responseRatio.value =
                            (currentRatio - details.delta.dy / availableHeight)
                                .clamp(_minResponseRatio, maxRatio)
                                .toDouble();
                      },
                      onDoubleTap: () => _responseRatio.value = 0.4,
                      child: SizedBox(
                        height: _handleHeight,
                        width: double.infinity,
                        child: Center(
                          child: Container(
                            width: 48,
                            height: 5,
                            decoration: BoxDecoration(
                              color: widget.borderColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              LayoutId(
                id: _ResponseSplitSlot.response,
                child: widget.response,
              ),
            ],
          );
        },
      );
}

enum _ResponseSplitSlot { editor, handle, response }

class _ResponseSplitLayoutDelegate extends MultiChildLayoutDelegate {
  _ResponseSplitLayoutDelegate({
    required this.responseRatio,
    required this.handleHeight,
  }) : super(relayout: responseRatio);

  final ValueListenable<double> responseRatio;
  final double handleHeight;

  @override
  Size getSize(BoxConstraints constraints) => constraints.biggest;

  @override
  void performLayout(Size size) {
    final availableHeight =
        (size.height - handleHeight).clamp(0.0, size.height);
    final minimumEditorHeight = (availableHeight * 0.65).clamp(0.0, 180.0);
    final maxRatio = availableHeight <= 0
        ? _ResizableResponseSplitState._maxResponseRatio
        : (1 - minimumEditorHeight / availableHeight)
            .clamp(
              _ResizableResponseSplitState._minResponseRatio,
              _ResizableResponseSplitState._maxResponseRatio,
            )
            .toDouble();
    final ratio = responseRatio.value
        .clamp(
          _ResizableResponseSplitState._minResponseRatio,
          maxRatio,
        )
        .toDouble();
    final responseHeight = availableHeight * ratio;
    final editorHeight = availableHeight - responseHeight;

    layoutChild(
      _ResponseSplitSlot.editor,
      BoxConstraints.tight(Size(size.width, editorHeight)),
    );
    positionChild(_ResponseSplitSlot.editor, Offset.zero);

    layoutChild(
      _ResponseSplitSlot.handle,
      BoxConstraints.tight(Size(size.width, handleHeight)),
    );
    positionChild(
      _ResponseSplitSlot.handle,
      Offset(0, editorHeight),
    );

    layoutChild(
      _ResponseSplitSlot.response,
      BoxConstraints.tight(Size(size.width, responseHeight)),
    );
    positionChild(
      _ResponseSplitSlot.response,
      Offset(0, editorHeight + handleHeight),
    );
  }

  @override
  bool shouldRelayout(covariant _ResponseSplitLayoutDelegate oldDelegate) =>
      responseRatio != oldDelegate.responseRatio ||
      handleHeight != oldDelegate.handleHeight;
}

class _RequestEditor extends StatelessWidget {
  const _RequestEditor({
    required this.controller,
    required this.params,
    required this.activeTabId,
    required this.dark,
    required this.panelColor,
    required this.borderColor,
    required this.mutedColor,
    required this.onBodyChanged,
    required this.onBodyModeChanged,
    required this.onTestsChanged,
  });

  final TabController controller;
  final RequestParams params;
  final int activeTabId;
  final bool dark;
  final Color panelColor;
  final Color borderColor;
  final Color mutedColor;
  final ValueChanged<String> onBodyChanged;
  final ValueChanged<BodyMode> onBodyModeChanged;
  final ValueChanged<String> onTestsChanged;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: panelColor,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: borderColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            _PanelHeading(
              icon: Icons.tune_rounded,
              title: context.tr('Request setup', 'Configuração da request'),
              detail: context.tr(
                'Tune every part of the active request',
                'Ajuste todos os detalhes da request ativa',
              ),
              mutedColor: mutedColor,
              borderColor: borderColor,
              trailing: _EnabledCount(params: params),
            ),
            TabBar(
              controller: controller,
              isScrollable: true,
              labelColor: AppColors.primary,
              unselectedLabelColor: mutedColor,
              indicatorColor: AppColors.primary,
              tabs: [
                Tab(text: context.tr('Params', 'Parâmetros')),
                const Tab(text: 'Headers'),
                const Tab(text: 'Body'),
                const Tab(text: 'Auth'),
                const Tab(text: 'Tests'),
              ],
            ),
            Divider(height: 1, color: borderColor),
            Expanded(
              child: TabBarView(
                controller: controller,
                children: [
                  const ParamsEditorView(),
                  const HeadersEditorView(),
                  _BodyEditor(
                    params: params,
                    dark: dark,
                    activeTabId: activeTabId,
                    mutedColor: mutedColor,
                    onBodyChanged: onBodyChanged,
                    onBodyModeChanged: onBodyModeChanged,
                  ),
                  AuthEditorView(auth: params.auth),
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr(
                              'Response assertions', 'Asserções da resposta'),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          context.tr(
                            'One expression per line. Check status, duration, or response data.',
                            'Uma expressão por linha. Valide status, duração ou os dados da resposta.',
                          ),
                          style: TextStyle(fontSize: 11, color: mutedColor),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: TextFormField(
                            key: ValueKey('studio-tests-$activeTabId'),
                            initialValue: params.testScript,
                            onChanged: onTestsChanged,
                            expands: true,
                            maxLines: null,
                            minLines: null,
                            textAlignVertical: TextAlignVertical.top,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                            decoration: InputDecoration(
                              hintText:
                                  'status == 200\nresponseTimeMs < 1000\ndata.id != null',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _EnabledCount extends StatelessWidget {
  const _EnabledCount({required this.params});

  final RequestParams params;

  @override
  Widget build(BuildContext context) {
    final count = params.headers.where((item) => item.isEnabled).length +
        params.queryParams.where((item) => item.isEnabled).length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        '$count ${context.tr('active', 'ativos')}',
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _BodyEditor extends ConsumerWidget {
  const _BodyEditor({
    required this.params,
    required this.dark,
    required this.activeTabId,
    required this.mutedColor,
    required this.onBodyChanged,
    required this.onBodyModeChanged,
  });

  final RequestParams params;
  final bool dark;
  final int activeTabId;
  final Color mutedColor;
  final ValueChanged<String> onBodyChanged;
  final ValueChanged<BodyMode> onBodyModeChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(httpClientProvider.notifier);
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            children: [
              DropdownButton<BodyMode>(
                value: params.bodyMode,
                items: [
                  for (final mode in BodyMode.values)
                    DropdownMenuItem(
                      value: mode,
                      child: Text(switch (mode) {
                        BodyMode.none => context.tr('No body', 'Sem body'),
                        BodyMode.json => 'JSON',
                        BodyMode.text => context.tr('Text', 'Texto'),
                        BodyMode.formUrlEncoded => 'x-www-form-urlencoded',
                        BodyMode.formData => 'form-data',
                        BodyMode.binary => 'Binary',
                      }),
                    ),
                ],
                onChanged: (mode) {
                  if (mode != null) onBodyModeChanged(mode);
                },
              ),
              const Spacer(),
              Text(
                context.tr('Request payload', 'Payload da request'),
                style: TextStyle(color: mutedColor, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (params.bodyMode == BodyMode.json ||
              params.bodyMode == BodyMode.text)
            Expanded(
              child: CodeEditorWidget(
                key: ValueKey('studio-body-$activeTabId-${params.bodyMode}'),
                initialText: params.body ?? '',
                onChanged: onBodyChanged,
                isDark: dark,
              ),
            )
          else if (params.bodyMode == BodyMode.formData ||
              params.bodyMode == BodyMode.formUrlEncoded)
            Expanded(
              child: ListView(
                children: [
                  for (var index = 0; index < params.formFields.length; index++)
                    _FormFieldRow(
                      index: index,
                      field: params.formFields[index],
                      onUpdate: notifier.updateFormField,
                      onRemove: notifier.removeFormField,
                    ),
                  Wrap(
                    spacing: 8,
                    children: [
                      TextButton.icon(
                        onPressed: () => notifier.addFormField(),
                        icon: const Icon(Icons.add, size: 16),
                        label: Text(context.tr('Add field', 'Adicionar campo')),
                      ),
                      if (params.bodyMode == BodyMode.formData)
                        TextButton.icon(
                          onPressed: () => notifier.addFormField(isFile: true),
                          icon: const Icon(Icons.attach_file, size: 16),
                          label:
                              Text(context.tr('Add file', 'Adicionar arquivo')),
                        ),
                    ],
                  ),
                ],
              ),
            )
          else if (params.bodyMode == BodyMode.binary)
            Align(
              alignment: Alignment.topLeft,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final file = await openFile();
                  if (file != null) notifier.updateBody(file.path);
                },
                icon: const Icon(Icons.attach_file),
                label: Text(params.body?.split('/').last ??
                    context.tr('Choose a file', 'Selecionar arquivo')),
              ),
            )
          else
            Expanded(
              child: Center(
                child: Text(
                  context.tr('This request has no body.',
                      'Esta request não tem body.'),
                  style: TextStyle(color: mutedColor),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FormFieldRow extends StatelessWidget {
  const _FormFieldRow({
    required this.index,
    required this.field,
    required this.onUpdate,
    required this.onRemove,
  });

  final int index;
  final FormFieldItem field;
  final void Function(int,
      {String? key, String? value, bool? isFile, bool? isEnabled}) onUpdate;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Checkbox(
            value: field.isEnabled,
            onChanged: (value) => onUpdate(index, isEnabled: value ?? true),
          ),
          Expanded(
            child: TextFormField(
              initialValue: field.key,
              onChanged: (value) => onUpdate(index, key: value),
              decoration: InputDecoration(
                hintText: context.tr('Key', 'Chave'),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              initialValue: field.value,
              onChanged: (value) => onUpdate(index, value: value),
              decoration: InputDecoration(
                hintText: context.tr('Value', 'Valor'),
                isDense: true,
              ),
            ),
          ),
          IconButton(
            onPressed: () => onRemove(index),
            icon: const Icon(Icons.close, size: 16),
          ),
        ],
      );
}

class _ResponseStudio extends StatelessWidget {
  const _ResponseStudio({
    required this.controller,
    required this.response,
    required this.isLoading,
    required this.dark,
    required this.panelColor,
    required this.borderColor,
    required this.inkColor,
    required this.mutedColor,
  });

  final TabController controller;
  final ResponseResult? response;
  final bool isLoading;
  final bool dark;
  final Color panelColor;
  final Color borderColor;
  final Color inkColor;
  final Color mutedColor;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: panelColor,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: borderColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            _PanelHeading(
              icon: Icons.data_object_rounded,
              title: context.tr('Response', 'Resposta'),
              detail: response == null
                  ? context.tr(
                      'Waiting for a request', 'Aguardando uma request')
                  : '${response?.statusCode} · ${response?.responseTimeMs} ms · ${response?.responseSizeBytes} bytes',
              mutedColor: mutedColor,
              borderColor: borderColor,
              trailing: response == null
                  ? const SizedBox.shrink()
                  : _StatusPill(statusCode: response!.statusCode),
            ),
            TabBar(
              controller: controller,
              isScrollable: true,
              labelColor: AppColors.primary,
              unselectedLabelColor: mutedColor,
              indicatorColor: AppColors.primary,
              tabs: const [
                Tab(text: 'Body'),
                Tab(text: 'Headers'),
                Tab(text: 'Preview'),
                Tab(text: 'Cookies'),
                Tab(text: 'Tests'),
              ],
            ),
            Divider(height: 1, color: borderColor),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: controller,
                      children: [
                        _ResponseBody(
                          response: response,
                          dark: dark,
                          mutedColor: mutedColor,
                        ),
                        _ResponseHeaders(
                          response: response,
                          mutedColor: mutedColor,
                        ),
                        _ResponsePreview(
                          response: response,
                          dark: dark,
                          mutedColor: mutedColor,
                        ),
                        _ResponseCookies(
                          response: response,
                          mutedColor: mutedColor,
                        ),
                        _ResponseTests(
                          response: response,
                          mutedColor: mutedColor,
                        ),
                      ],
                    ),
            ),
          ],
        ),
      );
}

class _PanelHeading extends StatelessWidget {
  const _PanelHeading({
    required this.icon,
    required this.title,
    required this.detail,
    required this.mutedColor,
    required this.borderColor,
    required this.trailing,
  });

  final IconData icon;
  final String title;
  final String detail;
  final Color mutedColor;
  final Color borderColor;
  final Widget trailing;

  @override
  Widget build(BuildContext context) => Container(
        height: 51,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: borderColor)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 17, color: AppColors.primary),
            const SizedBox(width: 9),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                detail,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: mutedColor, fontSize: 10),
              ),
            ),
            trailing,
          ],
        ),
      );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.statusCode});

  final int statusCode;

  @override
  Widget build(BuildContext context) {
    final color = statusCode >= 500
        ? AppColors.error
        : statusCode >= 400
            ? Colors.orange
            : AppColors.accent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        '$statusCode',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _ResponseBody extends StatelessWidget {
  const _ResponseBody({
    required this.response,
    required this.dark,
    required this.mutedColor,
  });

  final ResponseResult? response;
  final bool dark;
  final Color mutedColor;

  @override
  Widget build(BuildContext context) {
    final result = response;
    if (result == null) return _EmptyResponse(mutedColor: mutedColor);
    final data = result.data;
    final text = data is String
        ? data
        : data is List<int>
            ? 'Binary response (${data.length} bytes)'
            : const JsonEncoder.withIndent('  ').convert(data);
    final json = data is Map || data is List;
    return CodeEditorWidget(
      key: ValueKey(
        'studio-response-${result.statusCode}-${result.responseSizeBytes}',
      ),
      initialText: text,
      onChanged: (_) {},
      isDark: dark,
      readOnly: true,
      syntaxHighlight: json,
    );
  }
}

class _ResponseHeaders extends StatelessWidget {
  const _ResponseHeaders({
    required this.response,
    required this.mutedColor,
  });

  final ResponseResult? response;
  final Color mutedColor;

  @override
  Widget build(BuildContext context) {
    final headers = response?.headers;
    if (headers == null || headers.isEmpty) {
      return _EmptyResponse(mutedColor: mutedColor);
    }
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        for (final entry in headers.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SelectableText.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${entry.key}: ',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(text: entry.value.join(', ')),
                ],
              ),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
            ),
          ),
      ],
    );
  }
}

class _ResponsePreview extends StatelessWidget {
  const _ResponsePreview({
    required this.response,
    required this.dark,
    required this.mutedColor,
  });

  final ResponseResult? response;
  final bool dark;
  final Color mutedColor;

  @override
  Widget build(BuildContext context) {
    final result = response;
    if (result == null) return _EmptyResponse(mutedColor: mutedColor);
    final contentType = result.headers.entries
        .firstWhere(
          (entry) => entry.key.toLowerCase() == 'content-type',
          orElse: () => const MapEntry('', <String>[]),
        )
        .value
        .join(' ')
        .toLowerCase();
    final data = result.data;
    if (contentType.startsWith('image/') && data is List<int>) {
      return Center(
        child: InteractiveViewer(
          child: Image.memory(Uint8List.fromList(data)),
        ),
      );
    }
    if (contentType.contains('html') && data is String) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SelectableText(
          data,
          style: TextStyle(
            color:
                dark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            fontFamily: 'monospace',
            fontSize: 12,
          ),
        ),
      );
    }
    return Center(
      child: Text(
        context.tr(
          'Preview supports HTML and image responses.',
          'O preview aceita respostas HTML e imagens.',
        ),
        style: TextStyle(color: mutedColor),
      ),
    );
  }
}

class _ResponseCookies extends StatelessWidget {
  const _ResponseCookies({
    required this.response,
    required this.mutedColor,
  });

  final ResponseResult? response;
  final Color mutedColor;

  @override
  Widget build(BuildContext context) {
    final cookies = response?.cookies ?? const <String>[];
    if (cookies.isEmpty) return _EmptyResponse(mutedColor: mutedColor);
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        for (final cookie in cookies)
          ListTile(
            dense: true,
            leading: const Icon(Icons.cookie_outlined, size: 16),
            title: SelectableText(cookie),
          ),
      ],
    );
  }
}

class _ResponseTests extends StatelessWidget {
  const _ResponseTests({
    required this.response,
    required this.mutedColor,
  });

  final ResponseResult? response;
  final Color mutedColor;

  @override
  Widget build(BuildContext context) {
    final results = response?.testResults ?? const [];
    if (results.isEmpty) return _EmptyResponse(mutedColor: mutedColor);
    return ListView(
      children: [
        for (final result in results)
          ListTile(
            dense: true,
            leading: Icon(
              result.passed ? Icons.check_circle : Icons.cancel,
              color: result.passed ? AppColors.accent : AppColors.error,
            ),
            title: Text(result.name),
            subtitle: Text(result.message ?? ''),
          ),
      ],
    );
  }
}

class _EmptyResponse extends StatelessWidget {
  const _EmptyResponse({required this.mutedColor});

  final Color mutedColor;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, color: mutedColor, size: 24),
            const SizedBox(height: 8),
            Text(
              context.tr(
                  'No response data yet', 'Ainda não há dados de resposta'),
              style: TextStyle(color: mutedColor, fontSize: 11),
            ),
          ],
        ),
      );
}

class _NamePromptDialog extends StatefulWidget {
  const _NamePromptDialog({
    required this.title,
    required this.submitLabel,
    this.initialValue = '',
  });

  final String title;
  final String submitLabel;
  final String initialValue;

  @override
  State<_NamePromptDialog> createState() => _NamePromptDialogState();
}

class _NamePromptDialogState extends State<_NamePromptDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => Navigator.of(context).pop(_controller.text.trim());

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.title),
        content: TextField(
          controller: _controller,
          autofocus: true,
          decoration: InputDecoration(labelText: context.tr('Name', 'Nome')),
          onSubmitted: (_) => _submit(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.tr('Cancel', 'Cancelar')),
          ),
          FilledButton(
            onPressed: _submit,
            child: Text(widget.submitLabel),
          ),
        ],
      );
}
