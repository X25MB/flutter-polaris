import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:polaris/core/dto.dart' as dto;
import 'package:polaris/core/playlist.dart';
import 'package:polaris/core/polaris.dart' as polaris;
import 'package:polaris/ui/strings.dart';

final getIt = GetIt.instance;

void noop() {}

enum CollectionFileAction {
  queueLast,
  queueNext,
  refresh,
  removeFromQueue,
}

class CollectionFileContextMenuButton extends StatelessWidget {
  final dto.CollectionFile file;
  final List<dto.Song>? children;
  final IconData icon;
  final bool compact;
  final List<CollectionFileAction> actions;
  final void Function() onRefresh;
  final void Function() onRemoveFromQueue;

  const CollectionFileContextMenuButton(
      {required this.file,
      required this.actions,
      this.children,
      this.compact = false,
      this.icon = Icons.more_vert,
      this.onRefresh = noop,
      this.onRemoveFromQueue = noop,
      Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Mimic logic from ListTile._iconColor
    const iconSize = 20.0;
    final theme = Theme.of(context);
    final ListTileTheme tileTheme = ListTileTheme.of(context);
    var iconColor = tileTheme.iconColor;
    iconColor ??= theme.brightness == Brightness.light ? Colors.black45 : theme.iconTheme.color;

    final icon = Icon(
      this.icon,
      color: iconColor,
      size: iconSize,
    );

    PopupMenuItem<CollectionFileAction> buildButton(CollectionFileAction action, IconData icon, String label) {
      return PopupMenuItem<CollectionFileAction>(
        value: action,
        child: Row(
          children: [
            Padding(padding: const EdgeInsets.only(right: 16.0), child: Icon(icon)),
            Text(label),
          ],
        ),
      );
    }

    return PopupMenuButton<CollectionFileAction>(
      // Manually specify child because default IconButton comes with an excessive minimum size of 48x48
      child: compact ? icon : null,
      icon: compact ? null : icon,
      iconSize: iconSize,
      onSelected: (CollectionFileAction result) async {
        final Playlist playlist = getIt<Playlist>();
        final polaris.Client client = getIt<polaris.Client>();

        late List<dto.Song> songs;
        final knownSongs = children;
        if (file.isDirectory()) {
          if (knownSongs == null) {
            // TODO show some kind of UI while this is in progress (+ confirm)
            songs = await client.flatten(file.asDirectory().path);
          } else {
            songs = knownSongs;
          }
        } else {
          songs = [file.asSong()];
        }

        switch (result) {
          case CollectionFileAction.queueLast:
            playlist.queueLast(songs);
            break;
          case CollectionFileAction.queueNext:
            playlist.queueNext(songs);
            break;
          case CollectionFileAction.refresh:
            onRefresh();
            break;
          case CollectionFileAction.removeFromQueue:
            onRemoveFromQueue();
            break;
          default:
            break;
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<CollectionFileAction>>[
        if (actions.contains(CollectionFileAction.queueLast))
          buildButton(CollectionFileAction.queueLast, Icons.playlist_add, queueLast),
        if (actions.contains(CollectionFileAction.queueNext))
          buildButton(CollectionFileAction.queueNext, Icons.playlist_play, queueNext),
        if (actions.contains(CollectionFileAction.refresh))
          buildButton(CollectionFileAction.refresh, Icons.refresh, refresh),
        if (actions.contains(CollectionFileAction.removeFromQueue))
          buildButton(CollectionFileAction.removeFromQueue, Icons.clear, removeFromQueue),
      ],
    );
  }
}
