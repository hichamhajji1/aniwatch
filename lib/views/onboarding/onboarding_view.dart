import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/motion/ani_motion.dart';
import '../../widgets/brand_logo.dart';
import '../../widgets/gold_button.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final _controller = PageController();
  int _page = 0;
  static const _pageCount = 4;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_page >= _pageCount - 1) {
      widget.onFinished();
      return;
    }
    _controller.nextPage(
      duration: AniMotion.page,
      curve: AniMotion.curve,
    );
  }

  @override
  Widget build(BuildContext context) {
    final last = _page == _pageCount - 1;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
              child: Row(
                children: [
                  const AniWordmark(size: 26),
                  const Spacer(),
                  if (!last)
                    TextButton(
                      onPressed: widget.onFinished,
                      child: const Text('Skip', style: TextStyle(color: AppColors.textSecondary)),
                    ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (value) => setState(() => _page = value),
                children: const [
                  _WelcomePage(),
                  _DiscoverPage(),
                  _ReminderGuidePage(),
                  _ReadyPage(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < _pageCount; i++)
                        AnimatedContainer(
                          duration: AniMotion.fast,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 7,
                          width: i == _page ? 22 : 7,
                          decoration: BoxDecoration(
                            color: i == _page ? AppColors.gold : Colors.white24,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  GoldButton(
                    label: last ? 'Start AnShow Anime show' : 'Continue',
                    onPressed: _next,
                    glow: last,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IntroScaffold extends StatelessWidget {
  const _IntroScaffold({
    required this.icon,
    required this.title,
    required this.body,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String body;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  child,
                  const SizedBox(height: 18),
                  Icon(icon, color: AppColors.gold, size: 28),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    body,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 15,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage();

  @override
  Widget build(BuildContext context) {
    return const _IntroScaffold(
      icon: Icons.auto_awesome_rounded,
      title: 'Your next anime adventure',
      body:
          'Browse more than 10,000 titles, save the ones you love, and pick up exactly where you left off.',
      child: _PosterStack(),
    );
  }
}

class _DiscoverPage extends StatelessWidget {
  const _DiscoverPage();

  @override
  Widget build(BuildContext context) {
    return const _IntroScaffold(
      icon: Icons.explore_rounded,
      title: 'Find, save, and watch later',
      body: 'Home, Search, and Saved work together so the next episode is never more than a tap away.',
      child: Column(
        children: [
          _FeatureTile(
            icon: Icons.home_rounded,
            title: 'Home',
            detail: 'Hero banners, top rated titles, and the current season.',
          ),
          SizedBox(height: 10),
          _FeatureTile(
            icon: Icons.search_rounded,
            title: 'Search',
            detail: 'Filter by TV, Movie, OVA, ONA, or Special.',
          ),
          SizedBox(height: 10),
          _FeatureTile(
            icon: Icons.bookmark_rounded,
            title: 'Saved',
            detail: 'Bookmarks and watched history, kept on this device.',
          ),
        ],
      ),
    );
  }
}

class _ReminderGuidePage extends StatelessWidget {
  const _ReminderGuidePage();

  @override
  Widget build(BuildContext context) {
    return const _IntroScaffold(
      icon: Icons.notifications_active_rounded,
      title: 'Never miss an episode',
      body:
          'Open any anime, tap Add reminder, and pick a date. AnShow Anime show sends a lock-screen notification when it is time to watch.',
      child: _ReminderDemo(),
    );
  }
}

class _ReadyPage extends StatelessWidget {
  const _ReadyPage();

  @override
  Widget build(BuildContext context) {
    return const _IntroScaffold(
      icon: Icons.play_circle_fill_rounded,
      title: 'Ready when you are',
      body: 'Discover titles, keep a watchlist, and get a reminder when it is time to press play.',
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 10,
        runSpacing: 10,
        children: [
          _Badge(icon: Icons.explore_rounded, label: 'Discover'),
          _Badge(icon: Icons.bookmark_rounded, label: 'Watchlist'),
          _Badge(icon: Icons.notifications_rounded, label: 'Reminders'),
        ],
      ),
    );
  }
}

class _PosterStack extends StatelessWidget {
  const _PosterStack();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 250,
      width: 280,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.translate(
            offset: const Offset(-58, 12),
            child: Transform.rotate(
              angle: -0.16,
              child: const _PosterCard(
                label: 'Cowboy Bebop',
                asset: 'assets/onboarding/cowboy.jpg',
                featured: false,
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(58, 12),
            child: Transform.rotate(
              angle: 0.16,
              child: const _PosterCard(
                label: 'Spirited Away',
                asset: 'assets/onboarding/spirited.jpg',
                featured: false,
              ),
            ),
          ),
          const _PosterCard(
            label: 'Jujutsu Kaisen',
            asset: 'assets/onboarding/jujutsu.jpg',
            featured: true,
          ),
        ],
      ),
    );
  }
}

class _PosterCard extends StatelessWidget {
  const _PosterCard({
    required this.label,
    required this.asset,
    required this.featured,
  });

  final String label;
  final String asset;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    final width = featured ? 128.0 : 108.0;
    final height = featured ? 184.0 : 156.0;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: featured ? AppColors.gold : AppColors.stroke, width: featured ? 1.6 : 1),
        boxShadow: const [
          BoxShadow(color: Color(0x66000000), blurRadius: 18, offset: Offset(0, 10)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(asset, fit: BoxFit.cover),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00000000), Color(0xCC000000)],
                ),
              ),
            ),
            Positioned(
              left: 10,
              right: 10,
              bottom: 10,
              child: Text(
                label,
                maxLines: 2,
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: featured ? 13 : 11),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({required this.icon, required this.title, required this.detail});

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: AppColors.chip, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: AppColors.gold),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(detail, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.gold),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _ReminderDemo extends StatefulWidget {
  const _ReminderDemo();

  @override
  State<_ReminderDemo> createState() => _ReminderDemoState();
}

class _ReminderDemoState extends State<_ReminderDemo> {
  int _step = 0;
  Timer? _timer;

  static const _labels = ['1. Open a title', '2. Pick date & time', '3. Get notified'];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 2200), (_) {
      if (!mounted) return;
      setState(() => _step = (_step + 1) % 3);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 248,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.stroke),
            ),
            child: Stack(
              children: [
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 280),
                  opacity: _step == 0 ? 1 : 0.18,
                  child: const _DemoAnimeCard(),
                ),
                if (_step == 1)
                  const Align(alignment: Alignment.bottomCenter, child: _DemoPicker()),
                if (_step == 2)
                  const Align(alignment: Alignment.topCenter, child: _DemoNotification()),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (var i = 0; i < _labels.length; i++)
              Expanded(
                child: Text(
                  _labels[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: i == _step ? AppColors.gold : AppColors.textMuted,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _DemoAnimeCard extends StatelessWidget {
  const _DemoAnimeCard();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(10)),
              child: Image(
                image: AssetImage('assets/onboarding/jujutsu.jpg'),
                width: 52,
                height: 74,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Jujutsu Kaisen', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  Text('2023  ·  TV', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset('assets/onboarding/jujutsu.jpg', fit: BoxFit.cover),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x33000000), Color(0x99000000)],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        const _OutlineAction(icon: Icons.notifications_none_rounded, label: 'Add reminder'),
      ],
    );
  }
}

class _OutlineAction extends StatelessWidget {
  const _OutlineAction({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.chip,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gold),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.gold, size: 18),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _DemoPicker extends StatelessWidget {
  const _DemoPicker();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Remind me to watch', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          const Row(
            children: [
              _MiniChip(label: 'Day', value: '24'),
              _MiniChip(label: 'Month', value: 'Aug'),
              _MiniChip(label: 'Hour', value: '08 PM'),
              _MiniChip(label: 'Min', value: '30'),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(12)),
            child: const Text(
              'Set reminder',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF1A1408), fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(color: AppColors.chip, borderRadius: BorderRadius.circular(10)),
        child: Column(
          children: [
            Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _DemoNotification extends StatelessWidget {
  const _DemoNotification();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xF21B1B1B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.stroke),
      ),
      child: const Row(
        children: [
          BrandLogo(size: 32, radius: 8),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('AnShow Anime show', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                Text(
                  'Time to watch Jujutsu Kaisen',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          Text('now', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
        ],
      ),
    );
  }
}
