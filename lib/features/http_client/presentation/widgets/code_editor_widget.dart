import 'package:flutter/material.dart';
import 'package:re_editor/re_editor.dart';
import 'package:re_highlight/languages/json.dart' as lang_json;
import 'package:re_highlight/styles/atom-one-light.dart' as style_light;
import 'package:re_highlight/styles/vs2015.dart' as style_dark;

class CodeEditorWidget extends StatefulWidget {
  final String initialText;
  final ValueChanged<String> onChanged;
  final bool isDark;
  final bool readOnly;
  final bool syntaxHighlight;

  const CodeEditorWidget({
    super.key,
    required this.initialText,
    required this.onChanged,
    required this.isDark,
    this.readOnly = false,
    this.syntaxHighlight = true,
  });

  @override
  State<CodeEditorWidget> createState() => _CodeEditorWidgetState();
}

class _CodeEditorWidgetState extends State<CodeEditorWidget> {
  late final CodeLineEditingController _controller;
  bool _editorReady = false;

  @override
  void initState() {
    super.initState();

    _controller = CodeLineEditingController.fromText(widget.initialText);

    _controller.addListener(_handleTextChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _editorReady = true;
    });
  }

  void _handleTextChanged() {
    if (!_editorReady) return;

    widget.onChanged(_controller.text);
  }

  @override
  void didUpdateWidget(covariant CodeEditorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.initialText != widget.initialText &&
        _controller.text != widget.initialText) {
      _controller.text = widget.initialText;
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleTextChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme =
        widget.isDark ? style_dark.vs2015Theme : style_light.atomOneLightTheme;

    return CodeEditor(
      controller: _controller,
      readOnly: widget.readOnly,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      style: CodeEditorStyle(
        fontSize: 13,
        fontFamily: 'monospace',
        fontHeight: 1.45,
        textColor:
            widget.isDark ? const Color(0xFFD4D4D4) : const Color(0xFF24292F),
        backgroundColor:
            widget.isDark ? const Color(0xFF181824) : const Color(0xFFFCFCFD),
        codeTheme: CodeHighlightTheme(
          languages: widget.syntaxHighlight
              ? {
                  'json': CodeHighlightThemeMode(mode: lang_json.langJson),
                }
              : const {},
          theme: theme,
        ),
      ),
      indicatorBuilder: (
        context,
        editingController,
        chunkController,
        notifier,
      ) {
        return DefaultCodeLineNumber(
          controller: editingController,
          notifier: notifier,
          textStyle: TextStyle(
            color: widget.isDark
                ? const Color(0xFF6A9955)
                : const Color(0xFF858585),
            fontSize: 12,
          ),
        );
      },
    );
  }
}
