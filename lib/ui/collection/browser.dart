import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get_it/get_it.dart';
import 'package:polaris/platform/api.dart';
import 'package:polaris/platform/dto.dart' as dto;
import 'package:polaris/ui/collection/album_details.dart';
import 'package:polaris/ui/collection/album_grid.dart';
import 'package:polaris/ui/strings.dart';
import 'package:polaris/ui/utils/error_message.dart';
import 'package:polaris/ui/utils/format.dart';
import 'package:polaris/ui/utils/thumbnail.dart';

final getIt = GetIt.instance;

class Browser extends StatefulWidget {
  final bool handleBackButton;

  Browser({this.handleBackButton, Key key}) : super(key: key);

  @override
  _BrowserState createState() => _BrowserState();
}

class _BrowserState extends State<Browser> with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  List<String> _locations = [''];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Future<bool> didPopRoute() async {
    if (!widget.handleBackButton) {
      return false;
    }
    return _navigateToParent();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final Color fillColor = Theme.of(context).scaffoldBackgroundColor;
    final sharedAxisTransition =
        SharedAxisPageTransitionsBuilder(transitionType: SharedAxisTransitionType.scaled, fillColor: fillColor);
    final PageTransitionsTheme transitionTheme = PageTransitionsTheme(
        builders: {TargetPlatform.android: sharedAxisTransition, TargetPlatform.iOS: sharedAxisTransition});

