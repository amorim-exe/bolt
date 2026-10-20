// lib/features/home/presentation/pages/home_page.dart
import 'dart:convert';
import 'package:bolt/core/theme/theme_provider.dart';
import 'package:bolt/features/environment/presentation/environment_dialog.dart';
import 'package:bolt/features/http_client/presentation/widgets/code_editor_widget.dart';
import 'package:bolt/features/http_client/presentation/widgets/headers_editor_view.dart';
import 'package:bolt/features/http_client/presentation/widgets/params_editor_view.dart';
import 'package:bolt/features/workspace/data/models/request_entity.dart';
import 'package:bolt/features/workspace/presentation/workspace_provider.dart';
import 'package:flutter/material.dart';
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
          // Barra lateral de coleções e ferramentas
          Container(
            width: 240,
            color: surfaceColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Image.asset(
                    'assets/images/logo-bolt.png',
                    height: 32,
                  ),
                ),

                // Botão de Variáveis de Ambiente
                Material(
                  color: Colors.transparent,
                  child: ListTile(
                    leading: const Icon(Icons.code,
                        size: 18, color: AppColors.primary),
                    title:
                        const Text('Variáveis', style: TextStyle(fontSize: 14)),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => const EnvironmentDialog(),
                      );
                    },
                  ),
                ),

                // Botão de Alternar Tema (Dark/Light)
                Material(
                  color: Colors.transparent,
                  child: ListTile(
                    leading: Icon(
                      isDark ? Icons.light_mode : Icons.dark_mode,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    title: Text(
                      isDark ? 'Modo Claro' : 'Modo Escuro',
                      style: const TextStyle(fontSize: 14),
                    ),
                    onTap: () {
                      final currentMode = ref.read(themeModeProvider);
                      ref.read(themeModeProvider.notifier).state =
                          currentMode == ThemeMode.dark
                              ? ThemeMode.light
                              : ThemeMode.dark;
                    },
                  ),
                ),

                Divider(height: 1, color: borderColor),

                // Lista de Workspaces
                Expanded(
                  child: Column(
                    children: [
                      // Header com botão de adicionar workspace
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8.0, vertical: 4.0),
                        child: Row(
                          children: [
                            const Text('Workspaces',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 12)),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.add, size: 16),
                              onPressed: () => _showAddWorkspaceDialog(context),
                              tooltip: 'Adicionar Workspace',
                              padding: const EdgeInsets.all(4),
                            ),
                          ],
                        ),
                      ),
                      Divider(height: 1, color: borderColor),
                      // Lista de workspaces e requests
                      Expanded(
                        child: workspaceState.isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : ListView.builder(
                                padding: const EdgeInsets.all(4),
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
                                      // Workspace item
                                      Material(
                                        color: isSelected
                                            ? surfaceColor.withValues(
                                                alpha: 0.5)
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
                                                    ? AppColors
                                                        .textSecondaryDark
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
                                          title: Text(workspace.name,
                                              style: const TextStyle(
                                                  fontSize: 14)),
                                          trailing: IconButton(
                                            icon: const Icon(
                                                Icons.delete_outline,
                                                size: 16),
                                            onPressed: () =>
                                                _showDeleteWorkspaceDialog(
                                                    context, workspace.id),
                                            tooltip: 'Deletar Workspace',
                                            padding: const EdgeInsets.all(4),
                                          ),
                                          dense: true,
                                          onTap: () {
                                            ref
                                                .read(
                                                    workspaceProvider.notifier)
                                                .toggleWorkspaceExpanded(
                                                    workspace.id);

                                            ref
                                                .read(
                                                    workspaceProvider.notifier)
                                                .selectWorkspace(workspace.id);
                                          },
                                        ),
                                      ),
                                      // Requests do workspace (expandido)
                                      if (isExpanded)
                                        ...requests.map((request) {
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                                left: 16.0),
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
                                                title: Text(request.name,
                                                    style: const TextStyle(
                                                        fontSize: 13)),
                                                trailing: IconButton(
                                                  icon: const Icon(
                                                      Icons.delete_outline,
                                                      size: 14),
                                                  onPressed: () => ref
                                                      .read(workspaceProvider
                                                          .notifier)
                                                      .deleteRequest(
                                                          request.id),
                                                  tooltip: 'Deletar Request',
                                                  padding:
                                                      const EdgeInsets.all(4),
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
                    ],
                  ),
                ),
              ],
            ),
          ),
          VerticalDivider(width: 1, thickness: 1, color: borderColor),

          // Painel Principal de Requisição e Resposta
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
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(8),
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
                      IconButton(
                        onPressed: () => _showAddRequestDialog(context),
                        icon: const Icon(Icons.add),
                        tooltip: 'Adicionar Request',
                        style: IconButton.styleFrom(
                          backgroundColor: surfaceColor,
                          side: BorderSide(color: borderColor),
                          padding: const EdgeInsets.all(14),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _urlController,
                          onChanged: (val) => ref
                              .read(httpClientProvider.notifier)
                              .updateUrl(val),
                          decoration: InputDecoration(
                            hintText:
                                'Digite a URL da API (ex: {{baseUrl}}/todos/1)',
                            filled: true,
                            fillColor: surfaceColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
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
                              horizontal: 24, vertical: 18),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: state.isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.send, size: 16),
                        label: const Text('Send',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
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

                          await ref
                              .read(workspaceProvider.notifier)
                              .createRequest(
                                name: name,
                                url: currentState.params.url,
                                method: currentState.params.method.name,
                                headersJson:
                                    jsonEncode(currentState.params.headers),
                                queryParamsJson:
                                    jsonEncode(currentState.params.queryParams),
                                body: currentState.params.body,
                              );

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
                        icon: const Icon(Icons.save_outlined),
                        tooltip: 'Salvar Requisição',
                        style: IconButton.styleFrom(
                          backgroundColor: surfaceColor,
                          side: BorderSide(color: borderColor),
                          padding: const EdgeInsets.all(14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Área de Configuração da Requisição (Abas: Params, Headers, Body)
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
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: CodeEditorWidget(
                                    initialText: _bodyText,
                                    onChanged: (val) {
                                      _bodyText = val;
                                      ref
                                          .read(httpClientProvider.notifier)
                                          .updateBody(val);
                                    },
                                    isDark: isDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Área de Resposta
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
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              border: Border(
                                  bottom: BorderSide(color: borderColor)),
                            ),
                            child: Row(
                              children: [
                                const Text('Response',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                const Spacer(),
                                if (state.response != null) ...[
                                  _buildStatusBadge(state.response!.statusCode),
                                  const SizedBox(width: 16),
                                  _buildMetricBadge(
                                      Icons.timer_outlined,
                                      '${state.response!.responseTimeMs} ms',
                                      isDark),
                                  const SizedBox(width: 16),
                                  _buildMetricBadge(
                                      Icons.data_usage,
                                      '${state.response!.responseSizeBytes} bytes',
                                      isDark),
                                ],
                              ],
                            ),
                          ),
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
                                Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: SingleChildScrollView(
                                    child: SelectableText(
                                      state.response != null
                                          ? const JsonEncoder.withIndent('  ')
                                              .convert(state.response!.data)
                                          : 'Clique em "Send" para executar a requisição...',
                                      style: const TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 15),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: ListView(
                                    children: state.response?.headers.entries
                                            .map((entry) {
                                          return Text(
                                              '${entry.key}: ${entry.value.join(", ")}',
                                              style: const TextStyle(
                                                  fontFamily: 'monospace',
                                                  fontSize: 14));
                                        }).toList() ??
                                        const [Text('Nenhum header recebido.')],
                                  ),
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
        return Colors.blueAccent;
      case HttpMethod.put:
        return Colors.orangeAccent;
      case HttpMethod.delete:
        return AppColors.error;
      case HttpMethod.patch:
        return Colors.purpleAccent;
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
            TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14),
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
        Text(text, style: TextStyle(fontSize: 14, color: secondaryColor)),
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

  void _loadRequest(RequestEntity request) {
    _urlController.text = request.url;
    _bodyText = request.body ?? '';
    ref.read(httpClientProvider.notifier).updateUrl(request.url);
    ref.read(httpClientProvider.notifier).updateBody(request.body ?? '');

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
        return Colors.blueAccent;
      case 'PUT':
        return Colors.orangeAccent;
      case 'DELETE':
        return AppColors.error;
      case 'PATCH':
        return Colors.purpleAccent;
      default:
        return Colors.grey;
    }
  }
}
