import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/pages/add_ticket_page.dart';
import 'package:trainlog_app/widgets/dismissible_error_banner_block.dart';
import 'package:trainlog_app/widgets/error_banner.dart';
import 'package:trainlog_app/widgets/trainlog_web_page.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';

class TicketsPage extends StatefulWidget {
  final void Function(FloatingActionButton? fab) onFabReady;
  const TicketsPage({super.key, required this.onFabReady});

  @override
  State<TicketsPage> createState() => _TicketsPageState();
}

class _TicketsPageState extends State<TicketsPage> {
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
            trainlogPage: "ticket_list",
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
            child: const AddTicketPage(),
          ),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ));
      },
      child: const Icon(Icons.add),
    );
  }
}
