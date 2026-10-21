// lib/features/home/presentation/pages/home_page.dart
import 'dart:convert';
import 'package:bolt/core/theme/theme_provider.dart';
import 'package:bolt/features/environment/presentation/environment_dialog.dart';
import 'package:bolt/features/http_client/presentation/widgets/code_editor_widget.dart';
import 'package:bolt/features/http_client/presentation/widgets/headers_editor_view.dart';
import 'package:bolt/features/http_client/presentation/widgets/params_editor_view.dart';
import 'package:bolt/features/workspace/data/models/request_entity.dart';
import 'package:bolt/features/workspace/presentation/workspace_provider.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../http_client/domain/models/request_params.dart';
import '../../../http_client/presentation/controllers/http_client_provider.dart';

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

  @override
  void initState() {
    super.initState();
    final currentState = ref.read(httpClientProvider);
    _urlController = TextEditingController(text: currentState.params.url);
    _bodyText = currentState.params.body ?? '';
    _requestTabController = TabController(length: 3, vsync: this);
    _responseTabController = TabController(length: 2, vsync: this);
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
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(httpClientProvider);
    final workspaceState = ref.watch(workspaceProvider);
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: borderColor)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.folder_shared, size: 18, color: AppColors.primary),
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
                        icon: const Icon(Icons.add, size: 16),
                        onPressed: () => _showAddWorkspaceDialog(context),
                        tooltip: 'Novo Workspace',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.create_new_folder_outlined, size: 16),
                        onPressed: () => _showAddRequestDialog(context),
                        tooltip: 'Novo Request',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),

                // Lista de Workspaces e Requisições
                Expanded(
                  child: workspaceState.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          itemCount: workspaceState.workspaces.length,
                          itemBuilder: (context, index) {
                            final workspace = workspaceState.workspaces[index];
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
                                              : AppColors.textSecondaryLight,
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
                                          icon: const Icon(Icons.edit, size: 14),
                                          onPressed: () =>
                                              _showRenameWorkspaceDialog(
                                            context,
                                            workspace.id,
                                            workspace.name,
                                          ),
                                          tooltip: 'Renomear Workspace',
                                          padding: const EdgeInsets.all(4),
                                          constraints: const BoxConstraints(),
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
                                          constraints: const BoxConstraints(),
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
                                      padding: const EdgeInsets.only(left: 12.0),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: ListTile(
                                          leading: Icon(
                                            Icons.bolt,
                                            size: 14,
                                            color: _getMethodColorFromString(
                                                request.method),
                                          ),
                                          title: Text(
                                            request.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontSize: 12),
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
                                                padding: const EdgeInsets.all(4),
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
                                                    .deleteRequest(request.id),
                                                tooltip: 'Deletar Request',
                                                padding: const EdgeInsets.all(4),
                                                constraints:
                                                    const BoxConstraints(),
                                              ),
                                            ],
                                          ),
                                          dense: true,
                                          onTap: () => _loadRequest(request),
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
                        onPressed: () {
                          final currentMode = ref.read(themeModeProvider);
                          ref.read(themeModeProvider.notifier).state =
                              currentMode == ThemeMode.dark
                                  ? ThemeMode.light
                                  : ThemeMode.dark;
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings_outlined, size: 18),
                        tooltip: 'Configurações',
                        onPressed: () {},
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
                        onPressed: state.isLoading
                            ? null
                            : () => ref
                                .read(httpClientProvider.notifier)
                                .sendRequest(),
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
                                    },
                                ]),
                                body: body,
                              );

                          if (saved != null) {
                            setState(() {
                              _activeRequestId = saved.id;
                              _activeRequestName = saved.name;
                            });
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
                            tabs: const [
                              Tab(text: 'Params'),
                              Tab(text: 'Headers'),
                              Tab(text: 'Body'),
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
                                _buildBodyEditor(state.params, isDark),
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
                            tabs: const [
                              Tab(text: 'Body'),
                              Tab(text: 'Headers'),
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
                                        : const JsonEncoder.withIndent('  ')
                                            .convert(state.response!.data);

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
                                                            ? AppColors.textSecondaryDark
                                                            : AppColors.textSecondaryLight,
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
                                                            ? AppColors.textPrimaryDark
                                                            : AppColors.textPrimaryLight,
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
                                                            ? AppColors.textSecondaryDark
                                                            : AppColors.textSecondaryLight,
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
                                                                          color: AppColors.primary,
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

  Widget _buildBodyEditor(RequestParams params, bool isDark) {
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
                key: ValueKey(params.bodyMode),
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

  String _encodeBody(RequestParams params) => jsonEncode({
        '__boltBody': 1,
        'mode': params.bodyMode.name,
        'text': params.body,
        'fields': [
          for (final field in params.formFields)
            {
              'key': field.key,
              'value': field.value,
              'isFile': field.isFile,
              'isEnabled': field.isEnabled,
            },
        ],
      });

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
    _activeRequestId = request.id;
    _activeRequestName = request.name;
    _urlController.text = request.url;
    final notifier = ref.read(httpClientProvider.notifier);
    notifier.updateUrl(request.url);

    BodyMode bodyMode = BodyMode.json;
    String? bodyText = request.body;
    List<FormFieldItem> formFields = [];
    if (request.body != null) {
      try {
        final decoded = jsonDecode(request.body!);
        if (decoded is Map && decoded['__boltBody'] == 1) {
          bodyMode = BodyMode.values.firstWhere(
            (mode) => mode.name == decoded['mode'],
            orElse: () => BodyMode.json,
          );
          bodyText = decoded['text'] as String?;
          final fields = decoded['fields'];
          if (fields is List) {
            formFields = fields.whereType<Map>().map((field) {
              return FormFieldItem(
                key: field['key']?.toString() ?? '',
                value: field['value']?.toString() ?? '',
                isFile: field['isFile'] == true,
                isEnabled: field['isEnabled'] != false,
              );
            }).toList();
          }
        }
      } on FormatException {
        // Plain text from older saved requests remains a JSON editor body.
      }
    }
    _bodyText = bodyText ?? '';
    notifier.updateBody(_bodyText);
    notifier.updateBodyMode(bodyMode);
    notifier.updateFormFields(formFields);

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
      request.headersJson,
      (item) => HeaderItem(
        key: item['key']?.toString() ?? '',
        value: item['value']?.toString() ?? '',
        isEnabled: item['isEnabled'] != false,
      ),
    ));
    notifier.updateQueryParams(decodeItems(
      request.queryParamsJson,
      (item) => QueryParamItem(
        key: item['key']?.toString() ?? '',
        value: item['value']?.toString() ?? '',
        isEnabled: item['isEnabled'] != false,
      ),
    ));

    final method = HttpMethod.values.firstWhere(
      (m) => m.name.toUpperCase() == request.method.toUpperCase(),
      orElse: () => HttpMethod.get,
    );
    ref.read(httpClientProvider.notifier).updateMethod(method);
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