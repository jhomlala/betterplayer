import 'dart:async';

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// Row that shows a link. Tapping it copies the URL to the clipboard.
class PlayerAboutLinkRow extends StatefulWidget {
  const PlayerAboutLinkRow({
    required this.url,
    required this.semanticsIdentifier,
    required this.copiedLabel,
    required this.isCupertino,
    this.label,
    super.key,
  });

  final String url;
  final String? label;
  final String semanticsIdentifier;
  final String copiedLabel;
  final bool isCupertino;

  @override
  State<PlayerAboutLinkRow> createState() => _PlayerAboutLinkRowState();
}

class _PlayerAboutLinkRowState extends State<PlayerAboutLinkRow> {
  static const Duration _copiedDuration = Duration(seconds: 2);

  Timer? _resetTimer;
  bool _copied = false;

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }

  Future<void> _copyUrl() async {
    await Clipboard.setData(ClipboardData(text: widget.url));
    if (!mounted) return;
    setState(() => _copied = true);
    _resetTimer?.cancel();
    _resetTimer = Timer(_copiedDuration, () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final linkColor = widget.isCupertino
        ? CupertinoTheme.of(context).primaryColor
        : Theme.of(context).colorScheme.primary;
    return Semantics(
      identifier: widget.semanticsIdentifier,
      label: widget.url,
      button: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _copyUrl,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              children: [
                Text(
                  widget.label ?? widget.url,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: linkColor,
                    decoration: TextDecoration.underline,
                    decorationColor: linkColor,
                  ),
                ),
                if (_copied) Text(widget.copiedLabel),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
