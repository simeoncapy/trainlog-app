import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/pages/add_tag_page.dart';
import 'package:trainlog_app/widgets/dismissible_error_banner_block.dart';
import 'package:trainlog_app/widgets/error_banner.dart';
import 'package:trainlog_app/widgets/trainlog_web_page.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';

class TagsPage extends StatefulWidget {
  final void Function(FloatingActionButton? fab) onFabReady;
  const TagsPage({super.key, required this.onFabReady});

  @override
  State<TagsPage> createState() => _TagsPageState();
}

class _TagsPageState extends State<TagsPage> {
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onFabReady(buildFloatingActionButton(context)!);
      });
    
    return Column(
      children: [
        DismissibleErrorBannerBlock(
          message: loc.pageNotImplementedYet,
          severity: ErrorSeverity.warning,
        ),
        Expanded(
          child: TrainlogWebPage(
            trainlogPage: "tag_list",
          ),
        ),
      ],
    );
  }

  FloatingActionButton? buildFloatingActionButton(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        Navigator.of(context).push(PageRouteBuilder(
          pageBuilder: (_, __, ___) => ChangeNotifierProvider(
            create: (_) => null,
            child: const AddTagPage(),
          ),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ));
      },
      child: const Icon(Icons.add),
    );
  }
}
