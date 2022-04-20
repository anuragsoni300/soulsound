
import 'package:APIs/api.dart';
import 'package:CustomWidgets/artist_like_button.dart';
import 'package:CustomWidgets/bouncy_sliver_scroll_view.dart';
import 'package:CustomWidgets/copy_clipboard.dart';
import 'package:CustomWidgets/download_button.dart';
import 'package:CustomWidgets/empty_screen.dart';
import 'package:CustomWidgets/gradient_containers.dart';
import 'package:CustomWidgets/horizontal_albumlist.dart';
import 'package:CustomWidgets/like_button.dart';
import 'package:CustomWidgets/miniplayer.dart';
import 'package:CustomWidgets/playlist_popupmenu.dart';
import 'package:CustomWidgets/song_tile_trailing_menu.dart';
import 'package:Screens/Common/song_list.dart';
import 'package:Screens/Player/audioplayer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:share_plus/share_plus.dart';

class ArtistSearchPage extends StatefulWidget {
  final Map data;

  const ArtistSearchPage({
    Key? key,
    required this.data,
  }) : super(key: key);

  @override
  _ArtistSearchPageState createState() => _ArtistSearchPageState();
}

class _ArtistSearchPageState extends State<ArtistSearchPage> {
  bool status = false;
  String category = '';
  String sortOrder = '';
  Map<String, List> data = {};
  bool fetched = false;

