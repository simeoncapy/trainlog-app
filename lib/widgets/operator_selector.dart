import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/providers/trainlog_provider.dart';

/// Content for the "operator" block:
///  - Text field with autocomplete suggestions (inline, not overlay)
///  - Multiple operators support (comma or Enter to add)
///  - Suggestions shown above or below depending on screen space
///  - Logos (or text badge if unknown), each with a close button
///  - Auto-scrolls to the right when a new logo is added
///
/// Usage:
///   final key = GlobalKey<OperatorSelectorState>();
///   ...
///   OperatorSelector(key: key)
///   ...
///   final value = key.currentState?.finalValue ?? '';
class OperatorSelector extends StatefulWidget {
  const OperatorSelector({Key? key}) : super(key: key);

  @override
  OperatorSelectorState createState() => OperatorSelectorState();
}

class OperatorSelectorState extends State<OperatorSelector> {
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _logosScrollController = ScrollController();

  // Key to measure the TextFormField position on screen
  final GlobalKey _fieldKey = GlobalKey();

  // Validated operators (those already turned into logos)
  final List<String> _selectedOperators = [];

  // Autocomplete suggestions
  List<String> _suggestions = [];

  // Whether to show suggestions above the field (if not enough space below)
  bool _showSuggestionsAbove = false;

  static const double _suggestionsMaxHeight = 220;

  @override
  void initState() {
    super.initState();

    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        // Hide suggestions when field loses focus
        setState(() {
          _suggestions = [];
        });
      }
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _focusNode.dispose();
    _logosScrollController.dispose();
    super.dispose();
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
    // Commit completed parts separated by commas, keep last fragment in field.
    if (value.contains(',')) {
      final parts = value.split(',');
      for (int i = 0; i < parts.length - 1; i++) {
        _commitRawOperator(parts[i]);
      }
      final remaining = parts.last;
      _inputController.value = TextEditingValue(
        text: remaining,
        selection: TextSelection.collapsed(offset: remaining.length),
      );
    }

    _updateSuggestions(fieldContext);
  }

  void _onSubmitted(String value) {
    _commitRawOperator(value);
    _inputController.clear();
    setState(() {
      _suggestions = [];
    });
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

    setState(() {
      _selectedOperators.add(trimmed);
    });

    _scrollLogosToEnd();
  }

  void _removeOperator(String name) {
    setState(() {
      _selectedOperators.remove(name);
    });
  }

  // ─────────────────────────────────────────────────────────────
  // Suggestions (inline, above or below)
  // ─────────────────────────────────────────────────────────────

  void _updateSuggestions(BuildContext fieldContext) {
    final query = _inputController.text.trim();
    final trainlog = context.read<TrainlogProvider>();

    if (!_focusNode.hasFocus || query.isEmpty) {
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
              // Must run BEFORE the field loses focus
              _addOperator(op);
              // Clear input
              _inputController.clear();
              // Keep keyboard open
              _focusNode.requestFocus();
              // Hide suggestions
              setState(() {
                _suggestions = [];
              });
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
        // If we should show suggestions above the field, render them first.
        if (_showSuggestionsAbove && _suggestions.isNotEmpty)
          _buildSuggestionsBox(context),

        // Text field with key for position measurement
        Builder(
          builder: (fieldContext) {
            return Container(
              key: _fieldKey,
              child: TextFormField(
                controller: _inputController,
                focusNode: _focusNode,
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

        // If we show suggestions below, render them here.
        if (!_showSuggestionsAbove && _suggestions.isNotEmpty)
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
                    children:
                        _selectedOperators.map(_buildOperatorChip).toList(),
                  ),
                ),
        ),
      ],
    );
  }
}
