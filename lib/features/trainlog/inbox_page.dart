import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/data/models/news_model.dart';
import 'package:trainlog_app/providers/settings_provider.dart';
import 'package:trainlog_app/providers/trainlog_provider.dart';
import 'package:trainlog_app/utils/date_utils.dart';
import 'package:trainlog_app/utils/platform_utils.dart';
import 'package:trainlog_app/widgets/error_banner.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';

class InboxPage extends StatefulWidget {
  const InboxPage({super.key});

  static String pageTitle(BuildContext context) => AppLocalizations.of(context)!.inboxPageTitle;

  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> {
  bool _isLoading = true;
  List<NewsModel> _newsList = [];

  @override
  void initState() {
    super.initState();
    _loadNews();
  }

  Future<void> _loadNews() async {
    final settings = context.read<SettingsProvider>();
    final trainlog = context.read<TrainlogProvider>();

    setState(() {
      _isLoading = true;
    });

    try {
      final listNews = await trainlog.fetchNews(settings);
      debugPrint('Fetched ${listNews.length} news items');
      
      if (mounted) {
        setState(() {
          _newsList = listNews;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching news: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Impossible to load the news")),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _newsDisplayDialog(NewsModel news) async {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final hasBeenModified = news.created != news.lastModified;
    final modificationDateLabel = hasBeenModified 
                                ? loc.inboxModifiedIndication(formatDateTime(context, news.lastModified)) 
                                : "";
    final isAdmin = news.author == "admin";

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog.fullscreen(
          child: Scaffold(
            appBar: AppBar(
              title: Text(news.title),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Author and date info
                  Row(
                    children: [
                      _authorBadgeHelper(isAdmin, theme, news.author),
                      const SizedBox(width: 8,),
                      Text(
                        formatDateTime(context, news.created),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  if(modificationDateLabel.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                        modificationDateLabel,
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ),
                  ],
                  const SizedBox(height: 16),
                  // Content
                  Text(
                    news.content,
                    style: theme.textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _newsTile(
    NewsModel news,
    AppLocalizations loc, 
    ThemeData theme,
  ) {
    final hasBeenModified = news.created != news.lastModified;
    final modificationDateLabel = hasBeenModified ? " ${loc.inboxModified}" : "";
    final isAdmin = news.author == "admin";

    return Card(
      child: ListTile(
        titleAlignment: ListTileTitleAlignment.center,
        title: Row(
          children: [
            Expanded(
              child: Text(
                news.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            if (news.isNew) ...[
              const SizedBox(width: 8),
              Badge(
                backgroundColor: Colors.red,
                label: Text(loc.newBadge),
                textColor: Colors.white,
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _authorBadgeHelper(isAdmin, theme, news.author),
                const SizedBox(width: 8,),
                Expanded(
                  child: Text(
                    "${formatDateTime(context, news.created)}$modificationDateLabel",
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
            Text(
              news.content,
              maxLines: 3, // Limits to a maximum of 2 lines
              overflow: TextOverflow.ellipsis,
            )
          ],
        ),
        isThreeLine: true,
        onTap: () {          
          _newsDisplayDialog(news);
          setState(() {
            news.haveBeenRead();
          });
        },
      ),
    );
  }

  Container _authorBadgeHelper(bool isAdmin, ThemeData theme, String author) {
    Color bkg = isAdmin ? Colors.orange : theme.colorScheme.secondaryContainer;
    Color frg = isAdmin ? Colors.black : theme.colorScheme.onSecondaryContainer;

    return Container(
      decoration: BoxDecoration(
        color: bkg, // Orange if isAdmin is true, dark blue otherwise
        borderRadius: BorderRadius.circular(2), // Rounded corners with a radius of 12
      ),
      padding: EdgeInsets.only(left:4, right: 4),
      margin: EdgeInsets.only(top:4),
      child: Row(
        children: [
          if (isAdmin) ... [ Icon(Symbols.crown, size: 16, color: frg), // Icon appears if isAdmin is true
          SizedBox(width: 4) ], // Space between the icon and the text
          Text(
            author,
            style: TextStyle(
              color: frg,
            ),
          ),
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final theme = Theme.of(context);

    if(AppPlatform.isApple) {
      return _bodyHelper(locale, loc, theme);
    }

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text(loc.inboxPageTitle),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        body: _bodyHelper(locale, loc, theme),
      ),
    );
  }

  Padding _bodyHelper(String locale, AppLocalizations loc, ThemeData theme) {
    return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            if (locale != "en") ...[
              ErrorBanner(
                severity: ErrorSeverity.info,
                compact: true,
                message: loc.pageNotAvailableInUserLanguage,
              ),
              SizedBox(height: 8,)
            ],
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                    //padding: const EdgeInsets.only(bottom: 80), // Avoid the last item to be hidden by the FAB
                    itemCount: _newsList.length,
                    itemBuilder: (context, index) {
                      final record = _newsList[index];

                      return _newsTile(record, loc, theme);
                    },
                  ),
            ),
          ],
        ),
      );
  }
}