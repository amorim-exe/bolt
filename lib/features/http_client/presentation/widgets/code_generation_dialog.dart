import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/models/request_params.dart';
import '../services/request_code_generator.dart';

class CodeGenerationDialog extends StatefulWidget {
  const CodeGenerationDialog({required this.params, super.key});

  final RequestParams params;

  @override
  State<CodeGenerationDialog> createState() => _CodeGenerationDialogState();
}

class _CodeGenerationDialogState extends State<CodeGenerationDialog> {
  RequestCodeFormat _format = RequestCodeFormat.curl;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final code = RequestCodeGenerator.generate(widget.params, _format);
    final formats = {
      RequestCodeFormat.curl: 'cURL',
      RequestCodeFormat.javascript: 'JavaScript (Fetch)',
      RequestCodeFormat.python: 'Python (Requests)',
      RequestCodeFormat.dart: 'Dart (Dio)',
    };

    return AlertDialog(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      title: const Text('Generate Code'),
      content: SizedBox(
        width: 680,
        height: 440,
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                children: [
                  for (final entry in formats.entries)
                    ChoiceChip(
                      label: Text(entry.value),
                      selected: _format == entry.key,
                      selectedColor: AppColors.primary.withValues(alpha: 0.22),
                      onSelected: (_) => setState(() => _format = entry.key),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.backgroundDark
                      : AppColors.backgroundLight,
                  border: Border.all(
                    color:
                        isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    code,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      height: 1.5,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        ElevatedButton.icon(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: code));
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Code copied to clipboard'),
                duration: Duration(seconds: 1),
              ),
            );
          },
          icon: const Icon(Icons.copy, size: 16),
          label: const Text('Copy to clipboard'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: const Color(0xFF282018),
          ),
        ),
      ],
    );
  }
}
