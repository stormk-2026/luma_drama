import '../../catalog/domain/drama.dart';

/// A player session has one navigation meaning: browse dramas or browse episodes.
class PlaybackQueue {
  PlaybackQueue.home(List<Drama> dramas)
    : entries = List.unmodifiable(
        dramas
            .where((drama) => drama.episodes.isNotEmpty)
            .map((drama) => PlaybackEntry(drama, drama.episodes.first)),
      );

  PlaybackQueue.series(Drama drama)
    : entries = List.unmodifiable(
        drama.episodes.map((episode) => PlaybackEntry(drama, episode)),
      );

  final List<PlaybackEntry> entries;

  int get length => entries.length;
  PlaybackEntry entryAt(int index) => entries[index];
  int? nextIndex(int index) => index + 1 < entries.length ? index + 1 : null;
}

class PlaybackEntry {
  const PlaybackEntry(this.drama, this.episode);
  final Drama drama;
  final Episode episode;
}