  @override
  Widget build(BuildContext context) {
    if (!status) {
      status = true;
      SaavnAPI()
          .fetchArtistSongs(
        artistToken: widget.data['artistToken'].toString(),
        category: category,
        sortOrder: sortOrder,
      )
          .then((value) {
        setState(() {
          data = value;
          fetched = true;
        });
      });
    }
    return GradientContainer(
      child: Column(
        children: [
          Expanded(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: !fetched
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : data.isEmpty
                      ? emptyScreen(
                          context,
                          0,
                          ':( ',
                          100,
                          AppLocalizations.of(context)!.sorry,
                          60,
                          AppLocalizations.of(context)!.resultsNotFound,
                          20,
                        )
                      : BouncyImageSliverScrollView(
                          actions: [
                            IconButton(
                              icon: const Icon(Icons.share_rounded),
                              tooltip: AppLocalizations.of(context)!.share,
                              onPressed: () {
                                Share.share(
                                  widget.data['perma_url'].toString(),
                                );
                              },
                            ),
                            ArtistLikeButton(
                              data: widget.data,
                              size: 27.0,
                            ),
                            if (data['Top Songs'] != null)
                              PlaylistPopupMenu(
                                data: data['Top Songs']!,
                                title:
                                    widget.data['title']?.toString() ?? 'Songs',
                              ),
                          ],
                          title: widget.data['title']?.toString() ??
                              AppLocalizations.of(context)!.songs,
                          placeholderImage: 'assets/artist.png',
                          imageUrl: widget.data['image']
                              .toString()
                              .replaceAll('http:', 'https:')
                              .replaceAll('50x50', '500x500')
                              .replaceAll('150x150', '500x500'),
                          sliverList: SliverList(
                            delegate: SliverChildListDelegate(
                              data.entries.map(
                                (entry) {
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          left: 25,
                                          top: 15,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              entry.key,
                                              style: TextStyle(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .secondary,
                                                fontSize: 18,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            if (entry.key ==
                                                'Top Songs') ...<Widget>[
                                              const SizedBox(
                                                height: 5,
                                              ),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: <Widget>[
                                                  ChoiceChip(
                                                    label: Text(
                                                      AppLocalizations.of(
                                                        context,
                                                      )!
                                                          .popularity,
                                                    ),
                                                    selectedColor:
                                                        Theme.of(context)
                                                            .colorScheme
                                                            .secondary
                                                            .withOpacity(0.2),
                                                    labelStyle: TextStyle(
                                                      color: category == ''
                                                          ? Theme.of(context)
                                                              .colorScheme
                                                              .secondary
                                                          : Theme.of(context)
                                                              .textTheme
                                                              .bodyText1!
                                                              .color,
                                                      fontWeight: category == ''
                                                          ? FontWeight.w600
                                                          : FontWeight.normal,
                                                    ),
                                                    selected: category == '',
                                                    onSelected:
                                                        (bool selected) {
                                                      if (selected) {
                                                        category = '';
                                                        sortOrder = '';
                                                        status = false;
                                                        setState(() {});
                                                      }
                                                    },
                                                  ),
                                                  const SizedBox(
                                                    width: 5,
                                                  ),
                                                  ChoiceChip(
                                                    label: Text(
                                                      AppLocalizations.of(
                                                        context,
                                                      )!
                                                          .date,
                                                    ),
                                                    selectedColor:
                                                        Theme.of(context)
                                                            .colorScheme
                                                            .secondary
                                                            .withOpacity(0.2),
                                                    labelStyle: TextStyle(
                                                      color: category ==
                                                              'latest'
                                                          ? Theme.of(context)
                                                              .colorScheme
                                                              .secondary
                                                          : Theme.of(context)
                                                              .textTheme
                                                              .bodyText1!
                                                              .color,
                                                      fontWeight: category ==
                                                              'latest'
                                                          ? FontWeight.w600
                                                          : FontWeight.normal,
                                                    ),
                                                    selected:
                                                        category == 'latest',
                                                    onSelected:
                                                        (bool selected) {
                                                      if (selected) {
                                                        category = 'latest';
                                                        sortOrder = 'desc';
                                                        status = false;
                                                        setState(() {});
                                                      }
                                                    },
                                                  ),
                                                  const SizedBox(
                                                    width: 5,
                                                  ),
                                                  ChoiceChip(
                                                    label: Text(
                                                      AppLocalizations.of(
                                                        context,
                                                      )!
                                                          .alphabetical,
                                                    ),
                                                    selectedColor:
                                                        Theme.of(context)
                                                            .colorScheme
                                                            .secondary
                                                            .withOpacity(0.2),
                                                    labelStyle: TextStyle(
                                                      color: category ==
                                                              'alphabetical'
                                                          ? Theme.of(context)
                                                              .colorScheme
                                                              .secondary
                                                          : Theme.of(context)
                                                              .textTheme
                                                              .bodyText1!
                                                              .color,
                                                      fontWeight: category ==
                                                              'alphabetical'
                                                          ? FontWeight.w600
                                                          : FontWeight.normal,
                                                    ),
                                                    selected: category ==
                                                        'alphabetical',
                                                    onSelected:
                                                        (bool selected) {
                                                      if (selected) {
                                                        category =
                                                            'alphabetical';
                                                        sortOrder = 'asc';
                                                        status = false;
                                                        setState(() {});
                                                      }
                                                    },
                                                  ),
                                                  const Spacer(),
                                                  if (data['Top Songs'] != null)
                                                    MultiDownloadButton(
                                                      data: data['Top Songs']!,
                                                      playlistName: widget
                                                              .data['title']
                                                              ?.toString() ??
                                                          'Songs',
                                                    ),
                                                  const SizedBox(
                                                    width: 5,
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      if (entry.key != 'Top Songs')
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                            5,
                                            10,
                                            5,
                                            0,
                                          ),
                                          child: HorizontalAlbumsList(
                                            songsList: entry.value,
                                            onTap: (int idx) {
                                              Navigator.push(
                                                context,
                                                PageRouteBuilder(
                                                  opaque: false,
                                                  pageBuilder: (
                                                    _,
                                                    __,
                                                    ___,
                                                  ) =>
                                                      entry.key ==
                                                              'Related Artists'
                                                          ? ArtistSearchPage(
                                                              data: entry.value[
                                                                  idx] as Map,
                                                            )
                                                          : SongsListPage(
                                                              listItem: entry
                                                                      .value[
                                                                  idx] as Map,
                                                            ),
                                                ),
                                              );
                                            },
                                          ),
                                        )
                                      else
                                        ListView.builder(
                                          itemCount: entry.value.length,
                                          padding: const EdgeInsets.fromLTRB(
                                            5,
                                            5,
                                            5,
                                            0,
                                          ),
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          shrinkWrap: true,
                                          itemBuilder: (context, index) {
                                            return ListTile(
                                              contentPadding:
                                                  const EdgeInsets.only(
                                                left: 15.0,
                                              ),
                                              title: Text(
                                                '${entry.value[index]["title"]}',
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              onLongPress: () {
                                                copyToClipboard(
                                                  context: context,
                                                  text:
                                                      '${entry.value[index]["title"]}',
                                                );
                                              },
                                              subtitle: Text(
                                                '${entry.value[index]["subtitle"]}',
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              leading: Card(
                                                elevation: 8,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                    7.0,
                                                  ),
                                                ),
                                                clipBehavior: Clip.antiAlias,
                                                child: CachedNetworkImage(
                                                  fit: BoxFit.cover,
                                                  errorWidget:
                                                      (context, _, __) => Image(
                                                    fit: BoxFit.cover,
                                                    image: AssetImage(
                                                      (entry.key ==
                                                                  'Top Songs' ||
                                                              entry.key ==
                                                                  'Latest Release')
                                                          ? 'assets/cover.jpg'
                                                          : 'assets/album.png',
                                                    ),
                                                  ),
                                                  imageUrl:
                                                      '${entry.value[index]["image"].replaceAll('http:', 'https:')}',
                                                  placeholder: (context, url) =>
                                                      Image(
                                                    fit: BoxFit.cover,
                                                    image: AssetImage(
                                                      (entry.key ==
                                                                  'Top Songs' ||
                                                              entry.key ==
                                                                  'Latest Release' ||
                                                              entry.key ==
                                                                  'Singles')
                                                          ? 'assets/cover.jpg'
                                                          : 'assets/album.png',
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              trailing: (entry.key ==
                                                          'Top Songs' ||
                                                      entry.key ==
                                                          'Latest Release' ||
                                                      entry.key == 'Singles')
                                                  ? Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        DownloadButton(
                                                          data:
                                                              entry.value[index]
                                                                  as Map,
                                                          icon: 'download',
                                                        ),
                                                        LikeButton(
                                                          data:
                                                              entry.value[index]
                                                                  as Map,
                                                          mediaItem: null,
                                                        ),
                                                        SongTileTrailingMenu(
                                                          data:
                                                              entry.value[index]
                                                                  as Map,
                                                        ),
                                                      ],
                                                    )
                                                  : null,
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  PageRouteBuilder(
                                                    opaque: false,
                                                    pageBuilder: (
                                                      _,
                                                      __,
                                                      ___,
                                                    ) =>
                                                        (entry.key ==
                                                                    'Top Songs' ||
                                                                entry.key ==
                                                                    'Latest Release' ||
                                                                entry.key ==
                                                                    'Singles')
                                                            ? PlayScreen(
                                                                songsList:
                                                                    entry.value,
                                                                index: index,
                                                                offline: false,
                                                                fromMiniplayer:
                                                                    false,
                                                                fromDownloads:
                                                                    false,
                                                                recommend: true,
                                                              )
                                                            : SongsListPage(
                                                                listItem: entry
                                                                        .value[
                                                                    index] as Map,
                                                              ),
                                                  ),
                                                );
                                              },
                                            );
                                          },
                                        ),
                                    ],
                                  );
                                },
                              ).toList(),
                            ),
                          ),
                        ),
            ),
          ),
          const MiniPlayer(),
        ],
      ),
    );
  }
}
