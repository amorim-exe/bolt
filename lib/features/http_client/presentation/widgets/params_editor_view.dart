// lib/features/http_client/presentation/widgets/params_editor_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
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
              const Text('Query Parameters', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ElevatedButton.icon(
                onPressed: () => ref.read(httpClientProvider.notifier).addQueryParam(),
                icon: const Icon(Icons.add, size: 14),
                label: const Text('Adicionar Param'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
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
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            Checkbox(
                              value: param.isEnabled,
                              onChanged: (val) {
                                ref.read(httpClientProvider.notifier).updateQueryParam(index, isEnabled: val ?? true);
                              },
                            ),
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: TextEditingController(text: param.key)
                                  ..selection = TextSelection.collapsed(offset: param.key.length),
                                onChanged: (val) => ref.read(httpClientProvider.notifier).updateQueryParam(index, key: val),
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
                                controller: TextEditingController(text: param.value)
                                  ..selection = TextSelection.collapsed(offset: param.value.length),
                                onChanged: (val) => ref.read(httpClientProvider.notifier).updateQueryParam(index, value: val),
                                decoration: const InputDecoration(
                                  hintText: 'Valor (ex: 1)',
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                ),
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 18),
                              onPressed: () => ref.read(httpClientProvider.notifier).removeQueryParam(index),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}