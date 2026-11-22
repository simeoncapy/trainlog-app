// Checks the layering rules described in CLAUDE.md by reading the imports
// and platform checks of every file under lib/.
//
// Each rule lists the files that broke it when the rule was introduced
// (`known`). A new file breaking a rule fails the test; so does a listed
// file that no longer breaks it, so the list only ever shrinks: remove the
// file from the list when you fix it.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

class _Rule {
  const _Rule({
    required this.name,
    required this.why,
    required this.appliesTo,
    required this.breaks,
    this.known = const {},
  });

  final String name;
  final String why;

  /// Whether the rule looks at this file (path relative to the repo root).
  final bool Function(String path) appliesTo;

  /// Whether the file's source breaks the rule.
  final bool Function(String path, String source) breaks;

  /// Files that broke the rule when it was introduced, to be fixed.
  final Set<String> known;
}

// The URI of each import or export, including those split over lines.
final _importRe = RegExp(
  r'''^\s*(?:import|export)\s+'([^']+)'[^;]*;''',
  multiLine: true,
);

Iterable<String> _imports(String source) =>
    _importRe.allMatches(source).map((m) => m.group(1)!);

bool _importsAny(String source, List<String> prefixes) =>
    _imports(source).any((i) => prefixes.any(i.startsWith));

bool _under(String path, String dir) => path.startsWith('lib/$dir/');

const _appUi = [
  'package:trainlog_app/app/',
  'package:trainlog_app/features/',
  'package:trainlog_app/navigation/',
  'package:trainlog_app/ui/',
  'package:trainlog_app/widgets/',
];

final _rules = <_Rule>[
  _Rule(
    name: 'core-has-no-views',
    why:
        'lib/core (models, repository, API, providers) is shared by both '
        'designs: it must not depend on a view, on Cupertino widgets or on '
        'Liquid Glass.',
    appliesTo: (p) => _under(p, 'core'),
    breaks: (p, s) => _importsAny(s, [
      ..._appUi,
      'package:flutter/cupertino.dart',
      'package:liquid_glass_widgets/',
    ]),
    known: {},
  ),
  _Rule(
    name: 'controllers-are-pure',
    why:
        'A screen controller (`*_controller.dart`, `*_vm.dart`) holds state '
        'and actions for both views: it imports foundation.dart, never '
        'material.dart, cupertino.dart or widgets.dart.',
    appliesTo: (p) =>
        _under(p, 'features') &&
        (p.endsWith('_controller.dart') || p.endsWith('_vm.dart')),
    breaks: (p, s) => _importsAny(s, [
      'package:flutter/material.dart',
      'package:flutter/cupertino.dart',
      'package:flutter/widgets.dart',
      'package:liquid_glass_widgets/',
      ..._appUi,
    ]),
  ),
  _Rule(
    name: 'glass-only-in-ui',
    why:
        'Liquid Glass is iOS only: liquid_glass_widgets is imported in '
        'lib/ui/cupertino (the iOS components) and lib/ui/adaptive (the '
        'facades that draw them on iOS), plus main.dart, which starts it. '
        'Screens use those components, so a Material view cannot reach a '
        'glass widget by mistake.',
    appliesTo: (p) =>
        p != 'lib/main.dart' &&
        !_under(p, 'ui/cupertino') &&
        !_under(p, 'ui/adaptive'),
    breaks: (p, s) => _importsAny(s, ['package:liquid_glass_widgets/']),
    known: {
    },
  ),
  _Rule(
    name: 'views-do-not-mix',
    why:
        'A file in a material/ folder never imports one in a cupertino/ '
        'folder, and the other way round.',
    appliesTo: (p) => p.contains('/material/') || p.contains('/cupertino/'),
    breaks: (p, s) {
      final other = p.contains('/material/') ? '/cupertino/' : '/material/';
      return _imports(
        s,
      ).any((i) => i.startsWith('package:trainlog_app/') && i.contains(other));
    },
  ),
  _Rule(
    name: 'no-platform-checks-in-screens',
    why:
        'Screens do not test the platform: each picks its view once with '
        'PlatformView, and the Material and iOS views live in their own '
        'material/ and cupertino/ folders.',
    appliesTo: (p) =>
        _under(p, 'features') ||
        _under(p, 'widgets') ||
        _under(p, 'navigation'),
    breaks: (p, s) => s.contains('AppPlatform.isApple'),
    known: {
      'lib/features/map/map_page.dart',
      'lib/features/menu/full_screen_menu_page.dart',
      'lib/features/spr/geolog_note_page.dart',
      'lib/features/spr/smart_prerecorder_page.dart',
      'lib/features/spr/widgets/pre_record_tile.dart',
      'lib/features/spr/widgets/spr_button_bar.dart',
      'lib/features/trips/detail_sheet/trip_details_bottom_sheet.dart',
      'lib/features/trips/detail_sheet/trip_details_common.dart',
      'lib/features/trips/detail_sheet/trip_details_header.dart',
      'lib/features/trips/detail_sheet/trip_details_metrics.dart',
      'lib/features/trips/trips_page.dart',
      'lib/features/trips/widgets/trip_table_view.dart',
      'lib/features/trips_edit_copy/edit_trip_path_page.dart',
      'lib/features/trips_edit_copy/widgets/edit_trip_app_bar.dart',
      'lib/features/trips_edit_copy/widgets/edit_trip_section_bar.dart',
      'lib/features/user/widgets/instance_selector_widget.dart',
    },
  ),
];

void main() {
  final files =
      Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .where((f) => !f.path.startsWith('lib/l10n/'))
          .map((f) => f.path.replaceAll(r'\', '/'))
          .toList()
        ..sort();

  for (final rule in _rules) {
    test(rule.name, () {
      final breaking = <String>{
        for (final path in files)
          if (rule.appliesTo(path) &&
              rule.breaks(path, File(path).readAsStringSync()))
            path,
      };

      final added = breaking.difference(rule.known).toList()..sort();
      final fixed = rule.known.difference(breaking).toList()..sort();

      expect(
        added,
        isEmpty,
        reason: '${rule.why}\nThese files break the rule: $added',
      );
      expect(
        fixed,
        isEmpty,
        reason:
            'These files no longer break "${rule.name}": remove them '
            'from its `known` list in test/architecture_test.dart: $fixed',
      );
    });
  }
}
