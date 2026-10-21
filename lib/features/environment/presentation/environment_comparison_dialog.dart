import 'dart:convert';

import 'package:bolt/core/constants/app_colors.dart';
import 'package:bolt/core/localization/app_localizations.dart';
import 'package:bolt/core/settings/app_settings.dart';
import 'package:bolt/features/environment/domain/environment_comparison_result.dart';
import 'package:bolt/features/environment/domain/environment_model.dart';
import 'package:bolt/features/http_client/presentation/controllers/http_client_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EnvironmentComparisonDialog extends ConsumerStatefulWidget {
  const EnvironmentComparisonDialog({super.key});

  @override
  ConsumerState<EnvironmentComparisonDialog> createState() =>
      _EnvironmentComparisonDialogState();
}

class _EnvironmentComparisonDialogState
    extends ConsumerState<EnvironmentComparisonDialog> {
  late List<EnvironmentProfile> _profiles;
  final Set<String> _selectedProfiles = {};
  List<EnvironmentComparisonResult>? _results;
  bool _isRunning = false;
  String? _error;
  String? _notice;

  @override
  void initState() {
    super.initState();
    _profiles = [
      for (final profile
          in ref.read(appSettingsProvider).settings.environmentProfiles)
        profile.copyWith(
          variables: [
            for (final variable in profile.variables)
              EnvironmentVariable(
                key: variable.key,
                value: variable.value,
                isEnabled: variable.isEnabled,
              ),
          ],
        ),
    ];
  }

  Future<void> _saveProfiles() async {
    final settings = ref.read(appSettingsProvider).settings;
    await ref.read(appSettingsProvider.notifier).save(
          settings.copyWith(
            environmentProfiles: [
              for (final profile in _profiles)
                profile.copyWith(
                  variables: List.unmodifiable(profile.variables),
                ),
            ],
          ),
        );
  }

  void _addProfile() {
    final currentVariables = ref.read(httpClientProvider).variables;
    final profile = EnvironmentProfile(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: context.tr('Environment ${_profiles.length + 1}',
          'Ambiente ${_profiles.length + 1}'),
      variables: [
        for (final variable in currentVariables)
          EnvironmentVariable(
            key: variable.key,
            value: variable.value,
            isEnabled: variable.isEnabled,
          ),
      ],
    );
    setState(() {
      _profiles.add(profile);
      _selectedProfiles.add(profile.id);
      _error = null;
    });
  }

  void _updateProfile(int index, EnvironmentProfile profile) {
    _profiles[index] = profile;
  }

  void _addVariable(int profileIndex) {
    final profile = _profiles[profileIndex];
    _updateProfile(
      profileIndex,
      profile.copyWith(
        variables: [
          ...profile.variables,
          EnvironmentVariable(key: '', value: ''),
        ],
      ),
    );
    setState(() {});
  }

  void _removeVariable(int profileIndex, int variableIndex) {
    final profile = _profiles[profileIndex];
    final variables = List<EnvironmentVariable>.from(profile.variables)
      ..removeAt(variableIndex);
    setState(
      () => _updateProfile(
        profileIndex,
        profile.copyWith(variables: variables),
      ),
    );
    setState(() {});
  }

  void _updateVariable(
    int profileIndex,
    int variableIndex, {
    String? key,
    String? value,
    bool? isEnabled,
  }) {
    final profile = _profiles[profileIndex];
    final variables = List<EnvironmentVariable>.from(profile.variables);
    final variable = variables[variableIndex];
    variables[variableIndex] = EnvironmentVariable(
      key: key ?? variable.key,
      value: value ?? variable.value,
      isEnabled: isEnabled ?? variable.isEnabled,
    );
    _updateProfile(profileIndex, profile.copyWith(variables: variables));
  }

  Future<void> _compare() async {
    if (_selectedProfiles.isEmpty || _isRunning) return;
    final currentRequestName =
        context.tr('Current request', 'Request atual');
    setState(() {
      _isRunning = true;
      _error = null;
      _notice = null;
    });
    try {
      await _saveProfiles();
      final current = ref.read(httpClientProvider);
      final profiles = <EnvironmentProfile>[
        EnvironmentProfile(
          id: 'current',
          name: currentRequestName,
          variables: current.variables,
        ),
        for (final profile in _profiles)
          if (_selectedProfiles.contains(profile.id)) profile,
      ];
      final results = await ref
          .read(httpClientProvider.notifier)
          .compareEnvironments(profiles);
      if (mounted) {
        setState(() {
          _results = results;
          _isRunning = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = context.tr(
            'Could not compare environments: $error',
            'Não foi possível comparar os ambientes: $error',
          );
          _isRunning = false;
        });
      }
    }
  }

  Future<void> _saveAndReport() async {
    try {
      await _saveProfiles();
      if (mounted) {
        setState(() {
          _error = null;
          _notice = context.tr('Environments saved.', 'Ambientes salvos.');
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = context.tr(
            'Could not save environments: $error',
            'Não foi possível salvar os ambientes: $error',
          );
          _notice = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final border = dark ? AppColors.borderDark : AppColors.borderLight;
    final panel = dark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final muted =
        dark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    return Dialog(
      child: SizedBox(
        width: 780,
        height: 620,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.compare_arrows, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      context.tr(
                        'Compare environments',
                        'Comparar ambientes',
                      ),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: context.tr('Close', 'Fechar'),
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                context.tr(
                  'Run the active request with different variable sets. The current request is always included.',
                  'Execute a request ativa com diferentes conjuntos de variáveis. A request atual é sempre incluída.',
                ),
                style: TextStyle(color: muted, fontSize: 12),
              ),
              const SizedBox(height: 14),
              if (_results == null)
                Expanded(
                  child: _buildProfiles(border, panel, muted),
                )
              else
                Expanded(
                  child: _buildResults(border, panel, muted),
                ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: AppColors.error)),
              ],
              if (_notice != null) ...[
                const SizedBox(height: 8),
                Text(_notice!, style: const TextStyle(color: AppColors.accent)),
              ],
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (_results != null)
                    TextButton.icon(
                      onPressed: () => setState(() => _results = null),
                      icon: const Icon(Icons.edit_outlined),
                      label: Text(context.tr(
                        'Edit environments',
                        'Editar ambientes',
                      )),
                    )
                  else
                    TextButton.icon(
                    onPressed: _saveAndReport,
                      icon: const Icon(Icons.save_outlined),
                      label: Text(context.tr('Save', 'Salvar')),
                    ),
                  const SizedBox(width: 8),
                  if (_results == null)
                    FilledButton.icon(
                      onPressed:
                          _selectedProfiles.isEmpty || _isRunning ? null : _compare,
                      icon: _isRunning
                          ? const SizedBox(
                              height: 14,
                              width: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.play_arrow_rounded),
                      label: Text(context.tr(
                        'Compare',
                        'Comparar',
                      )),
                    )
                  else
                    TextButton(
                      onPressed: () => setState(() => _results = null),
                      child: Text(context.tr('Done', 'Concluir')),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfiles(Color border, Color panel, Color muted) {
    final currentVariables = ref.read(httpClientProvider).variables;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: panel,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: border),
          ),
          child: Row(
            children: [
              const Icon(Icons.radio_button_checked, color: AppColors.accent),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('Current request', 'Request atual'),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      context.tr(
                        '${currentVariables.length} variables from the active tab',
                        '${currentVariables.length} variáveis da aba ativa',
                      ),
                      style: TextStyle(color: muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Text(
                context.tr('Always included', 'Sempre incluída'),
                style: TextStyle(color: muted, fontSize: 11),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Text(
                context.tr('Saved environments', 'Ambientes salvos'),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            TextButton.icon(
              onPressed: _addProfile,
              icon: const Icon(Icons.add, size: 16),
              label: Text(context.tr('Add environment', 'Adicionar ambiente')),
            ),
          ],
        ),
        Expanded(
          child: _profiles.isEmpty
              ? Center(
                  child: Text(
                    context.tr(
                      'Add an environment to compare it with the current request.',
                      'Adicione um ambiente para compará-lo com a request atual.',
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: muted),
                  ),
                )
              : ListView.builder(
                  itemCount: _profiles.length,
                  itemBuilder: (context, index) => _EnvironmentProfileCard(
                    profile: _profiles[index],
                    selected:
                        _selectedProfiles.contains(_profiles[index].id),
                    borderColor: border,
                    mutedColor: muted,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedProfiles.add(_profiles[index].id);
                        } else {
                          _selectedProfiles.remove(_profiles[index].id);
                        }
                      });
                    },
                    onProfileChanged: (profile) =>
                        _updateProfile(index, profile),
                    onAddVariable: () => _addVariable(index),
                    onUpdateVariable: (variableIndex,
                            {key, value, isEnabled}) =>
                        _updateVariable(
                      index,
                      variableIndex,
                      key: key,
                      value: value,
                      isEnabled: isEnabled,
                    ),
                    onRemoveVariable: (variableIndex) =>
                        _removeVariable(index, variableIndex),
                    onDelete: () {
                      setState(() {
                        _selectedProfiles.remove(_profiles[index].id);
                        _profiles.removeAt(index);
                      });
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildResults(Color border, Color panel, Color muted) {
    final results = _results!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr(
            'Response comparison',
            'Comparação das respostas',
          ),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final result in results)
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: SizedBox(
                      width: 330,
                      child: _EnvironmentResponseCard(
                        result: result,
                        panelColor: panel,
                        borderColor: border,
                        mutedColor: muted,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _EnvironmentProfileCard extends StatelessWidget {
  const _EnvironmentProfileCard({
    required this.profile,
    required this.selected,
    required this.borderColor,
    required this.mutedColor,
    required this.onSelected,
    required this.onProfileChanged,
    required this.onAddVariable,
    required this.onUpdateVariable,
    required this.onRemoveVariable,
    required this.onDelete,
  });

  final EnvironmentProfile profile;
  final bool selected;
  final Color borderColor;
  final Color mutedColor;
  final ValueChanged<bool> onSelected;
  final ValueChanged<EnvironmentProfile> onProfileChanged;
  final VoidCallback onAddVariable;
  final void Function(
    int index, {
    String? key,
    String? value,
    bool? isEnabled,
  }) onUpdateVariable;
  final ValueChanged<int> onRemoveVariable;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(
          side: BorderSide(color: borderColor),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              Row(
                children: [
                  Checkbox(value: selected, onChanged: (v) => onSelected(v ?? false)),
                  Expanded(
                    child: TextFormField(
                      key: ValueKey('environment-name-${profile.id}'),
                      initialValue: profile.name,
                      onChanged: (name) => onProfileChanged(
                        profile.copyWith(name: name),
                      ),
                      decoration: InputDecoration(
                        labelText: context.tr('Environment name', 'Nome do ambiente'),
                        isDense: true,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: context.tr('Delete environment', 'Excluir ambiente'),
                    onPressed: onDelete,
                    icon: const Icon(
                      Icons.delete_outline,
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
              for (var index = 0; index < profile.variables.length; index++)
                _EnvironmentVariableRow(
                  key: ValueKey('environment-${profile.id}-variable-$index'),
                  variable: profile.variables[index],
                  index: index,
                  mutedColor: mutedColor,
                  onChanged: onUpdateVariable,
                  onRemove: onRemoveVariable,
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: onAddVariable,
                  icon: const Icon(Icons.add, size: 15),
                  label: Text(context.tr('Add variable', 'Adicionar variável')),
                ),
              ),
            ],
          ),
        ),
      );
}

class _EnvironmentVariableRow extends StatelessWidget {
  const _EnvironmentVariableRow({
    super.key,
    required this.variable,
    required this.index,
    required this.mutedColor,
    required this.onChanged,
    required this.onRemove,
  });

  final EnvironmentVariable variable;
  final int index;
  final Color mutedColor;
  final void Function(
    int index, {
    String? key,
    String? value,
    bool? isEnabled,
  }) onChanged;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(
          children: [
            Checkbox(
              value: variable.isEnabled,
              onChanged: (value) =>
                  onChanged(index, isEnabled: value ?? true),
            ),
            Expanded(
              child: TextFormField(
                initialValue: variable.key,
                onChanged: (key) => onChanged(index, key: key),
                decoration: InputDecoration(
                  hintText: context.tr('Variable', 'Variável'),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                initialValue: variable.value,
                onChanged: (value) => onChanged(index, value: value),
                decoration: InputDecoration(
                  hintText: context.tr('Value', 'Valor'),
                  isDense: true,
                ),
              ),
            ),
            IconButton(
              tooltip: context.tr('Remove variable', 'Remover variável'),
              onPressed: () => onRemove(index),
              icon: Icon(Icons.close, size: 16, color: mutedColor),
            ),
          ],
        ),
      );
}

class _EnvironmentResponseCard extends StatelessWidget {
  const _EnvironmentResponseCard({
    required this.result,
    required this.panelColor,
    required this.borderColor,
    required this.mutedColor,
  });

  final EnvironmentComparisonResult result;
  final Color panelColor;
  final Color borderColor;
  final Color mutedColor;

  @override
  Widget build(BuildContext context) {
    final response = result.response;
    final statusColor = response.statusCode >= 500
        ? AppColors.error
        : response.statusCode >= 400
            ? Colors.orange
            : AppColors.accent;
    final body = response.data is List<int>
        ? context.tr(
            'Binary response (${response.responseSizeBytes} bytes)',
            'Resposta binária (${response.responseSizeBytes} bytes)',
          )
        : const JsonEncoder.withIndent('  ').convert(response.data);
    final truncatedBody = body.length > 4000
        ? '${body.substring(0, 4000)}\n…'
        : body;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            result.environmentName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _ResultMetric(
                label: '${response.statusCode}',
                color: statusColor,
              ),
              _ResultMetric(
                label: '${response.responseTimeMs} ms',
                color: mutedColor,
              ),
              _ResultMetric(
                label: '${response.responseSizeBytes} bytes',
                color: mutedColor,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(color: borderColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  truncatedBody,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultMetric extends StatelessWidget {
  const _ResultMetric({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
        ),
      );
}
