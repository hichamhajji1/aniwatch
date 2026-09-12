import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/motion/ani_motion.dart';
import 'core/theme/app_theme.dart';
import 'data/services/jikan_api_service.dart';
import 'data/services/notification_service.dart';
import 'data/services/remote_config_service.dart';
import 'data/services/storage_service.dart';
import 'state/catalog_provider.dart';
import 'state/journal_provider.dart';
import 'state/progress_provider.dart';
import 'state/reminder_provider.dart';
import 'state/watchlist_provider.dart';
import 'views/onboarding/onboarding_view.dart';
import 'views/splash/splash_view.dart';
import 'widgets/main_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final prefs = await SharedPreferences.getInstance();
  final storage = StorageService(prefs);
  final remoteConfig = RemoteConfigService();
  await NotificationService.instance.init();

  runApp(
    AniApp(
      storage: storage,
      api: JikanApiService(),
      remoteConfig: remoteConfig,
    ),
  );
}

class AniApp extends StatelessWidget {
  const AniApp({
    super.key,
    required this.storage,
    required this.api,
    required this.remoteConfig,
  });

  final StorageService storage;
  final JikanApiService api;
  final RemoteConfigService remoteConfig;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<StorageService>.value(value: storage),
        Provider<RemoteConfigService>.value(value: remoteConfig),
        ChangeNotifierProvider(create: (_) => CatalogProvider(api)),
        ChangeNotifierProvider(create: (_) => WatchlistProvider(storage)..load()),
        ChangeNotifierProvider(create: (_) => ProgressProvider(storage)..load()),
        ChangeNotifierProvider(
          create: (_) => ReminderProvider(storage, NotificationService.instance)..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => JournalProvider(storage, NotificationService.instance)..load(),
        ),
      ],
      child: MaterialApp(
        title: 'AnShow Anime show',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.luxuryDark(),
        scrollBehavior: const _AniScrollBehavior(),
        home: _RootGate(remoteConfig: remoteConfig),
      ),
    );
  }
}

class _RootGate extends StatefulWidget {
  const _RootGate({required this.remoteConfig});

  final RemoteConfigService remoteConfig;

  @override
  State<_RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<_RootGate> {
  bool _splashDone = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Future.wait([
      Future<void>.delayed(const Duration(milliseconds: 2600)),
      widget.remoteConfig.load(),
    ]);
    if (!mounted) return;
    if (widget.remoteConfig.showAds) {
      context.read<CatalogProvider>().loadHome();
    }
    setState(() => _splashDone = true);
  }

  Future<void> _finishOnboarding() async {
    await context.read<StorageService>().setOnboardingComplete();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final showAds = widget.remoteConfig.showAds;
    Widget child;
    if (!_splashDone) {
      child = const SplashView(key: ValueKey('splash'));
    } else if (showAds && !context.read<StorageService>().onboardingComplete) {
      child = OnboardingView(key: const ValueKey('onboarding'), onFinished: _finishOnboarding);
    } else {
      child = const MainShell(key: ValueKey('shell'));
    }
    return AnimatedSwitcher(
      duration: AniMotion.page,
      switchInCurve: AniMotion.curve,
      switchOutCurve: Curves.easeInCubic,
      child: child,
    );
  }
}

class _AniScrollBehavior extends MaterialScrollBehavior {
  const _AniScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
  }
}
