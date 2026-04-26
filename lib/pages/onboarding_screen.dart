import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/providers/settings_provider.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _currentPage = 0;

  static const _pageCount = 4;

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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final pages = [
      _OnboardingPage(
        icon: Icons.travel_explore,
        title: 'Visualise your travels',
        subtitle:
            'Keeping track of your journeys made easy. See all your train, bus, ferry, and aeroplane journeys neatly on a map.',
        color: colorScheme.primaryContainer,
        iconColor: colorScheme.primary,
      ),
      _OnboardingPage(
        icon: Icons.bar_chart_rounded,
        title: 'Explore your statistics',
        subtitle:
            'See a statistical breakdown of how, when, and where you have travelled.\n\nGet useful statistics on your most frequently visited stations, most frequently used operators, and how much of your country\'s railway network you have been on.',
        color: colorScheme.secondaryContainer,
        iconColor: colorScheme.secondary,
      ),
      _OnboardingPage(
        icon: Icons.share,
        title: 'Share your travels',
        subtitle:
            'Create shareable links about your trips to share your travel plans with anyone.',
        color: colorScheme.tertiaryContainer,
        iconColor: colorScheme.tertiary,
      ),
      _OnboardingPage(
        icon: Icons.emoji_events,
        title: 'Leaderboards',
        subtitle:
            'Are you a frequent traveller? See how your travels stack up against other members worldwide.',
        color: colorScheme.errorContainer,
        iconColor: colorScheme.error,
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

  const _BottomControls({
    required this.currentPage,
    required this.pageCount,
    required this.onNext,
    required this.isLast,
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
              isLast ? 'Get started' : 'Next',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
