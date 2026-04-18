import 'dart:collection';

/// A simple stub class to mimic audio playback
class AudioPlayerStub {
  final String name;
  double _volume = 1.0;

  AudioPlayerStub(this.name);

  Future<void> setVolume(double volume) async {
    _volume = volume;
  }

  Future<void> resume() async {
    // Do nothing (stub)
  }

  Future<void> pause() async {
    // Do nothing (stub)
  }

  Future<void> dispose() async {
    // Do nothing (stub)
  }
}

class WorkspaceAudio {
  final WorkspaceAudio? parentWorkspace;
  final Map<String, AudioPlayerStub> _sounds = HashMap();
  DateTime? _lastSound;

  /// Limit between sounds in milliseconds
  static const int soundLimit = 100;

  WorkspaceAudio({this.parentWorkspace});

  /// Load an audio file (stub)
  Future<void> load(String path, String name) async {
    _sounds[name] = AudioPlayerStub(name);
  }

  /// Preload all sounds (stub)
  Future<void> preload() async {
    for (final player in _sounds.values) {
      await player.setVolume(0.01);
      await player.resume();
      await player.pause();
    }
  }

  /// Play a sound by name (stub)
  Future<void> play(String name, {double volume = 1.0}) async {
    final sound = _sounds[name];
    final now = DateTime.now();
    if (_lastSound != null &&
        now.difference(_lastSound!).inMilliseconds < soundLimit) {
      return;
    }
    _lastSound = now;

    if (sound != null) {
      await sound.setVolume(volume);
      await sound.resume();
    } else if (parentWorkspace != null) {
      await parentWorkspace!.play(name, volume: volume);
    }
  }

  /// Dispose all audio players (stub)
  Future<void> dispose() async {
    for (final player in _sounds.values) {
      await player.dispose();
    }
    _sounds.clear();
  }

  /// Static helper to mimic InjectHelpers.loadSounds
  static Future<void> loadSounds(
      String pathToMedia, WorkspaceAudio workspace) async {
    // Load default sounds (stub)
    await workspace.load('$pathToMedia/click.mp3', 'click');
    await workspace.load('$pathToMedia/error.mp3', 'error');
  }
}
