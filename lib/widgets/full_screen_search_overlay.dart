import 'package:flutter/material.dart';

class FullScreenSearchOverlay<T> extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final List<T> items;
  final Widget Function(BuildContext, T) itemBuilder;
  final void Function(T) onSelected;
  final VoidCallback onClose;
  final String hintText;
  final bool dimBackground;

  const FullScreenSearchOverlay({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.items,
    required this.itemBuilder,
    required this.onSelected,
    required this.onClose,
    required this.hintText,
    this.dimBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final media = MediaQuery.of(context);
    final keyboardHeight = media.viewInsets.bottom;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      bottom: keyboardHeight,
      child: Stack(
        children: [
          // Optional dimming
          if (dimBackground)
            GestureDetector(
              onTap: onClose,
              child: Container(color: Colors.black54),
            ),

          // Main panel
          Positioned.fill(
            child: Material(
              color: theme.colorScheme.surface,
              child: SafeArea(
                child: Column(
                  children: [
                    // Search bar
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: TextField(
                        controller: controller,
                        focusNode: focusNode,
                        autofocus: true,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerHighest,
                          hintText: hintText,
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: onClose,
                          ),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),

                    // Items / suggestions
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: items.length,
                        itemBuilder: (context, i) => InkWell(
                          onTap: () => onSelected(items[i]),
                          child: itemBuilder(context, items[i]),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
