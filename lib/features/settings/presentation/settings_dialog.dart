import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/settings/app_settings.dart';

class SettingsDialog extends ConsumerStatefulWidget {
  const SettingsDialog({super.key});

  @override
  ConsumerState<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends ConsumerState<SettingsDialog> {
  AppSettings _draft = const AppSettings();
  bool _initialized = false;
  bool _saving = false;
  String? _saveError;

  void _update(AppSettings Function(AppSettings) change) {
    setState(() {
      _draft = change(_draft);
      _saveError = null;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(appSettingsProvider.notifier).save(_draft);
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saveError = 'Não foi possível guardar as configurações: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = ref.watch(appSettingsProvider);
    if (!_initialized && !settingsState.isLoading) {
      _draft = settingsState.settings;
      _initialized = true;
    }
    return AlertDialog(
      title: const Text('Configurações'),
      content: SizedBox(
        width: 480,
        child: settingsState.isLoading
            ? const SizedBox(
                height: 160,
                child: Center(child: CircularProgressIndicator()),
              )
            : SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (settingsState.loadError != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(settingsState.loadError!),
                ),
              Text('Aparência', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              DropdownButtonFormField<ThemeMode>(
                initialValue: _draft.themeMode,
                decoration: const InputDecoration(
                  labelText: 'Tema',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: ThemeMode.system,
                    child: Text('Sistema'),
                  ),
                  DropdownMenuItem(
                    value: ThemeMode.light,
                    child: Text('Claro'),
                  ),
                  DropdownMenuItem(
                    value: ThemeMode.dark,
                    child: Text('Escuro'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    _update((settings) => settings.copyWith(themeMode: value));
                  }
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Densidade compacta'),
                subtitle: const Text('Reduz o espaçamento dos controlos'),
                value: _draft.compactDensity,
                onChanged: (value) => _update(
                  (settings) => settings.copyWith(compactDensity: value),
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Tamanho do texto'),
                subtitle: Slider(
                  value: _draft.textScale,
                  min: 0.8,
                  max: 1.4,
                  divisions: 12,
                  label: '${(_draft.textScale * 100).round()}%',
                  onChanged: (value) => _update(
                    (settings) => settings.copyWith(textScale: value),
                  ),
                ),
                trailing: Text('${(_draft.textScale * 100).round()}%'),
              ),
              const Divider(height: 24),
              Text(
                'Requisições',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Timeout'),
                subtitle: Slider(
                  value: _draft.timeoutSeconds.toDouble(),
                  min: 5,
                  max: 120,
                  divisions: 23,
                  label: '${_draft.timeoutSeconds}s',
                  onChanged: (value) => _update(
                    (settings) => settings.copyWith(
                      timeoutSeconds: (value / 5).round() * 5,
                    ),
                  ),
                ),
                trailing: Text('${_draft.timeoutSeconds}s'),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Seguir redirecionamentos'),
                value: _draft.followRedirects,
                onChanged: (value) => _update(
                  (settings) => settings.copyWith(followRedirects: value),
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Validar certificados SSL'),
                subtitle: Text(
                  _draft.verifySslCertificates
                      ? 'Certificados inválidos serão rejeitados.'
                      : 'Aviso: certificados inválidos serão aceites para todas as requisições.',
                ),
                value: _draft.verifySslCertificates,
                onChanged: (value) => _update(
                  (settings) =>
                      settings.copyWith(verifySslCertificates: value),
                ),
              ),
              if (_saveError != null) ...[
                const SizedBox(height: 8),
                Text(
                  _saveError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed:
              _saving || settingsState.isLoading ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Guardar'),
        ),
      ],
    );
  }
}
