import 'package:flutter/material.dart';
import 'package:trainlog_app/core/data/models/location_search_result.dart';
import 'package:trainlog_app/features/map/location_category_icons.dart';
import 'package:trainlog_app/features/map/map_page_controller.dart';
import 'package:trainlog_app/features/trips_add/widgets/full_screen_search_overlay.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/utils/text_utils.dart';

/// The full-screen place search of the map page: a search field over the
/// app, the results below it. It shows [MapPageController]'s search and
/// tells it what is typed and picked.
///
/// A view creates one, calls [open] from its search button and [dispose]s
/// it with its state.
class MapSearchOverlay {
  MapSearchOverlay(this._controller);

  final MapPageController _controller;
  final TextEditingController _text = TextEditingController();
  final FocusNode _focus = FocusNode();
  OverlayEntry? _entry;

  bool get isOpen => _entry != null;

  /// Opens the search, empty, over the whole app.
  void open(BuildContext context) {
    if (_entry != null) return;

    _text.clear();
    _controller.openSearch();
    _controller.addListener(_rebuild);

    _entry = OverlayEntry(builder: _build);
    Overlay.of(context).insert(_entry!);

    Future.microtask(() => _focus.requestFocus());
  }

  void close() {
    if (_entry == null) return;
    _controller.removeListener(_rebuild);
    _controller.closeSearch();
    _entry?.remove();
    _entry = null;
    _focus.unfocus();
  }

  void dispose() {
    _controller.removeListener(_rebuild);
    _entry?.remove();
    _entry = null;
    _text.dispose();
    _focus.dispose();
  }

  void _rebuild() => _entry?.markNeedsBuild();

  Widget _build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return FullScreenSearchOverlay<LocationSearchResult>(
      controller: _text,
      focusNode: _focus,
      items: _controller.results,
      isLoading: _controller.isSearching,
      hintText: loc.mapSearchLocationHint,
      belowSearchField: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  loc.mapSearchLocationTip,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          if (_controller.hasNoResult) ...[
            const SizedBox(height: 12),
            Text(
              loc.mapSearchLocationNoResult,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
      onChanged: _controller.queryChanged,
      onSubmitted: _controller.submitQuery,
      itemBuilder: (context, place) {
        final flag = place.countryCode.isEmpty
            ? ''
            : '${countryCodeToEmoji(place.countryCode)} ';
        final category = loc.mapSearchLocationCategory(place.category.name);
        final subtitle = place.subtitle.isEmpty
            ? category
            : '$category · ${place.subtitle}';

        return ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              place.category.icon,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          title: Text(
            '$flag${place.name}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        );
      },
      onSelected: (place) {
        close();
        _controller.choosePlace(place);
      },
      onClose: close,
    );
  }
}
