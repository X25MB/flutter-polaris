import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:polaris/platform/dto.dart';
import 'package:polaris/playback/media_item.dart';
import 'package:polaris/playback/media_proxy.dart';
import 'package:polaris/playback/player_task.dart';
import 'package:polaris/ui/strings.dart';
import 'package:polaris/ui/utils/thumbnail.dart';
import 'package:rxdart/rxdart.dart';

final getIt = GetIt.instance;

class Player extends StatefulWidget {
  @override
  _PlayerState createState() => _PlayerState();
}

class _PlayerState extends State<Player> {
  @override
  void initState() {
    super.initState();
    // TODO determine if we ever need to stop this
    AudioService.start(
      backgroundTaskEntrypoint: audioPlayerTaskEntrypoint,
      androidNotificationChannelName: appName,
      androidNotificationColor: Colors.blue[400].value, // TODO evaluate where this goes and how it looks
      androidNotificationIcon: 'mipmap/ic_launcher',
      androidEnableQueue: true,
      params: {
        MediaProxy.portParam: getIt<MediaProxy>().port,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<MediaItem>(
        stream: AudioService.currentMediaItemStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Container(); // TODO animate the whole thing out when no data
          }
          final theme = Theme.of(context);
          final backgroundColor = theme.colorScheme.surface;
          final foregroundColor = theme.colorScheme.onSurface;
          final song = snapshot.data.toSong();
          return SizedBox(
              height: 64,
              child: Material(
                elevation: 8,
                child: Container(
                  color: backgroundColor,
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: ListThumbnail(song.artwork),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              song.title,
                              style: theme.textTheme.subtitle2.copyWith(color: foregroundColor),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            Text(
                              song.artist,
                              style: theme.textTheme.caption.copyWith(color: foregroundColor.withOpacity(0.75)),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                      StreamBuilder<PlaybackState>(
                        stream: AudioService.playbackStateStream,
                        builder: (context, snapshot) {
                          bool playing = false;
                          if (snapshot.hasData) {
                            playing = snapshot.data.playing &&
                                snapshot.data.processingState != AudioProcessingState.completed;
                          }
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (playing) pauseButton(foregroundColor) else playButton(foregroundColor),
                              nextButton(foregroundColor), // TODO grey out when cannot skip next
                            ],
                          );
                        },
                      ),
                      // TODO Buffering indicator
                      // TODO Seekbar
                    ],
                  ),
                ),
              ));
        });
  }
}

IconButton pauseButton(Color color) => IconButton(
      icon: Icon(Icons.pause),
      onPressed: AudioService.pause,
      iconSize: 24.0,
      color: color,
    );

IconButton playButton(Color color) => IconButton(
      icon: Icon(Icons.play_arrow),
      onPressed: AudioService.play,
      iconSize: 24.0,
      color: color,
    );

IconButton nextButton(Color color) => IconButton(
      icon: Icon(Icons.skip_next),
      onPressed: AudioService.skipToNext,
      iconSize: 24.0,
      color: color,
    );
