import 'dart:io';
import 'dart:math';

import 'package:soulsound/CustomWidgets/custom_physics.dart';
import 'package:soulsound/CustomWidgets/gradient_containers.dart';
import 'package:soulsound/CustomWidgets/miniplayer.dart';
import 'package:soulsound/CustomWidgets/snackbar.dart';
import 'package:soulsound/CustomWidgets/textinput_dialog.dart';
import 'package:soulsound/Helpers/backup_restore.dart';
import 'package:soulsound/Helpers/downloads_checker.dart';
import 'package:soulsound/Helpers/supabase.dart';
import 'package:soulsound/Screens/Home/saavn.dart';
import 'package:soulsound/Screens/Library/library.dart';
import 'package:soulsound/Screens/LocalMusic/downed_songs.dart';
import 'package:soulsound/Screens/Search/search.dart';
import 'package:soulsound/Screens/Settings/setting.dart';
import 'package:soulsound/Screens/Top Charts/top.dart';
import 'package:soulsound/Screens/YouTube/youtube_home.dart';
import 'package:soulsound/Services/ext_storage_provider.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ValueNotifier<int> _selectedIndex = ValueNotifier<int>(0);
  bool checked = false;
  String? appVersion;
  String name =
      Hive.box('settings').get('name', defaultValue: 'Guest') as String;
  bool checkUpdate =
      Hive.box('settings').get('checkUpdate', defaultValue: false) as bool;
  bool autoBackup =
      Hive.box('settings').get('autoBackup', defaultValue: false) as bool;
  DateTime? backButtonPressTime;

  String capitalize(String msg) {
    return '${msg[0].toUpperCase()}${msg.substring(1)}';
  }

  void callback() {
    setState(() {});
  }

  void _onItemTapped(int index) {
    _selectedIndex.value = index;
    _pageController.jumpToPage(
      index,
    );
  }

  bool compareVersion(String latestVersion, String currentVersion) {
    bool update = false;
    final List latestList = latestVersion.split('.');
    final List currentList = currentVersion.split('.');

    for (int i = 0; i < latestList.length; i++) {
      try {
        if (int.parse(latestList[i] as String) >
            int.parse(currentList[i] as String)) {
          update = true;
          break;
        }
      } catch (e) {
        break;
      }
    }
    return update;
  }

  void updateUserDetails(String key, dynamic value) {
    final userId = Hive.box('settings').get('userId') as String?;
    SupaBase().updateUserDetails(userId, key, value);
  }

  Future<bool> handleWillPop(BuildContext context) async {
    final now = DateTime.now();
    final backButtonHasNotBeenPressedOrSnackBarHasBeenClosed =
        backButtonPressTime == null ||
            now.difference(backButtonPressTime!) > const Duration(seconds: 3);

    if (backButtonHasNotBeenPressedOrSnackBarHasBeenClosed) {
      backButtonPressTime = now;
      ShowSnackBar().showSnackBar(
        context,
        AppLocalizations.of(context)!.exitConfirm,
        duration: const Duration(seconds: 2),
        noAction: true,
      );
      return false;
    }
    return true;
  }

  Widget checkVersion() {
    if (!checked && Theme.of(context).platform == TargetPlatform.android) {
      checked = true;
      final SupaBase db = SupaBase();
      final DateTime now = DateTime.now();
      final List lastLogin = now
          .toUtc()
          .add(const Duration(hours: 5, minutes: 30))
          .toString()
          .split('.')
        ..removeLast()
        ..join('.');
      updateUserDetails('lastLogin', '${lastLogin[0]} IST');
      final String offset =
          now.timeZoneOffset.toString().replaceAll('.000000', '');

      updateUserDetails(
        'timeZone',
        'Zone: ${now.timeZoneName}, Offset: $offset',
      );

      PackageInfo.fromPlatform().then((PackageInfo packageInfo) {
        appVersion = packageInfo.version;
        updateUserDetails('version', packageInfo.version);

        if (checkUpdate) {
          db.getUpdate().then((Map value) async {
            if (compareVersion(
              value['LatestVersion'] as String,
              appVersion!,
            )) {
              List? abis =
                  await Hive.box('settings').get('supportedAbis') as List?;

              if (abis == null) {
                final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
                final AndroidDeviceInfo androidDeviceInfo =
                    await deviceInfo.androidInfo;
                abis = androidDeviceInfo.supportedAbis;
                await Hive.box('settings').put('supportedAbis', abis);
              }

              ShowSnackBar().showSnackBar(
                context,
                AppLocalizations.of(context)!.updateAvailable,
                duration: const Duration(seconds: 15),
                action: SnackBarAction(
                  textColor: Theme.of(context).colorScheme.secondary,
                  label: AppLocalizations.of(context)!.update,
                  onPressed: () {
                    Navigator.pop(context);
                    if (abis!.contains('arm64-v8a')) {
                      launch(value['arm64-v8a'] as String);
                    } else {
                      if (abis.contains('armeabi-v7a')) {
                        launch(value['armeabi-v7a'] as String);
                      } else {
                        launch(value['universal'] as String);
                      }
                    }
                  },
                ),
              );
            }
          });
        }
        if (autoBackup) {
          final List<String> checked = [
            AppLocalizations.of(
              context,
            )!
                .settings,
            AppLocalizations.of(
              context,
            )!
                .downs,
            AppLocalizations.of(
              context,
            )!
                .playlists,
          ];
          final List playlistNames = Hive.box('settings').get(
            'playlistNames',
            defaultValue: ['Favorite Songs'],
          ) as List;
          final Map<String, List> boxNames = {
            AppLocalizations.of(
              context,
            )!
                .settings: ['settings'],
            AppLocalizations.of(
              context,
            )!
                .cache: ['cache'],
            AppLocalizations.of(
              context,
            )!
                .downs: ['downloads'],
            AppLocalizations.of(
              context,
            )!
                .playlists: playlistNames,
          };
          final String autoBackPath = Hive.box('settings').get(
            'autoBackPath',
            defaultValue: '',
          ) as String;
          if (autoBackPath == '') {
            ExtStorageProvider.getExtStorage(
              dirName: 'SoulSound/Backups',
            ).then((value) {
              Hive.box('settings').put('autoBackPath', value);
              createBackup(
                context,
                checked,
                boxNames,
                path: value,
                fileName: 'SoulSound_AutoBackup',
                showDialog: false,
              );
            });
          } else {
            createBackup(
              context,
              checked,
              boxNames,
              path: autoBackPath,
              fileName: 'SoulSound_AutoBackup',
              showDialog: false,
            );
          }
        }
      });
      if (Hive.box('settings').get('proxyIp') == null) {
        Hive.box('settings').put('proxyIp', '103.47.67.134');
      }
      if (Hive.box('settings').get('proxyPort') == null) {
        Hive.box('settings').put('proxyPort', 8080);
      }
      downloadChecker();
      return const SizedBox();
    } else {
      return const SizedBox();
    }
  }

  final ScrollController _scrollController = ScrollController();
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.transparent,
        drawer: Drawer(
          child: GradientContainer(
            child: CustomScrollView(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  backgroundColor: Colors.transparent,
                  automaticallyImplyLeading: false,
                  elevation: 0,
                  stretch: true,
                  expandedHeight: MediaQuery.of(context).size.height * 0.2,
                  flexibleSpace: FlexibleSpaceBar(
                    title: RichText(
                      text: TextSpan(
                        text: AppLocalizations.of(context)!.appTitle,
                        style: const TextStyle(
                          fontSize: 30.0,
                          fontWeight: FontWeight.w500,
                        ),
                        children: const <TextSpan>[
                          TextSpan(
                            text: '',
                            style: TextStyle(
                              fontSize: 7.0,
                            ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.end,
                    ),
                    titlePadding: const EdgeInsets.only(bottom: 40.0),
                    centerTitle: true,
                    background: ShaderMask(
                      shaderCallback: (rect) {
                        return LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.8),
                            Colors.black.withOpacity(0.1),
                          ],
                        ).createShader(
                          Rect.fromLTRB(0, 0, rect.width, rect.height),
                        );
                      },
                      blendMode: BlendMode.dstIn,
                      child: Image(
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                        image: AssetImage(
                          Theme.of(context).brightness == Brightness.dark
                              ? 'assets/header-dark.jpg'
                              : 'assets/header.jpg',
                        ),
                      ),
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      ListTile(
                        title: Text(
                          AppLocalizations.of(context)!.home,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 20.0),
                        leading: Icon(
                          Icons.home_rounded,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        selected: true,
                        onTap: () {
                          Navigator.pop(context);
                        },
                      ),
                      if (Platform.isAndroid)
                        ListTile(
                          title: Text(AppLocalizations.of(context)!.myMusic),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 20.0),
                          leading: Icon(
                            MdiIcons.folderMusic,
                            color: Theme.of(context).iconTheme.color,
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const DownloadedSongs(
                                  showPlaylists: true,
                                ),
                              ),
                            );
                          },
                        ),
                      ListTile(
                        title: Text(AppLocalizations.of(context)!.downs),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 20.0),
                        leading: Icon(
                          Icons.download_done_rounded,
                          color: Theme.of(context).iconTheme.color,
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/downloads');
                        },
                      ),
                      ListTile(
                        title: Text(AppLocalizations.of(context)!.playlists),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 20.0),
                        leading: Icon(
                          Icons.playlist_play_rounded,
                          color: Theme.of(context).iconTheme.color,
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/playlists');
                        },
                      ),
                      ListTile(
                        title: Text(AppLocalizations.of(context)!.settings),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 20.0),
                        leading: Icon(
                          Icons
                              .settings_rounded, // miscellaneous_services_rounded,
                          color: Theme.of(context).iconTheme.color,
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  SettingPage(callback: callback),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        body: WillPopScope(
          onWillPop: () => handleWillPop(context),
          child: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: PageView(
                    physics: const CustomPhysics(),
                    onPageChanged: (indx) {
                      _selectedIndex.value = indx;
                    },
                    controller: _pageController,
                    children: [
                      Stack(
                        children: [
                          NestedScrollView(
                            physics: const BouncingScrollPhysics(),
                            controller: _scrollController,
                            headerSliverBuilder:
                                (BuildContext context, bool innerBoxScrolled) {
                              return <Widget>[
                                SliverAppBar(
                                  automaticallyImplyLeading: false,
                                  pinned: true,
                                  backgroundColor: Colors.transparent,
                                  elevation: 0,
                                  stretch: true,
                                  toolbarHeight: 65,
                                  title: Align(
                                    alignment: Alignment.centerRight,
                                    child: AnimatedBuilder(
                                      animation: _scrollController,
                                      builder: (context, child) {
                                        return GestureDetector(
                                          child: AnimatedContainer(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.8,
                                            height: 52.0,
                                            duration: const Duration(
                                              milliseconds: 150,
                                            ),
                                            padding: const EdgeInsets.all(2.0),
                                            // margin: EdgeInsets.zero,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10.0),
                                              color:
                                                  Theme.of(context).cardColor,
                                              boxShadow: const [
                                                BoxShadow(
                                                  color: Colors.black26,
                                                  blurRadius: 5.0,
                                                  offset: Offset(1.5, 1.5),
                                                  // shadow direction: bottom right
                                                )
                                              ],
                                            ),
                                            child: Row(
                                              children: [
                                                const SizedBox(width: 10.0),
                                                Icon(
                                                  CupertinoIcons.search,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .secondary,
                                                ),
                                                const SizedBox(width: 10.0),
                                                Text(
                                                  AppLocalizations.of(
                                                    context,
                                                  )!
                                                      .searchText,
                                                  style: TextStyle(
                                                    fontSize: 16.0,
                                                    color: Theme.of(context)
                                                        .textTheme
                                                        .caption!
                                                        .color,
                                                    fontWeight:
                                                        FontWeight.normal,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          onTap: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const SearchPage(
                                                query: '',
                                                fromHome: true,
                                                autofocus: true,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ];
                            },
                            body: SaavnHomePage(),
                          ),
                          Builder(
                            builder: (context) => Padding(
                              padding:
                                  const EdgeInsets.only(top: 8.0, left: 4.0),
                              child: Transform.rotate(
                                angle: 22 / 7 * 2,
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.horizontal_split_rounded,
                                  ),
                                  // color: Theme.of(context).iconTheme.color,
                                  onPressed: () {
                                    Scaffold.of(context).openDrawer();
                                  },
                                  tooltip: MaterialLocalizations.of(context)
                                      .openAppDrawerTooltip,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      TopCharts(
                        pageController: _pageController,
                      ),
                      const YouTube(),
                      const LibraryPage(),
                    ],
                  ),
                ),
                const MiniPlayer()
              ],
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: ValueListenableBuilder(
            valueListenable: _selectedIndex,
            builder: (BuildContext context, int indexValue, Widget? child) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                height: 60,
                child: SalomonBottomBar(
                  currentIndex: indexValue,
                  onTap: (index) {
                    _onItemTapped(index);
                  },
                  items: [
                    /// Home
                    SalomonBottomBarItem(
                      icon: const Icon(Icons.home_rounded),
                      title: Text(AppLocalizations.of(context)!.home),
                      selectedColor: Theme.of(context).colorScheme.secondary,
                    ),

                    SalomonBottomBarItem(
                      icon: const Icon(Icons.trending_up_rounded),
                      title: Text(AppLocalizations.of(context)!.spotifyCharts),
                      selectedColor: Theme.of(context).colorScheme.secondary,
                    ),
                    SalomonBottomBarItem(
                      icon: const Icon(MdiIcons.youtube),
                      title: Text(AppLocalizations.of(context)!.youTube),
                      selectedColor: Theme.of(context).colorScheme.secondary,
                    ),
                    SalomonBottomBarItem(
                      icon: const Icon(Icons.my_library_music_rounded),
                      title: Text(AppLocalizations.of(context)!.library),
                      selectedColor: Theme.of(context).colorScheme.secondary,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
