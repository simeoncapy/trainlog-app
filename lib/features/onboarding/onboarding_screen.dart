import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/platform/adaptive_button.dart';
import 'package:trainlog_app/providers/settings_provider.dart';
import 'package:trainlog_app/services/geo_permission_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  final GeoPermissionService _geo = const GeoPermissionService();
  int _currentPage = 0;

  static const _pageCount = 5;
  // The location-activation page is the last step and carries its own
  // primary/secondary actions instead of the shared "Next" button.
  static const _locationPageIndex = _pageCount - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < _pageCount - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      context.read<SettingsProvider>().completeOnboarding();
    }
  }

  Future<void> _activateLocation() async {
    final settings = context.read<SettingsProvider>();
    // Explicit user action: ask the OS for permission, then proceed
    // regardless of the outcome (the service records a refusal for us).
    await _geo.requestPermission(settings);
    if (!mounted) return;
    settings.completeOnboarding();
  }

  void _skipLocation() {
    final settings = context.read<SettingsProvider>();
    // Bypass the system prompt entirely and remember the refusal.
    settings.setRefusedToSharePosition(true);
    settings.completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context)!;

    final pages = [
      _OnboardingPage(
        icon: Icons.travel_explore,
        title: loc.onboardingPage1Title,
        subtitle: loc.onboardingPage1Subtitle,
        color: colorScheme.primaryContainer,
        iconColor: colorScheme.primary,
      ),
      _OnboardingPage(
        icon: Icons.bar_chart_rounded,
        title: loc.onboardingPage2Title,
        subtitle: loc.onboardingPage2Subtitle,
        color: colorScheme.secondaryContainer,
        iconColor: colorScheme.secondary,
      ),
      _OnboardingPage(
        icon: Icons.share,
        title: loc.onboardingPage3Title,
        subtitle: loc.onboardingPage3Subtitle,
        color: colorScheme.tertiaryContainer,
        iconColor: colorScheme.tertiary,
      ),
      _OnboardingPage(
        icon: Icons.emoji_events,
        title: loc.onboardingPage4Title,
        subtitle: loc.onboardingPage4Subtitle,
        color: colorScheme.errorContainer,
        iconColor: colorScheme.error,
      ),
      _LocationOnboardingPage(
        title: loc.onboardingLocationTitle,
        subtitle: loc.onboardingLocationSubtitle,
        activateLabel: loc.onboardingLocationActivate,
        skipLabel: loc.onboardingLocationSkip,
        color: colorScheme.primaryContainer,
        iconColor: colorScheme.primary,
        onActivate: _activateLocation,
        onSkip: _skipLocation,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: pages.length,
                itemBuilder: (_, i) => pages[i],
              ),
            ),
            _BottomControls(
              currentPage: _currentPage,
              pageCount: _pageCount,
              onNext: _next,
              isLast: _currentPage == _pageCount - 1,
              // The location page provides its own actions.
              showNextButton: _currentPage != _locationPageIndex,
              loc: AppLocalizations.of(context)!,
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color iconColor;

  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, size: 60, color: iconColor),
          ),
          const SizedBox(height: 40),
          Text(
            title,
            style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            subtitle,
            style: textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _BottomControls extends StatelessWidget {
  final int currentPage;
  final int pageCount;
  final VoidCallback onNext;
  final bool isLast;
  final bool showNextButton;
  final AppLocalizations loc;

  const _BottomControls({
    required this.currentPage,
    required this.pageCount,
    required this.onNext,
    required this.isLast,
    required this.showNextButton,
    required this.loc,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 16, 32, 32),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              pageCount,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: i == currentPage ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: i == currentPage
                      ? colorScheme.primary
                      : colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          if (showNextButton) ...[
            const SizedBox(height: 24),
            FilledButton(
              onPressed: onNext,
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                isLast ? loc.onboardingGetStarted : loc.nextButton,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The location-activation step of onboarding. Mirrors [_OnboardingPage]'s
/// icon/title/subtitle layout but adds a primary "Activate location" action
/// and a secondary outlined "Skip" action directly below it.
class _LocationOnboardingPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final String activateLabel;
  final String skipLabel;
  final Color color;
  final Color iconColor;
  final Future<void> Function() onActivate;
  final VoidCallback onSkip;

  const _LocationOnboardingPage({
    required this.title,
    required this.subtitle,
    required this.activateLabel,
    required this.skipLabel,
    required this.color,
    required this.iconColor,
    required this.onActivate,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(Icons.location_on, size: 60, color: iconColor),
          ),
          const SizedBox(height: 40),
          Text(
            title,
            style:
                textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            subtitle,
            style: textTheme.bodyLarge?.copyWith(
              color:
                  Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: AdaptiveButton.build(
              context: context,
              type: AdaptiveButtonType.primary,
              minimumSize: const Size(double.infinity, 52),
              size: AdaptiveButton.large,
              onPressed: () => onActivate(),
              label: Text(activateLabel),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: AdaptiveButton.build(
              context: context,
              type: AdaptiveButtonType.outlined,
              minimumSize: const Size(double.infinity, 52),
              size: AdaptiveButton.large,
              onPressed: onSkip,
              label: Text(skipLabel),
            ),
          ),
        ],
      ),
    );
  }
}
