import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/request_params.dart';
import '../controllers/http_client_provider.dart';
import '../../../../core/localization/app_localizations.dart';

class AuthEditorView extends ConsumerWidget {
  const AuthEditorView({super.key, required this.auth});

  final RequestAuth auth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(httpClientProvider.notifier);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<AuthType>(
            initialValue: auth.type,
            decoration: InputDecoration(
              labelText:
                  context.tr('Authentication type', 'Tipo de autenticação'),
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: [
              DropdownMenuItem(
                value: AuthType.none,
                child: Text(context.tr('None', 'Nenhuma')),
              ),
              DropdownMenuItem(
                value: AuthType.bearer,
                child: Text('Bearer Token'),
              ),
              const DropdownMenuItem(
                  value: AuthType.basic, child: Text('Basic Auth')),
              const DropdownMenuItem(value: AuthType.apiKey, child: Text('API Key')),
            ],
            selectedItemBuilder: (context) => [
              Text(context.tr('None', 'Nenhuma')),
              const Text('Bearer Token'),
              const Text('Basic Auth'),
              const Text('API Key'),
            ],
            onChanged: (type) {
              if (type != null) notifier.updateAuth(auth.copyWith(type: type));
            },
          ),
          const SizedBox(height: 16),
          if (auth.type == AuthType.bearer)
            _field(
              context.tr('Token', 'Token'),
              auth.token,
              (value) => notifier.updateAuth(auth.copyWith(token: value)),
              secret: true,
            ),
          if (auth.type == AuthType.basic) ...[
            _field(
              context.tr('Username', 'Nome de usuário'),
              auth.username,
              (value) => notifier.updateAuth(auth.copyWith(username: value)),
            ),
            const SizedBox(height: 12),
            _field(
              context.tr('Password', 'Senha'),
              auth.password,
              (value) => notifier.updateAuth(auth.copyWith(password: value)),
              secret: true,
            ),
          ],
          if (auth.type == AuthType.apiKey) ...[
            Row(
              children: [
                Expanded(
                  child: _field(
                    context.tr('Key', 'Chave'),
                    auth.apiKeyName,
                    (value) =>
                        notifier.updateAuth(auth.copyWith(apiKeyName: value)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _field(
                    context.tr('Value', 'Valor'),
                    auth.apiKeyValue,
                    (value) =>
                        notifier.updateAuth(auth.copyWith(apiKeyValue: value)),
                    secret: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SegmentedButton<ApiKeyLocation>(
              segments: [
                ButtonSegment(
                  value: ApiKeyLocation.header,
                  label: Text(context.tr('Header', 'Header')),
                  icon: Icon(Icons.short_text),
                ),
                ButtonSegment(
                  value: ApiKeyLocation.query,
                  label: Text(context.tr('Query Param', 'Parâmetro de consulta')),
                  icon: Icon(Icons.link),
                ),
              ],
              selected: {auth.apiKeyLocation},
              onSelectionChanged: (selection) => notifier.updateAuth(
                auth.copyWith(apiKeyLocation: selection.first),
              ),
            ),
          ],
          if (auth.type == AuthType.none)
            Text(context.tr(
              'This request will be sent without authentication.',
              'Esta requisição será enviada sem autenticação.',
            )),
        ],
      ),
    );
  }

  Widget _field(
    String label,
    String value,
    ValueChanged<String> onChanged, {
    bool secret = false,
  }) {
    return _AuthField(
      key: ValueKey('${auth.type.name}-$label'),
      label: label,
      value: value,
      secret: secret,
      onChanged: onChanged,
    );
  }
}

class _AuthField extends StatefulWidget {
  const _AuthField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.secret = false,
  });

  final String label;
  final String value;
  final bool secret;
  final ValueChanged<String> onChanged;

  @override
  State<_AuthField> createState() => _AuthFieldState();
}

class _AuthFieldState extends State<_AuthField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _AuthField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_controller.text != widget.value) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      obscureText: widget.secret,
      decoration: InputDecoration(
        labelText: widget.label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      onChanged: widget.onChanged,
    );
  }
}