    return Theme(
      data: Theme.of(context).copyWith(pageTransitionsTheme: transitionTheme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Breadcrumbs(_locations.last, _popLocations),
          ),
          Expanded(
            child: Navigator(
              pages: _locations.map((location) {
                return MaterialPage(
                    child: BrowserLocation(
                  location,
                  onDirectoryTapped: _enterDirectory,
                  navigateBack: () => _navigateToParent(),
                ));
              }).toList(),
              onPopPage: (route, result) {
                return route.didPop(result);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _enterDirectory(dto.Directory directory) {
    final newLocations = List<String>.from(_locations);
    newLocations.add(directory.path);
    setState(() {
      _locations = newLocations;
    });
  }

  void _popLocations(int numLocationsToPop) {
    final newLocations = _locations.take(_locations.length - numLocationsToPop).toList();
    setState(() {
      _locations = newLocations;
    });
  }

  bool _navigateToParent() {
    if (_locations.length <= 1) {
      return false;
    }

    final newLocations = List<String>.from(_locations);
    newLocations.removeLast();
    setState(() {
      _locations = newLocations;
    });
    return true;
  }

  @override
  bool get wantKeepAlive => true;
}

enum ViewMode {
  explorer,
  discography,
}

class BrowserLocation extends StatefulWidget {
  final String location;
  final void Function(dto.Directory) onDirectoryTapped;
  final void Function() navigateBack;

  BrowserLocation(this.location, {@required this.onDirectoryTapped, @required this.navigateBack, Key key})
      : assert(location != null),
        assert(onDirectoryTapped != null),
        super(key: key);

  @override
  _BrowserLocationState createState() => _BrowserLocationState();
}

class _BrowserLocationState extends State<BrowserLocation> {
  List<dto.CollectionFile> _files;
  APIError _error;

  @override
  initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() async {
    setState(() {
      _files = null;
      _error = null;
    });
    try {
      final files = await getIt<API>().browse(widget.location);
      setState(() {
        _files = files;
      });
    } on APIError catch (e) {
      setState(() {
        _error = e;
      });
    }
  }

  ViewMode _getViewMode() {
    if (_files == null || _files.length == 0) {
      return ViewMode.explorer;
    }

    var onlyDirectories = true;
    var hasAnyPicture = false;
    var allHaveAlbums = true;
    for (var file in _files) {
      onlyDirectories &= file.isDirectory();
      hasAnyPicture |= file.asDirectory()?.artwork != null;
      allHaveAlbums &= file.asDirectory()?.album != null;
    }

    if (onlyDirectories && hasAnyPicture && allHaveAlbums) {
      return ViewMode.discography;
    }
    return ViewMode.explorer;
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return ErrorMessage(
        browseError,
        action: _fetchData,
        actionLabel: retryButtonLabel,
      );
    }

    if (_files == null) {
      return Center(child: CircularProgressIndicator());
    }

    if (_files.length == 0) {
      return ErrorMessage(
        emptyDirectory,
        action: widget.navigateBack,
        actionLabel: goBackButtonLabel,
      );
    }

    if (_getViewMode() == ViewMode.discography) {
      final albums = _files.map((f) => f.asDirectory()).toList();
      return AlbumGrid(albums);
    } else {
      return ListView.builder(
        physics: BouncingScrollPhysics(),
        itemCount: _files.length,
        itemBuilder: (context, index) {
          final file = _files[index];
          if (file.isDirectory()) {
            final directory = file.asDirectory();
            return Directory(directory, onTap: () => widget.onDirectoryTapped(directory));
          } else {
            assert(file.isSong());
            return Song(file.asSong());
          }
        },
      );
    }
  }
}

class Directory extends StatelessWidget {
  final dto.Directory directory;
  final GestureTapCallback onTap;

  Directory(this.directory, {this.onTap, Key key})
      : assert(directory != null),
        super(key: key);

  Widget _getLeading() {
    if (directory.artwork != null || directory.album != null) {
      return ListThumbnail(directory.artwork);
    }
    return Icon(Icons.folder);
  }

  Widget _getSubtitle() {
    if (directory.album != null) {
      return Text(directory.formatArtist());
    }
    return null;
  }

  ListTile _buildTile({void Function() onTap}) {
    return ListTile(
      leading: _getLeading(),
      title: Text(directory.formatName()),
      subtitle: _getSubtitle(),
      trailing: Icon(Icons.more_vert),
      dense: true,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAlbum = directory.album != null;
    final tile = _buildTile(onTap: isAlbum ? null : onTap);
    if (!isAlbum) {
      return Material(child: tile);
    } else {
      return OpenContainer(
        closedElevation: 0,
        useRootNavigator: true,
        transitionType: ContainerTransitionType.fade,
        closedColor: Theme.of(context).scaffoldBackgroundColor,
        openColor: Theme.of(context).scaffoldBackgroundColor,
        openBuilder: (context, action) => AlbumDetails(directory),
        closedBuilder: (context, action) => Material(child: InkWell(child: tile, enableFeedback: true, onTap: action)),
      );
    }
  }
}

class Song extends StatelessWidget {
  final dto.Song song;

  Song(this.song, {Key key})
      : assert(song != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: ListThumbnail(song.artwork),
      title: Text(song.formatTrackNumberAndTitle(), overflow: TextOverflow.ellipsis),
      subtitle: Text(song.formatArtist(), overflow: TextOverflow.ellipsis),
      trailing: Icon(Icons.more_vert),
      dense: true,
    );
  }
}

class Breadcrumbs extends StatefulWidget {
  final String path;
  final void Function(int) popLocations;

  Breadcrumbs(this.path, this.popLocations, {Key key})
      : assert(path != null),
        super(key: key);

  @override
  _BreadcrumbsState createState() => _BreadcrumbsState();
}

class _BreadcrumbsState extends State<Breadcrumbs> {
  final _scrollController = ScrollController();

  List<String> _getSegments() {
    return ["All"].followedBy(splitPath(widget.path).where((s) => s.isNotEmpty)).toList();
  }

  @override
  void didUpdateWidget(Breadcrumbs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) {
      _scrollToEnd();
    }
  }

  void _scrollToEnd() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _scrollController.jumpTo(
        _scrollController.position.maxScrollExtent,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<String> segments = _getSegments();

    final textWidgets = segments.asMap().entries.map((entry) {
      final int index = entry.key;
      final String value = entry.value;
      final style = index == segments.length - 1 ? TextStyle(color: Theme.of(context).accentColor) : null;
      return GestureDetector(
        onTap: () => widget.popLocations(segments.length - 1 - index),
        child: Text(value, style: style),
      );
    });
    List<Widget> children = textWidgets.expand((t) => [Icon(Icons.chevron_right), t]).skip(1).toList();

    return ScrollConfiguration(
      behavior: BreadcrumbsScrollBehavior(),
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        child: Row(
          children: children,
        ),
      ),
    );
  }
}

// Disable ink
class BreadcrumbsScrollBehavior extends ScrollBehavior {
  @override
  Widget buildViewportChrome(BuildContext context, Widget child, AxisDirection axisDirection) {
    return child;
  }
}
