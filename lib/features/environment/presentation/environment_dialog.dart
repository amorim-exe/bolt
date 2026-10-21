import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../http_client/presentation/controllers/http_client_provider.dart';

class EnvironmentDialog extends ConsumerWidget {
  const EnvironmentDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(httpClientProvider);
    final variables = state.variables;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final primaryTextColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return AlertDialog(
      backgroundColor: surfaceColor,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(context.tr('Environment Variables', 'Variáveis de Ambiente'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          IconButton(
            icon: const Icon(Icons.add, size: 18),
            onPressed: () => ref.read(httpClientProvider.notifier).addVariable(),
            tooltip: context.tr('Add Variable', 'Adicionar variável'),
          ),
        ],
      ),
      content: SizedBox(
        width: 450,
        height: 300,
        child: variables.isEmpty
            ? Center(child: Text(context.tr('No variables defined.', 'Nenhuma variável cadastrada.'), style: TextStyle(color: textColor)))
            : ListView.builder(
                itemCount: variables.length,
                itemBuilder: (context, index) {
                  final v = variables[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        Checkbox(
                          value: v.isEnabled,
                          onChanged: (val) => ref.read(httpClientProvider.notifier).updateVariable(index, isEnabled: val ?? true),
                        ),
                        Expanded(
                          child: TextField(
                            controller: TextEditingController(text: v.key)
                              ..selection = TextSelection.collapsed(offset: v.key.length),
                            onChanged: (val) => ref.read(httpClientProvider.notifier).updateVariable(index, key: val),
                            decoration: InputDecoration(hintText: context.tr('Key (e.g. baseUrl)', 'Chave (ex: baseUrl)'), isDense: true, border: const OutlineInputBorder()),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: TextEditingController(text: v.value)
                              ..selection = TextSelection.collapsed(offset: v.value.length),
                            onChanged: (val) => ref.read(httpClientProvider.notifier).updateVariable(index, value: val),
                            decoration: InputDecoration(hintText: context.tr('Value', 'Valor'), isDense: true, border: const OutlineInputBorder()),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 18),
                          onPressed: () => ref.read(httpClientProvider.notifier).removeVariable(index),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.tr('Close', 'Fechar'), style: TextStyle(color: primaryTextColor)),
        ),
      ],
    );
  }
}