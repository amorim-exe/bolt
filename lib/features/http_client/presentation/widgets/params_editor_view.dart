// lib/features/http_client/presentation/widgets/params_editor_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/models/request_params.dart';
import '../controllers/http_client_provider.dart';

class ParamsEditorView extends ConsumerWidget {
  const ParamsEditorView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(httpClientProvider);
    final params = state.params.queryParams;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Query Parameters',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              ElevatedButton.icon(
                onPressed: () =>
                    ref.read(httpClientProvider.notifier).addQueryParam(),
                icon: const Icon(Icons.add, size: 14),
                label: const Text('Adicionar Param'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          if (params.any((param) => param.isAutoDetected)) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.auto_awesome,
                  size: 14,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Parâmetros detetados automaticamente na URL',
                  style: TextStyle(color: textColor, fontSize: 12),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Expanded(
            child: params.isEmpty
                ? Center(
                    child: Text(
                      'Nenhum parâmetro adicionado ainda.',
                      style: TextStyle(color: textColor, fontSize: 14),
                    ),
                  )
                : ListView.builder(
                    itemCount: params.length,
                    itemBuilder: (context, index) {
                      final param = params[index];
                      return _QueryParameterRow(
                        key: ValueKey('query-param-$index'),
                        index: index,
                        param: param,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _QueryParameterRow extends ConsumerStatefulWidget {
  const _QueryParameterRow({
    super.key,
    required this.index,
    required this.param,
  });

  final int index;
  final QueryParamItem param;

  @override
  ConsumerState<_QueryParameterRow> createState() =>
      _QueryParameterRowState();
}

class _QueryParameterRowState extends ConsumerState<_QueryParameterRow> {
  late final TextEditingController _keyController;
  late final TextEditingController _valueController;

  @override
  void initState() {
    super.initState();
    _keyController = TextEditingController(text: widget.param.key);
    _valueController = TextEditingController(text: widget.param.value);
  }

  @override
  void didUpdateWidget(covariant _QueryParameterRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncController(_keyController, widget.param.key);
    _syncController(_valueController, widget.param.value);
  }

  void _syncController(TextEditingController controller, String value) {
    if (controller.text == value) return;
    controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  @override
  void dispose() {
    _keyController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(httpClientProvider.notifier);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Checkbox(
            value: widget.param.isEnabled,
            onChanged: (value) => notifier.updateQueryParam(
              widget.index,
              isEnabled: value ?? true,
            ),
          ),
          Expanded(
            flex: 2,
            child: TextField(
              controller: _keyController,
              onChanged: (value) =>
                  notifier.updateQueryParam(widget.index, key: value),
              decoration: const InputDecoration(
                hintText: 'Chave (ex: page)',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(fontSize: 14),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: TextField(
              controller: _valueController,
              onChanged: (value) =>
                  notifier.updateQueryParam(widget.index, value: value),
              decoration: InputDecoration(
                hintText: 'Valor (ex: 1)',
                isDense: true,
                border: const OutlineInputBorder(),
                suffixIcon: widget.param.isAutoDetected
                    ? const Tooltip(
                        message: 'Detetado na URL',
                        child: Icon(Icons.link, size: 16),
                      )
                    : null,
              ),
              style: const TextStyle(fontSize: 14),
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline,
              color: AppColors.error,
              size: 18,
            ),
            onPressed: () => notifier.removeQueryParam(widget.index),
          ),
        ],
      ),
    );
  }
}
