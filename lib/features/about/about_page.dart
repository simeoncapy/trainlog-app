import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/features/about/privacy_tab.dart';
import 'package:trainlog_app/platform/adaptive_button.dart';
import 'package:trainlog_app/providers/trainlog_provider.dart';
import 'package:trainlog_app/utils/platform_utils.dart';
import 'package:trainlog_app/widgets/app_steps_tab_bar.dart';
import 'package:trainlog_app/widgets/localised_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final languageCode = locale.languageCode;
    final trainlog = Provider.of<TrainlogProvider>(context, listen: false);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: AppStepsTabBar(
            fullWidth: true,
            selectedIndex: _tabController.index,
            onTabChanged: (i) => _tabController.animateTo(i),
            tabs: [
              AppStepsTab(label: loc.aboutPageAboutSubPageTitle),
              AppStepsTab(label: loc.aboutPageHowToSubPageTitle),
              AppStepsTab(label: loc.aboutPagePrivacySubPageTitle),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              TrainlogProjectDescription(), // About Trainlog
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: LocalisedMarkdown(assetBaseName: 'howto', displayToc: false,),
              ),
              PrivacyHtmlTab(url: Uri.parse('${trainlog.instanceUrl}/privacy/$languageCode')),
            ],
          ),
        ),
        AppPlatform.bottomPadding(context),
      ],
    );
  }
}

class TrainlogProjectDescription extends StatelessWidget {
  const TrainlogProjectDescription({
    super.key,
  });

  Widget _buttonHelper(BuildContext context, String label, Widget iconWidget, String url, {Color? background, Color? color})
  {
    return SizedBox(
      width: double.infinity,
      child: AdaptiveButton.build(
        context: context,
        iconWidget: iconWidget,
        label: Text(label),
        onPressed: () async {
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(
              uri,
              mode: LaunchMode.externalApplication,
            );
          }
        },
        backgroundColor: background ?? Theme.of(context).colorScheme.primary,
        foregroundColor: color ?? Theme.of(context).colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        elevation: 3,
        size: AdaptiveButton.large,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final githubLogo = "assets/images/github-mark.svg";

    return Padding(
      padding: const EdgeInsets.only(top: 0, left: 8, right: 8, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  LocalisedMarkdown(assetBaseName: 'about', displayToc: false,),
                  SizedBox(height: 8,),
                  _buttonHelper(
                    context, 
                    loc.websiteRepoButton, 
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: SvgPicture.asset(
                        githubLogo,
                        colorFilter: ColorFilter.mode(
                          isDark ? Colors.black : Colors.white,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                    "https://github.com/BorealBaguette/Trainlog",
                    background: isDark ? Colors.grey.shade200 : Colors.black,
                    color: isDark ? Colors.black :  Colors.white
                  ),
                  SizedBox(height: 8,),
                  _buttonHelper(
                    context, 
                    loc.applicationRepoButton, 
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: SvgPicture.asset(
                        githubLogo,
                        colorFilter: ColorFilter.mode(
                          isDark ? Colors.black : Colors.white,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                    "https://github.com/simeoncapy/trainlog-app",
                    background: isDark ? Colors.grey.shade200 : Colors.black,
                    color: isDark ? Colors.black :  Colors.white
                  )
                ],
              ),
            ),
          ),
          _buttonHelper(
            context, 
            loc.supportTrainlogButton, 
            Icon(Icons.favorite, size: 24),
            "https://www.buymeacoffee.com/Trainlog"
          ),
          SizedBox(height: 12,),
          _buttonHelper(
            context, 
            loc.joinDiscordButton, 
            Icon(Icons.discord, size: 24),
            "https://discord.com/invite/2FhrFTQKvU",
            background: Color(0xFF5865F2),
            color: Colors.white
          ),
        ],
      ),
    );
  }
}


