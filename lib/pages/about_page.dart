import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/pages/privacy_tab.dart';
import 'package:trainlog_app/services/trainlog_service.dart';
import 'package:trainlog_app/utils/platform_utils.dart';
import 'package:trainlog_app/widgets/localised_markdown.dart';
import 'package:trainlog_app/widgets/localised_markdown_v2.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final languageCode = locale.languageCode;
    final mq = MediaQuery.of(context);
    final bottomPadding = mq.padding.bottom;

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Material(
            child: TabBar(
              tabs: [
                Tab(text: loc.aboutPageAboutSubPageTitle),
                Tab(text: loc.aboutPageHowToSubPageTitle),
                Tab(text: loc.aboutPagePrivacySubPageTitle),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                TrainlogProjectDescription(), // About Trainlog
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: LocalisedMarkdown(assetBaseName: 'howto', displayToc: false,),
                ),
                PrivacyHtmlTab(url: Uri.parse('${TrainlogService.baseUrl}/privacy/$languageCode')),
              ],
            ),
          ),
          if(AppPlatform.isApple)
            SizedBox(height: bottomPadding,)
        ],
      ),
    );
  }
}

class TrainlogProjectDescription extends StatelessWidget {
  const TrainlogProjectDescription({
    super.key,
  });

  Widget _buttonHelper(BuildContext context, String label, Widget icon, String url, {Color? background, Color? color})
  {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: icon,
        onPressed: () async {
          final uri = Uri.parse(url);
            if (await canLaunchUrl(uri)) {
              await launchUrl(
                uri,
                mode: LaunchMode.externalApplication,
              );
            }
        }, 
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: background ?? Theme.of(context).colorScheme.primaryContainer,
          foregroundColor: color ?? Theme.of(context).colorScheme.onPrimaryContainer,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
          elevation: 3,
        ),
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


