import 'package:just_audio/just_audio.dart';
import 'package:polaris/core/dto.dart';
import 'package:polaris/core/media_item.dart';
import 'package:polaris/core/polaris.dart' as polaris;
import 'package:uuid/uuid.dart';

class Playlist {
  final _audioSource = new ConcatenatingAudioSource(children: []);
  final Uuid uuid;
  final polaris.Client polarisClient;
  final AudioPlayer audioPlayer;

  AudioSource get audioSource => _audioSource;

  Playlist({
    required this.uuid,
    required this.polarisClient,
    required this.audioPlayer,
  });

  Future queueLast(Song song) async {
    final bool wasEmpty = _audioSource.sequence.isEmpty;
    final songAudioSource = _makeSongAudioSource(song);
    await _audioSource.add(songAudioSource);
    if (wasEmpty) {
      audioPlayer.play();
    }
  }

  Future queueNext(Song song) async {
    final bool wasEmpty = _audioSource.sequence.isEmpty;
    final songAudioSource = _makeSongAudioSource(song);
    final int insertIndex = 1 + (audioPlayer.currentIndex ?? -1);
    await _audioSource.insert(insertIndex, songAudioSource);
    if (wasEmpty) {
      audioPlayer.play();
    }
  }

  Future moveSong(int oldIndex, int newIndex) async {
    if (oldIndex == newIndex ||
        oldIndex < 0 ||
        oldIndex >= _audioSource.length ||
        newIndex < 0 ||
        newIndex > _audioSource.length) {
      return;
    }
    final int insertIndex = oldIndex > newIndex ? newIndex : newIndex - 1;
    return _audioSource.move(oldIndex, insertIndex);
  }

  AudioSource _makeSongAudioSource(Song song) {
    final songURI = polarisClient.getAudioURI(song.path);
    final mediaItem = song.toMediaItem(uuid, polarisClient);
    return AudioSource.uri(songURI, tag: mediaItem);
  }
}
