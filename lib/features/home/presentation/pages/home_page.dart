// lib/features/home/presentation/pages/home_page.dart
import 'dart:convert';
import 'package:bolt/core/theme/theme_provider.dart';
import 'package:bolt/core/settings/app_settings.dart';
import 'package:bolt/features/settings/presentation/settings_dialog.dart';
import 'package:bolt/features/environment/presentation/environment_dialog.dart';
import 'package:bolt/features/http_client/presentation/widgets/code_editor_widget.dart';
import 'package:bolt/features/http_client/presentation/widgets/code_generation_dialog.dart';
import 'package:bolt/features/http_client/presentation/widgets/headers_editor_view.dart';
import 'package:bolt/features/http_client/presentation/widgets/auth_editor_view.dart';
import 'package:bolt/features/http_client/presentation/widgets/params_editor_view.dart';
import 'package:bolt/features/workspace/data/services/collection_transfer_service.dart';
import 'package:bolt/features/workspace/data/models/request_entity.dart';
import 'package:bolt/features/workspace/presentation/workspace_provider.dart';
import 'package:bolt/features/history/data/models/request_history_entity.dart';
import 'package:bolt/features/history/presentation/history_provider.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../http_client/domain/models/request_params.dart';
import '../../../http_client/domain/models/request_params_codec.dart';
import '../../../http_client/domain/models/response_result.dart';
import '../../../http_client/presentation/controllers/http_client_provider.dart';
import '../../../http_client/presentation/controllers/request_tabs_provider.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with TickerProviderStateMixin {
  late TextEditingController _urlController;
  late TabController _requestTabController;
  late TabController _responseTabController;
  String _bodyText = '';
  int? _activeRequestId;
  String? _activeRequestName;
  bool _showHistory = false;

  @override
  void initState() {
    super.initState();
    final currentState = ref.read(httpClientProvider);
    _urlController = TextEditingController(text: currentState.params.url);
    _bodyText = currentState.params.body ?? '';
    _requestTabController = TabController(length: 5, vsync: this);
    _responseTabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _urlController.dispose();
    _requestTabController.dispose();
    _responseTabController.dispose();
    super.dispose();
  }

  Widget _responseToolbar({
    required bool isDark,
    required Color borderColor,
    required String label,
    required IconData icon,
    required VoidCallback? onCopy,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.backgroundLight,
        border: Border(
          bottom: BorderSide(color: borderColor),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Copiar $label',
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.copy, size: 16),
            onPressed: onCopy,
          ),
        ],
      ),
    );
  }

  Future<void> _copyResponseText(
    String text,
    String message,
  ) async {
    await Clipboard.setData(ClipboardData(text: text));

    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 1),
        ),
      );
  }

  Future<void> _sendRequest() async {
    try {
      await ref.read(httpClientProvider.notifier).sendRequest();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao salvar no histórico: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(httpClientProvider);
    final workspaceState = ref.watch(workspaceProvider);
    final tabsState = ref.watch(requestTabsProvider);
    final historyState = ref.watch(requestHistoryProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor =
        isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Scaffold(
      body: Row(
        children: [
          // -----------------------------------------------------------------
          // BARRA LATERAL ESTILO BRUNO / POSTMAN (Com cores do Bolt)
          // -----------------------------------------------------------------
          Container(
            width: 260,
            color: surfaceColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Topo: Seletor de Workspace
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: borderColor)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.folder_shared,
                          size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Collections',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.create_new_folder_outlined,
                            size: 16),
                        onPressed: () => _showAddWorkspaceDialog(context),
                        tooltip: 'Novo Workspace',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.add, size: 16),
                        onPressed: () => _showAddRequestDialog(context),
                        tooltip: 'Novo Request',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      IconButton(
                        icon: const Icon(Icons.file_open_outlined, size: 16),
                        onPressed: workspaceState.selectedWorkspace == null
                            ? null
                            : _importCollection,
                        tooltip: 'Importar collection',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.ios_share_outlined, size: 16),
                        onPressed: workspaceState.selectedWorkspace == null
                            ? null
                            : _exportCollection,
                        tooltip: 'Exportar collection',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: _sidebarSectionButton(
                          label: 'Collections',
                          icon: Icons.folder_copy_outlined,
                          selected: !_showHistory,
                          onTap: () => setState(() => _showHistory = false),
                        ),
                      ),
                      Expanded(
                        child: _sidebarSectionButton(
                          label: 'History',
                          icon: Icons.history,
                          selected: _showHistory,
                          onTap: () => setState(() => _showHistory = true),
                        ),
                      ),
                    ],
                  ),
                ),

                // Lista de Workspaces e Requisições
                Expanded(
                  child: _showHistory
                      ? historyState.when(
                          loading: () => const Center(
                            child: CircularProgressIndicator(),
                          ),
                          error: (error, stackTrace) => Center(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                'Não foi possível carregar o histórico: $error',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                          data: (entries) => Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      'Recent requests',
                                      style: TextStyle(
                                        color: isDark
                                            ? AppColors.textSecondaryDark
                                            : AppColors.textSecondaryLight,
                                        fontSize: 11,
                                      ),
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      tooltip: 'Limpar histórico',
                                      visualDensity: VisualDensity.compact,
                                      onPressed: entries.isEmpty
                                          ? null
                                          : () => ref
                                              .read(requestHistoryProvider
                                                  .notifier)
                                              .clear(),
                                      icon: const Icon(
                                        Icons.delete_sweep_outlined,
                                        size: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: entries.isEmpty
                                    ? const Center(
                                        child: Text(
                                          'No requests yet',
                                          style: TextStyle(fontSize: 12),
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
                                                  color:
                                                      _getMethodColorFromString(
                                                    entry.method,
                                                  ),
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              title: Text(
                                                entry.url,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                ),
                                              ),
                                              subtitle: Text(
                                                '${entry.statusCode ?? '-'} · ${_formatHistoryTimestamp(entry.timestamp)}',
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                ),
                                              ),
                                              onTap: () =>
                                                  _loadHistoryEntry(entry),
                                            ),
                                          );
                                        },
                                      ),
                              ),
                            ],
                          ),
                        )
                      : workspaceState.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              itemCount: workspaceState.workspaces.length,
                              itemBuilder: (context, index) {
                                final workspace =
                                    workspaceState.workspaces[index];
                                final isSelected =
                                    workspaceState.selectedWorkspace?.id ==
                                        workspace.id;
                                final isExpanded = workspaceState
                                    .expandedWorkspaces
                                    .contains(workspace.id);
                                final requests = ref
                                    .read(workspaceProvider.notifier)
                                    .getRequestsForWorkspace(workspace.id);

                                return Column(
                                  children: [
                                    Material(
                                      color: isSelected
                                          ? surfaceColor.withValues(alpha: 0.5)
                                          : Colors.transparent,
                                      child: ListTile(
                                        leading: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              isExpanded
                                                  ? Icons.expand_more
                                                  : Icons.chevron_right,
                                              size: 16,
                                              color: isDark
                                                  ? AppColors.textSecondaryDark
                                                  : AppColors
                                                      .textSecondaryLight,
                                            ),
                                            const SizedBox(width: 4),
                                            Icon(
                                              isSelected
                                                  ? Icons.folder_open
                                                  : Icons.folder,
                                              size: 18,
                                              color: isSelected
                                                  ? AppColors.primary
                                                  : null,
                                            ),
                                          ],
                                        ),
                                        title: Text(
                                          workspace.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit,
                                                  size: 14),
                                              onPressed: () =>
                                                  _showRenameWorkspaceDialog(
                                                context,
                                                workspace.id,
                                                workspace.name,
                                              ),
                                              tooltip: 'Renomear Workspace',
                                              padding: const EdgeInsets.all(4),
                                              constraints:
                                                  const BoxConstraints(),
                                            ),
                                            const SizedBox(width: 6),
                                            IconButton(
                                              icon: const Icon(
                                                  Icons.delete_outline,
                                                  size: 14),
                                              onPressed: () =>
                                                  _showDeleteWorkspaceDialog(
                                                      context, workspace.id),
                                              tooltip: 'Deletar Workspace',
                                              padding: const EdgeInsets.all(4),
                                              constraints:
                                                  const BoxConstraints(),
                                            ),
                                          ],
                                        ),
                                        dense: true,
                                        onTap: () {
                                          ref
                                              .read(workspaceProvider.notifier)
                                              .toggleWorkspaceExpanded(
                                                  workspace.id);

                                          ref
                                              .read(workspaceProvider.notifier)
                                              .selectWorkspace(workspace.id);
                                        },
                                      ),
                                    ),
                                    if (isExpanded)
                                      ...requests.map((request) {
                                        return Padding(
                                          padding:
                                              const EdgeInsets.only(left: 12.0),
                                          child: Material(
                                            color: Colors.transparent,
                                            child: ListTile(
                                              leading: Icon(
                                                Icons.bolt,
                                                size: 14,
                                                color:
                                                    _getMethodColorFromString(
                                                        request.method),
                                              ),
                                              title: Text(
                                                request.name,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                    fontSize: 12),
                                              ),
                                              trailing: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(Icons.edit,
                                                        size: 12),
                                                    onPressed: () =>
                                                        _showRenameRequestDialog(
                                                      context,
                                                      request.id,
                                                      request.name,
                                                    ),
                                                    tooltip: 'Renomear Request',
                                                    padding:
                                                        const EdgeInsets.all(4),
                                                    constraints:
                                                        const BoxConstraints(),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  IconButton(
                                                    icon: const Icon(
                                                        Icons.delete_outline,
                                                        size: 12),
                                                    onPressed: () => ref
                                                        .read(workspaceProvider
                                                            .notifier)
                                                        .deleteRequest(
                                                            request.id),
                                                    tooltip: 'Deletar Request',
                                                    padding:
                                                        const EdgeInsets.all(4),
                                                    constraints:
                                                        const BoxConstraints(),
                                                  ),
                                                ],
                                              ),
                                              dense: true,
                                              onTap: () =>
                                                  _loadRequest(request),
                                            ),
                                          ),
                                        );
                                      }),
                                  ],
                                );
                              },
                            ),
                ),

                // Rodapé da Barra Lateral
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: borderColor)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.code, size: 18),
                        tooltip: 'Variáveis de Ambiente',
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => const EnvironmentDialog(),
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          isDark ? Icons.light_mode : Icons.dark_mode,
                          size: 18,
                        ),
                        tooltip: isDark ? 'Modo Claro' : 'Modo Escuro',
                        onPressed: () async {
                          final current =
                              ref.read(appSettingsProvider).settings;
                          try {
                            await ref.read(appSettingsProvider.notifier).save(
                                  current.copyWith(
                                    themeMode: isDark
                                        ? ThemeMode.light
                                        : ThemeMode.dark,
                                  ),
                                );
                          } catch (error) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Falha ao guardar o tema: $error',
                                ),
                              ),
                            );
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings_outlined, size: 18),
                        tooltip: 'Configurações',
                        onPressed: () => showDialog<void>(
                          context: context,
                          builder: (_) => const SettingsDialog(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          VerticalDivider(width: 1, thickness: 1, color: borderColor),

          // -----------------------------------------------------------------
          // PAINEL PRINCIPAL
          // -----------------------------------------------------------------
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 40,
                    child: Row(
                      children: [
                        Expanded(
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: tabsState.tabs.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(width: 4),
                            itemBuilder: (context, index) {
                              final tab = tabsState.tabs[index];
                              final selected = tab.id == tabsState.activeTabId;
                              return InkWell(
                                borderRadius: BorderRadius.circular(6),
                                onTap: () => _activateRequestTab(tab.id),
                                child: Container(
                                  constraints:
                                      const BoxConstraints(maxWidth: 220),
                                  padding: const EdgeInsets.only(
                                    left: 12,
                                    right: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? (isDark
                                            ? const Color(0xFF303030)
                                            : const Color(0xFFE8E8E8))
                                        : Colors.transparent,
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(6),
                                    ),
                                    border: Border(
                                      bottom: BorderSide(
                                        color: selected
                                            ? AppColors.primary
                                            : Colors.transparent,
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
                                          color: _getMethodColor(
                                            tab.params.method,
                                          ),
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          _requestTabLabel(tab),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: 'Fechar aba',
                                        visualDensity: VisualDensity.compact,
                                        onPressed: () =>
                                            _closeRequestTab(tab.id),
                                        icon: const Icon(Icons.close, size: 14),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        IconButton(
                          tooltip: 'Nova aba',
                          visualDensity: VisualDensity.compact,
                          onPressed: _openRequestTab,
                          icon: const Icon(Icons.add, size: 18),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: borderColor),
                  const SizedBox(height: 8),
                  // Linha de URL, Método, Send e Salvar
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: borderColor),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<HttpMethod>(
                            value: state.params.method,
                            dropdownColor: surfaceColor,
                            items: HttpMethod.values.map((method) {
                              return DropdownMenuItem(
                                value: method,
                                child: Text(
                                  method.name.toUpperCase(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: _getMethodColor(method),
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                ref
                                    .read(httpClientProvider.notifier)
                                    .updateMethod(val);
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: surfaceColor,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: borderColor),
                          ),
                          child: TextField(
                            controller: _urlController,
                            onChanged: (val) => ref
                                .read(httpClientProvider.notifier)
                                .updateUrl(val),
                            decoration: const InputDecoration(
                              hintText:
                                  'Digite a URL da API (ex: {{baseUrl}}/todos/1)',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                              isDense: true,
                            ),
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: state.isLoading ? null : _sendRequest,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6)),
                        ),
                        icon: state.isLoading
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.send, size: 14),
                        label: const Text('Send',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        tooltip: 'Generate Code',
                        onPressed: () => showDialog(
                          context: context,
                          builder: (_) =>
                              CodeGenerationDialog(params: state.params),
                        ),
                        icon: const Icon(Icons.code, size: 18),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        onPressed: () async {
                          final workspaceState = ref.read(workspaceProvider);
                          if (workspaceState.selectedWorkspace == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Selecione um workspace primeiro')),
                            );
                            return;
                          }

                          final currentState = ref.read(httpClientProvider);
                          final name =
                              currentState.params.url.split('/').last.isEmpty
                                  ? 'Requisição Principal'
                                  : currentState.params.url.split('/').last;

                          final body = _encodeBody(currentState.params);
                          final saved = await ref
                              .read(workspaceProvider.notifier)
                              .saveRequest(
                                id: _activeRequestId,
                                name: _activeRequestName ?? name,
                                url: currentState.params.url,
                                method: currentState.params.method.name,
                                headersJson: jsonEncode([
                                  for (final header
                                      in currentState.params.headers)
                                    {
                                      'key': header.key,
                                      'value': header.value,
                                      'isEnabled': header.isEnabled,
                                    },
                                ]),
                                queryParamsJson: jsonEncode([
                                  for (final param
                                      in currentState.params.queryParams)
                                    {
                                      'key': param.key,
                                      'value': param.value,
                                      'isEnabled': param.isEnabled,
                                      'isAutoDetected': param.isAutoDetected,
                                    },
                                ]),
                                body: body,
                              );

                          if (saved != null) {
                            setState(() {
                              _activeRequestId = saved.id;
                              _activeRequestName = saved.name;
                            });
                            ref
                                .read(httpClientProvider.notifier)
                                .setTabMetadata(
                                  name: saved.name,
                                  savedRequestId: saved.id,
                                );
                          }

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Requisição salva com sucesso no Bolt! ⚡'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.save_outlined, size: 18),
                        tooltip: 'Salvar Requisição',
                        style: IconButton.styleFrom(
                          backgroundColor: surfaceColor,
                          side: BorderSide(color: borderColor),
                          padding: const EdgeInsets.all(10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Área de Configuração da Requisição (Abas)
                  Expanded(
                    flex: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TabBar(
                            controller: _requestTabController,
                            isScrollable: true,
                            tabs: const [
                              Tab(text: 'Params'),
                              Tab(text: 'Headers'),
                              Tab(text: 'Body'),
                              Tab(text: 'Auth'),
                              Tab(text: 'Tests'),
                            ],
                            labelColor: AppColors.primary,
                            unselectedLabelColor: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                            indicatorColor: AppColors.primary,
                            indicatorSize: TabBarIndicatorSize.label,
                          ),
                          Divider(height: 1, color: borderColor),
                          Expanded(
                            child: TabBarView(
                              controller: _requestTabController,
                              children: [
                                const ParamsEditorView(),
                                const HeadersEditorView(),
                                _buildBodyEditor(
                                  state.params,
                                  isDark,
                                  tabsState.activeTabId,
                                ),
                                AuthEditorView(
                                  key: ValueKey(
                                    '${tabsState.activeTabId}-${state.params.auth.type}',
                                  ),
                                  auth: state.params.auth,
                                ),
                                _buildTestsEditor(
                                  state.params.testScript,
                                  isDark,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Área de Resposta
                  Expanded(
                    flex: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: borderColor),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.http, size: 18),
                                const SizedBox(width: 8),
                                const Text(
                                  'Response',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const Spacer(),
                                if (state.response != null) ...[
                                  _buildStatusBadge(
                                    state.response!.statusCode,
                                  ),
                                  const SizedBox(width: 12),
                                  _buildMetricBadge(
                                    Icons.timer_outlined,
                                    '${state.response!.responseTimeMs} ms',
                                    isDark,
                                  ),
                                  const SizedBox(width: 12),
                                  _buildMetricBadge(
                                    Icons.data_usage,
                                    '${state.response!.responseSizeBytes} bytes',
                                    isDark,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Divider(height: 1, color: borderColor),
                          TabBar(
                            controller: _responseTabController,
                            isScrollable: true,
                            tabs: const [
                              Tab(text: 'Body'),
                              Tab(text: 'Headers'),
                              Tab(text: 'Preview'),
                              Tab(text: 'Cookies'),
                              Tab(text: 'Tests'),
                            ],
                            labelColor: AppColors.primary,
                            unselectedLabelColor: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                            indicatorColor: AppColors.primary,
                            indicatorSize: TabBarIndicatorSize.label,
                          ),
                          Divider(height: 1, color: borderColor),
                          Expanded(
                            child: TabBarView(
                              controller: _responseTabController,
                              children: [
                                // BODY
                                Builder(
                                  builder: (context) {
                                    final responseText = state.response == null
                                        ? ''
                                        : state.response!.data is String
                                            ? state.response!.data as String
                                            : state.response!.data is List<int>
                                                ? 'Binary response (${(state.response!.data as List<int>).length} bytes)'
                                                : const JsonEncoder.withIndent(
                                                    '  ',
                                                  ).convert(
                                                    state.response!.data,
                                                  );

                                    return Column(
                                      children: [
                                        _responseToolbar(
                                          isDark: isDark,
                                          borderColor: borderColor,
                                          label: 'JSON',
                                          icon: Icons.data_object,
                                          onCopy: state.response == null
                                              ? null
                                              : () => _copyResponseText(
                                                    responseText,
                                                    'Resposta copiada!',
                                                  ),
                                        ),
                                        Expanded(
                                          child: Container(
                                            width: double.infinity,
                                            color: isDark
                                                ? AppColors.backgroundDark
                                                : AppColors.backgroundLight,
                                            child: state.response == null
                                                ? Center(
                                                    child: Text(
                                                      'Execute uma requisição para ver a resposta.',
                                                      style: TextStyle(
                                                        color: isDark
                                                            ? AppColors
                                                                .textSecondaryDark
                                                            : AppColors
                                                                .textSecondaryLight,
                                                      ),
                                                    ),
                                                  )
                                                : SingleChildScrollView(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            16),
                                                    child: SelectableText(
                                                      responseText,
                                                      style: TextStyle(
                                                        fontFamily: 'monospace',
                                                        fontSize: 13,
                                                        height: 1.6,
                                                        color: isDark
                                                            ? AppColors
                                                                .textPrimaryDark
                                                            : AppColors
                                                                .textPrimaryLight,
                                                      ),
                                                    ),
                                                  ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),

                                // HEADERS
                                Builder(
                                  builder: (context) {
                                    final headersText =
                                        state.response?.headers.entries
                                                .map(
                                                  (entry) =>
                                                      '${entry.key}: ${entry.value.join(", ")}',
                                                )
                                                .join('\n') ??
                                            '';

                                    return Column(
                                      children: [
                                        _responseToolbar(
                                          isDark: isDark,
                                          borderColor: borderColor,
                                          label: 'Response Headers',
                                          icon: Icons.list_alt,
                                          onCopy: state.response == null
                                              ? null
                                              : () => _copyResponseText(
                                                    headersText,
                                                    'Headers copiados!',
                                                  ),
                                        ),
                                        Expanded(
                                          child: Container(
                                            width: double.infinity,
                                            color: isDark
                                                ? AppColors.backgroundDark
                                                : AppColors.backgroundLight,
                                            child: state.response == null
                                                ? Center(
                                                    child: Text(
                                                      'Nenhum header recebido.',
                                                      style: TextStyle(
                                                        color: isDark
                                                            ? AppColors
                                                                .textSecondaryDark
                                                            : AppColors
                                                                .textSecondaryLight,
                                                      ),
                                                    ),
                                                  )
                                                : ListView(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            16),
                                                    children:
                                                        state.response!.headers
                                                            .entries
                                                            .map(
                                                              (entry) =>
                                                                  Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .only(
                                                                  bottom: 10,
                                                                ),
                                                                child:
                                                                    SelectableText
                                                                        .rich(
                                                                  TextSpan(
                                                                    children: [
                                                                      TextSpan(
                                                                        text:
                                                                            '${entry.key}: ',
                                                                        style:
                                                                            const TextStyle(
                                                                          fontWeight:
                                                                              FontWeight.bold,
                                                                          color:
                                                                              AppColors.primary,
                                                                        ),
                                                                      ),
                                                                      TextSpan(
                                                                        text: entry
                                                                            .value
                                                                            .join(', '),
                                                                        style:
                                                                            TextStyle(
                                                                          color: isDark
                                                                              ? AppColors.textPrimaryDark
                                                                              : AppColors.textPrimaryLight,
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                  style:
                                                                      const TextStyle(
                                                                    fontFamily:
                                                                        'monospace',
                                                                    fontSize:
                                                                        12,
                                                                  ),
                                                                ),
                                                              ),
                                                            )
                                                            .toList(),
                                                  ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                                Builder(
                                  builder: (context) {
                                    final response = state.response;
                                    final contentType =
                                        _responseContentType(response);
                                    final data = response?.data;
                                    final imageBytes =
                                        data is List<int> ? data : null;
                                    final htmlText =
                                        data is String ? data : null;
                                    final isHtml = htmlText != null &&
                                        (contentType.contains('html') ||
                                            htmlText
                                                .toLowerCase()
                                                .contains('<html'));
                                    return Container(
                                      width: double.infinity,
                                      color: isDark
                                          ? AppColors.backgroundDark
                                          : AppColors.backgroundLight,
                                      alignment: Alignment.topLeft,
                                      padding: const EdgeInsets.all(16),
                                      child: response == null
                                          ? const Text(
                                              'Nenhuma resposta disponível.',
                                            )
                                          : imageBytes != null &&
                                                  contentType
                                                      .startsWith('image/')
                                              ? InteractiveViewer(
                                                  child: Image.memory(
                                                    Uint8List.fromList(
                                                      imageBytes,
                                                    ),
                                                  ),
                                                )
                                              : isHtml
                                                  ? SingleChildScrollView(
                                                      child: Text.rich(
                                                        _safeHtmlSpan(
                                                          htmlText,
                                                        ),
                                                      ),
                                                    )
                                                  : const Text(
                                                      'A resposta não é uma imagem nem HTML.',
                                                    ),
                                    );
                                  },
                                ),
                                Builder(
                                  builder: (context) {
                                    final cookies = state.response?.cookies ??
                                        const <String>[];
                                    return cookies.isEmpty
                                        ? const Center(
                                            child: Text(
                                              'Nenhum cookie recebido nesta resposta.',
                                            ),
                                          )
                                        : ListView(
                                            padding: const EdgeInsets.all(16),
                                            children: [
                                              for (final cookie in cookies)
                                                ListTile(
                                                  dense: true,
                                                  leading: const Icon(
                                                    Icons.cookie_outlined,
                                                  ),
                                                  title: SelectableText(cookie),
                                                ),
                                            ],
                                          );
                                  },
                                ),
                                Builder(
                                  builder: (context) {
                                    final results =
                                        state.response?.testResults ?? [];
                                    return results.isEmpty
                                        ? const Center(
                                            child: Text(
                                              'Sem testes executados. Adicione assertions na aba Tests e envie a requisição.',
                                              textAlign: TextAlign.center,
                                            ),
                                          )
                                        : ListView(
                                            padding: const EdgeInsets.all(16),
                                            children: [
                                              for (final result in results)
                                                ListTile(
                                                  dense: true,
                                                  leading: Icon(
                                                    result.passed
                                                        ? Icons.check_circle
                                                        : Icons.cancel,
                                                    color: result.passed
                                                        ? Colors.green
                                                        : AppColors.error,
                                                  ),
                                                  title: Text(result.name),
                                                  subtitle: Text(
                                                    result.message ?? '',
                                                  ),
                                                ),
                                            ],
                                          );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getMethodColor(HttpMethod method) {
    switch (method) {
      case HttpMethod.get:
        return AppColors.accent;
      case HttpMethod.post:
        return AppColors.primary;
      case HttpMethod.put:
        return Colors.orangeAccent;
      case HttpMethod.delete:
        return AppColors.error;
      case HttpMethod.patch:
        return Colors.purpleAccent;
      case HttpMethod.head:
        return Colors.teal;
      case HttpMethod.options:
        return Colors.cyan;
      case HttpMethod.trace:
        return Colors.indigo;
      case HttpMethod.connect:
        return Colors.brown;
    }
  }

  Widget _buildBodyEditor(
    RequestParams params,
    bool isDark,
    int activeTabId,
  ) {
    final notifier = ref.read(httpClientProvider.notifier);
    final isForm = params.bodyMode == BodyMode.formData ||
        params.bodyMode == BodyMode.formUrlEncoded;

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButton<BodyMode>(
            value: params.bodyMode,
            items: BodyMode.values
                .map((mode) => DropdownMenuItem(
                      value: mode,
                      child: Text(switch (mode) {
                        BodyMode.none => 'No body',
                        BodyMode.json => 'JSON',
                        BodyMode.text => 'Text',
                        BodyMode.formUrlEncoded => 'x-www-form-urlencoded',
                        BodyMode.formData => 'form-data',
                        BodyMode.binary => 'Binary',
                      }),
                    ))
                .toList(),
            onChanged: (mode) {
              if (mode != null) notifier.updateBodyMode(mode);
            },
          ),
          if (params.bodyMode == BodyMode.json ||
              params.bodyMode == BodyMode.text)
            Expanded(
              child: CodeEditorWidget(
                key: ValueKey('$activeTabId-${params.bodyMode}'),
                initialText: _bodyText,
                onChanged: (value) {
                  _bodyText = value;
                  notifier.updateBody(value);
                },
                isDark: isDark,
              ),
            )
          else if (isForm) ...[
            Row(
              children: [
                Text(params.bodyMode == BodyMode.formData
                    ? 'Multipart fields'
                    : 'Form fields'),
                const Spacer(),
                IconButton(
                  tooltip: 'Adicionar campo de texto',
                  onPressed: () => notifier.addFormField(),
                  icon: const Icon(Icons.add),
                ),
                if (params.bodyMode == BodyMode.formData)
                  IconButton(
                    tooltip: 'Adicionar arquivo',
                    onPressed: () => notifier.addFormField(isFile: true),
                    icon: const Icon(Icons.attach_file),
                  ),
              ],
            ),
            Expanded(
              child: ListView.builder(
                itemCount: params.formFields.length,
                itemBuilder: (context, index) {
                  final field = params.formFields[index];
                  return Row(
                    children: [
                      Checkbox(
                        value: field.isEnabled,
                        onChanged: (value) => notifier.updateFormField(
                          index,
                          isEnabled: value ?? true,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          key: ValueKey('form-key-$index'),
                          initialValue: field.key,
                          decoration: const InputDecoration(
                            hintText: 'Key',
                            isDense: true,
                          ),
                          onChanged: (value) =>
                              notifier.updateFormField(index, key: value),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 3,
                        child: field.isFile
                            ? Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      field.value.isEmpty
                                          ? 'Nenhum arquivo selecionado'
                                          : field.value.split('/').last,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Selecionar arquivo',
                                    onPressed: () async {
                                      final file = await openFile();
                                      if (file != null) {
                                        notifier.updateFormField(
                                          index,
                                          value: file.path,
                                        );
                                      }
                                    },
                                    icon: const Icon(Icons.folder_open),
                                  ),
                                ],
                              )
                            : TextFormField(
                                key: ValueKey('form-value-$index'),
                                initialValue: field.value,
                                decoration: const InputDecoration(
                                  hintText: 'Value',
                                  isDense: true,
                                ),
                                onChanged: (value) => notifier.updateFormField(
                                  index,
                                  value: value,
                                ),
                              ),
                      ),
                      IconButton(
                        tooltip: 'Remover campo',
                        onPressed: () => notifier.removeFormField(index),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  );
                },
              ),
            ),
          ] else if (params.bodyMode == BodyMode.binary)
            Row(
              children: [
                Expanded(
                  child: Text(params.body?.split('/').last ??
                      'Nenhum arquivo selecionado'),
                ),
                IconButton(
                  tooltip: 'Selecionar arquivo',
                  onPressed: () async {
                    final file = await openFile();
                    if (file != null) notifier.updateBody(file.path);
                  },
                  icon: const Icon(Icons.folder_open),
                ),
              ],
            )
          else
            const Expanded(child: SizedBox.shrink()),
        ],
      ),
    );
  }

  Widget _buildTestsEditor(String script, bool isDark) {
    final tabId = ref.read(requestTabsProvider).activeTabId;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Assertions após a resposta',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            'Uma assertion por linha. Ex.: status == 200; responseTimeMs < 1000',
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TextFormField(
              key: ValueKey('tests-$tabId'),
              initialValue: script,
              expands: true,
              maxLines: null,
              minLines: null,
              textAlignVertical: TextAlignVertical.top,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              decoration: const InputDecoration(
                hintText:
                    'status == 200\nresponseTimeMs < 1000\ndata.id != null',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              onChanged: ref.read(httpClientProvider.notifier).updateTestScript,
            ),
          ),
        ],
      ),
    );
  }

  TextSpan _safeHtmlSpan(String source) {
    final sanitized = source.replaceAll(
      RegExp(
        r'<(script|style)\b[^>]*>[\s\S]*?</\1\s*>',
        caseSensitive: false,
      ),
      '',
    );
    final tokens = RegExp(r'<[^>]*>|[^<]+').allMatches(sanitized);
    final children = <TextSpan>[];
    final styles = <TextStyle>[const TextStyle(fontSize: 14, height: 1.5)];
    const allowedTags = {
      'b',
      'strong',
      'i',
      'em',
      'u',
      'h1',
      'h2',
      'h3',
      'p',
      'div',
      'br',
      'li',
      'pre',
      'code',
    };
    for (final token in tokens) {
      final value = token.group(0)!;
      if (value.startsWith('<')) {
        final match = RegExp(r'^<\s*(/?)\s*([a-zA-Z0-9]+)').firstMatch(value);
        if (match == null) continue;
        final closing = match.group(1) == '/';
        final tag = match.group(2)!.toLowerCase();
        if (!allowedTags.contains(tag)) continue;
        if (tag == 'br' || tag == 'li' || tag == 'p' || tag == 'div') {
          children.add(const TextSpan(text: '\n'));
        }
        if (closing) {
          if (styles.length > 1) styles.removeLast();
        } else if (tag != 'br') {
          final parent = styles.last;
          styles.add(switch (tag) {
            'b' ||
            'strong' =>
              parent.merge(const TextStyle(fontWeight: FontWeight.bold)),
            'i' ||
            'em' =>
              parent.merge(const TextStyle(fontStyle: FontStyle.italic)),
            'u' => parent.merge(
                const TextStyle(decoration: TextDecoration.underline),
              ),
            'h1' => parent.merge(
                const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
            'h2' => parent.merge(
                const TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
              ),
            'h3' => parent.merge(
                const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
              ),
            'pre' ||
            'code' =>
              parent.merge(const TextStyle(fontFamily: 'monospace')),
            _ => parent,
          });
        }
        continue;
      }
      final decoded = value
          .replaceAll('&nbsp;', ' ')
          .replaceAll('&lt;', '<')
          .replaceAll('&gt;', '>')
          .replaceAll('&quot;', '"')
          .replaceAll('&#39;', "'")
          .replaceAll('&amp;', '&');
      children.add(TextSpan(text: decoded, style: styles.last));
    }
    return TextSpan(children: children);
  }

  String _responseContentType(ResponseResult? response) {
    if (response == null) return '';
    for (final entry in response.headers.entries) {
      if (entry.key.toLowerCase() == 'content-type' && entry.value.isNotEmpty) {
        return entry.value.first.toLowerCase();
      }
    }
    return '';
  }

  String _encodeBody(RequestParams params) =>
      RequestParamsCodec.encodeBody(params);

  Future<void> _importCollection() async {
    final workspace = ref.read(workspaceProvider).selectedWorkspace;
    if (workspace == null) return;
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
        workspaceId: workspace.id,
        content: await file.readAsString(),
      );
      await ref.read(workspaceProvider.notifier).selectWorkspace(workspace.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$count requests importadas.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao importar collection: $error')),
      );
    }
  }

  Future<void> _exportCollection() async {
    final workspace = ref.read(workspaceProvider).selectedWorkspace;
    if (workspace == null) return;
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Collection exportada para ${location.path}')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao exportar collection: $error')),
      );
    }
  }

  Widget _buildStatusBadge(int code) {
    Color color = AppColors.accent;
    if (code >= 400 && code < 500) color = Colors.orangeAccent;
    if (code >= 500) color = AppColors.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color),
      ),
      child: Text(
        'Status: $code',
        style:
            TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }

  Widget _buildMetricBadge(IconData icon, String text, bool isDark) {
    final secondaryColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    return Row(
      children: [
        Icon(icon, size: 14, color: secondaryColor),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 13, color: secondaryColor)),
      ],
    );
  }

  void _showAddWorkspaceDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Novo Workspace'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Nome do workspace'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                ref
                    .read(workspaceProvider.notifier)
                    .createWorkspace(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Criar'),
          ),
        ],
      ),
    );
  }

  void _showRenameWorkspaceDialog(
    BuildContext context,
    int workspaceId,
    String currentName,
  ) {
    final controller = TextEditingController(text: currentName);
    final formKey = GlobalKey<FormState>();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Renomear Workspace'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Nome do workspace'),
            autofocus: true,
            validator: (value) =>
                value?.trim().isNotEmpty == true ? null : 'Informe um nome',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              try {
                await ref
                    .read(workspaceProvider.notifier)
                    .renameWorkspace(workspaceId, controller.text.trim());
                if (context.mounted) Navigator.pop(context);
              } catch (error) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Falha ao renomear workspace: $error'),
                  ),
                );
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    ).whenComplete(controller.dispose);
  }

  void _showDeleteWorkspaceDialog(BuildContext context, int workspaceId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deletar Workspace'),
        content: const Text(
            'Tem certeza que deseja deletar este workspace e todos os seus requests?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              ref.read(workspaceProvider.notifier).deleteWorkspace(workspaceId);
              Navigator.pop(context);
            },
            child:
                const Text('Deletar', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _showAddRequestDialog(BuildContext context, [int? workspaceId]) {
    final nameController = TextEditingController();
    final urlController = TextEditingController();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor =
        isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    HttpMethod selectedMethod = HttpMethod.get;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Novo Request'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(hintText: 'Nome do request'),
                autofocus: true,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: urlController,
                decoration: const InputDecoration(hintText: 'URL'),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<HttpMethod>(
                    value: selectedMethod,
                    dropdownColor: surfaceColor,
                    isExpanded: true,
                    items: HttpMethod.values.map((method) {
                      return DropdownMenuItem(
                        value: method,
                        child: Text(
                          method.name.toUpperCase(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _getMethodColor(method),
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => selectedMethod = val);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                if (nameController.text.isNotEmpty &&
                    urlController.text.isNotEmpty) {
                  final workspaceState = ref.read(workspaceProvider);
                  final targetWorkspaceId =
                      workspaceId ?? workspaceState.selectedWorkspace?.id;

                  if (targetWorkspaceId != null) {
                    ref.read(workspaceProvider.notifier).createRequest(
                          name: nameController.text,
                          url: urlController.text,
                          method: selectedMethod.name,
                          headersJson: '{}',
                          queryParamsJson: '{}',
                        );
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Selecione um workspace primeiro')),
                    );
                  }
                }
              },
              child: const Text('Criar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showRenameRequestDialog(
    BuildContext context,
    int requestId,
    String currentName,
  ) {
    final controller = TextEditingController(text: currentName);
    final formKey = GlobalKey<FormState>();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Renomear Request'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Nome do request'),
            autofocus: true,
            validator: (value) =>
                value?.trim().isNotEmpty == true ? null : 'Informe um nome',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final name = controller.text.trim();
              try {
                await ref
                    .read(workspaceProvider.notifier)
                    .renameRequest(requestId, name);
                if (_activeRequestId == requestId && mounted) {
                  setState(() => _activeRequestName = name);
                  ref
                      .read(httpClientProvider.notifier)
                      .setTabMetadata(name: name, savedRequestId: requestId);
                }
                if (context.mounted) Navigator.pop(context);
              } catch (error) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Falha ao renomear request: $error'),
                  ),
                );
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    ).whenComplete(controller.dispose);
  }

  void _loadRequest(RequestEntity request) {
    _loadRequestValues(
      name: request.name,
      savedRequestId: request.id,
      url: request.url,
      method: request.method,
      headersJson: request.headersJson,
      queryParamsJson: request.queryParamsJson,
      body: request.body,
    );
  }

  void _loadHistoryEntry(RequestHistoryEntity entry) {
    _showHistory = true;
    _loadRequestValues(
      name: '${entry.method.toUpperCase()} · ${_urlLabel(entry.url)}',
      url: entry.url,
      method: entry.method,
      headersJson: entry.headersJson,
      queryParamsJson: entry.queryParamsJson,
      body: entry.body,
    );
  }

  void _loadRequestValues({
    required String name,
    required String url,
    required String method,
    required String headersJson,
    required String queryParamsJson,
    String? body,
    int? savedRequestId,
  }) {
    _activeRequestId = savedRequestId;
    _activeRequestName = name;
    _urlController.text = url;
    final notifier = ref.read(httpClientProvider.notifier);
    notifier.clearResponse();
    notifier.updateUrl(url);

    final decodedBody = RequestParamsCodec.decodeBody(body);
    _bodyText = decodedBody.text ?? '';
    notifier.updateBody(_bodyText);
    notifier.updateBodyMode(decodedBody.mode);
    notifier.updateFormFields(decodedBody.fields);
    notifier.updateAuth(decodedBody.auth);
    notifier.updateTestScript(decodedBody.testScript);

    List<T> decodeItems<T>(
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

    notifier.updateHeaders(decodeItems(
      headersJson,
      (item) => HeaderItem(
        key: item['key']?.toString() ?? '',
        value: item['value']?.toString() ?? '',
        isEnabled: item['isEnabled'] != false,
      ),
    ));
    notifier.updateQueryParams(decodeItems(
      queryParamsJson,
      (item) => QueryParamItem(
        key: item['key']?.toString() ?? '',
        value: item['value']?.toString() ?? '',
        isEnabled: item['isEnabled'] != false,
        isAutoDetected: item['isAutoDetected'] == true,
      ),
    ));

    final parsedMethod = HttpMethod.values.firstWhere(
      (m) => m.name.toUpperCase() == method.toUpperCase(),
      orElse: () => HttpMethod.get,
    );
    notifier.updateMethod(parsedMethod);
    notifier.setTabMetadata(
      name: name,
      savedRequestId: savedRequestId,
    );
    setState(() {});
  }

  void _openRequestTab() {
    ref.read(httpClientProvider.notifier).openTab();
    final state = ref.read(httpClientProvider);
    _urlController.text = state.params.url;
    _bodyText = state.params.body ?? '';
    _activeRequestId = null;
    _activeRequestName = null;
    setState(() {});
  }

  void _activateRequestTab(int id) {
    ref.read(httpClientProvider.notifier).selectTab(id);
    final state = ref.read(httpClientProvider);
    final tab = ref.read(requestTabsProvider).activeTab;
    _urlController.text = state.params.url;
    _bodyText = state.params.body ?? '';
    _activeRequestId = tab.savedRequestId;
    _activeRequestName = tab.name == 'New Request' ? null : tab.name;
    setState(() {});
  }

  void _closeRequestTab(int id) {
    ref.read(httpClientProvider.notifier).closeTab(id);
    final state = ref.read(httpClientProvider);
    final tab = ref.read(requestTabsProvider).activeTab;
    _urlController.text = state.params.url;
    _bodyText = state.params.body ?? '';
    _activeRequestId = tab.savedRequestId;
    _activeRequestName = tab.name == 'New Request' ? null : tab.name;
    setState(() {});
  }

  String _requestTabLabel(RequestTabSnapshot tab) {
    if (tab.name != 'New Request') return tab.name;
    return _urlLabel(tab.params.url);
  }

  String _urlLabel(String url) {
    final path = Uri.tryParse(url)?.pathSegments;
    if (path != null && path.isNotEmpty) return path.last;
    return url.isEmpty ? 'New Request' : url;
  }

  String _formatHistoryTimestamp(DateTime timestamp) {
    final local = timestamp.toLocal();
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    return '${twoDigits(local.hour)}:${twoDigits(local.minute)}:${twoDigits(local.second)}';
  }

  Widget _sidebarSectionButton({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: onTap,
      child: Container(
        height: 32,
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.14)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: selected ? AppColors.primary : null,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  color: selected ? AppColors.primary : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getMethodColorFromString(String method) {
    final upperMethod = method.toUpperCase();
    switch (upperMethod) {
      case 'GET':
        return AppColors.accent;
      case 'POST':
        return AppColors.primary;
      case 'PUT':
        return Colors.orangeAccent;
      case 'DELETE':
        return AppColors.error;
      case 'PATCH':
        return Colors.purpleAccent;
      default:
        return AppColors.textSecondaryDark;
    }
  }
}
