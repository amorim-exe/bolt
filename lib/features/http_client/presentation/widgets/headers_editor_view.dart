import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../controllers/http_client_provider.dart';

class _HeaderPreset {
  final String label;
  final String key;
  final String value;

  const _HeaderPreset(this.label, this.key, this.value);
}

const _headerPresets = [
  _HeaderPreset(
      'Authorization: Bearer token', 'Authorization', 'Bearer {{token}}'),
  _HeaderPreset('Authorization: Basic', 'Authorization', 'Basic '),
  _HeaderPreset('X-API-Key', 'X-API-Key', '{{apiKey}}'),
  _HeaderPreset('Content-Type: JSON', 'Content-Type', 'application/json'),
  _HeaderPreset('Content-Type: form-urlencoded', 'Content-Type',
      'application/x-www-form-urlencoded'),
  _HeaderPreset('Accept: JSON', 'Accept', 'application/json'),
  _HeaderPreset('Accept: any format', 'Accept', '*/*'),
  _HeaderPreset('Cache-Control: no-cache', 'Cache-Control', 'no-cache'),
];

class HeadersEditorView extends ConsumerWidget {
  const HeadersEditorView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(httpClientProvider);
    final headers = state.params.headers;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(context.tr('Request Headers', 'Headers da Requisição'),
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PopupMenuButton<_HeaderPreset>(
                    tooltip:
                        context.tr('Header presets', 'Presets de headers'),
                    icon: const Icon(Icons.bolt_outlined),
                    onSelected: (preset) => ref
                        .read(httpClientProvider.notifier)
                        .addHeaderPreset(key: preset.key, value: preset.value),
                    itemBuilder: (context) => [
                      for (final preset in _headerPresets)
                        PopupMenuItem(
                          value: preset,
                          child: Text(context.tr(
                            preset.label,
                            preset.label == 'Accept: any format'
                                ? 'Accept: qualquer formato'
                                : preset.label,
                          )),
                        ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () =>
                        ref.read(httpClientProvider.notifier).addHeader(),
                    icon: const Icon(Icons.add, size: 14),
                    label: Text(context.tr('Add Header', 'Adicionar Header')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      textStyle: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: headers.isEmpty
                ? Center(
                    child: Text(
                      context.tr(
                        'No headers added yet. Click "Add Header".',
                        'Nenhum header adicionado ainda. Clique em "Adicionar Header".',
                      ),
                      style: TextStyle(color: textColor, fontSize: 14),
                    ),
                  )
                : ListView.builder(
                    itemCount: headers.length,
                    itemBuilder: (context, index) {
                      final header = headers[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            Checkbox(
                              value: header.isEnabled,
                              onChanged: (val) {
                                ref
                                    .read(httpClientProvider.notifier)
                                    .updateHeader(index,
                                        isEnabled: val ?? true);
                              },
                            ),
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller:
                                    TextEditingController(text: header.key)
                                      ..selection = TextSelection.collapsed(
                                          offset: header.key.length),
                                onChanged: (val) => ref
                                    .read(httpClientProvider.notifier)
                                    .updateHeader(index, key: val),
                                decoration: InputDecoration(
                                  hintText: context.tr(
                                    'Key (e.g. Authorization)',
                                    'Chave (ex: Authorization)',
                                  ),
                                  isDense: true,
                                  border: const OutlineInputBorder(),
                                ),
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 3,
                              child: TextField(
                                controller:
                                    TextEditingController(text: header.value)
                                      ..selection = TextSelection.collapsed(
                                          offset: header.value.length),
                                onChanged: (val) => ref
                                    .read(httpClientProvider.notifier)
                                    .updateHeader(index, value: val),
                                decoration: const InputDecoration(
                                  hintText: 'Valor (ex: Bearer token...)',
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                ),
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: AppColors.error, size: 18),
                              onPressed: () => ref
                                  .read(httpClientProvider.notifier)
                                  .removeHeader(index),
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
