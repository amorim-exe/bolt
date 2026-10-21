import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/request_params.dart';
import '../controllers/http_client_provider.dart';

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
            decoration: const InputDecoration(
              labelText: 'Authentication type',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: const [
              DropdownMenuItem(value: AuthType.none, child: Text('None')),
              DropdownMenuItem(
                value: AuthType.bearer,
                child: Text('Bearer Token'),
              ),
              DropdownMenuItem(
                  value: AuthType.basic, child: Text('Basic Auth')),
              DropdownMenuItem(value: AuthType.apiKey, child: Text('API Key')),
            ],
            onChanged: (type) {
              if (type != null) notifier.updateAuth(auth.copyWith(type: type));
            },
          ),
          const SizedBox(height: 16),
          if (auth.type == AuthType.bearer)
            _field(
              'Token',
              auth.token,
              (value) => notifier.updateAuth(auth.copyWith(token: value)),
              secret: true,
            ),
          if (auth.type == AuthType.basic) ...[
            _field(
              'Username',
              auth.username,
              (value) => notifier.updateAuth(auth.copyWith(username: value)),
            ),
            const SizedBox(height: 12),
            _field(
              'Password',
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
                    'Key',
                    auth.apiKeyName,
                    (value) =>
                        notifier.updateAuth(auth.copyWith(apiKeyName: value)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _field(
                    'Value',
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
              segments: const [
                ButtonSegment(
                  value: ApiKeyLocation.header,
                  label: Text('Header'),
                  icon: Icon(Icons.short_text),
                ),
                ButtonSegment(
                  value: ApiKeyLocation.query,
                  label: Text('Query Param'),
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
            const Text('Esta requisição será enviada sem autenticação.'),
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
