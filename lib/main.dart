

import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:soulsound/Helpers/config.dart';
import 'package:soulsound/Helpers/handle_native.dart';
import 'package:soulsound/Helpers/route_handler.dart';
import 'package:soulsound/Screens/Home/home.dart';
import 'package:soulsound/Screens/Library/downloads.dart';
import 'package:soulsound/Screens/Library/nowplaying.dart';
import 'package:soulsound/Screens/Library/playlists.dart';
import 'package:soulsound/Screens/Library/recent.dart';
import 'package:soulsound/Screens/Login/auth.dart';
import 'package:soulsound/Screens/Login/pref.dart';
import 'package:soulsound/Screens/Player/audioplayer.dart';
import 'package:soulsound/Screens/Settings/setting.dart';
import 'package:soulsound/Services/audio_service.dart';
import 'package:soulsound/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Paint.enableDithering = true;

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await Hive.initFlutter('SoulSound');
  } else {
    await Hive.initFlutter();
  }
  await openHiveBox('settings');
  await openHiveBox('downloads');
  await openHiveBox('Favorite Songs');
  await openHiveBox('cache', limit: true);
  if (Platform.isAndroid) {
    setOptimalDisplayMode();
  }
  await startService();
  runApp(MyApp());
}

Future<void> setOptimalDisplayMode() async {
  final List<DisplayMode> supported = await FlutterDisplayMode.supported;
  final DisplayMode active = await FlutterDisplayMode.active;

  final List<DisplayMode> sameResolution = supported
      .where(
        (DisplayMode m) => m.width == active.width && m.height == active.height,
      )
      .toList()
    ..sort(
      (DisplayMode a, DisplayMode b) => b.refreshRate.compareTo(a.refreshRate),
    );

  final DisplayMode mostOptimalMode =
      sameResolution.isNotEmpty ? sameResolution.first : active;

  await FlutterDisplayMode.setPreferredMode(mostOptimalMode);
}

Future<void> startService() async {
  final AudioPlayerHandler audioHandler = await AudioService.init(
    builder: () => AudioPlayerHandlerImpl(),
    config: AudioServiceConfig(
      androidNotificationChannelId: 'com.shadow.soulsound.channel.audio',
      androidNotificationChannelName: 'SoulSound',
      androidNotificationOngoing: true,
      androidNotificationIcon: 'drawable/ic_stat_music_note',
      androidShowNotificationBadge: true,
      // androidStopForegroundOnPause: Hive.box('settings')
      // .get('stopServiceOnPause', defaultValue: true) as bool,
      notificationColor: Colors.grey[900],
    ),
  );
  GetIt.I.registerSingleton<AudioPlayerHandler>(audioHandler);
  GetIt.I.registerSingleton<MyTheme>(MyTheme());
}

Future<void> openHiveBox(String boxName, {bool limit = false}) async {
  final box = await Hive.openBox(boxName).onError((error, stackTrace) async {
    final Directory dir = await getApplicationDocumentsDirectory();
    final String dirPath = dir.path;
    File dbFile = File('$dirPath/$boxName.hive');
    File lockFile = File('$dirPath/$boxName.lock');
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      dbFile = File('$dirPath/SoulSound/$boxName.hive');
      lockFile = File('$dirPath/SoulSound/$boxName.lock');
    }
    await dbFile.delete();
    await lockFile.delete();
    await Hive.openBox(boxName);
    throw 'Failed to open $boxName Box\nError: $error';
  });
  // clear box if it grows large
  if (limit && box.length > 500) {
    box.clear();
  }
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();

  static _MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>()!;
}

class _MyAppState extends State<MyApp> {
  Locale _locale = const Locale('en', '');

  @override
  void initState() {
    super.initState();
    callIntent();
    final String lang =
        Hive.box('settings').get('lang', defaultValue: 'English') as String;
    final Map<String, String> codes = {
      'Chinese': 'zh',
      'Czech': 'cs',
      'Dutch': 'nl',
      'English': 'en',
      'French': 'fr',
      'German': 'de',
      'Hindi': 'hi',
      'Indonesian': 'id',
      'Portuguese': 'pt',
      'Russian': 'ru',
      'Spanish': 'es',
      'Tamil': 'ta',
      'Turkish': 'tr',
      'Ukrainian': 'uk',
    };
    _locale = Locale(codes[lang]!);

    AppTheme.currentTheme.addListener(() {
      setState(() {});
    });
  }

  Future<void> callIntent() async {
    await NativeMethod.handleIntent();
  }

  void setLocale(Locale value) {
    setState(() {
      _locale = value;
    });
  }

  Widget initialFuntion() {
    return Hive.box('settings').get('userId') != null
        ? HomePage()
        : AuthScreen();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppTheme.themeMode == ThemeMode.dark
            ? Colors.black38
            : Colors.white,
        statusBarIconBrightness: AppTheme.themeMode == ThemeMode.dark
            ? Brightness.light
            : Brightness.dark,
        systemNavigationBarIconBrightness: AppTheme.themeMode == ThemeMode.dark
            ? Brightness.light
            : Brightness.dark,
      ),
    );
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    return MaterialApp(
      title: 'SoulSound',
      restorationScopeId: 'soulsound',
      debugShowCheckedModeBanner: false,
      themeMode: AppTheme.themeMode,
      theme: AppTheme.lightTheme(
        context: context,
      ),
      darkTheme: AppTheme.darkTheme(
        context: context,
      ),
      locale: _locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh', ''), // Chinese
        Locale('cs', ''), // Czech
        Locale('nl', ''), // Dutch
        Locale('en', ''), // English, no country code
        Locale('fr', ''), // French
        Locale('de', ''), // German
        Locale('hi', ''), // Hindi
        Locale('id', ''), // Indonesian
        Locale('pt', ''), // Portuguese
        Locale('ru', ''), // Russian
        Locale('es', ''), // Spanish
        Locale('ta', ''), // Tamil
        Locale('tr', ''), // Turkish
        Locale('uk', ''), // Ukrainian
      ],
      routes: {
        '/': (context) => HomePage(),
        '/pref': (context) => const PrefScreen(),
        '/setting': (context) => const SettingPage(),
        '/playlists': (context) => PlaylistScreen(),
        '/nowplaying': (context) => NowPlaying(),
        '/recent': (context) => RecentlyPlayed(),
        '/downloads': (context) => const Downloads(),
        // '/featured':
      },
      onGenerateRoute: (RouteSettings settings) {
        return HandleRoute().handleRoute(settings.name);
      },
    );
  }
}
