import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/providers/trainlog_provider.dart';
import 'package:trainlog_app/widgets/full_screen_search_overlay.dart';

class OperatorSelector extends StatefulWidget {
  final List<String>? initialOperators;
  final ValueChanged<List<String>>? onChanged;

  const OperatorSelector({
    super.key,
    this.initialOperators,
    this.onChanged,
  });

  @override
  OperatorSelectorState createState() => OperatorSelectorState();
}

class OperatorSelectorState extends State<OperatorSelector> {
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _fieldFocusNode = FocusNode();        // main form field
  final FocusNode _overlayFocusNode = FocusNode();      // overlay search field
  final ScrollController _logosScrollController = ScrollController();

  final GlobalKey _fieldKey = GlobalKey();

  final List<String> _selectedOperators = [];
  List<String> _suggestions = [];

  bool _showSuggestionsAbove = false;
  static const double _suggestionsMaxHeight = 220;

  OverlayEntry? _overlayEntry;
  bool _operatorsLoaded = false;

  @override
  void initState() {
    super.initState();

    if (widget.initialOperators != null) {
      _selectedOperators.addAll(widget.initialOperators!);
    }

    _fieldFocusNode.addListener(() {
      if (_fieldFocusNode.hasFocus) _showOverlay();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_operatorsLoaded) return;
    _operatorsLoaded = true;

    final trainlog = context.read<TrainlogProvider>();
    trainlog.reloadOperatorList();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _fieldFocusNode.dispose();
    _overlayFocusNode.dispose();
    _logosScrollController.dispose();
    super.dispose();
  }

  void clear() {
    setState(() {
      _selectedOperators.clear();
      _inputController.clear();
      _suggestions.clear();
    });
    widget.onChanged?.call([]);
  }

  /// Public getter: final value = selected operators + current text (comma separated)
  String get finalValue {
    final current = _inputController.text.trim();
    return [
      ..._selectedOperators,
      if (current.isNotEmpty) current,
    ].join(',');
  }

  // ─────────────────────────────────────────────────────────────
  // Input handling
  // ─────────────────────────────────────────────────────────────

  void _onTextChanged(String value, BuildContext fieldContext) {
    bool committed = false;
    debugPrint("OperatorSelector: text changed: '$value'");
    // Commit parts separated by commas
    if (value.contains(',')) {
      final parts = value.split(',');
      for (int i = 0; i < parts.length - 1; i++) {
        _commitRawOperator(parts[i]);
        committed = true;
      }

      final remaining = parts.last;
      _inputController.value = TextEditingValue(
        text: remaining,
        selection: TextSelection.collapsed(offset: remaining.length),
      );
    }

    // If we committed at least one operator while overlay is open,
    // close overlay (Option 2 behaviour).
    if (committed && _overlayEntry != null) {
      _closeOverlayAndReset();
      return;
    }

    if (_overlayEntry == null) {
      _updateSuggestions(fieldContext);
    } else {
      _updateSuggestionsOverlay();
    }
  }

  void _onOverlayTextChanged(String value) {
    // Commit parts separated by commas
    if (value.contains(',')) {
      final parts = value.split(',');

      _addOperator(parts.first.trim());
      _closeOverlayAndReset();
    }
  }

  void _onSubmitted(String value) {
    // Enter pressed in overlay or main field: commit once and close overlay.
    _commitRawOperator(value);
    _closeOverlayAndReset();
  }

  /// Take a raw string from input and add it as operator (matching known if possible).
  void _commitRawOperator(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return;

    final trainlog = context.read<TrainlogProvider>();
    final closest = trainlog.getClosestOperators(trimmed, limit: 1);
    String toAdd = trimmed;

    if (closest.isNotEmpty &&
        closest.first.toLowerCase() == trimmed.toLowerCase()) {
      // Exact match (case-insensitive): use canonical operator name
      toAdd = closest.first;
    }

    _addOperator(toAdd);
  }

  void _addOperator(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    if (_selectedOperators.contains(trimmed)) return;

    setState(() => _selectedOperators.add(trimmed));

    widget.onChanged?.call(List.from(_selectedOperators));

    _scrollLogosToEnd();
  }

  void _removeOperator(String name) {
    setState(() => _selectedOperators.remove(name));
    widget.onChanged?.call(List.from(_selectedOperators));
  }

  // ─────────────────────────────────────────────────────────────
  // Inline suggestions (for non-overlay usage, e.g. desktop)
  // ─────────────────────────────────────────────────────────────

  void _updateSuggestions(BuildContext fieldContext) {
    if (_overlayEntry != null) return;

    final query = _inputController.text.trim();
    final trainlog = context.read<TrainlogProvider>();

    if (!_fieldFocusNode.hasFocus || query.isEmpty) {
      setState(() {
        _suggestions = [];
      });
      return;
    }

    final results = trainlog.getClosestOperators(query, limit: 10);

    bool showAbove = _showSuggestionsAbove;
    if (results.isNotEmpty) {
      final box = _fieldKey.currentContext?.findRenderObject() as RenderBox?;
      if (box != null) {
        final fieldOffset = box.localToGlobal(Offset.zero);
        final fieldSize = box.size;
        final screenHeight = MediaQuery.of(fieldContext).size.height;
        final spaceBelow = screenHeight - (fieldOffset.dy + fieldSize.height);
        showAbove = spaceBelow < _suggestionsMaxHeight;
      }
    }

    setState(() {
      _suggestions = results;
      _showSuggestionsAbove = showAbove;
    });
  }

  Widget _buildSuggestionsBox(BuildContext context) {
    if (_suggestions.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      constraints: const BoxConstraints(
        maxHeight: _suggestionsMaxHeight,
      ),
      child: ListView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: _suggestions.length,
        itemBuilder: (context, index) {
          final op = _suggestions[index];
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) {
              _addOperator(op);
              _closeOverlayAndReset();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              child: Text(op),
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Overlay autocomplete (mobile-style)
  // ─────────────────────────────────────────────────────────────

  OverlayEntry _buildOverlay() {
  final loc = AppLocalizations.of(context)!;
  return OverlayEntry(
    builder: (context) {
      return FullScreenSearchOverlay<String>(
        controller: _inputController,
        focusNode: _overlayFocusNode,
        items: _suggestions,
        hintText: loc.addTripOperatorHint,
        onChanged: _onOverlayTextChanged,
        onSubmitted: _onSubmitted,
        onSelected: (op) {
          _addOperator(op);
          _closeOverlayAndReset();
        },
        onClose: _closeOverlayAndReset,
        itemBuilder: (context, op) {
          final trainlog = context.read<TrainlogProvider>();
          final hasLogo = trainlog.hasOperatorLogo(op);

          return ListTile(
            leading: hasLogo
                ? SizedBox(
                    width: 32,
                    height: 32,
                    child: trainlog.getOperatorImage(
                      op,
                      maxWidth: 32,
                      maxHeight: 32,
                    ),
                  )
                : const Icon(Icons.train),
            title: Text(op),
          );
        },
      );
    },
  );
}


  void _showOverlay() {
    if (_overlayEntry != null) return;

    _overlayEntry = _buildOverlay();
    Overlay.of(context).insert(_overlayEntry!);

    _updateSuggestionsOverlay();
  }

  void _closeOverlayAndReset() {
    // Remove overlay if present
    _overlayEntry?.remove();
    _overlayEntry = null;

    // Clear text & suggestions
    _inputController.clear();
    _suggestions = [];

    // Unfocus both fields: form field should end up empty and unfocused
    _overlayFocusNode.unfocus();
    _fieldFocusNode.unfocus();

    if (mounted) setState(() {});
  }

  void _updateSuggestionsOverlay() {
    final query = _inputController.text.trim();
    final trainlog = context.read<TrainlogProvider>();

    if (query.isEmpty) {
      _suggestions = [];
    } else {
      _suggestions = trainlog.getClosestOperators(query, limit: 10);
    }

    _overlayEntry?.markNeedsBuild();
  }

  // ─────────────────────────────────────────────────────────────
  // Logos area
  // ─────────────────────────────────────────────────────────────

  void _scrollLogosToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_logosScrollController.hasClients) {
        _logosScrollController.animateTo(
          _logosScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildOperatorChip(String op) {
    final trainlog = context.read<TrainlogProvider>();
    final theme = Theme.of(context);

    final hasLogo = trainlog.hasOperatorLogo(op);

    Widget content;
    if (hasLogo) {
      final img = trainlog.getOperatorImage(
        op,
        maxWidth: 80,
        maxHeight: 48,
      );
      content = ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: img,
      );
    } else {
      // Text badge as "logo" for unknown operator
      content = Tooltip(
        message: op,
        child: Container(
          width: 160,
          height: 48,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            op,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Stack(
        children: [
          content,
          Positioned(
            top: 2,
            right: 2,
            child: GestureDetector(
              onTap: () => _removeOperator(op),
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  size: 12,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // If we should show suggestions above the field (inline mode)
        if (_overlayEntry == null && _showSuggestionsAbove && _suggestions.isNotEmpty)
          _buildSuggestionsBox(context),

        // Text field with key for position measurement
        Builder(
          builder: (fieldContext) {
            return Container(
              key: _fieldKey,
              child: TextFormField(
                controller: _inputController,
                focusNode: _fieldFocusNode,
                decoration: InputDecoration(
                  labelText: loc.nameField,
                  prefixIcon: const Icon(Icons.business),
                  border: const OutlineInputBorder(),
                  helperText: loc.addTripOperatorHelper,
                  helperMaxLines: 2,
                ),
                onChanged: (value) => _onTextChanged(value, fieldContext),
                onFieldSubmitted: _onSubmitted,
              ),
            );
          },
        ),

        if (_overlayEntry == null && !_showSuggestionsAbove && _suggestions.isNotEmpty)
          _buildSuggestionsBox(context),

        const SizedBox(height: 12),

        Container(
          height: 72,
          width: double.infinity,
          decoration: BoxDecoration(
            color: _selectedOperators.isEmpty
                ? theme.colorScheme.surfaceContainerHighest
                : null,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.dividerColor),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          alignment: _selectedOperators.isEmpty ? Alignment.center : Alignment.centerLeft,
          child: _selectedOperators.isEmpty
              ? Text(
                  loc.addTripOperatorPlaceholderLogo,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.hintColor,
                  ),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  controller: _logosScrollController,
                  child: Row(
                    children: _selectedOperators.map(_buildOperatorChip).toList(),
                  ),
                ),
        ),
      ],
    );
  }
}
