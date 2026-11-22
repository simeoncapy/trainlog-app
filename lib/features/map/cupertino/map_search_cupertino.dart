import 'dart:ui' show ImageFilter;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Theme;
import 'package:provider/provider.dart';
import 'package:trainlog_app/core/data/models/location_search_result.dart';
import 'package:trainlog_app/features/map/cupertino/location_category_cupertino.dart';
import 'package:trainlog_app/features/map/map_page_controller.dart';
import 'package:trainlog_app/features/settings/widgets/cupertino/settings_cupertino.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/ui/adaptive/adaptive_bottom_navbar.dart';
import 'package:trainlog_app/ui/cupertino/glass_search_bar.dart';
import 'package:trainlog_app/utils/text_utils.dart';

/// iOS place search of the map page, like Journal or Photos: a Liquid Glass
/// search bar docked just above the keyboard, the results in a blurred
/// panel above it. Picking a result moves the map there; Cancel or a swipe
/// down closes. Shown while [MapPageController.searchOpen]; fills the map's
/// Stack.
class CupertinoMapSearch extends StatefulWidget {
  const CupertinoMapSearch({super.key});

  /// true: the results cover the whole screen behind the search bar, under
  /// the status bar, like Journal or Photos. false: they sit in a rounded
  /// blurred panel above the bar, the map visible around it.
  static const bool fullScreenResults = true;

  @override
  State<CupertinoMapSearch> createState() => _CupertinoMapSearchState();
}

class _CupertinoMapSearchState extends State<CupertinoMapSearch> {
  final TextEditingController _text = TextEditingController();
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _close() {
    _focus.unfocus();
    context.read<MapPageController>().closeSearch();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final controller = context.watch<MapPageController>();
    final media = MediaQuery.of(context);
    // Above the keyboard, or above the tab bar once the keyboard is down.
    // The shell's Scaffold may already have shrunk the page to end at the
    // keyboard (its inset is then removed here): ask the window whether the
    // keyboard is up.
    final keyboard = media.viewInsets.bottom;
    final keyboardUp = View.of(context).viewInsets.bottom > 0;
    final bottom = keyboard > 0
        ? keyboard + 8
        : keyboardUp
        ? 8.0
        : kNavBarClearance + media.padding.bottom + 8;

    const fullScreen = CupertinoMapSearch.fullScreenResults;
    void onDragEnd(DragEndDetails d) {
      if ((d.primaryVelocity ?? 0) > 250) _close();
    }

    final searchBar = AppGlassSearchBar(
      controller: _text,
      focusNode: _focus,
      placeholder: loc.mapSearchLocationButton,
      onChanged: controller.queryChanged,
      onSubmitted: controller.submitQuery,
      onCancel: _close,
    );

    if (fullScreen) {
      return Stack(
        children: [
          // The results page: the whole screen, blurred, behind the bar.
          Positioned.fill(
            child: GestureDetector(
              onVerticalDragEnd: onDragEnd,
              child: _ResultsPanel(
                controller: controller,
                onClose: _close,
                fullScreen: true,
                bottomInset: bottom + AppGlassSearchBar.height + 8,
              ),
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            left: 12,
            right: 12,
            bottom: bottom,
            child: searchBar,
          ),
        ],
      );
    }

    return Stack(
      children: [
        // Swiping down anywhere closes, like the system search.
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            // A first tap lowers the keyboard, the next one closes.
            onTap: () => _focus.hasFocus ? _focus.unfocus() : _close(),
            onVerticalDragEnd: onDragEnd,
          ),
        ),
        AnimatedPositioned(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          left: 12,
          right: 12,
          top: media.padding.top + 8,
          bottom: bottom,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child: GestureDetector(
                  onVerticalDragEnd: onDragEnd,
                  child: _ResultsPanel(controller: controller, onClose: _close),
                ),
              ),
              const SizedBox(height: 10),
              searchBar,
            ],
          ),
        ),
      ],
    );
  }
}

/// The blurred results: the tip, "no result", the results. A rounded panel
/// above the search bar, or with [fullScreen] the whole screen, its list
/// kept clear of the status bar and of the bar ([bottomInset]).
class _ResultsPanel extends StatelessWidget {
  const _ResultsPanel({
    required this.controller,
    required this.onClose,
    this.fullScreen = false,
    this.bottomInset = 0,
  });

  final MapPageController controller;
  final VoidCallback onClose;
  final bool fullScreen;
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    final results = controller.results;

    final header = Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(CupertinoIcons.info_circle, size: 16, color: secondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  loc.mapSearchLocationTip,
                  style: textTheme.bodySmall?.copyWith(
                    color: secondary,
                    letterSpacing: 0,
                  ),
                ),
              ),
              if (controller.isSearching) ...[
                const SizedBox(width: 8),
                const CupertinoActivityIndicator(radius: 8),
              ],
            ],
          ),
          if (controller.hasNoResult) ...[
            const SizedBox(height: 12),
            Text(
              loc.mapSearchLocationNoResult,
              style: textTheme.bodyMedium?.copyWith(
                color: secondary,
                letterSpacing: 0,
              ),
            ),
          ],
        ],
      ),
    );

    return ClipRSuperellipse(
      borderRadius: BorderRadius.circular(fullScreen ? 0 : 26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
        child: ColoredBox(
          color: CupertinoColors.systemBackground
              .resolveFrom(context)
              .withValues(alpha: fullScreen ? 0.85 : 0.72),
          child: CustomScrollView(
            shrinkWrap: !fullScreen,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              if (fullScreen)
                SliverToBoxAdapter(
                  child: SizedBox(height: MediaQuery.paddingOf(context).top),
                ),
              SliverToBoxAdapter(child: header),
              SliverList.builder(
                itemCount: results.length,
                itemBuilder: (context, i) => _ResultRow(
                  place: results[i],
                  onTap: () => controller.choosePlace(results[i]),
                ),
              ),
              SliverToBoxAdapter(child: SizedBox(height: 8 + bottomInset)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultRow extends StatefulWidget {
  const _ResultRow({required this.place, required this.onTap});

  final LocationSearchResult place;
  final VoidCallback onTap;

  @override
  State<_ResultRow> createState() => _ResultRowState();
}

class _ResultRowState extends State<_ResultRow> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final place = widget.place;
    final flag = place.countryCode.isEmpty
        ? ''
        : '${countryCodeToEmoji(place.countryCode)} ';
    final category = loc.mapSearchLocationCategory(place.category.name);
    final subtitle = place.subtitle.isEmpty
        ? category
        : '$category · ${place.subtitle}';

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: Container(
        color: _pressed
            ? CupertinoColors.systemFill.resolveFrom(context)
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              CupertinoSettingsIcon(
                icon: place.category.cupertinoIcon,
                color: place.category.cupertinoColor,
                filled: place.category.cupertinoIconFilled,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$flag${place.name}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.label.resolveFrom(context),
                        letterSpacing: 0,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: CupertinoColors.secondaryLabel.resolveFrom(
                          context,
                        ),
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
