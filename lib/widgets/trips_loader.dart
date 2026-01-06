import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/providers/trips_provider.dart';
import 'package:fluttertoast/fluttertoast.dart';

class TripsLoader extends StatefulWidget {
  final Widget Function(BuildContext) builder;
  final String csvPath;
  final bool loadFromApi;

  const TripsLoader({
    super.key,
    required this.builder,
    this.csvPath = "",
    this.loadFromApi = false,
  });

  @override
  State<TripsLoader> createState() => _TripsLoaderState();
}

class _TripsLoaderState extends State<TripsLoader> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTrips();
    });
  }

  Future<void> _loadTrips() async {
    try {
      await Provider.of<TripsProvider>(context, listen: false)
          .loadTrips(csvPath: widget.csvPath, locale: Localizations.localeOf(context), loadFromApi: widget.loadFromApi);
    } catch (e) {
      Fluttertoast.showToast(
        msg: '⚠️ Failed to load trips.',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return widget.builder(context);
  }
}
